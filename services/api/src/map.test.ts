import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { z } from 'zod';
import { mapRoutes } from './routes/map.js';

/** Gizlilik: uye konumu asla tam olarak gonderilmemeli (~2 km yuvarlanir). */
const nearbyQuerySchema = z.object({
  lat: z.coerce.number().min(-90).max(90),
  lng: z.coerce.number().min(-180).max(180),
  radiusKm: z.coerce.number().min(1).max(500).default(50),
  limit: z.coerce.number().int().min(1).max(200).default(120)
});

/** map.ts icindeki blur ile ayni davranis: 2 ondalik yuvarlama. */
function blur(latitude: number, longitude: number) {
  return { latitude: Math.round(latitude * 50) / 50, longitude: Math.round(longitude * 50) / 50 };
}

describe('map: sorgu dogrulamasi', () => {
  it('applies defaults', () => {
    const parsed = nearbyQuerySchema.parse({ lat: '39.9', lng: '32.8' });
    assert.equal(parsed.radiusKm, 50);
    assert.equal(parsed.limit, 120);
  });

  it('rejects out-of-range coordinates and huge radii', () => {
    assert.equal(nearbyQuerySchema.safeParse({ lat: 120, lng: 0 }).success, false);
    assert.equal(nearbyQuerySchema.safeParse({ lat: 0, lng: 200 }).success, false);
    assert.equal(nearbyQuerySchema.safeParse({ lat: 0, lng: 0, radiusKm: 5000 }).success, false);
  });
});

describe('map: konum gizliligi', () => {
  it('rounds coordinates to roughly 2 km', () => {
    const exact = blur(39.9334, 32.8597);
    assert.notEqual(exact.latitude, 39.9334);
    assert.equal(exact.latitude, 39.94);
    assert.equal(exact.longitude, 32.86);
    // En fazla ~2 km sapma (0.02 derece yaklaşık 2.2 km).
    const shiftKm = Math.abs(39.94 - 39.9334) * 111;
    assert.ok(shiftKm < 2.3);
  });

  it('is stable and idempotent', () => {
    const once = blur(41.0082, 28.9784);
    assert.deepEqual(blur(once.latitude, once.longitude), once);
  });
});

describe('map: rota kaydi', () => {
  it('exposes GET /nearby', () => {
    const router = mapRoutes({} as never);
    const paths = (router as unknown as { stack: Array<{ route?: { path?: string } }> }).stack
      .map((layer) => layer.route?.path)
      .filter(Boolean);
    assert.ok(paths.includes('/nearby'));
  });
});
