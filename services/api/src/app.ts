import express, { Express } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { config } from './config';
import { prisma } from './db/prisma';
import { createRedisClient, connectRedis, RedisClient } from './db/redis';
import { requestId } from './middleware/request-id';
import { errorHandler, notFound } from './middleware/errors';
import { TokenService } from './security/tokens';
import { AuthService } from './services/auth';
import { requireAuth } from './middleware/auth';
import { asyncHandler } from './routes/route-utils';
import { authRoutes } from './routes/auth';
import { healthRoutes } from './routes/health';
import { profileRoutes } from './routes/profile';
import { discoverRoutes } from './routes/discover';
import { matchRoutes } from './routes/matches';
import { safetyRoutes } from './routes/safety';
import { communityRoutes } from './routes/communities';
import { messageRoutes } from './routes/messages';
import { mediaRoutes } from './routes/media';
import { eventRoutes, deviceRoutes } from './routes/events';
import { MeshManager } from './mesh/manager';
import { adminRoutes } from './routes/admin';
import { edgeRoutes } from './routes/edge';
import { presenceRoutes } from './routes/presence';
import { PresenceService } from './services/presence';
import { startEdgeUplink } from './edge/uplink';
import { hashToken } from './security/crypto';

function sensitiveLimiter() {
  // Kod uretimi/sifirlama/onay: e-posta dondurerek SMTP kotu kullanimi engellenir.
  return rateLimit({ windowMs: 60_000, limit: 10, standardHeaders: 'draft-7', legacyHeaders: false, keyGenerator: (req) => req.ip ?? req.socket.remoteAddress ?? 'unknown' });
}

function writeLimiter() {
  // Mesaj/sikayet/blok spam freni (kimlikli kullanimda IP bazli).
  return rateLimit({ windowMs: 60_000, limit: 30, standardHeaders: 'draft-7', legacyHeaders: false, keyGenerator: (req) => req.ip ?? req.socket.remoteAddress ?? 'unknown' });
}

export interface AppContext {
  app: Express;
  redis: RedisClient;
  mesh: MeshManager;
  close: () => Promise<void>;
}

/** Paketlenmis .env ile gelen ilk yan sunucuyu DB'ye isler ve mesh aramasi baslatir. */
async function seedEdgeNode(mesh: MeshManager): Promise<void> {
  const seed = config.edgeSeed;
  const stored = await prisma.edgeNode.findMany({ orderBy: { createdAt: 'asc' } }).catch(() => {
    console.warn('[edge] kayitli nodelar okunamadi, mesh aramasi atlaniyor');
    return [];
  });
  for (const node of stored) {
    try {
      mesh.addPeer(`mesh://${node.id}@${node.meshHost}:${node.meshPort}`);
    } catch {
      // Best-effort; kayit durur, heartbeat ile canlilik izlenir.
    }
  }
  if (seed.name && seed.host && seed.port && seed.token) {
    try {
      await prisma.edgeNode.upsert({
        where: { id: '00000000-0000-0000-0000-000000000001' },
        create: { id: '00000000-0000-0000-0000-000000000001', name: seed.name, meshHost: seed.host, meshPort: seed.port, tokenHash: hashToken(seed.token) },
        update: { name: seed.name, meshHost: seed.host, meshPort: seed.port, tokenHash: hashToken(seed.token) }
      });
      mesh.addPeer(`mesh://edge-seed@${seed.host}:${seed.port}`);
    } catch {
      // Best-effort.
    }
  }
}

export async function createApp(): Promise<AppContext> {
  const app = express();
  const redis = createRedisClient();
  await connectRedis(redis);
  const tokens = new TokenService();
  const auth = new AuthService(prisma, tokens);
  const presence = new PresenceService(redis);
  const mesh = new MeshManager();
  await mesh.start();

  app.disable('x-powered-by');
  app.set('trust proxy', config.trustProxy ? 1 : false);
  app.use(requestId);
  app.use(helmet({ contentSecurityPolicy: config.nodeEnv === 'production' ? undefined : false }));
  const corsOrigins = config.corsOrigins.filter((origin) => origin !== '*');
  if (config.nodeEnv === 'production' && corsOrigins.length === 0) {
    throw new Error('CORS_ORIGINS must list explicit origins in production');
  }
  app.use(cors({
    origin: corsOrigins.length > 0 ? corsOrigins : false,
    credentials: true,
    maxAge: 86400
  }));
  app.use(express.json({ limit: '64kb', strict: true }));
  app.use(express.urlencoded({ extended: false, limit: '16kb' }));
  app.use(rateLimit({ windowMs: config.rateLimitWindowMs, limit: config.rateLimitMax, standardHeaders: 'draft-7', legacyHeaders: false, keyGenerator: (req) => req.ip ?? req.socket.remoteAddress ?? 'unknown' }));

  app.get('/', (_req, res) => res.json({ service: 'alevi-api', version: '0.1.0' }));
  app.use('/health', healthRoutes(redis, mesh));
  app.use('/v1/auth', rateLimit({ windowMs: config.rateLimitWindowMs, limit: config.authRateLimitMax, standardHeaders: 'draft-7', legacyHeaders: false, keyGenerator: (req) => req.ip ?? req.socket.remoteAddress ?? 'unknown' }), authRoutes(auth));
  app.use('/v1/edge', rateLimit({ windowMs: config.rateLimitWindowMs, limit: config.authRateLimitMax, standardHeaders: 'draft-7', legacyHeaders: false, keyGenerator: (req) => req.ip ?? req.socket.remoteAddress ?? 'unknown' }), edgeRoutes(prisma));

  await seedEdgeNode(mesh);
  startEdgeUplink();

  const secured = express.Router();
  secured.use(requireAuth(tokens));
  secured.use('/profile', profileRoutes(prisma));
  secured.use('/discover', discoverRoutes(prisma));
  secured.use('/matches', matchRoutes(prisma));
  secured.use('/safety', writeLimiter(), safetyRoutes(prisma));
  secured.use('/communities', communityRoutes(prisma));
  secured.use('/messages', writeLimiter(), messageRoutes(prisma));
  secured.use('/', mediaRoutes(prisma));
  secured.use('/events', eventRoutes(prisma));
  secured.use('/devices', deviceRoutes(prisma));
  secured.use('/presence', presenceRoutes(prisma, presence));
  secured.use('/admin', adminRoutes(prisma, mesh));
  app.use('/v1', secured);

  app.use(notFound);
  app.use(errorHandler);

  return {
    app,
    redis,
    mesh,
    close: async () => {
      await mesh.stop();
      presence.stop();
      await prisma.$disconnect();
      if (redis) await redis.quit().catch(() => undefined);
    }
  };
}
