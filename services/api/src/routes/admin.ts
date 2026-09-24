import { Router } from 'express';
import { randomBytes } from 'node:crypto';
import { PrismaClient } from '@prisma/client';
import { createEdgeNodeRequestSchema, resolveReportRequestSchema, suspendUserRequestSchema } from '@alevi/contracts';
import { z } from 'zod';
import { validate } from '../middleware/validation';
import { decryptText } from '../security/fields';
import { hashToken } from '../security/crypto';
import { supportAdminRoutes } from './support';
import { asyncHandler, routeParam, userId } from './route-utils';
import { ApiError } from '../middleware/errors';
import { MeshManager, meshHealth } from '../mesh/manager';

const adminListQuerySchema = z.object({
  limit: z.coerce.number().int().min(1).max(100).default(50)
});

function maskEmail(email: string): string {
  const [local, domain] = email.split('@');
  if (!domain) return '***';
  const head = (local ?? '').slice(0, 1) || '*';
  return `${head}***@${domain}`;
}

async function writeAudit(
  prisma: PrismaClient,
  entry: { actorId?: string; action: string; targetType: string; targetId?: string; reason?: string; metadata?: Record<string, unknown> }
): Promise<void> {
  try {
    await prisma.auditLog.create({
      data: {
        actorId: entry.actorId,
        action: entry.action,
        targetType: entry.targetType,
        targetId: entry.targetId,
        reason: entry.reason,
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        metadata: (entry.metadata ?? undefined) as any
      }
    });
  } catch {
    // Audit kaybi gorunmez olmamali.
    console.warn(`[audit] yazilamadi: ${entry.action} -> ${entry.targetType}/${entry.targetId ?? '-'}`);
  }
}

