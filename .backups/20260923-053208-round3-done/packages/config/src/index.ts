import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().min(1).max(65535).default(3000),
  HOST: z.string().default('0.0.0.0'),
  DATABASE_URL: z.string().min(1).default('postgresql://app:app@localhost:5432/alevi?schema=public'),
  REDIS_URL: z.string().min(1).default('redis://localhost:6379'),
  REDIS_REQUIRED: z.string().default('false'),
  CORS_ORIGINS: z.string().default('*'),
  TRUST_PROXY: z.string().default('false'),
  RATE_LIMIT_WINDOW_MS: z.coerce.number().int().positive().default(60000),
  RATE_LIMIT_MAX: z.coerce.number().int().positive().default(120),
  AUTH_RATE_LIMIT_MAX: z.coerce.number().int().positive().default(20),
  JWT_ACCESS_SECRET: z.string().default('development-access-secret-change-me-32-chars'),
  JWT_REFRESH_SECRET: z.string().default('development-refresh-secret-change-me-32-chars'),
  JWT_ISSUER: z.string().default('alevi-connect'),
  JWT_AUDIENCE: z.string().default('alevi-mobile'),
  GOOGLE_CLIENT_ID: z.string().default(''),
  GOOGLE_ANDROID_CLIENT_ID: z.string().default(''),
  SMTP_HOST: z.string().default(''),
  SMTP_PORT: z.coerce.number().int().min(1).max(65535).default(587),
  SMTP_USER: z.string().default(''),
  SMTP_PASS: z.string().default(''),
  SMTP_FROM: z.string().default('Can Meydanı <noreply@sonalis.com.tr>'),
  UPLOAD_DIR: z.string().default('./uploads'),
  MAX_UPLOAD_MB: z.coerce.number().int().min(1).max(20).default(5),
  ACCESS_TOKEN_TTL_SECONDS: z.coerce.number().int().positive().default(900),
  REFRESH_TOKEN_TTL_SECONDS: z.coerce.number().int().positive().default(2592000),
  SENSITIVE_DATA_KEY: z.string().optional(),
  FIELD_ENCRYPTION_KEY_BASE64: z.string().optional(),
  MESH_ENABLED: z.string().default('false'),
  MESH_NODE_ID: z.string().min(1).default('api-node-1'),
  MESH_HOST: z.string().default('0.0.0.0'),
  MESH_PORT: z.coerce.number().int().min(1).max(65535).default(9443),
  MESH_JOIN_SECRET: z.string().default('development-mesh-join-secret-change-me-32-chars'),
  MESH_CA_FILE: z.string().default('/run/secrets/mesh/ca.crt'),
  MESH_CERT_FILE: z.string().default('/run/secrets/mesh/node.crt'),
  MESH_KEY_FILE: z.string().default('/run/secrets/mesh/node.key'),
  MESH_HEARTBEAT_MS: z.coerce.number().int().positive().default(10000),
  MESH_CONNECT_TIMEOUT_MS: z.coerce.number().int().positive().default(10000),
  MESH_RECONNECT_BASE_MS: z.coerce.number().int().positive().default(500),
  MESH_RECONNECT_MAX_MS: z.coerce.number().int().positive().default(30000),
  MESH_PEERS: z.string().default(''),
  MESH_BOOTSTRAP_PEERS: z.string().default(''),
  EDGE_SEED_NAME: z.string().default(''),
  EDGE_SEED_HOST: z.string().default(''),
  EDGE_SEED_PORT: z.string().default(''),
  EDGE_SEED_TOKEN: z.string().default(''),
  EDGE_UPLINK_URL: z.string().default(''),
  EDGE_JOIN_TOKEN: z.string().default(''),
  EDGE_HEARTBEAT_MS: z.coerce.number().int().positive().default(15000)
});

export type NodeEnvironment = 'development' | 'test' | 'production';

