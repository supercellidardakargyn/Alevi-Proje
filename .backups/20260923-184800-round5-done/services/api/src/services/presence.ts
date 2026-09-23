import { RedisClient } from '../db/redis';

const TTL_SECONDS = 120;
const WINDOW_MS = 90_000;

// Cevrimici varligi izler. Redis varsa SCAN ile okunur (cok node uyumlu),
// yoksa process ici haritaya yazilir. Her iki durumda da API ayni cevabi verir.
export class PresenceService {
  private readonly memory = new Map<string, number>();
  private readonly sweeper: NodeJS.Timeout;

  constructor(private readonly redis: RedisClient) {
    this.sweeper = setInterval(() => {
      const now = Date.now();
      for (const [id, seen] of this.memory) {
        if (now - seen >= WINDOW_MS) this.memory.delete(id);
      }
    }, 60_000);
    this.sweeper.unref?.();
  }

  stop(): void {
    clearInterval(this.sweeper);
  }

  async heartbeat(userId: string): Promise<void> {
    if (this.redis) {
      try {
        await this.redis.set(`presence:${userId}`, String(Date.now()), 'EX', TTL_SECONDS);
        return;
      } catch {
        // Redis duserse bellege dus.
      }
    }
    this.memory.set(userId, Date.now());
  }

  async activeIds(): Promise<string[]> {
    if (this.redis) {
      try {
        // KEYS yerine SCAN: buyuk anahtar uzayinda bloklamaz.
        const ids: string[] = [];
        let cursor = '0';
        do {
          const [next, keys] = await this.redis.scan(cursor, 'MATCH', 'presence:*', 'COUNT', 500);
          cursor = next;
          if (keys.length === 0) continue;
          const values = await this.redis.mget(keys);
          const now = Date.now();
          keys.forEach((key, index) => {
            const seen = Number(values[index]);
            if (Number.isFinite(seen) && now - seen < WINDOW_MS) ids.push(key.slice('presence:'.length));
          });
          if (ids.length >= 500) break;
        } while (cursor !== '0');
        return ids;
      } catch {
        // Asagidaki bellege dus.
      }
    }
    const now = Date.now();
    const ids: string[] = [];
    for (const [id, seen] of this.memory) {
      if (now - seen < WINDOW_MS) ids.push(id);
      else this.memory.delete(id);
    }
    return ids;
  }
}
