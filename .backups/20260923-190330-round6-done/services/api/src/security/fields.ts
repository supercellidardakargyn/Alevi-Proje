import { config } from '../config';
import { decryptSensitivePayload, encryptSensitivePayload } from './crypto';

/**
 * Kullanici iceriklerini (mesaj, gonderi, sikayet detayi) veritabaninda
 * AES-256-GCM ile sifreli saklar. Okumada cozum basarisiz olursa (eski
 * acik satirlar) ham degeri dondurur; boylece gecis doneminde veri kaybi olmaz.
 */
export function encryptText(plaintext: string): string {
  return encryptSensitivePayload({ text: plaintext }, config.sensitiveDataKey);
}

export function decryptText(stored: string): string {
  try {
    const decoded = decryptSensitivePayload(stored, config.sensitiveDataKey) as { text?: unknown };
    return typeof decoded.text === 'string' ? decoded.text : stored;
  } catch {
    return stored;
  }
}