export interface AppConfig {
  nodeEnv: NodeEnvironment;
  port: number;
  host: string;
  databaseUrl: string;
  redisUrl: string;
  redisRequired: boolean;
  corsOrigins: string[];
  trustProxy: boolean;
  rateLimitWindowMs: number;
  rateLimitMax: number;
  authRateLimitMax: number;
  jwtAccessSecret: string;
  jwtRefreshSecret: string;
  jwtIssuer: string;
  jwtAudience: string;
  googleClientId: string;
  googleAndroidClientId: string;
  smtp: {
    host: string;
    port: number;
    user: string;
    pass: string;
    from: string;
  };
  uploadDir: string;
  maxUploadMb: number;
  accessTokenTtlSeconds: number;
  refreshTokenTtlSeconds: number;
  sensitiveDataKey: Buffer;
  mesh: {
    enabled: boolean;
    nodeId: string;
    host: string;
    port: number;
    joinSecret: string;
    caFile: string;
    certFile: string;
    keyFile: string;
    heartbeatMs: number;
    connectTimeoutMs: number;
    reconnectBaseMs: number;
    reconnectMaxMs: number;
    peers: string[];
  };
  edgeSeed: {
    name: string;
    host: string;
    port: number | null;
    token: string;
  };
  edgeUplink: {
    url: string;
    joinToken: string;
    heartbeatMs: number;
  };
}

function parseBoolean(value: string): boolean {
  return ['1', 'true', 'yes', 'on'].includes(value.toLowerCase());
}

function parseKey(hexValue: string | undefined, base64Value: string | undefined, environment: NodeEnvironment): Buffer {
  const fromBase64 = (base64Value ?? '').trim();
  if (fromBase64) {
    // Legacy root .env naming: FIELD_ENCRYPTION_KEY_BASE64 (32 bytes, base64).
    const decoded = Buffer.from(fromBase64, 'base64');
    if (decoded.length !== 32) {
      throw new Error('FIELD_ENCRYPTION_KEY_BASE64 must decode to exactly 32 bytes');
    }
    if (environment === 'production' && decoded.equals(Buffer.alloc(32, 0))) {
      throw new Error('FIELD_ENCRYPTION_KEY_BASE64 must not use the development placeholder in production');
    }
    return decoded;
  }
  const normalized = (hexValue ?? '0000000000000000000000000000000000000000000000000000000000000000').trim();
  if (!/^[a-fA-F0-9]{64}$/.test(normalized)) {
    throw new Error('SENSITIVE_DATA_KEY must be exactly 64 hexadecimal characters');
  }
  if (environment === 'production' && /^0+$/.test(normalized)) {
    throw new Error('SENSITIVE_DATA_KEY must not use the development placeholder in production');
  }
  return Buffer.from(normalized, 'hex');
}

function requireProductionSecret(value: string, name: string, environment: NodeEnvironment): void {
  if (environment === 'production' && (value.length < 32 || value.includes('change-me'))) {
    throw new Error(`${name} must be a unique secret of at least 32 characters in production`);
  }
}

