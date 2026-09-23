import { config } from '../config';

/**
 * Yan sunucu -> ana sunucu nabiz gonderici.
 * Yan sunucunun API'si ice kapali oldugu icin canlilik bilgisi
 * disari dogru (outbound HTTPS) akar; guvenlik duvari dostudur.
 */
export function startEdgeUplink(): () => void {
  const { url, joinToken, heartbeatMs } = config.edgeUplink;
  if (!url || !joinToken) return () => undefined;

  const beat = async (): Promise<void> => {
    try {
      const response = await fetch(`${url}/v1/edge/heartbeat`, {
        method: 'POST',
        headers: { 'content-type': 'application/json', accept: 'application/json' },
        body: JSON.stringify({ token: joinToken }),
        signal: AbortSignal.timeout(10_000)
      });
      if (!response.ok && config.nodeEnv !== 'production') {
        console.error(`edge uplink heartbeat failed: ${response.status}`);
      }
    } catch (error) {
      if (config.nodeEnv !== 'production') console.error('edge uplink heartbeat failed', error);
    }
  };

  void beat();
  const timer = setInterval(beat, heartbeatMs);
  timer.unref?.();
  return () => clearInterval(timer);
}
