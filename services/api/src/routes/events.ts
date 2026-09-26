import { Router } from 'express';
import { z } from 'zod';
import { createEventRequestSchema, deviceTokenRequestSchema } from '@alevi/contracts';
import { PrismaClient } from '@prisma/client';
import { validate } from '../middleware/validation';
import { asyncHandler, notFoundIfNull, routeParam, userId } from './route-utils';

const eventListQuerySchema = z.object({
  city: z.string().trim().max(120).optional(),
  limit: z.coerce.number().int().min(1).max(50).default(30)
});

export function eventRoutes(prisma: PrismaClient): Router {
  const router = Router();
  router.get('/', validate(eventListQuerySchema, 'query'), asyncHandler(async (req, res) => {
    const query = req.query as unknown as { city?: string; limit: number };
    const events = await prisma.event.findMany({
      where: { startsAt: { gte: new Date() }, ...(query.city ? { city: query.city } : {}) },
      include: { _count: { select: { attendees: true } } },
      orderBy: { startsAt: 'asc' },
      take: query.limit
    });
    const mine = await prisma.eventAttendee.findMany({
      where: { userId: userId(req), eventId: { in: events.map((event) => event.id) } },
      select: { eventId: true }
    });
    const joined = new Set(mine.map((row) => row.eventId));
    res.json({
      data: events.map((event) => ({
        id: event.id,
        title: event.title,
        description: event.description,
        city: event.city,
        startsAt: event.startsAt.toISOString(),
        attendeeCount: event._count.attendees,
        joined: joined.has(event.id)
      }))
    });
  }));
  router.post('/', validate(createEventRequestSchema), asyncHandler(async (req, res) => {
    const body = req.body as { title: string; description?: string; city?: string; latitude?: number; longitude?: number; startsAt: string };
    const event = await prisma.$transaction(async (tx) => {
      const created = await tx.event.create({
        data: { creatorId: userId(req), title: body.title, description: body.description, city: body.city, latitude: body.latitude, longitude: body.longitude, startsAt: new Date(body.startsAt) }
      });
      await tx.eventAttendee.create({ data: { eventId: created.id, userId: userId(req) } });
      return created;
    });
    res.status(201).json({ data: { ...event, attendeeCount: 1, joined: true } });
  }));
  router.post('/:id/join', asyncHandler(async (req, res) => {
    const eventId = routeParam(req, 'id');
    notFoundIfNull(await prisma.event.findUnique({ where: { id: eventId }, select: { id: true } }), 'Event');
    await prisma.eventAttendee.upsert({
      where: { eventId_userId: { eventId, userId: userId(req) } },
      create: { eventId, userId: userId(req) },
      update: {}
    });
    res.status(201).json({ data: { joined: true } });
  }));
  router.delete('/:id/join', asyncHandler(async (req, res) => {
    await prisma.eventAttendee.deleteMany({ where: { eventId: routeParam(req, 'id'), userId: userId(req) } });
    res.status(204).send();
  }));
  return router;
}

export function deviceRoutes(prisma: PrismaClient): Router {
  const router = Router();
  router.post('/token', validate(deviceTokenRequestSchema), asyncHandler(async (req, res) => {
    const body = req.body as { token: string; platform: string };
    await prisma.deviceToken.upsert({
      where: { token: body.token },
      create: { userId: userId(req), token: body.token, platform: body.platform },
      update: { userId: userId(req) }
    });
    res.status(201).json({ data: { saved: true } });
  }));
  router.delete('/token', asyncHandler(async (req, res) => {
    const token = typeof req.query.token === 'string' ? req.query.token : '';
    if (token) await prisma.deviceToken.deleteMany({ where: { userId: userId(req), token } });
    res.status(204).send();
  }));
  return router;
}
