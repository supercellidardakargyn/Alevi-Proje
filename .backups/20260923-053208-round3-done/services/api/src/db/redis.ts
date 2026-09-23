import Redis from 'ioredis';
import { config } from '../config';

export type RedisClient = Redis | null;

export function createRedisClient(): RedisClient {
  const client = new Redis(config.redisUrl, {
    lazyConnect: true,
    maxRetriesPerRequest: 1,
    enableOfflineQueue: false,
    retryStrategy: (attempt) => Math.min(attempt * 250, 5000)
  });
  let lastLogAt = 0;
  client.on('error', (error) => {
    if (config.nodeEnv === 'test') return;
    // Kesinti aninda her retry'de bagirmak yerine dakikada bir ornekle.
    const now = Date.now();
    if (now - lastLogAt > 60_000) {
      lastLogAt = now;
      console.error(`[redis] ${error.message}`);
    }
  });
  return client;
}

export async function connectRedis(client: RedisClient): Promise<boolean> {
  if (!client) return false;
  try {
    if (client.status === 'wait') await client.connect();
    await client.ping();
    return true;
  } catch (error) {
    if (config.redisRequired) throw error;
    return false;
  }
}

export async function checkRedis(client: RedisClient): Promise<boolean> {
  if (!client) return false;
  try {
    await client.ping();
    return true;
  } catch {
    return false;
  }
}
