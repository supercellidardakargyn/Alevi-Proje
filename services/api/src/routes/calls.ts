import { Router } from 'express';
import { callSignalSchema, createCallSchema } from '@alevi/contracts';
import { PrismaClient } from '@prisma/client';
import { validate } from '../middleware/validation';
import { ApiError } from '../middleware/errors';
import { asyncHandler, notFoundIfNull, routeParam, userId } from './route-utils';

// Zil suresi: 60 sn icinde cevaplanmayan cagri cevapsiz sayilir.
const RING_TTL_MS = 60_000;

type CallRow = {
  id: string;
  conversationId: string;
  kind: string;
  status: string;
  offer: unknown;
  answer: unknown;
  iceCandidates: unknown;
  createdAt: Date;
  endedAt: Date | null;
  caller: { id: string; displayName: string; avatarUrl: string | null };
};

function present(call: CallRow) {
  return {
    id: call.id,
    conversationId: call.conversationId,
    kind: call.kind,
    status: call.status,
    offer: call.offer ?? null,
    answer: call.answer ?? null,
    iceCandidates: Array.isArray(call.iceCandidates) ? call.iceCandidates : [],
    caller: call.caller,
    createdAt: call.createdAt.toISOString(),
    endedAt: call.endedAt ? call.endedAt.toISOString() : null
  };
}

const callerSelect = { id: true, displayName: true, avatarUrl: true };

async function expireStale(prisma: PrismaClient, where: Record<string, unknown>): Promise<void> {
  await prisma.call.updateMany({
    where: { ...where, status: 'RINGING', createdAt: { lt: new Date(Date.now() - RING_TTL_MS) } },
    data: { status: 'MISSED', endedAt: new Date() }
  }).catch(() => undefined);
}

export function callRoutes(prisma: PrismaClient): Router {
  const router = Router();

  router.post('/', validate(createCallSchema), asyncHandler(async (req, res) => {
    const me = userId(req);
    const input = req.body as { conversationId: string; kind: 'VOICE' | 'VIDEO' };
    const membership = await prisma.conversationMember.findUnique({
      where: { conversationId_userId: { conversationId: input.conversationId, userId: me } }
    });
    if (!membership) throw new ApiError(403, 'FORBIDDEN', 'You are not a member of this conversation');
    const others = await prisma.conversationMember.findMany({
      where: { conversationId: input.conversationId, userId: { not: me } },
      select: { userId: true }
    });
    if (others.length !== 1) throw new ApiError(400, 'GROUP_NOT_SUPPORTED', 'Calls are supported for one-to-one chats only');
    await expireStale(prisma, { conversationId: input.conversationId });
    const ongoing = await prisma.call.findFirst({
      where: { conversationId: input.conversationId, status: { in: ['RINGING', 'ACCEPTED'] } },
      include: { caller: { select: callerSelect } },
      orderBy: { createdAt: 'desc' }
    });
    if (ongoing) return res.status(200).json({ data: present(ongoing as unknown as CallRow) });
    const call = await prisma.call.create({
      data: { conversationId: input.conversationId, callerId: me, calleeId: others[0].userId, kind: input.kind },
      include: { caller: { select: callerSelect } }
    });
    res.status(201).json({ data: present(call as unknown as CallRow) });
  }));

  router.get('/incoming', asyncHandler(async (req, res) => {
    const me = userId(req);
    await expireStale(prisma, { calleeId: me });
    const calls = await prisma.call.findMany({
      where: { calleeId: me, status: 'RINGING' },
      include: { caller: { select: callerSelect } },
      orderBy: { createdAt: 'desc' },
      take: 10
    });
    res.json({ data: calls.map((call) => present(call as unknown as CallRow)) });
  }));

  router.get('/:id', asyncHandler(async (req, res) => {
    const me = userId(req);
    const call = notFoundIfNull(
      await prisma.call.findUnique({ where: { id: routeParam(req, 'id') }, include: { caller: { select: callerSelect } } }),
      'Call'
    );
    if (call.callerId !== me && call.calleeId !== me) throw new ApiError(403, 'FORBIDDEN', 'You are not a participant of this call');
    res.json({ data: present(call as unknown as CallRow) });
  }));

  router.post('/:id/accept', asyncHandler(async (req, res) => {
    const me = userId(req);
    const call = notFoundIfNull(await prisma.call.findUnique({ where: { id: routeParam(req, 'id') } }), 'Call');
    if (call.calleeId !== me) throw new ApiError(403, 'FORBIDDEN', 'Only the callee can accept');
    if (call.status !== 'RINGING') throw new ApiError(409, 'CALL_NOT_RINGING', 'Call is no longer ringing');
    const updated = await prisma.call.update({
      where: { id: call.id },
      data: { status: 'ACCEPTED' },
      include: { caller: { select: callerSelect } }
    });
    res.json({ data: present(updated as unknown as CallRow) });
  }));

  router.post('/:id/decline', asyncHandler(async (req, res) => {
    const me = userId(req);
    const call = notFoundIfNull(await prisma.call.findUnique({ where: { id: routeParam(req, 'id') } }), 'Call');
    if (call.callerId !== me && call.calleeId !== me) throw new ApiError(403, 'FORBIDDEN', 'You are not a participant of this call');
    if (call.status !== 'RINGING') throw new ApiError(409, 'CALL_NOT_RINGING', 'Call is no longer ringing');
    const updated = await prisma.call.update({
      where: { id: call.id },
      data: { status: 'DECLINED', endedAt: new Date() },
      include: { caller: { select: callerSelect } }
    });
    res.json({ data: present(updated as unknown as CallRow) });
  }));

  router.post('/:id/end', asyncHandler(async (req, res) => {
    const me = userId(req);
    const call = notFoundIfNull(await prisma.call.findUnique({ where: { id: routeParam(req, 'id') } }), 'Call');
    if (call.callerId !== me && call.calleeId !== me) throw new ApiError(403, 'FORBIDDEN', 'You are not a participant of this call');
    if (call.status !== 'ACCEPTED' && call.status !== 'RINGING') throw new ApiError(409, 'CALL_ALREADY_ENDED', 'Call has already ended');
    const updated = await prisma.call.update({
      where: { id: call.id },
      data: { status: 'ENDED', endedAt: new Date() },
      include: { caller: { select: callerSelect } }
    });
    res.json({ data: present(updated as unknown as CallRow) });
  }));

  router.patch('/:id/signal', validate(callSignalSchema), asyncHandler(async (req, res) => {
    const me = userId(req);
    const call = notFoundIfNull(await prisma.call.findUnique({ where: { id: routeParam(req, 'id') } }), 'Call');
    if (call.callerId !== me && call.calleeId !== me) throw new ApiError(403, 'FORBIDDEN', 'You are not a participant of this call');
    if (call.status !== 'RINGING' && call.status !== 'ACCEPTED') throw new ApiError(409, 'CALL_ALREADY_ENDED', 'Call has already ended');
    const input = req.body as { offer?: Record<string, unknown>; answer?: Record<string, unknown>; ice?: Array<Record<string, unknown>> };
    const data: Record<string, unknown> = {};
    if (input.offer !== undefined && me === call.callerId) data.offer = input.offer;
    if (input.answer !== undefined && me === call.calleeId) data.answer = input.answer;
    if (input.ice !== undefined) data.iceCandidates = input.ice;
    const updated = await prisma.call.update({
      where: { id: call.id },
      data,
      include: { caller: { select: callerSelect } }
    });
    res.json({ data: present(updated as unknown as CallRow) });
  }));

  return router;
}