export function adminRoutes(prisma: PrismaClient, mesh: MeshManager): Router {
  const router = Router();
  const roleCache = new Map<string, { role: string; exp: number }>();
  router.use(asyncHandler(async (req, _res, next) => {
    const id = userId(req);
    const cached = roleCache.get(id);
    let role = cached && cached.exp > Date.now() ? cached.role : null;
    if (!role) {
      const user = await prisma.user.findUnique({ where: { id }, select: { id: true, role: true } });
      role = user?.role ?? null;
      if (role) roleCache.set(id, { role, exp: Date.now() + 60_000 });
      if (roleCache.size > 1000) roleCache.clear();
    }
    if (role !== 'ADMIN') throw new ApiError(403, 'ADMIN_REQUIRED', 'Administrator access is required');
    next();
  }));
  router.get('/metrics', asyncHandler(async (_req, res) => {
    const [users, reports, posts] = await Promise.all([
      prisma.user.count({ where: { deletedAt: null } }),
      prisma.report.count({ where: { status: 'OPEN' } }),
      prisma.communityPost.count()
    ]);
    res.json({ data: { users, openReports: reports, posts, peers: mesh.snapshot() } });
  }));
  router.get('/overview', asyncHandler(async (_req, res) => {
    const dayAgo = new Date(Date.now() - 24 * 3600 * 1000);
    const weekAgo = new Date(Date.now() - 7 * 24 * 3600 * 1000);
    const [totalUsers, active24h, pendingVerification, newThisWeek, openReports, urgentReports, resolvedToday, pendingReview] =
      await prisma.$transaction([
        prisma.user.count({ where: { deletedAt: null } }),
        prisma.refreshToken.count({ where: { createdAt: { gte: dayAgo }, revokedAt: null } }),
        prisma.user.count({ where: { deletedAt: null, emailVerified: false } }),
        prisma.user.count({ where: { deletedAt: null, createdAt: { gte: weekAgo } } }),
        prisma.report.count({ where: { status: 'OPEN' } }),
        prisma.report.count({ where: { status: 'OPEN', reason: { in: ['SAFETY', 'HARASSMENT', 'HATE'] } } }),
        prisma.report.count({ where: { status: 'RESOLVED', createdAt: { gte: dayAgo } } }),
        prisma.report.count({ where: { status: { in: ['OPEN', 'REVIEWING'] } } })
      ]);
    const peers = mesh.snapshot();
    const { healthyNodes, totalNodes, state: meshState } = meshHealth(peers);
    const recentReports = await prisma.report.findMany({
      orderBy: { createdAt: 'desc' },
      take: 8,
      select: { id: true, reason: true, status: true, createdAt: true }
    });
    res.json({
      generatedAt: new Date().toISOString(),
      users: { total: totalUsers, active24h, pendingVerification, newThisWeek },
      reports: { open: openReports, urgent: urgentReports, resolvedToday, medianResponseMinutes: 0 },
      content: { pendingReview, removedToday: 0, flaggedMedia: 0, appeals: 0 },
      mesh: {
        state: meshState,
        healthyNodes,
        totalNodes,
        averageLatencyMs: 0,
        lastSyncAt: new Date().toISOString()
      },
      activity: recentReports.map((report) => ({
        id: report.id,
        kind: 'report' as const,
        title: `Report ${report.reason}`,
        detail: `Status: ${report.status}`,
        occurredAt: report.createdAt.toISOString()
      }))
    });
  }));
  router.get('/mesh/health', asyncHandler(async (_req, res) => {
    const { healthyNodes, totalNodes, state } = meshHealth(mesh.snapshot());
    res.json({
      state,
      healthyNodes,
      totalNodes,
      averageLatencyMs: 0,
      lastSyncAt: new Date().toISOString()
    });
  }));
  router.get('/users', validate(adminListQuerySchema, 'query'), asyncHandler(async (req, res) => {
    const query = req.query as unknown as { limit: number };
    const users = await prisma.user.findMany({ where: { deletedAt: null }, select: { id: true, email: true, displayName: true, createdAt: true, deletedAt: true }, orderBy: { createdAt: 'desc' }, take: query.limit });
    res.json({ data: users.map((user) => ({ ...user, email: maskEmail(user.email) })) });
  }));
  router.post('/users/:id/suspend', validate(suspendUserRequestSchema), asyncHandler(async (req, res) => {
    const actorId = userId(req);
    const targetId = routeParam(req, 'id');
    if (actorId === targetId) throw new ApiError(400, 'SELF_SUSPEND', 'You cannot suspend your own account');
    const body = req.body as { reason: string };
    const user = await prisma.user.update({
      where: { id: targetId },
      data: { deletedAt: new Date() },
      select: { id: true, deletedAt: true }
    });
    await writeAudit(prisma, {
      actorId,
      action: 'user.suspend',
      targetType: 'user',
      targetId,
      reason: body.reason
    });
    res.json({ data: user });
  }));
  router.get('/reports', validate(adminListQuerySchema, 'query'), asyncHandler(async (req, res) => {
    const query = req.query as unknown as { limit: number };
    const reports = await prisma.report.findMany({ where: { status: { in: ['OPEN', 'REVIEWING'] } }, orderBy: { createdAt: 'asc' }, take: query.limit });
    res.json({ data: reports.map((report) => ({ ...report, details: report.details ? decryptText(report.details) : null })) });
  }));
  router.post('/reports/:id/resolve', validate(resolveReportRequestSchema), asyncHandler(async (req, res) => {
    const actorId = userId(req);
    const reportId = routeParam(req, 'id');
    const body = req.body as { action: 'dismiss' | 'remove' | 'suspend'; note?: string };
    const status = body.action === 'dismiss' ? 'DISMISSED' : 'RESOLVED';
    const report = await prisma.report.update({ where: { id: reportId }, data: { status } });
    await writeAudit(prisma, {
      actorId,
      action: `report.${body.action}`,
      targetType: 'report',
      targetId: reportId,
      reason: body.note,
      metadata: { status }
    });
    res.json({ data: report });
  }));
  router.get('/edge', asyncHandler(async (_req, res) => {
    const nodes = await prisma.edgeNode.findMany({ orderBy: { createdAt: 'asc' } });
    const now = Date.now();
    res.json({
      data: nodes.map((node) => ({
        id: node.id,
        name: node.name,
        meshHost: node.meshHost,
        meshPort: node.meshPort,
        status: node.lastSeenAt && now - node.lastSeenAt.getTime() < 60_000 ? 'online' : node.status,
        lastSeenAt: node.lastSeenAt?.toISOString() ?? null,
        createdAt: node.createdAt.toISOString()
      }))
    });
  }));
  router.post('/edge', validate(createEdgeNodeRequestSchema), asyncHandler(async (req, res) => {
    const actorId = userId(req);
    const body = req.body as { name: string; meshHost: string; meshPort: number };
    const token = randomBytes(48).toString('hex');
    const node = await prisma.edgeNode.create({
      data: { name: body.name, meshHost: body.meshHost, meshPort: body.meshPort, tokenHash: hashToken(token) }
    });
    try {
      mesh.addPeer(`mesh://${node.id}@${body.meshHost}:${body.meshPort}`);
    } catch {
      // Mesh dial best-effort; kayit yine de olustu, heartbeat ile canlilik izlenir.
    }
    await writeAudit(prisma, { actorId, action: 'edge.create', targetType: 'edge', targetId: node.id });
    res.status(201).json({
      data: {
        id: node.id,
        name: node.name,
        meshHost: node.meshHost,
        meshPort: node.meshPort,
        status: node.status,
        // TEK SEFERLIK: yan sunucunun .env dosyasindaki EDGE_JOIN_TOKEN olur.
        joinToken: token
      }
    });
  }));
  router.delete('/edge/:id', asyncHandler(async (req, res) => {
    const actorId = userId(req);
    const targetId = routeParam(req, 'id');
    await prisma.edgeNode.delete({ where: { id: targetId } });
    await writeAudit(prisma, { actorId, action: 'edge.delete', targetType: 'edge', targetId });
    res.status(204).send();
  }));
  router.use(supportAdminRoutes(prisma));
  return router;
}
