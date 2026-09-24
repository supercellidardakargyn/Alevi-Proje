import { Router } from 'express';
import { z } from 'zod';
import { createTicketRequestSchema, replyTicketRequestSchema } from '@alevi/contracts';
import { PrismaClient } from '@prisma/client';
import { validate } from '../middleware/validation';
import { decryptText, encryptText } from '../security/fields';
import { asyncHandler, notFoundIfNull, routeParam, userId } from './route-utils';
import { ApiError } from '../middleware/errors';

const ticketListQuerySchema = z.object({
  limit: z.coerce.number().int().min(1).max(50).default(20)
});

function present(row: { id: string; subject: string; body: string; status: string; reply: string | null; createdAt: Date; updatedAt: Date }) {
  return {
    id: row.id,
    subject: row.subject,
    body: decryptText(row.body),
    status: row.status,
    reply: row.reply ? decryptText(row.reply) : null,
    createdAt: row.createdAt.toISOString(),
    updatedAt: row.updatedAt.toISOString()
  };
}

export function supportRoutes(prisma: PrismaClient): Router {
  const router = Router();
  router.get('/', validate(ticketListQuerySchema, 'query'), asyncHandler(async (req, res) => {
    const query = req.query as unknown as { limit: number };
    const tickets = await prisma.supportTicket.findMany({
      where: { userId: userId(req) },
      orderBy: { createdAt: 'desc' },
      take: query.limit
    });
    res.json({ data: tickets.map(present) });
  }));
  router.post('/', validate(createTicketRequestSchema), asyncHandler(async (req, res) => {
    const body = req.body as { subject: string; body: string };
    const ticket = await prisma.supportTicket.create({
      data: { userId: userId(req), subject: body.subject, body: encryptText(body.body) }
    });
    res.status(201).json({ data: present(ticket) });
  }));
  return router;
}

export function supportAdminRoutes(prisma: PrismaClient): Router {
  const router = Router();
  router.get('/tickets', validate(ticketListQuerySchema, 'query'), asyncHandler(async (req, res) => {
    const query = req.query as unknown as { limit: number };
    const tickets = await prisma.supportTicket.findMany({
      where: { status: { in: ['OPEN', 'ANSWERED'] } },
      include: { user: { select: { id: true, displayName: true } } },
      orderBy: { createdAt: 'asc' },
      take: query.limit
    });
    res.json({ data: tickets.map((ticket) => ({ ...present(ticket), user: ticket.user })) });
  }));
  router.post('/tickets/:id/reply', validate(replyTicketRequestSchema), asyncHandler(async (req, res) => {
    const ticketId = routeParam(req, 'id');
    const body = req.body as { message: string };
    const ticket = await prisma.supportTicket.update({
      where: { id: ticketId },
      data: { reply: encryptText(body.message), repliedAt: new Date(), status: 'ANSWERED' }
    });
    res.json({ data: present(ticket) });
  }));
  router.post('/tickets/:id/close', asyncHandler(async (req, res) => {
    const ticketId = routeParam(req, 'id');
    const ticket = notFoundIfNull(
      await prisma.supportTicket.findUnique({ where: { id: ticketId } }),
      'Ticket'
    );
    if (ticket.status === 'OPEN') throw new ApiError(400, 'UNANSWERED', 'Reply before closing the ticket');
    const closed = await prisma.supportTicket.update({ where: { id: ticketId }, data: { status: 'CLOSED' } });
    res.json({ data: present(closed) });
  }));
  return router;
}
