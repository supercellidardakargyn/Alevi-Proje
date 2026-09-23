import { EventEmitter } from 'node:events';
import { Socket } from 'node:net';
import { TLSSocket } from 'node:tls';
import { randomUUID } from 'node:crypto';
import { JoinTokenService } from './join-token';

export interface MeshHello {
  type: 'hello';
  protocol: 1;
  nodeId: string;
  requestId: string;
  joinToken: string;
  sentAt: number;
}

export interface MeshHelloAck {
  type: 'hello_ack';
  protocol: 1;
  nodeId: string;
  requestId: string;
  accepted: true;
  sentAt: number;
}

export type MeshControlMessage = MeshHello | MeshHelloAck;

export interface PeerHandshakeOptions {
  nodeId: string;
  joinTokens: JoinTokenService;
  expectedPeerNodeId?: string;
  timeoutMs?: number;
}

export class PeerHandshake extends EventEmitter {
  private buffer = '';
  private settled = false;
  private timer?: NodeJS.Timeout;
  private dataListener?: (chunk: string | Buffer) => void;

  constructor(private readonly socket: TLSSocket | Socket, private readonly options: PeerHandshakeOptions) {
    super();
  }

  startAsInitiator(joinToken: string): Promise<string> {
    return new Promise((resolve, reject) => {
      this.withTimeout(reject);
      this.socket.setEncoding('utf8');
      this.dataListener = (chunk: string | Buffer) => this.onData(String(chunk), resolve, reject);
      this.socket.on('data', this.dataListener);
      this.socket.once('error', reject);
      this.socket.once('close', () => {
        if (!this.settled) reject(new Error('Peer closed during handshake'));
      });
      this.send({ type: 'hello', protocol: 1, nodeId: this.options.nodeId, requestId: randomUUID(), joinToken, sentAt: Date.now() });
    });
  }

  startAsAcceptor(): Promise<string> {
    return new Promise((resolve, reject) => {
      this.withTimeout(reject);
      this.socket.setEncoding('utf8');
      this.dataListener = (chunk: string | Buffer) => this.onData(String(chunk), resolve, reject);
      this.socket.on('data', this.dataListener);
      this.socket.once('error', reject);
      this.socket.once('close', () => {
        if (!this.settled) reject(new Error('Peer closed during handshake'));
      });
    });
  }

  private onData(chunk: string, resolve: (nodeId: string) => void, reject: (error: Error) => void): void {
    this.buffer += chunk;
    if (this.buffer.length > 64 * 1024) return this.fail(reject, new Error('Handshake frame too large'));
    let newline = this.buffer.indexOf('\n');
    while (newline >= 0) {
      const frame = this.buffer.slice(0, newline);
      this.buffer = this.buffer.slice(newline + 1);
      newline = this.buffer.indexOf('\n');
      if (!frame) continue;
      let message: MeshControlMessage;
      try { message = JSON.parse(frame) as MeshControlMessage; } catch { return this.fail(reject, new Error('Invalid handshake frame')); }
      if (message.type === 'hello') {
        try {
          const claims = this.options.joinTokens.verifyAndConsume(message.joinToken, this.options.expectedPeerNodeId ?? message.nodeId);
          if (claims.nodeId !== message.nodeId) throw new Error('Join token subject mismatch');
          this.send({ type: 'hello_ack', protocol: 1, nodeId: this.options.nodeId, requestId: message.requestId, accepted: true, sentAt: Date.now() });
          return this.succeed(resolve, message.nodeId);
        } catch (error) {
          return this.fail(reject, error instanceof Error ? error : new Error('Join token rejected'));
        }
      }
      if (message.type === 'hello_ack' && message.accepted && message.protocol === 1) {
        return this.succeed(resolve, message.nodeId);
      }
      return this.fail(reject, new Error('Unexpected handshake message'));
    }
  }

  private send(message: MeshControlMessage): void {
    this.socket.write(`${JSON.stringify(message)}\n`);
  }

  private succeed(resolve: (nodeId: string) => void, nodeId: string): void {
    if (this.settled) return;
    this.settled = true;
    if (this.timer) clearTimeout(this.timer);
    if (this.dataListener) this.socket.removeListener('data', this.dataListener);
    resolve(nodeId);
    this.emit('authenticated', nodeId);
  }

  private fail(reject: (error: Error) => void, error: Error): void {
    if (this.settled) return;
    this.settled = true;
    if (this.timer) clearTimeout(this.timer);
    if (this.dataListener) this.socket.removeListener('data', this.dataListener);
    reject(error);
    this.socket.destroy();
  }

  private withTimeout(reject: (error: Error) => void): void {
    this.timer = setTimeout(() => this.fail(reject, new Error('Peer handshake timed out')), this.options.timeoutMs ?? 10_000);
    this.timer.unref();
  }
}
