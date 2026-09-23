import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { decryptText, encryptText } from './security/fields.js';

describe('security: field encryption at rest', () => {
  it('round-trips message bodies', () => {
    const ciphertext = encryptText('Merhaba, nasilsin? Kısa mesaj 123 👋');
    assert.notEqual(ciphertext, 'Merhaba, nasilsin? Kısa mesaj 123 👋');
    assert.equal(decryptText(ciphertext), 'Merhaba, nasilsin? Kısa mesaj 123 👋');
  });

  it('falls back to raw value for legacy plaintext rows', () => {
    assert.equal(decryptText('acik metin satir'), 'acik metin satir');
  });

  it('handles long and multilingual content', () => {
    const long = 'Alevi muhabbeti. '.repeat(500);
    assert.equal(decryptText(encryptText(long)), long);
  });
});
