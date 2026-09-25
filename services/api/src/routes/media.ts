import { randomUUID } from 'node:crypto';
import { existsSync, mkdirSync } from 'node:fs';
import { promises as fs } from 'node:fs';
import { join } from 'node:path';
import { Router } from 'express';
import multer from 'multer';
import { z } from 'zod';
import { PrismaClient } from '@prisma/client';
import { config } from '../config';
import { ApiError } from '../middleware/errors';
import { validate } from '../middleware/validation';
import { asyncHandler, routeParam, userId } from './route-utils';

const ALLOWED = new Map([
  ['image/jpeg', '.jpg'],
  ['image/png', '.png'],
  ['image/webp', '.webp']
]);

function uploadDir(): string {
  const dir = config.uploadDir;
  mkdirSync(dir, { recursive: true });
  return dir;
}

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: config.maxUploadMb * 1024 * 1024, files: 1 },
  fileFilter: (_req, file, done) => {
    done(null, ALLOWED.has(file.mimetype));
  }
});

function extFor(mimetype: string): string {
  return ALLOWED.get(mimetype) ?? '.bin';
}

export function mediaRoutes(prisma: PrismaClient): Router {
  const router = Router();

  router.post('/profile/avatar', upload.single('avatar'), asyncHandler(async (req, res) => {
    const file = (req as unknown as { file?: Express.Multer.File }).file;
    if (!file) throw new ApiError(400, 'INVALID_IMAGE', 'A JPEG, PNG or WebP image is required');
    const name = `${randomUUID()}${extFor(file.mimetype)}`;
    await fs.writeFile(join(uploadDir(), name), file.buffer, { mode: 0o600 });
    const current = await prisma.user.findUnique({ where: { id: userId(req) }, select: { avatarUrl: true } });
    const old = current?.avatarUrl?.startsWith('/v1/media/') ? current.avatarUrl.slice('/v1/media/'.length) : null;
    await prisma.user.update({ where: { id: userId(req) }, data: { avatarUrl: `/v1/media/${name}` } });
    if (old && old !== name) {
      try {
        await fs.unlink(join(uploadDir(), old));
      } catch {
        // Eski dosya silinemezse sessiz gecilir.
      }
    }
    res.status(201).json({ data: { avatarUrl: `/v1/media/${name}` } });
  }));

  router.post('/profile/photos', upload.single('photo'), asyncHandler(async (req, res) => {
    const file = (req as unknown as { file?: Express.Multer.File }).file;
    if (!file) throw new ApiError(400, 'INVALID_IMAGE', 'A JPEG, PNG or WebP image is required');
    const me = await prisma.user.findUnique({ where: { id: userId(req) }, select: { photos: true } });
    const current: string[] = me?.photos ?? [];
    const name = `${randomUUID()}${extFor(file.mimetype)}`;
    const url = `/v1/media/${name}`;
    if (!current.includes(url)) {
      if (current.length >= 6) throw new ApiError(400, 'PHOTOS_LIMIT_REACHED', 'Photo gallery is limited to 6 photos');
      await fs.writeFile(join(uploadDir(), name), file.buffer, { mode: 0o600 });
      const next = [...current, url];
      await prisma.user.update({ where: { id: userId(req) }, data: { photos: next } });
      return res.status(201).json({ data: { photos: next } });
    }
    return res.status(201).json({ data: { photos: current } });
  }));

  router.delete('/profile/photos', validate(z.object({ url: z.string().url().max(2048) })), asyncHandler(async (req, res) => {
    const input = req.body as { url: string };
    const me = await prisma.user.findUnique({ where: { id: userId(req) }, select: { photos: true } });
    const current: string[] = me?.photos ?? [];
    const next = current.filter((item) => item !== input.url);
    if (next.length !== current.length) {
      await prisma.user.update({ where: { id: userId(req) }, data: { photos: next } });
      // Yerel dosyayi silmeyi dene, olmazsa sessiz gec.
      if (input.url.startsWith('/v1/media/')) {
        const file = input.url.slice('/v1/media/'.length);
        try {
          await fs.unlink(join(uploadDir(), file));
        } catch {
          // Sessiz gecilir.
        }
      }
    }
    res.json({ data: { photos: next } });
  }));

  router.get('/media/:file', asyncHandler(async (req, res) => {
    userId(req);
    const file = routeParam(req, 'file');
    if (!/^[a-f0-9-]+\.(jpg|jpeg|png|webp)$/.test(file)) throw new ApiError(400, 'INVALID_FILE', 'Invalid file name');
    const full = join(uploadDir(), file);
    if (!existsSync(full)) throw new ApiError(404, 'NOT_FOUND', 'File not found');
    const type = file.endsWith('.png') ? 'image/png' : file.endsWith('.webp') ? 'image/webp' : 'image/jpeg';
    res.setHeader('content-type', type);
    res.setHeader('cache-control', 'public, max-age=86400');
    res.sendFile(full, { dotfiles: 'deny' }, (error) => {
      if (error && !res.headersSent) res.status(404).end();
    });
  }));

  return router;
}
