import { Router } from 'express';
import { edgeHeartbeatRequestSchema } from '@alevi/contracts';
import { PrismaClient } from '@prisma/client';
import { validate } from '../middleware/validation';
import { hashToken } from '../security/crypto';
import { ApiError } from '../middleware/errors';
import { asyncHandler } from './route-utils';

/**
 * Yan sunucularin ana sunucuya nabiz gonderdigi endpoint.
 * Yan sunucu disaridan tek portla (mesh) calisir; API'si ice kapalidir,
 * bu yuzden canlilik bilgisi bu yonden akar (edge -> main).
 */
export function edgeRoutes(prisma: PrismaClient): Router {
  const router = Router();
  router.post('/heartbeat', validate(edgeHeartbeatRequestSchema), asyncHandler(async (req, res) => {
    const updated = await prisma.edgeNode.updateMany({
      where: { tokenHash: hashToken((req.body as { token: string }).token) },
      data: { lastSeenAt: new Date(), status: 'online' }
    });
    if (updated.count === 0) throw new ApiError(401, 'INVALID_EDGE_TOKEN', 'Unknown edge node token');
    res.status(204).send();
  }));
  return router;
}
