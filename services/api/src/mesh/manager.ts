import { readFileSync } from 'node:fs';
import { EventEmitter } from 'node:events';
import { config } from '../config';
import { JoinTokenService } from './join-token';
import { MeshServer } from './server';
import { ReconnectingPeer } from './reconnecting-peer';

export type MeshPeerStatus = 'connecting' | 'connected' | 'disconnected' | 'error';
export type MeshPeerSnapshot = { nodeId: string; host: string; port: number; status: MeshPeerStatus; lastSeenAt: string | null };

export function meshHealth(peers: MeshPeerSnapshot[]): { healthyNodes: number; totalNodes: number; state: 'healthy' | 'degraded' | 'offline' } {
  const healthyNodes = peers.filter((peer) => peer.status === 'connected').length;
  const totalNodes = peers.length;
  const state = totalNodes === 0 ? 'offline' : healthyNodes === totalNodes ? 'healthy' : 'degraded';
  return { healthyNodes, totalNodes, state };
}

export class MeshManager extends EventEmitter {
  private readonly joinTokens: JoinTokenService;
  private readonly server: MeshServer;
  private readonly peers = new Map<string, { peer: ReconnectingPeer; snapshot: MeshPeerSnapshot }>();
  private stopped = true;

  constructor(private readonly options = config.mesh) {
    super();
    this.joinTokens = new JoinTokenService(options.joinSecret);
    this.server = new MeshServer(options);
  }

  async start(): Promise<void> {
    if (this.stopped === false) return;
    this.stopped = false;
    if (this.options.enabled) {
      await this.server.start();
      for (const peerUrl of this.options.peers) this.addPeer(peerUrl);
    }
  }

  async stop(): Promise<void> {
    this.stopped = true;
    for (const item of this.peers.values()) item.peer.stop();
    this.peers.clear();
    await this.server.stop();
  }

  issueJoinToken(nodeId: string, ttlMs?: number): string { return this.joinTokens.issue(nodeId, ttlMs); }

  snapshot(): MeshPeerSnapshot[] { return [...this.peers.values()].map(({ snapshot }) => ({ ...snapshot })); }

  /** gateway + admin + health ucunun ortak mesh ozeti. */
  health(): { healthyNodes: number; totalNodes: number; state: 'healthy' | 'degraded' | 'offline' } {
    return meshHealth(this.snapshot());
  }

  joinTokenService(): JoinTokenService { return this.joinTokens; }

  addPeer(peerUrl: string): void {
    const parsed = new URL(peerUrl.includes('://') ? peerUrl : `mesh://${peerUrl}`);
    const nodeId = parsed.username || parsed.hostname;
    const host = parsed.hostname;
    const port = Number(parsed.port || 9443);
    if (!nodeId || !host || !Number.isInteger(port)) return;
    this.removePeer(nodeId);
    const peer = new ReconnectingPeer({
      nodeId: this.options.nodeId,
      peerNodeId: nodeId,
      host,
      port,
      tls: {
        ca: readFileSync(this.options.caFile),
        cert: readFileSync(this.options.certFile),
        key: readFileSync(this.options.keyFile),
        rejectUnauthorized: true,
        ALPNProtocols: ['alevi-mesh/1']
      },
      joinTokens: this.joinTokens,
      heartbeatMs: this.options.heartbeatMs,
      connectTimeoutMs: this.options.connectTimeoutMs,
      reconnectBaseMs: this.options.reconnectBaseMs,
      reconnectMaxMs: this.options.reconnectMaxMs
    });
    const snapshot: MeshPeerSnapshot = { nodeId, host, port, status: 'connecting', lastSeenAt: null };
    this.peers.set(nodeId, { peer, snapshot });
    peer.on('connected', () => { snapshot.status = 'connected'; snapshot.lastSeenAt = new Date().toISOString(); this.emit('peer:connected', { ...snapshot }); });
    peer.on('disconnected', () => { snapshot.status = 'disconnected'; this.emit('peer:disconnected', { ...snapshot }); });
    peer.on('error', () => { snapshot.status = 'error'; this.emit('peer:error', { ...snapshot }); });
    peer.start();
  }

  removePeer(nodeId: string): void {
    const existing = this.peers.get(nodeId);
    if (!existing) return;
    existing.peer.removeAllListeners();
    existing.peer.stop();
    this.peers.delete(nodeId);
  }
}
