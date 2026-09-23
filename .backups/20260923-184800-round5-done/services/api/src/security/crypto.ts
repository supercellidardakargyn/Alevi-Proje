import { createCipheriv, createDecipheriv, createHash, randomBytes, timingSafeEqual } from 'node:crypto';

const VERSION = 'v1';

function encode(value: Buffer): string {
  return value.toString('base64url');
}

function decode(value: string): Buffer {
  return Buffer.from(value, 'base64url');
}

export function encryptSensitivePayload(payload: unknown, key: Buffer): string {
  const iv = randomBytes(12);
  const cipher = createCipheriv('aes-256-gcm', key, iv);
  const plaintext = Buffer.from(JSON.stringify(payload), 'utf8');
  const ciphertext = Buffer.concat([cipher.update(plaintext), cipher.final()]);
  return [VERSION, encode(iv), encode(cipher.getAuthTag()), encode(ciphertext)].join('.');
}

export function decryptSensitivePayload(value: string, key: Buffer): unknown {
  const [version, ivValue, tagValue, ciphertextValue] = value.split('.');
  if (version !== VERSION || !ivValue || !tagValue || !ciphertextValue) throw new Error('Invalid encrypted payload');
  const decipher = createDecipheriv('aes-256-gcm', key, decode(ivValue));
  decipher.setAuthTag(decode(tagValue));
  const plaintext = Buffer.concat([decipher.update(decode(ciphertextValue)), decipher.final()]);
  return JSON.parse(plaintext.toString('utf8')) as unknown;
}

export function hashToken(value: string): string {
  return createHash('sha256').update(value, 'utf8').digest('hex');
}

export function safeEqualText(left: string, right: string): boolean {
  const a = Buffer.from(left);
  const b = Buffer.from(right);
  return a.length === b.length && timingSafeEqual(a, b);
}
