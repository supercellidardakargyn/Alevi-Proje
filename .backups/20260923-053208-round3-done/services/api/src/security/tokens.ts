import { createHmac, randomUUID } from 'node:crypto';
import { config } from '../config';
import { safeEqualText } from './crypto';

export type TokenType = 'access' | 'refresh';
export interface TokenClaims {
  sub: string;
  type: TokenType;
  iat: number;
  exp: number;
  jti: string;
  iss: string;
  aud: string;
}

function encode(value: unknown): string {
  return Buffer.from(JSON.stringify(value), 'utf8').toString('base64url');
}

function decode<T>(value: string): T {
  try {
    return JSON.parse(Buffer.from(value, 'base64url').toString('utf8')) as T;
  } catch {
    throw new Error('Invalid token');
  }
}

export class TokenService {
  issue(userId: string, type: TokenType): { token: string; claims: TokenClaims } {
    const now = Math.floor(Date.now() / 1000);
    const claims: TokenClaims = {
      sub: userId,
      type,
      iat: now,
      exp: now + (type === 'access' ? config.accessTokenTtlSeconds : config.refreshTokenTtlSeconds),
      jti: randomUUID(),
      iss: config.jwtIssuer,
      aud: config.jwtAudience
    };
    const payload = encode(claims);
    const signature = this.sign(payload, type);
    return { token: `${payload}.${signature}`, claims };
  }

  verify(token: string, expectedType: TokenType): TokenClaims {
    const parts = token.split('.');
    if (parts.length !== 2) throw new Error('Invalid token');
    const [payload, signature] = parts;
    const expectedSignature = this.sign(payload, expectedType);
    if (!safeEqualText(signature, expectedSignature)) throw new Error('Invalid token');
    const claims = decode<TokenClaims>(payload);
    if (claims.type !== expectedType || !claims.sub || !claims.jti || !Number.isInteger(claims.exp) || claims.exp <= Math.floor(Date.now() / 1000)) {
      throw new Error('Expired or invalid token');
    }
    if (claims.iss !== config.jwtIssuer || claims.aud !== config.jwtAudience) {
      throw new Error('Expired or invalid token');
    }
    return claims;
  }

  private sign(payload: string, type: TokenType): string {
    const secret = type === 'access' ? config.jwtAccessSecret : config.jwtRefreshSecret;
    return createHmac('sha256', secret).update(payload).digest('base64url');
  }
}
