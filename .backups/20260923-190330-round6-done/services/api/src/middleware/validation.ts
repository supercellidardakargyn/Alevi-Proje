import { RequestHandler } from 'express';
import { z } from 'zod';
import { ApiError } from './errors';

type Source = 'body' | 'query' | 'params';

export function validate(schema: z.ZodTypeAny, source: Source = 'body'): RequestHandler {
  return (req, _res, next) => {
    const result = schema.safeParse(req[source]);
    if (!result.success) {
      return next(new ApiError(400, 'VALIDATION_ERROR', 'Request validation failed', result.error.flatten()));
    }
    const request = req as unknown as Record<Source, unknown>;
    request[source] = result.data;
    next();
  };
}
