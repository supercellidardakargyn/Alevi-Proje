import { Router } from 'express';
import { updateProfileRequestSchema } from '@alevi/contracts';
import { PrismaClient } from '@prisma/client';
import { config } from '../config';
import { encryptSensitivePayload } from '../security/crypto';
import { validate } from '../middleware/validation';
import { ApiError } from '../middleware/errors';
import { asyncHandler, userId } from './route-utils';
import { toPublicProfile, publicProfileSelect } from '../services/profiles';

export function profileRoutes(prisma: PrismaClient): Router {
  const router = Router();
  router.get('/me', asyncHandler(async (req, res) => {
    const user = await prisma.user.findFirst({ where: { id: userId(req), deletedAt: null }, select: { ...publicProfileSelect, inviteCode: true, showMapLocation: true } });
    if (!user) throw new ApiError(404, 'USER_NOT_FOUND', 'Profile not found');
    res.json({ data: { ...toPublicProfile(user), inviteCode: user.inviteCode, showMapLocation: user.showMapLocation } });
  }));

  router.patch('/me', validate(updateProfileRequestSchema), asyncHandler(async (req, res) => {
    const currentUserId = userId(req);
    const existing = await prisma.user.findFirst({ where: { id: currentUserId, deletedAt: null }, select: { id: true } });
    if (!existing) throw new ApiError(404, 'USER_NOT_FOUND', 'Profile not found');
    const body = req.body as { displayName?: string; bio?: string | null; avatarUrl?: string | null; photos?: string[]; city?: string | null; district?: string | null; country?: string | null; latitude?: number | null; longitude?: number | null; showMapLocation?: boolean; interests?: string[]; sensitivePayload?: Record<string, unknown> | null };
    const data: Record<string, unknown> = {};
    if (body.displayName !== undefined) data.displayName = body.displayName;
    if (body.bio !== undefined) data.bio = body.bio;
    if (body.avatarUrl !== undefined) data.avatarUrl = body.avatarUrl;
    if (body.photos !== undefined) {
      // Galeri URL'lerini temizle, boslari at, en fazla 6 al.
      data.photos = body.photos.map((url: string) => url.trim()).filter((url: string) => url.length > 0).slice(0, 6);
    }
    if (body.city !== undefined) data.city = body.city;
    if (body.district !== undefined) data.district = body.district;
    if (body.country !== undefined) data.country = body.country;
    if (body.latitude !== undefined) data.latitude = body.latitude;
    if (body.longitude !== undefined) data.longitude = body.longitude;
    if (body.showMapLocation !== undefined) data.showMapLocation = body.showMapLocation;
    if (body.interests !== undefined) {
      data.interests = body.interests.map((tag: string) => tag.trim()).filter((tag: string) => tag.length > 0).slice(0, 10);
    }
    if (Object.prototype.hasOwnProperty.call(body, 'sensitivePayload')) {
      data.sensitivePayloadCiphertext = body.sensitivePayload === null ? null : Buffer.from(encryptSensitivePayload(body.sensitivePayload, config.sensitiveDataKey), 'utf8');
      data.sensitivePayloadVersion = body.sensitivePayload === null ? null : 1;
    }
    const updated = await prisma.user.update({ where: { id: currentUserId }, data, select: publicProfileSelect });
    res.json({ data: toPublicProfile(updated) });
  }));

  router.delete('/me', asyncHandler(async (req, res) => {
    const currentUserId = userId(req);
    await prisma.$transaction([
      prisma.user.update({ where: { id: currentUserId }, data: { deletedAt: new Date() } }),
      prisma.refreshToken.updateMany({ where: { userId: currentUserId, revokedAt: null }, data: { revokedAt: new Date() } })
    ]);
    res.status(204).send();
  }));
  return router;
}