export function loadConfig(source: NodeJS.ProcessEnv = process.env): AppConfig {
  const parsed = envSchema.parse(source);
  const nodeEnv = parsed.NODE_ENV;
  requireProductionSecret(parsed.JWT_ACCESS_SECRET, 'JWT_ACCESS_SECRET', nodeEnv);
  requireProductionSecret(parsed.JWT_REFRESH_SECRET, 'JWT_REFRESH_SECRET', nodeEnv);
  requireProductionSecret(parsed.MESH_JOIN_SECRET, 'MESH_JOIN_SECRET', nodeEnv);
  if (nodeEnv === 'production') {
    if (!parsed.SMTP_HOST || !parsed.SMTP_USER || !parsed.SMTP_PASS) {
      throw new Error('SMTP_HOST, SMTP_USER and SMTP_PASS are required in production (eposta dogrulama icin)');
    }
    if (!parsed.GOOGLE_CLIENT_ID) {
      throw new Error('GOOGLE_CLIENT_ID is required in production (Google ile giris icin)');
    }
  }

  const corsOrigins = parsed.CORS_ORIGINS.split(',').map((origin) => origin.trim()).filter(Boolean);
  const peers = [...parsed.MESH_PEERS.split(','), ...parsed.MESH_BOOTSTRAP_PEERS.split(',')]
    .map((peer) => peer.trim())
    .filter(Boolean);
  const dedupedPeers = [...new Set(peers)];

  return {
    nodeEnv,
    port: parsed.PORT,
    host: parsed.HOST,
    databaseUrl: parsed.DATABASE_URL,
    redisUrl: parsed.REDIS_URL,
    redisRequired: parseBoolean(parsed.REDIS_REQUIRED),
    corsOrigins: corsOrigins.length > 0 ? corsOrigins : ['*'],
    trustProxy: parseBoolean(parsed.TRUST_PROXY),
    rateLimitWindowMs: parsed.RATE_LIMIT_WINDOW_MS,
    rateLimitMax: parsed.RATE_LIMIT_MAX,
    authRateLimitMax: parsed.AUTH_RATE_LIMIT_MAX,
    jwtAccessSecret: parsed.JWT_ACCESS_SECRET,
    jwtRefreshSecret: parsed.JWT_REFRESH_SECRET,
    jwtIssuer: parsed.JWT_ISSUER,
    jwtAudience: parsed.JWT_AUDIENCE,
    googleClientId: parsed.GOOGLE_CLIENT_ID,
    googleAndroidClientId: parsed.GOOGLE_ANDROID_CLIENT_ID,
    smtp: {
      host: parsed.SMTP_HOST,
      port: parsed.SMTP_PORT,
      user: parsed.SMTP_USER,
      pass: parsed.SMTP_PASS,
      from: parsed.SMTP_FROM
    },
    uploadDir: parsed.UPLOAD_DIR,
    maxUploadMb: parsed.MAX_UPLOAD_MB,
    accessTokenTtlSeconds: parsed.ACCESS_TOKEN_TTL_SECONDS,
    refreshTokenTtlSeconds: parsed.REFRESH_TOKEN_TTL_SECONDS,
    sensitiveDataKey: parseKey(parsed.SENSITIVE_DATA_KEY, parsed.FIELD_ENCRYPTION_KEY_BASE64, nodeEnv),
    mesh: {
      enabled: parseBoolean(parsed.MESH_ENABLED),
      nodeId: parsed.MESH_NODE_ID,
      host: parsed.MESH_HOST,
      port: parsed.MESH_PORT,
      joinSecret: parsed.MESH_JOIN_SECRET,
      caFile: parsed.MESH_CA_FILE,
      certFile: parsed.MESH_CERT_FILE,
      keyFile: parsed.MESH_KEY_FILE,
      heartbeatMs: parsed.MESH_HEARTBEAT_MS,
      connectTimeoutMs: parsed.MESH_CONNECT_TIMEOUT_MS,
      reconnectBaseMs: parsed.MESH_RECONNECT_BASE_MS,
      reconnectMaxMs: parsed.MESH_RECONNECT_MAX_MS,
      peers: dedupedPeers
    },
    edgeSeed: {
      name: parsed.EDGE_SEED_NAME.trim(),
      host: parsed.EDGE_SEED_HOST.trim(),
      port: parsed.EDGE_SEED_PORT.trim() ? Number(parsed.EDGE_SEED_PORT.trim()) : null,
      token: parsed.EDGE_SEED_TOKEN.trim()
    },
    edgeUplink: {
      url: parsed.EDGE_UPLINK_URL.trim().replace(/\/$/, ''),
      joinToken: parsed.EDGE_JOIN_TOKEN.trim(),
      heartbeatMs: parsed.EDGE_HEARTBEAT_MS
    }
  };
}
