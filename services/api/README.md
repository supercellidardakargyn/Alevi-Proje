# API service

Runnable Node.js 22 + TypeScript API for the Alevi MVP. The service uses Express, Prisma/PostgreSQL, and optional Redis.

## Local run

```sh
cp .env.example .env
npm install --prefix ../../packages/config
npm install --prefix ../../packages/contracts
npm install
npm run prisma:generate
npm run prisma:push
npm run dev
```

Health endpoints:

- `GET /health/live` — process liveness.
- `GET /health/ready` — PostgreSQL and Redis readiness.

API routes are under `/v1`: auth, profile, discover, matches, safety (block/report), communities, and messages.

Sensitive cultural fields are accepted only as `sensitivePayload`, encrypted with AES-256-GCM before persistence, and never included in public profile projections. Set a unique 32-byte hexadecimal `SENSITIVE_DATA_KEY` outside development.

## Production notes

Use `npm run prisma:migrate` during deployment, not `prisma db push`. Set unique 32+ character JWT and mesh secrets, restrict `CORS_ORIGINS`, set `TRUST_PROXY` only behind a trusted proxy, and mount mTLS files read-only. The mesh implementation is in `src/mesh` and enforces TLS 1.3, client certificates, one-time HMAC join tokens, heartbeat timeout, and exponential reconnect.
