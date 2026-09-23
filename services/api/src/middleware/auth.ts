import { RequestHandler } from 'express';
import { TokenService } from '../security/tokens';
import { ApiError } from './errors';

export function requireAuth(tokens: TokenService): RequestHandler {
  return (req, _res, next) => {
    const header = req.header('authorization');
    if (!header?.startsWith('Bearer ')) return next(new ApiError(401, 'AUTH_REQUIRED', 'A valid bearer token is required'));
    try {
      const claims = tokens.verify(header.slice(7).trim(), 'access');
      req.auth = { userId: claims.sub, tokenId: claims.jti };
      next();
    } catch {
      next(new ApiError(401, 'INVALID_TOKEN', 'The access token is invalid or expired'));
    }
  };
}
