import { Router } from 'express';
import { createMatchRequestSchema, matchActionSchema } from '@alevi/contracts';
import { MatchStatus, PrismaClient } from '@prisma/client';
import { validate } from '../middleware/validation';
import { config } from '../config';
import { ApiError } from '../middleware/errors';
import { asyncHandler, notFoundIfNull, routeParam, userId } from './route-utils';
import { toPublicProfile, publicProfileSelect } from '../services/profiles';

export function matchRoutes(prisma: PrismaClient): Router {
  const router = Router();
  router.get('/', asyncHandler(async (req, res) => {
    const id = userId(req);
    const matches = await prisma.match.findMany({ where: { OR: [{ userAId: id }, { userBId: id }], status: { not: 'UNMATCHED' } }, include: { userA: { select: publicProfileSelect }, userB: { select: publicProfileSelect } }, orderBy: { updatedAt: 'desc' }, take: 100 });
    res.json({ data: matches.map((match) => ({ id: match.id, status: match.status, createdAt: match.createdAt.toISOString(), user: toPublicProfile(match.userAId === id ? match.userB : match.userA) })) });
  }));

  router.post('/', validate(createMatchRequestSchema), asyncHandler(async (req, res) => {
    const id = userId(req);
    const input = req.body as { userId: string; decision: 'LIKE' | 'PASS' };
    if (id === input.userId) throw new ApiError(400, 'SELF_MATCH', 'You cannot match with yourself');
    const target = await prisma.user.findFirst({ where: { id: input.userId, deletedAt: null }, select: { id: true } });
    notFoundIfNull(target, 'User');
    const blocked = await prisma.block.findFirst({ where: { OR: [{ blockerId: id, blockedId: input.userId }, { blockerId: input.userId, blockedId: id }] } });
    if (blocked) throw new ApiError(403, 'BLOCKED', 'This interaction is not available');
    if (input.decision === 'LIKE') {
      // Yavas flort: once profilini tamamla, sonra gunluk kotan kadar begen.
      const liker = await prisma.user.findUnique({ where: { id }, select: { bio: true } });
      if (!liker || !liker.bio || liker.bio.trim().length < 20) {
        throw new ApiError(400, 'PROFILE_INCOMPLETE', 'Complete your profile first: write at least 20 characters about yourself');
      }
      const dayAgo = new Date(Date.now() - 24 * 3600 * 1000);
      const likesToday = await prisma.swipe.count({ where: { fromUserId: id, decision: 'LIKE', createdAt: { gte: dayAgo } } });
      if (likesToday >= config.dailyLikeLimit) {
        throw new ApiError(429, 'DAILY_LIMIT_REACHED', 'Daily like limit reached. Come back tomorrow.');
      }
    }
    await prisma.swipe.upsert({ where: { fromUserId_toUserId: { fromUserId: id, toUserId: input.userId } }, create: { fromUserId: id, toUserId: input.userId, decision: input.decision }, update: { decision: input.decision } });
    if (input.decision === 'PASS') return res.status(201).json({ data: { matched: false } });
    const reciprocal = await prisma.swipe.findUnique({ where: { fromUserId_toUserId: { fromUserId: input.userId, toUserId: id } } });
    if (!reciprocal || reciprocal.decision !== 'LIKE') return res.status(201).json({ data: { matched: false } });
    const [userAId, userBId] = [id, input.userId].sort();
    const match = await prisma.match.upsert({ where: { userAId_userBId: { userAId, userBId } }, create: { userAId, userBId, status: 'ACCEPTED' }, update: { status: 'ACCEPTED' }, include: { userA: { select: publicProfileSelect }, userB: { select: publicProfileSelect } } });
    const conversationId = await ensureDirectConversation(prisma, userAId, userBId);
    res.status(201).json({ data: { matched: true, match: { id: match.id, status: match.status, user: toPublicProfile(match.userAId === id ? match.userB : match.userA) }, conversationId } });
  }));

  router.delete('/swipes/last', asyncHandler(async (req, res) => {
    const id = userId(req);
    // En son kaydirmayi bul.
    const swipe = await prisma.swipe.findFirst({ where: { fromUserId: id }, orderBy: { updatedAt: 'desc' } });
    if (!swipe) throw new ApiError(404, 'SWIPE_NOT_FOUND', 'No swipe to undo');
    const otherId = swipe.toUserId;
    const [userAId, userBId] = [id, otherId].sort();
    await prisma.swipe.delete({ where: { id: swipe.id } });
    // Kaydirmadan sonra olusan eslesmeyi geri al, sohbet korunur.
    const match = await prisma.match.findFirst({ where: { userAId, userBId, status: 'ACCEPTED', createdAt: { gte: swipe.createdAt } } });
    let unmatched = false;
    if (match) {
      await prisma.match.update({ where: { id: match.id }, data: { status: 'UNMATCHED' } });
      unmatched = true;
    }
    res.json({ data: { undone: true, unmatched, userId: otherId } });
  }));

  router.patch('/:id', validate(matchActionSchema), asyncHandler(async (req, res) => {
    const id = userId(req);
    const matchId = routeParam(req, 'id');
    const match = notFoundIfNull(await prisma.match.findUnique({ where: { id: matchId } }), 'Match');
    if (match.userAId !== id && match.userBId !== id) throw new ApiError(403, 'FORBIDDEN', 'You are not a participant in this match');
    const status: MatchStatus = req.body.decision === 'ACCEPT' ? 'ACCEPTED' : 'REJECTED';
    const updated = await prisma.match.update({ where: { id: match.id }, data: { status } });
    res.json({ data: { id: updated.id, status: updated.status } });
  }));

  router.delete('/:id', asyncHandler(async (req, res) => {
    const id = userId(req);
    const matchId = routeParam(req, 'id');
    const match = notFoundIfNull(await prisma.match.findUnique({ where: { id: matchId } }), 'Match');
    if (match.userAId !== id && match.userBId !== id) throw new ApiError(403, 'FORBIDDEN', 'You are not a participant in this match');
    await prisma.match.update({ where: { id: match.id }, data: { status: 'UNMATCHED' } });
    res.status(204).send();
  }));
  return router;
}

async function ensureDirectConversation(prisma: PrismaClient, userAId: string, userBId: string): Promise<string> {
  const candidates = await prisma.conversation.findMany({
    where: { members: { some: { userId: userAId } } },
    include: { members: { select: { userId: true } } },
    take: 50
  });
  for (const candidate of candidates) {
    const ids = candidate.members.map((member) => member.userId).sort();
    if (ids.length === 2 && ids[0] === userAId && ids[1] === userBId) return candidate.id;
  }
  const created = await prisma.$transaction(async (tx) => {
    const conversation = await tx.conversation.create({ data: {} });
    await tx.conversationMember.createMany({ data: [{ conversationId: conversation.id, userId: userAId }, { conversationId: conversation.id, userId: userBId }] });
    return conversation;
  });
  return created.id;
}
