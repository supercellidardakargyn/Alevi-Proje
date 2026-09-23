export interface AuthContext {
  userId: string;
  tokenId: string;
}

declare global {
  namespace Express {
    interface Request {
      requestId: string;
      auth?: AuthContext;
    }
  }
}

export {};
