import { Router } from 'express';
import { checkDatabase } from '../db/prisma';
import { checkRedis, RedisClient } from '../db/redis';
import { MeshManager, meshHealth } from '../mesh/manager';

export function healthRoutes(redis: RedisClient, mesh: MeshManager): Router {
  const router = Router();
  router.get('/live', (_req, res) => res.json({ status: 'ok', service: 'api', timestamp: new Date().toISOString() }));
  router.get('/ready', async (_req, res) => {
    const [database, redisOk] = await Promise.all([checkDatabase(), checkRedis(redis)]);
    const redisHealthy = redisOk || !redis;
    const ready = database && redisHealthy;
    res.status(ready ? 200 : 503).json({ status: ready ? 'ok' : 'degraded', checks: { database, redis: redisHealthy }, timestamp: new Date().toISOString() });
  });
  router.get('/mesh', (_req, res) => {
    const { healthyNodes, totalNodes, state } = meshHealth(mesh.snapshot());
    const httpStatus = state === 'healthy' ? 200 : 503;
    res.status(httpStatus).json({ status: state === 'healthy' ? 'ok' : 'degraded', nodeId: process.env.MESH_NODE_ID ?? 'unknown', peers: mesh.snapshot(), healthyNodes, totalNodes });
  });
  return router;
}
