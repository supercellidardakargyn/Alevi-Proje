import { Router } from 'express';
import { discoverQuerySchema } from '@alevi/contracts';
import { PrismaClient } from '@prisma/client';
import { validate } from '../middleware/validation';
import { asyncHandler, userId } from './route-utils';
import { toPublicProfile, publicProfileSelect } from '../services/profiles';

export function discoverRoutes(prisma: PrismaClient): Router {
  const router = Router();
  router.get('/', validate(discoverQuerySchema, 'query'), asyncHandler(async (req, res) => {
    const currentUserId = userId(req);
    const query = req.query as unknown as { cursor?: string; limit: number; q?: string; city?: string; district?: string; country?: string; latitude?: number; longitude?: number; maxDistanceKm?: number };
    const [me, blocks, swipes, myAttendances] = await Promise.all([
      prisma.user.findUnique({ where: { id: currentUserId }, select: { interests: true } }),
      prisma.block.findMany({ where: { OR: [{ blockerId: currentUserId }, { blockedId: currentUserId }] }, select: { blockerId: true, blockedId: true } }),
      prisma.swipe.findMany({ where: { fromUserId: currentUserId }, select: { toUserId: true } }),
      prisma.eventAttendee.findMany({ where: { userId: currentUserId }, select: { eventId: true } })
    ]);
    const excluded = new Set<string>([currentUserId]);
    for (const block of blocks) { excluded.add(block.blockerId); excluded.add(block.blockedId); }
    for (const swipe of swipes) { excluded.add(swipe.toUserId); }
    const useGeo = query.latitude !== undefined && query.longitude !== undefined && query.maxDistanceKm !== undefined;
    const users = await prisma.user.findMany({
      where: {
        deletedAt: null,
        id: { notIn: [...excluded] },
        ...(query.q ? { displayName: { contains: query.q, mode: 'insensitive' as const } } : {}),
        ...(query.country ? { country: { equals: query.country, mode: 'insensitive' as const } } : {}),
        ...(query.city ? { city: { equals: query.city, mode: 'insensitive' as const } } : {}),
        ...(query.district ? { district: { equals: query.district, mode: 'insensitive' as const } } : {})
      },
      select: { ...publicProfileSelect, latitude: true, longitude: true },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      // Konum filtresi bellege uygulanir; tutarli cursor icin o durumda cursor yoksayilir.
      take: useGeo ? 200 : query.limit + 1,
      ...(!useGeo && query.cursor ? { skip: 1, cursor: { id: query.cursor } } : {})
    });
    let items = users;
    if (useGeo) {
      items = users.filter((user) => {
        if (user.latitude == null || user.longitude == null) return false;
        return haversineKm(query.latitude as number, query.longitude as number, user.latitude, user.longitude) <= (query.maxDistanceKm as number);
      });
    }
    // Etkinlikten eslesme: ayni etkinliklere katilanlar one cikar.
    const myEventIds = new Set(myAttendances.map((row) => row.eventId));
    let sharedCounts: Record<string, number> = {};
    if (myEventIds.size > 0) {
      const overlaps = await prisma.eventAttendee.findMany({
        where: { eventId: { in: [...myEventIds] }, userId: { not: currentUserId } },
        select: { userId: true }
      });
      sharedCounts = {};
      for (const row of overlaps) sharedCounts[row.userId] = (sharedCounts[row.userId] ?? 0) + 1;
    }
    const myInterests = me?.interests ?? [];
    const withBoost = items.map((user) => {
      const profile = toPublicProfile(user, { myInterests, sharedEvents: sharedCounts[user.id] ?? 0 });
      const boost = profile.sharedEvents * 10 + profile.sharedInterests.length;
      return { profile, boost };
    });
    const boosted = withBoost.some((entry) => entry.boost > 0);
    const ordered = boosted
      ? withBoost.sort((a, b) => b.boost - a.boost).map((entry) => entry.profile)
      : withBoost.map((entry) => entry.profile);
    const limited = ordered.slice(0, query.limit + 1);
    const hasMore = limited.length > query.limit;
    const page = hasMore ? limited.slice(0, query.limit) : limited;
    res.json({ data: { items: page, nextCursor: !useGeo && !boosted && hasMore ? page.at(-1)?.id ?? null : null } });
  }));
  return router;
}

function haversineKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const toRad = (value: number): number => (value * Math.PI) / 180;
  const earthKm = 6371;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
  return 2 * earthKm * Math.asin(Math.sqrt(a));
}
