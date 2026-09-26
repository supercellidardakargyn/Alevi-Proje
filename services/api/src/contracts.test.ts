import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  registerRequestSchema,
  suspendUserRequestSchema,
  resolveReportRequestSchema,
  discoverQuerySchema,
  createEdgeNodeRequestSchema,
  edgeHeartbeatRequestSchema,
  googleRequestSchema,
  verifyEmailRequestSchema,
  resendCodeRequestSchema,
  forgotPasswordRequestSchema,
  resetPasswordRequestSchema,
  createEventRequestSchema,
  deviceTokenRequestSchema,
  createTicketRequestSchema,
  replyTicketRequestSchema,
  updateProfileRequestSchema
} from '@alevi/contracts';

describe('contracts: registration 18+ enforcement', () => {
  it('rejects registration without ageConfirmed', () => {
    const result = registerRequestSchema.safeParse({
      email: 'test@example.com',
      password: 'long-enough-password-123',
      displayName: 'Test User',
      consentVersion: 'v1'
    });
    assert.equal(result.success, false);
  });

  it('accepts registration with ageConfirmed true', () => {
    const result = registerRequestSchema.safeParse({
      email: 'Test@Example.com',
      password: 'long-enough-password-123',
      displayName: 'Test User',
      consentVersion: 'v1',
      ageConfirmed: true
    });
    assert.equal(result.success, true);
    if (result.success) {
      assert.equal(result.data.email, 'test@example.com');
    }
  });
});

describe('contracts: admin actions', () => {
  it('requires a reason for suspend', () => {
    assert.equal(suspendUserRequestSchema.safeParse({}).success, false);
    assert.equal(suspendUserRequestSchema.safeParse({ reason: 'ab' }).success, false);
    assert.equal(suspendUserRequestSchema.safeParse({ reason: 'spam and harassment' }).success, true);
  });

  it('validates report resolution actions', () => {
    assert.equal(resolveReportRequestSchema.safeParse({ action: 'dismiss' }).success, true);
    assert.equal(resolveReportRequestSchema.safeParse({ action: 'remove' }).success, true);
    assert.equal(resolveReportRequestSchema.safeParse({ action: 'suspend' }).success, true);
    assert.equal(resolveReportRequestSchema.safeParse({ action: 'delete' }).success, false);
  });
});

describe('contracts: discover pagination', () => {
  it('caps limit at 50', () => {
    const result = discoverQuerySchema.safeParse({ limit: 200 });
    assert.equal(result.success, false);
  });

  it('applies default limit', () => {
    const result = discoverQuerySchema.safeParse({});
    assert.equal(result.success, true);
    if (result.success) assert.equal(result.data.limit, 20);
  });
});

describe('contracts: edge nodes', () => {
  it('validates server creation input', () => {
    assert.equal(createEdgeNodeRequestSchema.safeParse({}).success, false);
    const ok = createEdgeNodeRequestSchema.safeParse({ name: 'yan-1', meshHost: '10.0.0.5', meshPort: 25763 });
    assert.equal(ok.success, true);
    assert.equal(createEdgeNodeRequestSchema.safeParse({ name: 'x', meshHost: 'h', meshPort: 99999 }).success, false);
  });

  it('requires a heartbeat token', () => {
    assert.equal(edgeHeartbeatRequestSchema.safeParse({}).success, false);
    assert.equal(edgeHeartbeatRequestSchema.safeParse({ token: 'short' }).success, false);
    assert.equal(edgeHeartbeatRequestSchema.safeParse({ token: 'a'.repeat(64) }).success, true);
  });
});

describe('contracts: email verification', () => {
  it('accepts 6-digit codes only', () => {
    assert.equal(verifyEmailRequestSchema.safeParse({ email: 'a@b.co', code: '123456' }).success, true);
    assert.equal(verifyEmailRequestSchema.safeParse({ email: 'a@b.co', code: '12345' }).success, false);
    assert.equal(verifyEmailRequestSchema.safeParse({ email: 'a@b.co', code: 'abcdef' }).success, false);
    assert.equal(resendCodeRequestSchema.safeParse({ email: 'a@b.co' }).success, true);
    assert.equal(resendCodeRequestSchema.safeParse({ email: 'degil' }).success, false);
  });
});

