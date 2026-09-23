import { createHmac, randomBytes, randomUUID, timingSafeEqual } from 'node:crypto';

export interface JoinTokenClaims {
  tokenId: string;
  nodeId: string;
  issuedAt: number;
  expiresAt: number;
  nonce: string;
}

export class JoinTokenService {
  private readonly consumed = new Map<string, number>();

  constructor(private readonly secret: string, private readonly now: () => number = () => Date.now()) {}

  issue(nodeId: string, ttlMs = 60_000): string {
    if (!nodeId || ttlMs < 1000 || ttlMs > 86_400_000) throw new Error('Invalid join token parameters');
    const issuedAt = this.now();
    const claims: JoinTokenClaims = {
      tokenId: randomUUID(),
      nodeId,
      issuedAt,
      expiresAt: issuedAt + ttlMs,
      nonce: randomBytes(16).toString('base64url')
    };
    const payload = Buffer.from(JSON.stringify(claims), 'utf8').toString('base64url');
    return `${payload}.${this.sign(payload)}`;
  }

  verifyAndConsume(token: string, expectedNodeId?: string): JoinTokenClaims {
    this.prune();
    const [payload, signature] = token.split('.');
    if (!payload || !signature || !this.safeEqual(signature, this.sign(payload))) throw new Error('Invalid join token signature');
    let claims: JoinTokenClaims;
    try {
      claims = JSON.parse(Buffer.from(payload, 'base64url').toString('utf8')) as JoinTokenClaims;
    } catch {
      throw new Error('Invalid join token payload');
    }
    if (!claims.tokenId || !claims.nodeId || !claims.nonce || !Number.isInteger(claims.issuedAt) || !Number.isInteger(claims.expiresAt)) throw new Error('Invalid join token claims');
    if (expectedNodeId && claims.nodeId !== expectedNodeId) throw new Error('Join token node mismatch');
    const now = this.now();
    if (claims.expiresAt <= now || claims.issuedAt > now + 30_000) throw new Error('Join token expired or not yet valid');
    if (this.consumed.has(claims.tokenId)) throw new Error('Join token already used');
    this.consumed.set(claims.tokenId, claims.expiresAt);
    return claims;
  }

  private sign(payload: string): string {
    return createHmac('sha256', this.secret).update(payload, 'utf8').digest('base64url');
  }

  private safeEqual(left: string, right: string): boolean {
    const a = Buffer.from(left);
    const b = Buffer.from(right);
    return a.length === b.length && timingSafeEqual(a, b);
  }

  private prune(): void {
    const now = this.now();
    for (const [tokenId, expiresAt] of this.consumed) if (expiresAt <= now) this.consumed.delete(tokenId);
  }
}
