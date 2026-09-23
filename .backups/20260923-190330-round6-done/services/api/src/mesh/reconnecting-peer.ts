import { EventEmitter } from 'node:events';
import { connect as tlsConnect, ConnectionOptions, TLSSocket } from 'node:tls';
import { HeartbeatManager } from './heartbeat';
import { JoinTokenService } from './join-token';
import { PeerHandshake } from './peer-handshake';

export interface ReconnectingPeerOptions {
  nodeId: string;
  peerNodeId: string;
  host: string;
  port: number;
  tls: Omit<ConnectionOptions, 'host' | 'port'>;
  joinTokens: JoinTokenService;
  heartbeatMs?: number;
  connectTimeoutMs?: number;
  reconnectBaseMs?: number;
  reconnectMaxMs?: number;
}

export class ReconnectingPeer extends EventEmitter {
  private socket?: TLSSocket;
  private heartbeat?: HeartbeatManager;
  private stopped = true;
  private reconnectTimer?: NodeJS.Timeout;
  private attempt = 0;

  constructor(private readonly options: ReconnectingPeerOptions) { super(); }

  start(): void {
    if (!this.stopped) return;
    this.stopped = false;
    this.connect();
  }

  stop(): void {
    this.stopped = true;
    if (this.reconnectTimer) clearTimeout(this.reconnectTimer);
    this.heartbeat?.stop();
    this.socket?.destroy();
    this.socket = undefined;
  }

  private connect(): void {
    if (this.stopped) return;
    const socket = tlsConnect({ ...this.options.tls, host: this.options.host, port: this.options.port, minVersion: 'TLSv1.3', maxVersion: 'TLSv1.3', servername: this.options.host });
    this.socket = socket;
    const timeout = setTimeout(() => socket.destroy(new Error('Mesh connection timeout')), this.options.connectTimeoutMs ?? 10_000);
    timeout.unref();
    socket.once('secureConnect', () => {
      clearTimeout(timeout);
      void this.handshake(socket);
    });
    socket.once('error', (error) => this.emit('error', error));
    socket.once('close', () => {
      clearTimeout(timeout);
      this.heartbeat?.stop();
      this.emit('disconnected');
      if (!this.stopped) this.scheduleReconnect();
    });
  }

  private async handshake(socket: TLSSocket): Promise<void> {
    try {
      const handshake = new PeerHandshake(socket, { nodeId: this.options.nodeId, expectedPeerNodeId: this.options.peerNodeId, joinTokens: this.options.joinTokens, timeoutMs: this.options.connectTimeoutMs });
      const peerId = await handshake.startAsInitiator(this.options.joinTokens.issue(this.options.peerNodeId));
      if (peerId !== this.options.peerNodeId) throw new Error('Unexpected peer identity');
      this.attempt = 0;
      this.heartbeat = new HeartbeatManager(socket, { intervalMs: this.options.heartbeatMs });
      this.heartbeat.on('timeout', () => this.emit('heartbeatTimeout'));
      this.heartbeat.start();
      this.emit('connected', peerId);
    } catch (error) {
      this.emit('error', error);
      socket.destroy();
    }
  }

  private scheduleReconnect(): void {
    if (this.reconnectTimer || this.stopped) return;
    const base = this.options.reconnectBaseMs ?? 500;
    const max = this.options.reconnectMaxMs ?? 30_000;
    const delay = Math.min(max, base * 2 ** Math.min(this.attempt++, 8)) + Math.floor(Math.random() * 250);
    this.reconnectTimer = setTimeout(() => { this.reconnectTimer = undefined; this.connect(); }, delay);
    this.reconnectTimer.unref();
  }
}