describe('contracts: google sign-in', () => {
  it('requires consent and 18+ for new accounts', () => {
    const base = { idToken: 'x'.repeat(64), consentVersion: 'v1' };
    assert.equal(googleRequestSchema.safeParse(base).success, false);
    assert.equal(googleRequestSchema.safeParse({ ...base, ageConfirmed: true }).success, true);
    assert.equal(googleRequestSchema.safeParse({ ...base, ageConfirmed: false }).success, false);
  });
});

describe('contracts: password reset', () => {
  it('validates reset input', () => {
    assert.equal(forgotPasswordRequestSchema.safeParse({ email: 'a@b.co' }).success, true);
    assert.equal(resetPasswordRequestSchema.safeParse({ email: 'a@b.co', code: '123456', newPassword: 'long-enough-pass-123' }).success, true);
    assert.equal(resetPasswordRequestSchema.safeParse({ email: 'a@b.co', code: '12', newPassword: 'long-enough-pass-123' }).success, false);
    assert.equal(resetPasswordRequestSchema.safeParse({ email: 'a@b.co', code: '123456', newPassword: 'short' }).success, false);
  });
});

describe('contracts: events and devices', () => {
  it('validates event creation', () => {
    assert.equal(createEventRequestSchema.safeParse({ title: 'Konser', startsAt: new Date().toISOString() }).success, true);
    assert.equal(createEventRequestSchema.safeParse({ title: 'x', startsAt: 'yarin' }).success, false);
  });

  it('validates device tokens', () => {
    assert.equal(deviceTokenRequestSchema.safeParse({ token: 'x'.repeat(20) }).success, true);
    assert.equal(deviceTokenRequestSchema.safeParse({ token: 'short' }).success, false);
  });
});

describe('contracts: invites and interests', () => {
  it('accepts optional invite code and tags', () => {
    const ok = registerRequestSchema.safeParse({
      email: 'a@b.co',
      password: 'long-enough-pass-123',
      displayName: 'Test',
      consentVersion: 'v1',
      ageConfirmed: true,
      inviteCode: 'ab12cd34',
      interests: ['Müzik', 'Doğa']
    });
    assert.equal(ok.success, true);
    assert.equal(registerRequestSchema.safeParse({
      email: 'a@b.co',
      password: 'long-enough-pass-123',
      displayName: 'Test',
      consentVersion: 'v1',
      ageConfirmed: true,
      interests: Array.from({ length: 11 }, (_, i) => `tag${i}`)
    }).success, false);
  });

  it('caps profile interests at 10', () => {
    assert.equal(updateProfileRequestSchema.safeParse({ interests: ['a', 'b'] }).success, true);
    assert.equal(updateProfileRequestSchema.safeParse({ interests: 'muzik' }).success, false);
  });
});

describe('contracts: support tickets', () => {
  it('validates ticket creation and replies', () => {
    assert.equal(createTicketRequestSchema.safeParse({ subject: 'Giris sorunu', body: 'Sifremi unuttum ama kod gelmiyor, yardim lutfen.' }).success, true);
    assert.equal(createTicketRequestSchema.safeParse({ subject: 'x', body: 'kisa' }).success, false);
    assert.equal(replyTicketRequestSchema.safeParse({ message: 'Cozduk, tekrar dene.' }).success, true);
    assert.equal(replyTicketRequestSchema.safeParse({ message: '' }).success, false);
  });
});

describe('contracts: profile geo fields', () => {
  it('accepts city and coordinates', () => {
    const ok = updateProfileRequestSchema.safeParse({ city: 'İstanbul', latitude: 41.0, longitude: 29.0 });
    assert.equal(ok.success, true);
    assert.equal(updateProfileRequestSchema.safeParse({ latitude: 100 }).success, false);
  });

  it('accepts a private street address but caps its length', () => {
    const ok = updateProfileRequestSchema.safeParse({ address: 'Örnek Mah. 123. Sk. No: 4 D: 7' });
    assert.equal(ok.success, true);
    assert.equal(updateProfileRequestSchema.safeParse({ address: 'a'.repeat(501) }).success, false);
    assert.equal(updateProfileRequestSchema.safeParse({ address: null }).success, true);
  });

  it('accepts discover geo filters', () => {
    const ok = discoverQuerySchema.safeParse({ latitude: 41.0, longitude: 29.0, maxDistanceKm: 25 });
    assert.equal(ok.success, true);
    if (ok.success) assert.equal(ok.data.maxDistanceKm, 25);
  });
});
