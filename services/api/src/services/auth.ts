import bcrypt from 'bcryptjs';
import { randomBytes } from 'node:crypto';
import { PrismaClient } from '@prisma/client';
import { LoginRequest, RegisterRequest } from '@alevi/contracts';
import { config } from '../config';
import { encryptSensitivePayload, hashToken } from '../security/crypto';
import { verifyGoogleIdToken } from '../security/google';
import { TokenService } from '../security/tokens';
import { PublicUser } from '../services/profiles';
import { sendVerificationEmail } from './mailer';

const CODE_TTL_MS = 10 * 60 * 1000;
const CODE_MAX_ATTEMPTS = 5;

// Bilinmeyen kullanicida zamanlama saldirisini engellemek icin karsilastirma
// yapilir; pahali hash her acilista BIR kez uretilir, her giriste degil.
let dummyHash = '';
async function getDummyHash(): Promise<string> {
  if (!dummyHash) dummyHash = await bcrypt.hash('timing-dummy-placeholder', 10);
  return dummyHash;
}
void getDummyHash();

function newInviteCode(): string {
  return randomBytes(4).toString('hex');
}

function newCode(): string {
  return String(randomBytes(4).readUInt32BE(0) % 1_000_000).padStart(6, '0');
}

export class AuthService {
  constructor(private readonly prisma: PrismaClient, private readonly tokens: TokenService) {}

  async register(input: RegisterRequest, metadata: { userAgent?: string; ipAddress?: string }) {
    const passwordHash = await bcrypt.hash(input.password, 12);
    let invitedById: string | null = null;
    if (input.inviteCode) {
      const inviter = await this.prisma.user.findFirst({ where: { inviteCode: input.inviteCode, deletedAt: null }, select: { id: true } });
      if (!inviter) throw new Error('INVALID_INVITE');
      invitedById = inviter.id;
    }
    const interests = (input.interests ?? []).map((tag) => tag.trim()).filter(Boolean).slice(0, 10);
    let user = null;
    for (let attempt = 0; attempt < 3 && !user; attempt++) {
      try {
        user = await this.prisma.user.create({
          data: {
            email: input.email,
            passwordHash,
            displayName: input.displayName,
            consentVersion: input.consentVersion,
            inviteCode: newInviteCode(),
            invitedById,
            interests,
            ...(input.sensitivePayload ? {
              sensitivePayloadCiphertext: Buffer.from(encryptSensitivePayload(input.sensitivePayload, config.sensitiveDataKey), 'utf8'),
              sensitivePayloadVersion: 1
            } : {})
          }
        });
      } catch (error) {
        if (error && typeof error === 'object' && 'code' in error && (error as { code?: string }).code === 'P2002' && attempt < 2) continue;
        throw error;
      }
    }
    if (!user) throw new Error('REGISTRATION_FAILED');
    await this.issueCode(user.id, input.email, metadata);
    return { userId: user.id, email: user.email };
  }

