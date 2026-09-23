import { Request, Router } from 'express';
import rateLimit from 'express-rate-limit';
import { forgotPasswordRequestSchema, googleRequestSchema, loginRequestSchema, logoutRequestSchema, refreshRequestSchema, registerRequestSchema, resendCodeRequestSchema, resetPasswordRequestSchema, verifyEmailRequestSchema } from '@alevi/contracts';
import { AuthService } from '../services/auth';
import { validate } from '../middleware/validation';
import { ApiError } from '../middleware/errors';
import { asyncHandler } from './route-utils';
import { toPublicProfile } from '../services/profiles';

export function authRoutes(auth: AuthService): Router {
  const router = Router();
  // Kod ureten/tuketen uclar ayrica sikilir (e-posta dondurerek SMTP spam engeli).
  const codeLimiter = rateLimit({ windowMs: 60_000, limit: 10, standardHeaders: 'draft-7', legacyHeaders: false });
  router.use(['/verify-email', '/resend-code', '/forgot-password', '/reset-password'], codeLimiter);
  const metadata = (req: Request) => ({
    userAgent: req.get('user-agent')?.slice(0, 512),
    ipAddress: req.ip?.slice(0, 64)
  });

  router.post('/register', validate(registerRequestSchema), asyncHandler(async (req, res) => {
    try {
      const result = await auth.register(req.body, metadata(req));
      res.status(201).json({ data: { needsVerification: true, email: result.email } });
    } catch (error) {
      if (error instanceof Error && error.message === 'INVALID_INVITE') throw new ApiError(400, 'INVALID_INVITE', 'This invite code is invalid');
      if (error && typeof error === 'object' && 'code' in error && (error as { code?: string }).code === 'P2002') throw new ApiError(409, 'EMAIL_IN_USE', 'An account with this email already exists');
      throw error;
    }
  }));

  router.post('/verify-email', validate(verifyEmailRequestSchema), asyncHandler(async (req, res) => {
    try {
      const result = await auth.verifyEmail(req.body.email, req.body.code, metadata(req));
      res.json({ data: { accessToken: result.accessToken, refreshToken: result.refreshToken, user: toPublicProfile(result.user) } });
    } catch {
      throw new ApiError(401, 'INVALID_CODE', 'The verification code is invalid or expired');
    }
  }));

  router.post('/resend-code', validate(resendCodeRequestSchema), asyncHandler(async (req, res) => {
    await auth.resendCode(req.body.email);
    res.json({ data: { sent: true } });
  }));

  router.post('/forgot-password', validate(forgotPasswordRequestSchema), asyncHandler(async (req, res) => {
    await auth.forgotPassword(req.body.email);
    res.json({ data: { sent: true } });
  }));

  router.post('/reset-password', validate(resetPasswordRequestSchema), asyncHandler(async (req, res) => {
    try {
      await auth.resetPassword(req.body.email, req.body.code, req.body.newPassword);
      res.json({ data: { reset: true } });
    } catch {
      throw new ApiError(401, 'INVALID_CODE', 'The verification code is invalid or expired');
    }
  }));

  router.post('/admin-login', validate(loginRequestSchema), asyncHandler(async (req, res) => {
    try {
      const result = await auth.adminLogin(req.body, metadata(req));
      res.json({ data: { accessToken: result.accessToken, refreshToken: result.refreshToken } });
    } catch (error) {
      if (error instanceof Error && error.message === 'ADMIN_REQUIRED') throw new ApiError(403, 'ADMIN_REQUIRED', 'Administrator access is required');
      throw new ApiError(401, 'INVALID_CREDENTIALS', 'Email or password is incorrect');
    }
  }));

  router.post('/google', validate(googleRequestSchema), asyncHandler(async (req, res) => {
    try {
      const result = await auth.google(req.body, metadata(req));
      res.json({ data: { accessToken: result.accessToken, refreshToken: result.refreshToken, user: toPublicProfile(result.user) } });
    } catch (error) {
      if (error instanceof Error && error.message === 'GOOGLE_DISABLED') throw new ApiError(503, 'GOOGLE_DISABLED', 'Google sign-in is not configured on this server');
      if (error instanceof Error && error.message === 'GOOGLE_NO_EMAIL') throw new ApiError(400, 'GOOGLE_NO_EMAIL', 'Google account has no verified email');
      if (error instanceof Error && error.message === 'AGE_CONFIRMATION_REQUIRED') throw new ApiError(400, 'AGE_CONFIRMATION_REQUIRED', 'Confirm that you are over 18 to create an account');
      throw new ApiError(401, 'GOOGLE_REJECTED', 'Google token was rejected');
    }
  }));

  router.post('/login', validate(loginRequestSchema), asyncHandler(async (req, res) => {
    try {
      const result = await auth.login(req.body, metadata(req));
      res.json({ data: { accessToken: result.accessToken, refreshToken: result.refreshToken, user: toPublicProfile(result.user) } });
    } catch (error) {
      if (error instanceof Error && error.message === 'INVALID_CREDENTIALS') throw new ApiError(401, 'INVALID_CREDENTIALS', 'Email or password is incorrect');
      if (error instanceof Error && error.message === 'EMAIL_NOT_VERIFIED') throw new ApiError(403, 'EMAIL_NOT_VERIFIED', 'Verify your email first. Check your inbox for the code.');
      throw error;
    }
  }));

  router.post('/refresh', validate(refreshRequestSchema), asyncHandler(async (req, res) => {
    try {
      const result = await auth.refresh(req.body.refreshToken, metadata(req));
      res.json({ data: { accessToken: result.accessToken, refreshToken: result.refreshToken, user: toPublicProfile(result.user) } });
    } catch (error) {
      if (error instanceof Error && ['INVALID_REFRESH', 'Expired or invalid token', 'Invalid token'].includes(error.message)) throw new ApiError(401, 'INVALID_REFRESH', 'The refresh token is invalid or expired');
      throw error;
    }
  }));

  router.post('/logout', validate(logoutRequestSchema), asyncHandler(async (req, res) => {
    await auth.logout(req.body.refreshToken);
    res.status(204).send();
  }));

  return router;
}
