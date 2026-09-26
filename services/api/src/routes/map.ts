import { Router } from 'express';
import { z } from 'zod';
import { PrismaClient } from '@prisma/client';
import { validate } from '../middleware/validation';
import { asyncHandler, userId } from './route-utils';

const nearbyQuerySchema = z.object({
  lat: z.coerce.number().min(-90).max(90),
  lng: z.coerce.number().min(-180).max(180),
  radiusKm: z.coerce.number().min(1).max(500).default(50),
  limit: z.coerce.number().int().min(1).max(200).default(120)
});

const EARTH_RADIUS_KM = 6371;

/** Iki koordinat arasindaki km cinsinden mesafe. */
function distanceKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const toRad = (value: number) => (value * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return 2 * EARTH_RADIUS_KM * Math.asin(Math.min(1, Math.sqrt(a)));
}

/**
 * Kisisellik: uye konumu 0.02 derece (~2 km) yukseklige yuvarlanir, boylece
 * harita yaklasik konum gosterir ve kullanicinin tam adresi sizmaz.
 */
function blur(latitude: number, longitude: number): { latitude: number; longitude: number } {
  return {
    latitude: Math.round(latitude * 50) / 50,
    longitude: Math.round(longitude * 50) / 50
  };
}

/**
 * Harita ekrani icin yakin uyeler ve etkinlikler. Bloklanan kullanicilar
 * hicbir zaman listelenmez; gizli konumlu uyeler haritada yer almaz.
 */
export function mapRoutes(prisma: PrismaClient): Router {
  const router = Router();
  router.get('/nearby', validate(nearbyQuerySchema, 'query'), asyncHandler(async (req, res) => {
    const query = req.query as unknown as { lat: number; lng: number; radiusKm: number; limit: number };
    const currentUserId = userId(req);

    // Kaba kutu filtresi: veritabaninda once dar bir alana indir, sonra hesapla.
    const latDelta = query.radiusKm / 111;
    const lngDelta = query.radiusKm / (111 * Math.max(0.1, Math.cos((query.lat * Math.PI) / 180)));
    const bounds = {
      latitude: { gte: query.lat - latDelta, lte: query.lat + latDelta, not: null },
      longitude: { gte: query.lng - lngDelta, lte: query.lng + lngDelta, not: null }
    } as const;

    const [users, events, blocks] = await Promise.all([
      prisma.user.findMany({
        where: {
          id: { not: currentUserId },
          deletedAt: null,
          showMapLocation: true,
          ...bounds
        },
        select: {
          id: true,
          displayName: true,
          avatarUrl: true,
          city: true,
          district: true,
          country: true,
          latitude: true,
          longitude: true
        },
        take: query.limit * 2
      }),
      prisma.event.findMany({
        where: { startsAt: { gte: new Date() }, ...bounds },
        include: { _count: { select: { attendees: true } } },
        orderBy: { startsAt: 'asc' },
        take: query.limit
      }),
      prisma.block.findMany({
        where: {
          OR: [
            { blockerId: currentUserId },
            { blockedId: currentUserId }
          ]
        },
        select: { blockerId: true, blockedId: true }
      })
    ]);

    const hidden = new Set<string>();
    for (const block of blocks) {
      hidden.add(block.blockerId === currentUserId ? block.blockedId : block.blockerId);
    }

    const members = users
      .filter((user) => !hidden.has(user.id))
      .map((user) => {
        const position = blur(user.latitude as number, user.longitude as number);
        return {
          id: user.id,
          displayName: user.displayName,
          avatarUrl: user.avatarUrl,
          city: user.city,
          district: user.district,
          country: user.country,
          latitude: position.latitude,
          longitude: position.longitude,
          distanceKm: Math.round(distanceKm(query.lat, query.lng, position.latitude, position.longitude) * 10) / 10
        };
      })
      .filter((member) => member.distanceKm <= query.radiusKm)
      .sort((a, b) => a.distanceKm - b.distanceKm)
      .slice(0, query.limit);

    const eventRows = events
      .map((event) => ({
        id: event.id,
        title: event.title,
        city: event.city,
        startsAt: event.startsAt.toISOString(),
        attendeeCount: event._count.attendees,
        latitude: event.latitude as number,
        longitude: event.longitude as number
      }))
      .filter((event) => distanceKm(query.lat, query.lng, event.latitude, event.longitude) <= query.radiusKm)
      .map((event) => ({
        ...event,
        distanceKm: Math.round(distanceKm(query.lat, query.lng, event.latitude, event.longitude) * 10) / 10
      }));

    res.json({ data: { members, events: eventRows } });
  }));
  return router;
}
