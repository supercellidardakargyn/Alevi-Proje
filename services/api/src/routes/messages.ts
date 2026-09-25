import { Router } from 'express';
import { z } from 'zod';
import { createConversationSchema, createMessageSchema } from '@alevi/contracts';
import { PrismaClient } from '@prisma/client';
import { validate } from '../middleware/validation';
import { decryptText, encryptText } from '../security/fields';
import { ApiError } from '../middleware/errors';
import { asyncHandler, notFoundIfNull, routeParam, userId } from './route-utils';

const conversationListQuerySchema = z.object({
  limit: z.coerce.number().int().min(1).max(50).default(20)
});

const messageListQuerySchema = z.object({
  limit: z.coerce.number().int().min(1).max(100).default(50),
  before: z.string().datetime().optional()
});

async function requireMember(prisma: PrismaClient, conversationId: string, currentUserId: string) {
  const member = await prisma.conversationMember.findUnique({ where: { conversationId_userId: { conversationId, userId: currentUserId } } });
  if (!member) throw new ApiError(403, 'FORBIDDEN', 'You are not a member of this conversation');
  return member;
}

export function messageRoutes(prisma: PrismaClient): Router {
  const router = Router();
  router.get('/conversations', validate(conversationListQuerySchema, 'query'), asyncHandler(async (req, res) => {
    const query = req.query as unknown as { limit: number };
    const conversations = await prisma.conversation.findMany({ where: { members: { some: { userId: userId(req) } } }, include: { members: { include: { user: { select: { id: true, displayName: true, avatarUrl: true } } } }, messages: { orderBy: { createdAt: 'desc' }, take: 1, select: { id: true, body: true, senderId: true, createdAt: true } } }, orderBy: { updatedAt: 'desc' }, take: query.limit });
    res.json({ data: conversations.map((conversation) => ({ id: conversation.id, title: conversation.title, members: conversation.members.map((member) => member.user), lastMessage: conversation.messages[0] ? { ...conversation.messages[0], body: decryptText(conversation.messages[0].body) } : null, updatedAt: conversation.updatedAt.toISOString() })) });
  }));
  router.post('/conversations', validate(createConversationSchema), asyncHandler(async (req, res) => {
    const currentUserId = userId(req);
    const input = req.body as { participantIds: string[]; title?: string };
    const participantIds = [...new Set([currentUserId, ...input.participantIds])];
    if (participantIds.length > 10) throw new ApiError(400, 'TOO_MANY_PARTICIPANTS', 'At most 10 participants are allowed');
    const users = await prisma.user.findMany({ where: { id: { in: participantIds }, deletedAt: null }, select: { id: true } });
    if (users.length !== participantIds.length) throw new ApiError(400, 'INVALID_PARTICIPANTS', 'One or more participants do not exist');
    const blocked = await prisma.block.findFirst({
      where: {
        OR: [
          { blockerId: currentUserId, blockedId: { in: participantIds } },
          { blockerId: { in: participantIds }, blockedId: currentUserId }
        ]
      },
      select: { id: true }
    });
    if (blocked) throw new ApiError(403, 'BLOCKED', 'This conversation is not available');
    // Birebir sohbette teklik: ayni ikili arasinda zaten kutu varsa yeniden
    // acma, en eskiye don (fazlalari mesajlariyla birlestir).
    if (participantIds.length === 2 && !input.title) {
      const mine = await prisma.conversation.findMany({
        where: { members: { some: { userId: currentUserId } }, title: null },
        include: { members: { select: { userId: true } } },
        orderBy: { createdAt: 'asc' }
      });
      const exact = mine.filter((conversation) =>
        conversation.members.length === 2 &&
        conversation.members.every((member) => participantIds.includes(member.userId)));
      if (exact.length > 0) {
        const primary = exact[0];
        const extras = exact.slice(1);
        if (extras.length > 0) {
          await prisma.$transaction(async (tx) => {
            for (const extra of extras) {
              await tx.message.updateMany({ where: { conversationId: extra.id }, data: { conversationId: primary.id } });
              await tx.conversationMember.deleteMany({ where: { conversationId: extra.id } });
              await tx.conversation.delete({ where: { id: extra.id } });
            }
            const newest = await tx.message.findFirst({ where: { conversationId: primary.id }, orderBy: { createdAt: 'desc' }, select: { createdAt: true } });
            if (newest) await tx.conversation.update({ where: { id: primary.id }, data: { updatedAt: newest.createdAt } });
          });
        }
        const full = await prisma.conversation.findUnique({ where: { id: primary.id } });
        return res.status(200).json({ data: full });
      }
    }
    const conversation = await prisma.$transaction(async (tx) => {
      const created = await tx.conversation.create({ data: { title: input.title } });
      await tx.conversationMember.createMany({ data: participantIds.map((participantId) => ({ conversationId: created.id, userId: participantId })) });
      return created;
    });
    res.status(201).json({ data: conversation });
  }));
  router.get('/conversations/:id/messages', validate(messageListQuerySchema, 'query'), asyncHandler(async (req, res) => {
    const conversationId = routeParam(req, 'id');
    const query = req.query as unknown as { limit: number; before?: string };
    await requireMember(prisma, conversationId, userId(req));
    const messages = await prisma.message.findMany({
      where: { conversationId, deletedAt: null, ...(query.before ? { createdAt: { lt: new Date(query.before) } } : {}) },
      orderBy: { createdAt: 'desc' },
      take: query.limit,
      select: { id: true, conversationId: true, senderId: true, body: true, clientMessageId: true, createdAt: true, editedAt: true }
    });
    const chronological = [...messages].reverse();
    res.json({ data: chronological.map((message) => ({ ...message, body: decryptText(message.body) })) });
  }));
  router.post('/conversations/:id/messages', validate(createMessageSchema), asyncHandler(async (req, res) => {
    const senderId = userId(req);
    const conversationId = routeParam(req, 'id');
    await requireMember(prisma, conversationId, senderId);
    const input = req.body as { body: string; clientMessageId?: string };
    if (input.clientMessageId) {
      const existing = await prisma.message.findFirst({ where: { conversationId, senderId, clientMessageId: input.clientMessageId } });
      if (existing) return res.status(200).json({ data: { ...existing, body: decryptText(existing.body) } });
    }
    const message = await prisma.message.create({ data: { conversationId, senderId, body: encryptText(input.body), clientMessageId: input.clientMessageId } });
    await prisma.conversation.update({ where: { id: conversationId }, data: { updatedAt: new Date() } }).catch(() => undefined);
    res.status(201).json({ data: { ...message, body: input.body } });
  }));
  return router;
}
