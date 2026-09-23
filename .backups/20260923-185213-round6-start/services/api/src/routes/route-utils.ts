import { NextFunction, Request, RequestHandler, Response } from 'express';
import { ApiError } from '../middleware/errors';

export function asyncHandler(handler: (req: Request, res: Response, next: NextFunction) => Promise<unknown>): RequestHandler {
  return (req, res, next) => {
    void handler(req, res, next).catch(next);
  };
}

export function userId(req: Request): string {
  if (!req.auth?.userId) throw new ApiError(401, 'AUTH_REQUIRED', 'Authentication is required');
  return req.auth.userId;
}

export function routeParam(req: Request, name: string): string {
  const value = req.params[name];
  if (typeof value !== 'string' || value.length === 0) throw new ApiError(400, 'INVALID_PARAMETER', `${name} is required`);
  return value;
}

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function routeUuid(req: Request, name: string): string {
  const value = routeParam(req, name);
  if (!UUID_RE.test(value)) throw new ApiError(400, 'INVALID_PARAMETER', `${name} must be a UUID`);
  return value;
}

export function notFoundIfNull<T>(value: T | null | undefined, label = 'Resource'): T {
  if (!value) throw new ApiError(404, 'NOT_FOUND', `${label} not found`);
  return value;
}
