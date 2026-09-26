import { Router } from 'express';
import { z } from 'zod';
import { createTicketRequestSchema, replyTicketRequestSchema } from '@alevi/contracts';
import { PrismaClient } from '@prisma/client';
import { validate } from '../middleware/validation';
import { decryptText, encryptText } from '../security/fields';
import { draftSupportReply } from '../services/ai';
import { asyncHandler, notFoundIfNull, routeParam, userId } from './route-utils';
import { ApiError } from '../middleware/errors';

const ticketListQuerySchema = z.object({
  limit: z.coerce.number().int().min(1).max(50).default(20)
});

/**
 * Destek otomasyonu: sikayet govdesinde tanik kaliptan aninda yanit yazar.
 * Model gerekmez, kurallar kutuphanede durur; tutmazsa akis degismez.
 */
const AUTO_REPLIES: Array<{ match: (lower: string) => boolean; text: string }> = [
  {
    match: (body) => body.includes('şifre') || body.includes('sifre') || body.includes('parola'),
    text: 'Şifrenizi giriş ekranındaki "Şifremi unuttum" bağlantısıyla sıfırlayabilirsiniz. E-postanıza 10 dakika geçerli 6 haneli kod gelir.'
  },
  {
    match: (body) => body.includes('hesap') && (body.includes('sil') || body.includes('kapat') || body.includes('silme')),
    text: 'Hesabınızı Profil > Hesabı sil bölümünden kapatabilirsiniz. Bu işlem geri alınamaz.'
  },
  {
    match: (body) =>
      body.includes('ücret') || body.includes('ucret') || body.includes('para') ||
      body.includes('ödeme') || body.includes('odeme') || body.includes('fiyat'),
    text: 'Can Meydanı şu an tamamen ücretsizdir, kart bilgileriniz istenmez.'
  }
];

function autoReplyFor(body: string): string | null {
  const lower = body.toLocaleLowerCase('tr');
  const found = AUTO_REPLIES.find((rule) => rule.match(lower));
  return found ? `[Otomatik yanıt] ${found.text}` : null;
}

function present(row: { id: string; subject: string; body: string; status: string; reply: string | null; aiDraft?: string | null; createdAt: Date; updatedAt: Date }) {
  return {
    id: row.id,
    subject: row.subject,
    body: decryptText(row.body),
    status: row.status,
    reply: row.reply ? decryptText(row.reply) : null,
    aiDraft: row.aiDraft ?? null,
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
    // Otomasyon: bilinen konulara aninda yanit, ticket'i cozulmus say.
    const auto = autoReplyFor(`${body.subject} ${body.body}`);
    const ticket = await prisma.supportTicket.create({
      data: { userId: userId(req), subject: body.subject, body: encryptText(body.body) }
    });
    if (auto) {
      const answered = await prisma.supportTicket.update({
        where: { id: ticket.id },
        data: { reply: encryptText(auto), repliedAt: new Date(), status: 'ANSWERED' }
      });
      res.status(201).json({ data: present(answered) });
      return;
    }
    // Yapay zeka taslagi arka planda uretilir, yaniti geciktirmez.
    void draftSupportReply(body.subject, body.body)
      .then((draft) => {
        if (!draft) return undefined;
        return prisma.supportTicket.update({ where: { id: ticket.id }, data: { aiDraft: encryptText(draft) } });
      })
      .catch(() => undefined);
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
