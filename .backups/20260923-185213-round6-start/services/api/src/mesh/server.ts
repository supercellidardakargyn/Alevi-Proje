import { createServer, Server, TLSSocket } from 'node:tls';
import { readFileSync } from 'node:fs';
import { config } from '../config';
import { JoinTokenService } from './join-token';
import { PeerHandshake } from './peer-handshake';
import { HeartbeatManager } from './heartbeat';

export class MeshServer {
  private server?: Server;
  private readonly joinTokens: JoinTokenService;
  private readonly heartbeats = new Set<HeartbeatManager>();

  constructor(private readonly options = config.mesh) {
    this.joinTokens = new JoinTokenService(options.joinSecret);
  }

  start(): Promise<void> {
    if (this.server) return Promise.resolve();
    this.server = createServer({
      minVersion: 'TLSv1.3',
      maxVersion: 'TLSv1.3',
      ca: readFileSync(this.options.caFile),
      cert: readFileSync(this.options.certFile),
      key: readFileSync(this.options.keyFile),
      requestCert: true,
      rejectUnauthorized: true,
      ALPNProtocols: ['alevi-mesh/1']
    }, (socket) => this.accept(socket));
    return new Promise((resolve, reject) => {
      this.server?.once('error', reject);
      this.server?.listen(this.options.port, this.options.host, () => resolve());
    });
  }

  issueJoinToken(peerNodeId: string, ttlMs?: number): string {
    return this.joinTokens.issue(peerNodeId, ttlMs);
  }

  async stop(): Promise<void> {
    if (!this.server) return;
    const server = this.server;
    for (const heartbeat of this.heartbeats) heartbeat.stop();
    this.heartbeats.clear();
    await new Promise<void>((resolve) => server.close(() => resolve()));
    this.server = undefined;
  }

  private accept(socket: TLSSocket): void {
    const certificate = socket.getPeerCertificate();
    const peerNodeId = typeof certificate.subject?.CN === 'string' ? certificate.subject.CN : undefined;
    if (!peerNodeId) {
      socket.destroy(new Error('Peer certificate CN is required'));
      return;
    }
    const handshake = new PeerHandshake(socket, { nodeId: this.options.nodeId, expectedPeerNodeId: peerNodeId, joinTokens: this.joinTokens, timeoutMs: this.options.connectTimeoutMs });
    void handshake.startAsAcceptor().then(() => {
      const heartbeat = new HeartbeatManager(socket, { intervalMs: this.options.heartbeatMs });
      this.heartbeats.add(heartbeat);
      heartbeat.start();
      socket.once('close', () => {
        heartbeat.stop();
        this.heartbeats.delete(heartbeat);
      });
    }).catch(() => socket.destroy());
  }
}
