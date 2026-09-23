import { Router } from 'express';
import { blockRequestSchema, reportRequestSchema } from '@alevi/contracts';
import { PrismaClient } from '@prisma/client';
import { validate } from '../middleware/validation';
import { encryptText } from '../security/fields';
import { ApiError } from '../middleware/errors';
import { asyncHandler, notFoundIfNull, routeParam, userId } from './route-utils';

export function safetyRoutes(prisma: PrismaClient): Router {
  const router = Router();
  router.get('/blocks', asyncHandler(async (req, res) => {
    const blocks = await prisma.block.findMany({ where: { blockerId: userId(req) }, include: { blocked: { select: { id: true, displayName: true, avatarUrl: true } } }, orderBy: { createdAt: 'desc' } });
    res.json({ data: blocks.map((block) => ({ id: block.id, createdAt: block.createdAt.toISOString(), user: block.blocked })) });
  }));
  router.post('/blocks', validate(blockRequestSchema), asyncHandler(async (req, res) => {
    const blockerId = userId(req);
    const { userId: blockedId } = req.body as { userId: string };
    if (blockerId === blockedId) throw new ApiError(400, 'SELF_BLOCK', 'You cannot block yourself');
    notFoundIfNull(await prisma.user.findFirst({ where: { id: blockedId, deletedAt: null }, select: { id: true } }), 'User');
    const block = await prisma.block.upsert({ where: { blockerId_blockedId: { blockerId, blockedId } }, create: { blockerId, blockedId }, update: {} });
    res.status(201).json({ data: { id: block.id, userId: blockedId } });
  }));
  router.delete('/blocks/:userId', asyncHandler(async (req, res) => {
    await prisma.block.deleteMany({ where: { blockerId: userId(req), blockedId: routeParam(req, 'userId') } });
    res.status(204).send();
  }));
  router.get('/reports/mine', asyncHandler(async (req, res) => {
    const reports = await prisma.report.findMany({ where: { reporterId: userId(req) }, orderBy: { createdAt: 'desc' }, take: 50 });
    res.json({ data: reports.map((report) => ({ id: report.id, reason: report.reason, status: report.status, createdAt: report.createdAt.toISOString() })) });
  }));
  router.post('/reports', validate(reportRequestSchema), asyncHandler(async (req, res) => {    const reporterId = userId(req);
    const body = req.body as { userId?: string; messageId?: string; reason: 'HARASSMENT' | 'HATE' | 'SPAM' | 'SAFETY' | 'OTHER'; details?: string };
    if (body.userId === reporterId) throw new ApiError(400, 'SELF_REPORT', 'You cannot report yourself');
    if (body.userId) notFoundIfNull(await prisma.user.findFirst({ where: { id: body.userId, deletedAt: null }, select: { id: true } }), 'User');
    if (body.messageId) {
      const message = notFoundIfNull(
        await prisma.message.findUnique({ where: { id: body.messageId }, select: { id: true, conversation: { select: { members: { select: { userId: true } } } } } }),
        'Message'
      );
      const member = message.conversation.members.some((entry) => entry.userId === reporterId);
      if (!member) throw new ApiError(403, 'FORBIDDEN', 'You are not a member of this conversation');
    }
    const report = await prisma.report.create({ data: { reporterId, ...(body.userId ? { reportedId: body.userId } : {}), ...(body.messageId ? { messageId: body.messageId } : {}), reason: body.reason, details: body.details ? encryptText(body.details) : undefined } });
    res.status(201).json({ data: { id: report.id, status: report.status, createdAt: report.createdAt.toISOString() } });
  }));
  return router;
}