  async verifyEmail(email: string, code: string, metadata: { userAgent?: string; ipAddress?: string }) {
    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user || user.deletedAt) throw new Error('INVALID_CODE');
    if (user.emailVerified) return this.issueSession(user, metadata);
    await this.consumeCode(user.id, code, 'verify');
    await this.prisma.user.update({ where: { id: user.id }, data: { emailVerified: true } });
    return this.issueSession(user, metadata);
  }

  async forgotPassword(email: string): Promise<void> {
    const user = await this.prisma.user.findUnique({ where: { email } });
    // Hesap varligi sizdirilmaz.
    if (!user || user.deletedAt || !user.passwordHash) return;
    const recent = await this.prisma.emailVerification.findFirst({
      where: { userId: user.id, purpose: 'reset', createdAt: { gte: new Date(Date.now() - 60_000) } },
      orderBy: { createdAt: 'desc' }
    });
    if (recent) return;
    await this.issueCode(user.id, user.email, {}, 'reset');
  }

  async resetPassword(email: string, code: string, newPassword: string): Promise<void> {
    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user || user.deletedAt || !user.passwordHash) throw new Error('INVALID_CODE');
    await this.consumeCode(user.id, code, 'reset');
    const passwordHash = await bcrypt.hash(newPassword, 12);
    await this.prisma.$transaction([
      this.prisma.user.update({ where: { id: user.id }, data: { passwordHash } }),
      this.prisma.refreshToken.updateMany({ where: { userId: user.id, revokedAt: null }, data: { revokedAt: new Date() } })
    ]);
  }

  async adminLogin(input: LoginRequest, metadata: { userAgent?: string; ipAddress?: string }) {
    const user = await this.prisma.user.findUnique({ where: { email: input.email } });
    if (!user || user.deletedAt) {
      await bcrypt.compare(input.password, await getDummyHash()).catch(() => undefined);
      throw new Error('INVALID_CREDENTIALS');
    }
    const valid = user.passwordHash ? await bcrypt.compare(input.password, user.passwordHash) : false;
    if (!valid) throw new Error('INVALID_CREDENTIALS');
    if (user.role !== 'ADMIN' && user.role !== 'MODERATOR') throw new Error('ADMIN_REQUIRED');
    return this.issueSession(user, metadata);
  }

  private async consumeCode(userId: string, code: string, purpose: string): Promise<void> {
    // Tek UPDATE ile atomik tuketim: paralel denemelerde hak asimi olmaz.
    const consumed = await this.prisma.emailVerification.updateMany({
      where: { userId, purpose, consumedAt: null, codeHash: hashToken(code), expiresAt: { gt: new Date() }, attempts: { lt: CODE_MAX_ATTEMPTS } },
      data: { consumedAt: new Date() }
    });
    if (consumed.count === 0) {
      await this.prisma.emailVerification.updateMany({
        where: { userId, purpose, consumedAt: null, codeHash: hashToken(code) },
        data: { attempts: { increment: 1 } }
      }).catch(() => undefined);
      throw new Error('INVALID_CODE');
    }
    await this.prisma.emailVerification.updateMany({
      where: { userId, purpose, consumedAt: null },
      data: { consumedAt: new Date() }
    });
  }

  async resendCode(email: string): Promise<void> {
    const user = await this.prisma.user.findUnique({ where: { email } });
    // Hesap varligi sizdirilmaz: her zaman basarili gorunur.
    if (!user || user.deletedAt || user.emailVerified) return;
    const recent = await this.prisma.emailVerification.findFirst({
      where: { userId: user.id, createdAt: { gte: new Date(Date.now() - 60_000) } },
      orderBy: { createdAt: 'desc' }
    });
    if (recent) return;
    await this.issueCode(user.id, user.email, {});
  }

  async login(input: LoginRequest, metadata: { userAgent?: string; ipAddress?: string }) {
    const user = await this.prisma.user.findUnique({ where: { email: input.email } });
    // Timing saldirisina karsi hesap yoksa da ayni maliyetli is yapilir.
    if (!user || user.deletedAt) {
      await bcrypt.compare(input.password, await getDummyHash()).catch(() => undefined);
      throw new Error('INVALID_CREDENTIALS');
    }
    const valid = user.passwordHash ? await bcrypt.compare(input.password, user.passwordHash) : false;
    if (!valid) throw new Error('INVALID_CREDENTIALS');
    if (!user.emailVerified) throw new Error('EMAIL_NOT_VERIFIED');
    return this.issueSession(user, metadata);
  }

  async google(input: { idToken: string; displayName?: string; consentVersion: string; ageConfirmed: boolean }, metadata: { userAgent?: string; ipAddress?: string }) {
    let claims;
    try {
      claims = await verifyGoogleIdToken(input.idToken);
    } catch (error) {
      if (error instanceof Error && error.message === 'GOOGLE_DISABLED') throw new Error('GOOGLE_DISABLED');
      throw new Error('GOOGLE_REJECTED');
    }
    if (!claims.email || claims.emailVerified === false) throw new Error('GOOGLE_NO_EMAIL');
    const existing = await this.prisma.user.findFirst({
      where: { OR: [{ googleSub: claims.sub }, { email: claims.email }] },
    });
    if (existing) {
      if (existing.deletedAt) throw new Error('INVALID_CREDENTIALS');
      const updated = existing.googleSub
        ? existing
        : await this.prisma.user.update({ where: { id: existing.id }, data: { googleSub: claims.sub, emailVerified: true } });
      return this.issueSession(updated, metadata);
    }
    if (!input.ageConfirmed) throw new Error('AGE_CONFIRMATION_REQUIRED');
    const displayName = input.displayName?.trim() || claims.name?.slice(0, 80) || claims.email.split('@')[0];
    const created = await this.prisma.user.create({
      data: {
        email: claims.email,
        passwordHash: '',
        displayName,
        consentVersion: input.consentVersion,
        inviteCode: newInviteCode(),
        emailVerified: true,
        googleSub: claims.sub
      }
    });
    return this.issueSession(created, metadata);
  }

  async refresh(refreshToken: string, metadata: { userAgent?: string; ipAddress?: string }) {
    const claims = this.tokens.verify(refreshToken, 'refresh');
    const tokenHash = hashToken(refreshToken);
    const stored = await this.prisma.refreshToken.findUnique({ where: { tokenHash }, include: { user: true } });
    if (!stored || stored.expiresAt <= new Date() || stored.user.deletedAt || stored.userId !== claims.sub) {
      throw new Error('INVALID_REFRESH');
    }
    if (stored.revokedAt) {
      // Calinmis token tekrar kullanimi: tum aile iptal edilir.
      await this.prisma.refreshToken.updateMany({
        where: { userId: stored.userId, revokedAt: null },
        data: { revokedAt: new Date() }
      }).catch(() => undefined);
      throw new Error('INVALID_REFRESH');
    }
    const next = await this.prisma.$transaction(async (tx) => {
      await tx.refreshToken.update({ where: { id: stored.id }, data: { revokedAt: new Date() } });
      const issued = this.tokens.issue(stored.userId, 'refresh');
      await tx.refreshToken.create({ data: {
        userId: stored.userId,
        tokenHash: hashToken(issued.token),
        expiresAt: new Date(issued.claims.exp * 1000),
        userAgent: metadata.userAgent,
        ipAddress: metadata.ipAddress
      } });
      const access = this.tokens.issue(stored.userId, 'access');
      return { accessToken: access.token, refreshToken: issued.token, user: stored.user };
    });
    return next;
  }

  async logout(refreshToken?: string): Promise<void> {
    if (!refreshToken) return;
    try {
      await this.prisma.refreshToken.updateMany({ where: { tokenHash: hashToken(refreshToken), revokedAt: null }, data: { revokedAt: new Date() } });
    } catch {
      // Logout is intentionally idempotent.
    }
  }

  private async issueCode(userId: string, email: string, _metadata: { userAgent?: string; ipAddress?: string }, purpose = 'verify'): Promise<void> {
    const code = newCode();
    await this.prisma.emailVerification.updateMany({ where: { userId, purpose, consumedAt: null }, data: { consumedAt: new Date() } });
    await this.prisma.emailVerification.create({
      data: { userId, purpose, codeHash: hashToken(code), expiresAt: new Date(Date.now() + CODE_TTL_MS) }
    });
    await sendVerificationEmail(email, code);
  }

  private async issueSession(user: PublicUser, metadata: { userAgent?: string; ipAddress?: string }) {
    const access = this.tokens.issue(user.id, 'access');
    const refresh = this.tokens.issue(user.id, 'refresh');
    await this.prisma.refreshToken.create({ data: {
      userId: user.id,
      tokenHash: hashToken(refresh.token),
      expiresAt: new Date(refresh.claims.exp * 1000),
      userAgent: metadata.userAgent,
      ipAddress: metadata.ipAddress
    } });
    return { accessToken: access.token, refreshToken: refresh.token, user };
  }
}
