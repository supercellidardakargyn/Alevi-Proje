import { EventEmitter } from 'node:events';
import { Socket } from 'node:net';

export type MeshHeartbeatMessage = { type: 'ping' | 'pong'; sentAt: number };

export interface HeartbeatOptions {
  intervalMs?: number;
  timeoutMs?: number;
  now?: () => number;
}

export class HeartbeatManager extends EventEmitter {
  private timer?: NodeJS.Timeout;
  private timeoutTimer?: NodeJS.Timeout;
  private lastPongAt = 0;
  private active = false;
  private buffer = '';
  private readonly onSocketData = (chunk: Buffer | string): void => this.onData(String(chunk));

  constructor(private readonly socket: Socket, private readonly options: HeartbeatOptions = {}) {
    super();
  }

  start(): void {
    if (this.active) return;
    this.active = true;
    this.lastPongAt = this.now();
    this.socket.on('data', this.onSocketData);
    const interval = this.options.intervalMs ?? 10_000;
    this.timer = setInterval(() => this.ping(), interval);
    this.timer.unref();
    this.ping();
  }

  stop(): void {
    this.active = false;
    this.socket.removeListener('data', this.onSocketData);
    if (this.timer) clearInterval(this.timer);
    if (this.timeoutTimer) clearTimeout(this.timeoutTimer);
    this.timer = undefined;
    this.timeoutTimer = undefined;
  }

  private ping(): void {
    if (!this.active || this.socket.destroyed) return this.stop();
    const sentAt = this.now();
    this.socket.write(`${JSON.stringify({ type: 'ping', sentAt })}\n`);
    if (this.timeoutTimer) clearTimeout(this.timeoutTimer);
    this.timeoutTimer = setTimeout(() => {
      if (this.now() - this.lastPongAt >= (this.options.timeoutMs ?? 30_000)) {
        this.emit('timeout');
        this.socket.destroy(new Error('Mesh heartbeat timed out'));
      }
    }, this.options.timeoutMs ?? 30_000);
    this.timeoutTimer.unref();
  }

  private onData(chunk: string): void {
    this.buffer += chunk;
    if (this.buffer.length > 64 * 1024) {
      // Saldirgan buyuk cerceveyle baglantiyi kilitlemesin: sifirla ve kapat.
      this.buffer = '';
      this.socket.destroy(new Error('Mesh frame too large'));
      return;
    }
    let newline = this.buffer.indexOf('\n');
    while (newline >= 0) {
      const line = this.buffer.slice(0, newline);
      this.buffer = this.buffer.slice(newline + 1);
      newline = this.buffer.indexOf('\n');
      if (!line) continue;
      try {
        const message = JSON.parse(line) as MeshHeartbeatMessage;
        if (message.type === 'ping') this.socket.write(`${JSON.stringify({ type: 'pong', sentAt: message.sentAt })}\n`);
        if (message.type === 'pong') {
          this.lastPongAt = this.now();
          this.emit('pong', message.sentAt);
        }
      } catch {
        // Application frames are deliberately ignored by the heartbeat parser.
      }
    }
  }

  private now(): number { return this.options.now?.() ?? Date.now(); }
}
