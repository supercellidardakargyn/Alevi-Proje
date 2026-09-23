import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { loadConfig } from '@alevi/config';

const baseEnv = {
  DATABASE_URL: 'postgresql://app:app@localhost:5432/alevi?schema=public',
  REDIS_URL: 'redis://localhost:6379',
  JWT_ACCESS_SECRET: 'test-access-secret-32-chars-minimum-ok',
  JWT_REFRESH_SECRET: 'test-refresh-secret-32-chars-minimum-ok',
  MESH_JOIN_SECRET: 'test-mesh-join-secret-32-chars-minimum-ok'
};

describe('config: issuer/audience defaults', () => {
  it('defaults to alevi-connect / alevi-mobile', () => {
    const config = loadConfig({ ...process.env, ...baseEnv });
    assert.equal(config.jwtIssuer, 'alevi-connect');
    assert.equal(config.jwtAudience, 'alevi-mobile');
  });
});

describe('config: encryption key aliases', () => {
  it('accepts legacy FIELD_ENCRYPTION_KEY_BASE64', () => {
    const key = Buffer.alloc(32, 7).toString('base64');
    const config = loadConfig({ ...process.env, ...baseEnv, FIELD_ENCRYPTION_KEY_BASE64: key });
    assert.equal(config.sensitiveDataKey.length, 32);
    assert.equal(config.sensitiveDataKey.equals(Buffer.alloc(32, 7)), true);
  });

  it('accepts hex SENSITIVE_DATA_KEY', () => {
    const config = loadConfig({ ...process.env, ...baseEnv, SENSITIVE_DATA_KEY: 'ab'.repeat(32) });
    assert.equal(config.sensitiveDataKey.toString('hex'), 'ab'.repeat(32));
  });
});

describe('config: mesh peer aliases', () => {
  it('merges MESH_PEERS and MESH_BOOTSTRAP_PEERS without duplicates', () => {
    const config = loadConfig({
      ...process.env,
      ...baseEnv,
      MESH_PEERS: 'node-a:9443,node-b:9443',
      MESH_BOOTSTRAP_PEERS: 'node-b:9443,node-c:9443'
    });
    assert.deepEqual(config.mesh.peers, ['node-a:9443', 'node-b:9443', 'node-c:9443']);
  });
});
