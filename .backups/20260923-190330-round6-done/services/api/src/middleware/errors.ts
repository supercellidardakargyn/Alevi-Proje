import { NextFunction, Request, RequestHandler, Response } from 'express';
import { ZodError } from 'zod';

export class ApiError extends Error {
  constructor(public readonly status: number, public readonly code: string, message: string, public readonly details?: unknown) {
    super(message);
    this.name = 'ApiError';
  }
}

export const notFound: RequestHandler = (req, _res, next) => {
  next(new ApiError(404, 'NOT_FOUND', `Route ${req.method} ${req.path} not found`));
};

export function errorHandler(error: unknown, req: Request, res: Response, _next: NextFunction): void {
  let status = 500;
  let code = 'INTERNAL_ERROR';
  let message = 'An unexpected error occurred';
  let details: unknown;

  if (error instanceof ApiError) {
    status = error.status;
    code = error.code;
    message = error.message;
    details = error.details;
  } else if (error instanceof ZodError) {
    status = 400;
    code = 'VALIDATION_ERROR';
    message = 'Request validation failed';
    details = error.flatten();
  } else if (error && typeof error === 'object' && 'code' in error && (error as { code?: string }).code === 'P2002') {
    status = 409;
    code = 'CONFLICT';
    message = 'A resource with these values already exists';
  } else if (error instanceof SyntaxError) {
    status = 400;
    code = 'INVALID_JSON';
    message = 'Request body contains invalid JSON';
  }

  if (status >= 500) {
    console.error(`[${req.requestId ?? 'no-request-id'}] ${status} ${code}`);
  }
  res.status(status).json({ error: { code, message, requestId: req.requestId, ...(details ? { details } : {}) } });
}
