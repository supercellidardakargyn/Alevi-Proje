import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import { PresenceService } from '../services/presence';
import { toPublicProfile, publicProfileSelect } from '../services/profiles';
import { asyncHandler, userId } from './route-utils';

export function presenceRoutes(prisma: PrismaClient, presence: PresenceService): Router {
  const router = Router();
  router.post('/heartbeat', asyncHandler(async (req, res) => {
    await presence.heartbeat(userId(req));
    res.status(204).send();
  }));
  router.get('/active', asyncHandler(async (req, res) => {
    const currentUserId = userId(req);
    const ids = (await presence.activeIds()).filter((id) => id !== currentUserId);
    if (ids.length === 0) return res.json({ data: { items: [] } });
    const blocks = await prisma.block.findMany({
      where: { OR: [{ blockerId: currentUserId }, { blockedId: currentUserId }] },
      select: { blockerId: true, blockedId: true }
    });
    const excluded = new Set<string>([currentUserId]);
    for (const block of blocks) {
      excluded.add(block.blockerId);
      excluded.add(block.blockedId);
    }
    const visible = ids.filter((id) => !excluded.has(id)).slice(0, 50);
    if (visible.length === 0) return res.json({ data: { items: [] } });
    const users = await prisma.user.findMany({ where: { id: { in: visible }, deletedAt: null }, select: publicProfileSelect });
    res.json({ data: { items: users.map(toPublicProfile) } });
  }));
  return router;
}
