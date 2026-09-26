import { Router } from 'express';
import {
  bioCoachRequestSchema,
  icebreakerRequestSchema,
  matchNoteRequestSchema,
  smartRepliesRequestSchema,
  summarizeRequestSchema
} from '@alevi/contracts';
import { PrismaClient } from '@prisma/client';
import { validate } from '../middleware/validation';
import { ApiError } from '../middleware/errors';
import { decryptText } from '../security/fields';
import { coachBio, icebreakers, matchNote, smartReplies, summarizeChat } from '../services/ai';
import { asyncHandler, notFoundIfNull, userId } from './route-utils';

const HISTORY_TAKE = 50;

/** Kullanici sohbetin uyesi degilse 403 firlatir. */
async function requireMembership(prisma: PrismaClient, conversationId: string, currentUserId: string): Promise<void> {
  const member = await prisma.conversationMember.findUnique({
    where: { conversationId_userId: { conversationId, userId: currentUserId } },
    select: { id: true }
  });
  if (!member) throw new ApiError(403, 'NOT_A_MEMBER', 'You are not a member of this conversation');
}

/** Iki yonlu blok kontrolu: engellenen kullanicinin istekleri reddedilir. */
async function ensureNotBlocked(prisma: PrismaClient, currentUserId: string, targetUserId: string): Promise<void> {
  if (currentUserId === targetUserId) throw new ApiError(400, 'SELF_TARGET', 'You cannot use this for yourself');
  const block = await prisma.block.findFirst({
    where: {
      OR: [
        { blockerId: currentUserId, blockedId: targetUserId },
        { blockerId: targetUserId, blockedId: currentUserId }
      ]
    },
    select: { id: true }
  });
  if (block) throw new ApiError(403, 'BLOCKED', 'This action is not available');
}

/** Sohbetin son mesajlarini cozerek dondurur. */
async function recentBodies(prisma: PrismaClient, conversationId: string, take: number): Promise<string[]> {
  const rows = await prisma.message.findMany({
    where: { conversationId, deletedAt: null },
    orderBy: { createdAt: 'desc' },
    take,
    select: { body: true }
  });
  return rows.reverse().map((row) => decryptText(row.body));
}

export function aiRoutes(prisma: PrismaClient): Router {
  const router = Router();

  // Akilli yanit onerileri: son mesaja gore 3 hazir cevap.
  router.post('/smart-replies', validate(smartRepliesRequestSchema), asyncHandler(async (req, res) => {
    const { conversationId } = req.body as { conversationId: string };
    const currentUserId = userId(req);
    await requireMembership(prisma, conversationId, currentUserId);
    const bodies = await recentBodies(prisma, conversationId, HISTORY_TAKE);
    if (bodies.length === 0) {
      res.json({ data: { suggestions: [] } });
      return;
    }
    const suggestions = await smartReplies(bodies.slice(-6));
    res.json({ data: { suggestions: suggestions ?? [] } });
  }));

  // Buz kirici: hedef profile gore 3 ilk mesaj onerisi.
  router.post('/icebreakers', validate(icebreakerRequestSchema), asyncHandler(async (req, res) => {
    const { userId: targetId } = req.body as { userId: string };
    const currentUserId = userId(req);
    await ensureNotBlocked(prisma, currentUserId, targetId);
    const target = notFoundIfNull(
      await prisma.user.findFirst({
        where: { id: targetId, deletedAt: null },
        select: { displayName: true, bio: true, city: true, interests: true }
      }),
      'User'
    );
    const openers = await icebreakers({
      displayName: target.displayName,
      bio: target.bio,
      city: target.city,
      interests: target.interests
    });
    res.json({ data: { openers: openers ?? [] } });
  }));

  // Bio + buz kirici koaci.
  router.post('/bio-coach', validate(bioCoachRequestSchema), asyncHandler(async (req, res) => {
    const { bio } = req.body as { bio: string };
    const suggestion = await coachBio(bio);
    res.json({ data: { suggestion } });
  }));

  // Sohbet ozeti.
  router.post('/summarize', validate(summarizeRequestSchema), asyncHandler(async (req, res) => {
    const { conversationId } = req.body as { conversationId: string };
    await requireMembership(prisma, conversationId, userId(req));
    const bodies = await recentBodies(prisma, conversationId, HISTORY_TAKE);
    const summary = await summarizeChat(bodies);
    res.json({ data: { summary } });
  }));

  // Akilli eslesme notu: ortak ilgi alanlari + ortak etkinlik sayisi.
  router.post('/match-note', validate(matchNoteRequestSchema), asyncHandler(async (req, res) => {
    const { userId: targetId } = req.body as { userId: string };
    const currentUserId = userId(req);
    await ensureNotBlocked(prisma, currentUserId, targetId);
    const [target, me] = await Promise.all([
      notFoundIfNull(
        await prisma.user.findFirst({ where: { id: targetId, deletedAt: null }, select: { id: true, interests: true } }),
        'User'
      ),
      await prisma.user.findUnique({ where: { id: currentUserId }, select: { interests: true } })
    ]);
    const mine = me?.interests ?? [];
    const shared = target.interests ?? [];
    const sharedInterests = mine.filter((item) => shared.some((other) => other.toLowerCase() === item.toLowerCase()));
    const [myEvents, theirEvents] = await Promise.all([
      prisma.eventAttendee.findMany({ where: { userId: currentUserId }, select: { eventId: true } }),
      prisma.eventAttendee.findMany({ where: { userId: targetId }, select: { eventId: true } })
    ]);
    const theirSet = new Set(theirEvents.map((row) => row.eventId));
    const sharedEvents = myEvents.filter((row) => theirSet.has(row.eventId)).length;
    const note = await matchNote(sharedInterests, sharedEvents);
    res.json({ data: { note } });
  }));

  return router;
}
