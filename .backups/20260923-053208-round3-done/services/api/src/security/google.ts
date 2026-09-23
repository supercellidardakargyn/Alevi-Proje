import { createPublicKey, verify } from 'node:crypto';
import { config } from '../config';

export interface GoogleClaims {
  sub: string;
  email?: string;
  emailVerified?: boolean;
  name?: string;
}

interface CertCache {
  at: number;
  keys: Record<string, Record<string, unknown>>;
}

let cache: CertCache = { at: 0, keys: {} };

async function loadCerts(): Promise<Record<string, Record<string, unknown>>> {
  if (Date.now() - cache.at < 3_600_000 && Object.keys(cache.keys).length > 0) return cache.keys;
  const response = await fetch('https://www.googleapis.com/oauth2/v3/certs', { signal: AbortSignal.timeout(10_000) });
  if (!response.ok) throw new Error('CERT_FETCH_FAILED');
  const body = (await response.json()) as { keys?: Array<{ kid?: string } & Record<string, unknown>> };
  const keys: Record<string, Record<string, unknown>> = {};
  for (const key of body.keys ?? []) {
    if (key.kid) keys[key.kid] = key;
  }
  cache = { at: Date.now(), keys };
  return keys;
}

/** Google ID token dogrular; basariliysa temel claimleri dondurur. */
export async function verifyGoogleIdToken(idToken: string): Promise<GoogleClaims> {
  if (!config.googleClientId) throw new Error('GOOGLE_DISABLED');
  const parts = idToken.split('.');
  if (parts.length !== 3) throw new Error('BAD_TOKEN');
  const header = JSON.parse(Buffer.from(parts[0], 'base64url').toString('utf8')) as { kid?: string; alg?: string };
  if (header.alg !== 'RS256' || !header.kid) throw new Error('BAD_TOKEN');
  const keys = await loadCerts();
  const jwk = keys[header.kid];
  if (!jwk) {
    cache.at = 0;
    throw new Error('UNKNOWN_KID');
  }
  const createJwkKey = createPublicKey as unknown as (options: { key: unknown; format: 'jwk' }) => ReturnType<typeof createPublicKey>;
  const key = createJwkKey({ key: jwk, format: 'jwk' });
  const valid = verify('sha256', Buffer.from(`${parts[0]}.${parts[1]}`), key, Buffer.from(parts[2], 'base64url'));
  if (!valid) throw new Error('BAD_SIGNATURE');
  const claims = JSON.parse(Buffer.from(parts[1], 'base64url').toString('utf8')) as {
    iss?: string;
    aud?: string;
    exp?: number;
    sub?: string;
    email?: string;
    email_verified?: boolean;
    name?: string;
  };
  const nowSeconds = Math.floor(Date.now() / 1000);
  const audiences = [config.googleClientId, config.googleAndroidClientId].filter(Boolean);
  if (
    (claims.iss !== 'https://accounts.google.com' && claims.iss !== 'accounts.google.com') ||
    !claims.aud ||
    !audiences.includes(claims.aud) ||
    !claims.sub ||
    !claims.exp ||
    claims.exp <= nowSeconds
  ) {
    throw new Error('BAD_CLAIMS');
  }
  return { sub: claims.sub, email: claims.email?.toLowerCase(), emailVerified: claims.email_verified, name: claims.name };
}
