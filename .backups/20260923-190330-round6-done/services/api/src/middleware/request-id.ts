import { randomUUID } from 'node:crypto';
import { RequestHandler } from 'express';

export const requestId: RequestHandler = (req, res, next) => {
  const supplied = req.header('x-request-id');
  const value = supplied && /^[a-zA-Z0-9._-]{8,128}$/.test(supplied) ? supplied : randomUUID();
  req.requestId = value;
  res.setHeader('x-request-id', value);
  next();
};
