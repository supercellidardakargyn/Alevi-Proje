import http from 'node:http';
import { mkdirSync, existsSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import {
  randomBytes, randomUUID, scryptSync, timingSafeEqual,
  createHmac, createCipheriv, createDecipheriv, createPublicKey, verify,
} from 'node:crypto';

// ---- Config (fail fast on weak secrets) ----
const PORT = Number(process.env.PORT || 3000);
const NODE_ID = process.env.SERVER_ID || randomUUID();
const ROLE = process.env.MESH_ROLE || 'primary';
const TTL = Number(process.env.PRESENCE_TTL_MS || 90000);
const DIR = process.env.DATA_DIR || join(process.cwd(), 'data');
const FILE = join(DIR, 'alevi.json');
const JWT_SECRET = process.env.JWT_ACCESS_SECRET || '';
const ALLOW_DEV = process.env.ALLOW_INSECURE_DEV === '1';
if (JWT_SECRET.length < 32 && !ALLOW_DEV) {
  console.error('FATAL: JWT_ACCESS_SECRET missing or <32 chars. Set a strong secret or ALLOW_INSECURE_DEV=1 (dev only).');
  process.exit(1);
}
const SECRET = JWT_SECRET || 'dev-only-insecure-secret';
const ENC_KEY_HEX = process.env.SENSITIVE_DATA_KEY || '';
const ENC_KEY = /^[0-9a-fA-F]{64}$/.test(ENC_KEY_HEX) ? Buffer.from(ENC_KEY_HEX, 'hex') : null;
const CORS_ORIGINS = String(process.env.CORS_ORIGINS || process.env.CORS_ORIGIN || '').split(',').map(s => s.trim()).filter(Boolean);
const GOOGLE_CLIENT_ID = (process.env.GOOGLE_CLIENT_ID || '').trim();
const RATE_GENERAL = Number(process.env.RATE_LIMIT_PER_MIN || 180);
const RATE_AUTH = Number(process.env.RATE_LIMIT_AUTH_PER_MIN || 20);
const TOKEN_TTL = 24 * 3600 * 1000;

// ---- Store (file-backed, 0600) ----
const db = { users: {}, presence: {}, posts: {}, messages: {}, swipes: {}, matches: {}, blocks: {}, reports: [] };
mkdirSync(DIR, { recursive: true });
if (existsSync(FILE)) try { Object.assign(db, JSON.parse(readFileSync(FILE, 'utf8'))); } catch { /* corrupt -> start empty, never crash */ }
if (!Array.isArray(db.reports)) db.reports = [];
const save = () => writeFileSync(FILE, JSON.stringify(db), { mode: 0o600 });

// ---- Crypto helpers ----
const hashPw = (p, s = randomBytes(16).toString('hex')) => s + ':' + scryptSync(p, s, 64).toString('hex');
const DUMMY_HASH = '00'.repeat(16) + ':' + '00'.repeat(64);
const checkPw = (p, v) => {
  const [s, x] = String(v || '').split(':');
  if (!s || !x) return false;
  let b;
  try { b = Buffer.from(x, 'hex'); } catch { return false; }
  if (!b.length) return false;
  const a = scryptSync(String(p || ''), s, b.length); // stored length: 32 (legacy) or 64
  return a.length === b.length && timingSafeEqual(a, b);
};
const dummyCompare = () => scryptSync('timing-dummy', 'timing-dummy-salt', 32); // equalize unknown-user timing
const signToken = (sub) => {
  const p = Buffer.from(JSON.stringify({ sub, iat: Date.now(), exp: Date.now() + TOKEN_TTL })).toString('base64url');
  return p + '.' + createHmac('sha256', SECRET).update(p).digest('base64url');
};
const authUser = (req) => {
  const h = req.headers.authorization || '';
  if (!h.startsWith('Bearer ')) return null;
  const [p, s] = h.slice(7).split('.');
  if (!p || !s) return null;
  const expect = createHmac('sha256', SECRET).update(p).digest('base64url');
  const a = Buffer.from(s), b = Buffer.from(expect);
  if (a.length !== b.length || !timingSafeEqual(a, b)) return null;
  try {
    const c = JSON.parse(Buffer.from(p, 'base64url').toString('utf8'));
    if (!c.sub || c.exp <= Date.now()) return null;
    return db.users[c.sub] || null;
  } catch { return null; }
};
const encryptSensitive = (v) => {
  const iv = randomBytes(12), c = createCipheriv('aes-256-gcm', ENC_KEY, iv);
  const x = Buffer.concat([c.update(JSON.stringify(v), 'utf8'), c.final()]);
  return 'v1.' + iv.toString('base64url') + '.' + c.getAuthTag().toString('base64url') + '.' + x.toString('base64url');
};

// ---- Public shapes (email NEVER leaves the owner) ----
const pub = (u) => u ? { id: u.id, displayName: u.displayName, bio: u.bio || null, city: u.city || null, purpose: u.purpose || null, createdAt: u.createdAt } : null;
const priv = (u) => ({ ...pub(u), email: u.email });
const blocked = (a, b) => (db.blocks[a] || []).includes(b) || (db.blocks[b] || []).includes(a);

// ---- Rate limiting (per IP sliding window) ----
const hits = new Map();
const limited = (ip, n, windowMs) => {
  const now = Date.now(), arr = (hits.get(ip) || []).filter(t => t > now - windowMs);
  arr.push(now); hits.set(ip, arr);
  if (arr.length > n) return true;
  if (hits.size > 10000) hits.clear();
  return false;
};

// ---- HTTP helpers ----
const secHeaders = (origin) => {
  const h = { 'x-content-type-options': 'nosniff', 'x-frame-options': 'DENY', 'referrer-policy': 'no-referrer', 'cache-control': 'no-store' };
  if (origin && CORS_ORIGINS.includes(origin)) h['access-control-allow-origin'] = origin;
  return h;
};
const send = (req, res, code, b) => {
  res.writeHead(code, { 'content-type': 'application/json; charset=utf-8', ...secHeaders(req.headers.origin), 'access-control-allow-headers': 'content-type,authorization', 'access-control-allow-methods': 'GET,POST,PATCH,OPTIONS' });
  res.end(JSON.stringify(b));
};
const readBody = (req) => new Promise((ok, fail) => {
  let s = '';
  req.on('data', x => { s += x; if (s.length > 131072) fail(Error('PAYLOAD_TOO_LARGE')); });
  req.on('end', () => { try { ok(s ? JSON.parse(s) : {}); } catch { fail(Error('INVALID_JSON')); } });
  req.on('error', () => fail(Error('READ_FAILED')));
});
const clampLimit = (u, dflt = 50) => {
  const n = Number(u.searchParams.get('limit') || dflt);
  return Math.min(100, Math.max(1, Number.isFinite(n) ? n : dflt));
};
const validEmail = (e) => /^[^\s@]{1,120}@[^\s@]{1,120}\.[^\s@]{2,20}$/.test(e);

// ---- Google ID token verification (stdlib https via fetch, certs cached 1h) ----
let googleCerts = { at: 0, keys: {} };
async function verifyGoogle(idToken) {
  if (!GOOGLE_CLIENT_ID) { const e = Error('GOOGLE_DISABLED'); e.code = 'GOOGLE_DISABLED'; throw e; }
  const parts = String(idToken || '').split('.');
  if (parts.length !== 3) { const e = Error('BAD_TOKEN'); e.code = 'BAD_TOKEN'; throw e; }
  if (Date.now() - googleCerts.at > 3600e3) {
    const r = await fetch('https://www.googleapis.com/oauth2/v3/certs');
    if (!r.ok) throw Error('CERT_FETCH_FAILED');
    const j = await r.json();
    googleCerts = { at: Date.now(), keys: Object.fromEntries((j.keys || []).map(k => [k.kid, k])) };
  }
  const header = JSON.parse(Buffer.from(parts[0], 'base64url').toString('utf8'));
  const jwk = googleCerts.keys[header.kid];
  if (!jwk) { googleCerts.at = 0; throw Error('UNKNOWN_KID'); }
  const key = createPublicKey({ key: jwk, format: 'jwk' });
  const ok = verify('sha256', Buffer.from(parts[0] + '.' + parts[1]), key, Buffer.from(parts[2], 'base64url'));
  if (!ok) { const e = Error('BAD_SIGNATURE'); e.code = 'BAD_SIGNATURE'; throw e; }
  const c = JSON.parse(Buffer.from(parts[1], 'base64url').toString('utf8'));
  if ((c.iss !== 'https://accounts.google.com' && c.iss !== 'accounts.google.com') || c.aud !== GOOGLE_CLIENT_ID || (c.exp * 1000) <= Date.now()) {
    const e = Error('BAD_CLAIMS'); e.code = 'BAD_CLAIMS'; throw e;
  }
  return c;
}

// ---- App ----
const api = http.createServer(async (req, res) => {
  const started = Date.now();
  const url = new URL(req.url || '/', `http://${req.headers.host || 'x'}`);
  const path = url.pathname;
  const ip = (req.headers['x-forwarded-for'] || '').toString().split(',')[0].trim() || req.socket.remoteAddress || '?';
  try {
    if (req.method === 'OPTIONS') { res.writeHead(204, secHeaders(req.headers.origin)); return res.end(); }
    const isAuthRoute = req.method === 'POST' && (path === '/v1/auth/register' || path === '/v1/auth/login' || path === '/v1/auth/google');
    if (limited(ip + (isAuthRoute ? ':auth' : ''), isAuthRoute ? RATE_AUTH : RATE_GENERAL, 60e3)) {
      res.setHeader('retry-after', '60');
      return send(req, res, 429, { error: { code: 'RATE_LIMITED', message: 'Too many requests, retry in a minute' } });
    }

    if (req.method === 'GET' && path === '/health/live') return send(req, res, 200, { status: 'ok', nodeId: NODE_ID, role: ROLE, service: 'alevi-connect' });
    if (req.method === 'GET' && path === '/health/ready') return send(req, res, 200, { status: 'ok', nodeId: NODE_ID });
    if (req.method === 'GET' && path === '/health/mesh') return send(req, res, 200, { status: 'ok', nodeId: NODE_ID, role: ROLE, peers: String(process.env.MESH_PEERS || '').split(',').filter(Boolean).map(peer => ({ peer, status: 'configured' })) });
    if (req.method === 'GET' && path === '/') return send(req, res, 200, { name: 'Alevi Connect API', nodeId: NODE_ID, role: ROLE });
    if (req.method === 'GET' && path === '/app') {
      try {
        const html = readFileSync(join(process.cwd(), 'public', 'app.html'), 'utf8');
        res.writeHead(200, { 'content-type': 'text/html; charset=utf-8', 'x-content-type-options': 'nosniff', 'x-frame-options': 'SAMEORIGIN', 'referrer-policy': 'no-referrer', 'cache-control': 'no-store' });
        return res.end(html);
      } catch { return send(req, res, 404, { error: { code: 'NOT_FOUND', message: 'Demo app missing' } }); }
    }

    if (req.method === 'POST' && path === '/v1/auth/register') {
      const b = await readBody(req);
      const email = String(b.email || '').trim().toLowerCase(), password = String(b.password || ''), name = String(b.displayName || '').trim();
      if (!validEmail(email) || password.length < 12 || name.length < 2 || name.length > 60) return send(req, res, 400, { error: { code: 'VALIDATION_ERROR', message: 'Valid email, displayName (2-60) and 12+ character password required' } });
      if (Object.values(db.users).some(x => x.email === email)) return send(req, res, 409, { error: { code: 'EMAIL_IN_USE', message: 'Email already registered' } });
      const u = { id: randomUUID(), email, displayName: name, passwordHash: hashPw(password), bio: '', city: '', purpose: '', googleSub: null, createdAt: new Date().toISOString() };
      db.users[u.id] = u; save();
      return send(req, res, 201, { data: { accessToken: signToken(u.id), user: priv(u) } });
    }
    if (req.method === 'POST' && path === '/v1/auth/login') {
      const b = await readBody(req);
      const u = Object.values(db.users).find(x => x.email === String(b.email || '').trim().toLowerCase());
      if (!u) { dummyCompare(); return send(req, res, 401, { error: { code: 'INVALID_CREDENTIALS', message: 'Email or password is incorrect' } }); }
      if (!u.passwordHash || !checkPw(String(b.password || ''), u.passwordHash)) return send(req, res, 401, { error: { code: 'INVALID_CREDENTIALS', message: 'Email or password is incorrect' } });
      return send(req, res, 200, { data: { accessToken: signToken(u.id), user: priv(u) } });
    }
    if (req.method === 'POST' && path === '/v1/auth/google') {
      let claims;
      try { claims = await verifyGoogle((await readBody(req)).idToken); }
      catch (e) {
        const code = e.code === 'GOOGLE_DISABLED' ? 503 : 401;
        return send(req, res, code, { error: { code: e.code || 'GOOGLE_AUTH_FAILED', message: e.code === 'GOOGLE_DISABLED' ? 'Google sign-in not configured on this server' : 'Google token rejected' } });
      }
      let u = Object.values(db.users).find(x => x.googleSub === claims.sub) || Object.values(db.users).find(x => x.email === String(claims.email || '').toLowerCase());
      if (!u) {
        if (!claims.email) return send(req, res, 400, { error: { code: 'GOOGLE_NO_EMAIL', message: 'Google account has no email' } });
        u = { id: randomUUID(), email: String(claims.email).toLowerCase(), displayName: String(claims.name || claims.email.split('@')[0]).slice(0, 60), passwordHash: null, bio: '', city: '', purpose: '', googleSub: claims.sub, createdAt: new Date().toISOString() };
        db.users[u.id] = u; save();
      } else if (!u.googleSub) { u.googleSub = claims.sub; save(); }
      return send(req, res, 200, { data: { accessToken: signToken(u.id), user: priv(u) } });
    }
    if (req.method === 'POST' && path === '/v1/auth/logout') return send(req, res, 204, {});

    const u = authUser(req);
    if (!u) return send(req, res, 401, { error: { code: 'AUTH_REQUIRED', message: 'Bearer token required' } });

    if (req.method === 'GET' && path === '/v1/profile/me') return send(req, res, 200, { data: priv(u) });
    if (req.method === 'PATCH' && path === '/v1/profile/me') {
      const b = await readBody(req);
      const pick = (v, max) => (v === undefined ? undefined : String(v).slice(0, max));
      const name = pick(b.displayName, 60), bio = pick(b.bio, 500), city = pick(b.city, 120), purpose = pick(b.purpose, 120);
      if (name !== undefined && name.trim().length < 2) return send(req, res, 400, { error: { code: 'VALIDATION_ERROR', message: 'displayName too short' } });
      if (name !== undefined) u.displayName = name.trim();
      if (bio !== undefined) u.bio = bio; if (city !== undefined) u.city = city; if (purpose !== undefined) u.purpose = purpose;
      if (b.sensitivePayload !== undefined) {
        if (!ENC_KEY) return send(req, res, 400, { error: { code: 'ENCRYPTION_UNAVAILABLE', message: 'Server has no SENSITIVE_DATA_KEY' } });
        u.sensitive = encryptSensitive(b.sensitivePayload);
      }
      save();
      return send(req, res, 200, { data: priv(u) });
    }
    if (req.method === 'POST' && path === '/v1/presence/heartbeat') { db.presence[u.id] = { userId: u.id, lastSeenAt: Date.now() }; save(); return send(req, res, 204, {}); }
    if (req.method === 'GET' && path === '/v1/presence/active') {
      const a = Object.values(db.presence).filter(x => x.userId !== u.id && x.lastSeenAt > Date.now() - TTL && db.users[x.userId] && !blocked(u.id, x.userId)).map(x => pub(db.users[x.userId])).filter(Boolean);
      return send(req, res, 200, { data: a.slice(0, clampLimit(url)) });
    }
    if (req.method === 'GET' && path === '/v1/discover') {
      const items = Object.values(db.users).filter(x => x.id !== u.id && !blocked(u.id, x.id)).map(pub).slice(0, clampLimit(url));
      return send(req, res, 200, { data: { items } });
    }
    if (req.method === 'POST' && path === '/v1/matches/swipe') {
      const b = await readBody(req), t = db.users[String(b.userId || '')];
      if (!t || t.id === u.id || blocked(u.id, t.id)) return send(req, res, 404, { error: { code: 'USER_NOT_FOUND', message: 'User not found' } });
      db.swipes[u.id + ':' + t.id] = { from: u.id, to: t.id, decision: b.decision === 'PASS' ? 'PASS' : 'LIKE' }; save();
      const back = db.swipes[t.id + ':' + u.id];
      if (b.decision !== 'PASS' && back && back.decision === 'LIKE' && !Object.values(db.matches).some(m => (m.a === u.id && m.b === t.id) || (m.a === t.id && m.b === u.id))) {
        const m = { id: randomUUID(), a: u.id, b: t.id, createdAt: new Date().toISOString() };
        db.matches[m.id] = m; save();
        return send(req, res, 201, { data: { matched: true, match: { id: m.id, user: pub(t) } } });
      }
      return send(req, res, 201, { data: { matched: false } });
    }
    if (req.method === 'GET' && path === '/v1/matches') {
      const list = Object.values(db.matches).filter(m => (m.a === u.id || m.b === u.id) && !blocked(u.id, m.a === u.id ? m.b : m.a))
        .map(m => ({ id: m.id, user: pub(db.users[m.a === u.id ? m.b : m.a]), createdAt: m.createdAt })).slice(0, clampLimit(url));
      return send(req, res, 200, { data: list });
    }
    if (req.method === 'GET' && path === '/v1/community/posts') return send(req, res, 200, { data: Object.values(db.posts).slice(-clampLimit(url)).reverse() });
    if (req.method === 'POST' && path === '/v1/community/posts') {
      const b = await readBody(req);
      const p = { id: randomUUID(), author: pub(u), body: String(b.body || '').slice(0, 2000), createdAt: new Date().toISOString() };
      if (!p.body.trim()) return send(req, res, 400, { error: { code: 'VALIDATION_ERROR', message: 'Body required' } });
      db.posts[p.id] = p; save();
      return send(req, res, 201, { data: p });
    }
    if (req.method === 'GET' && path === '/v1/messages') {
      const list = Object.values(db.messages).filter(x => (x.from === u.id || x.to === u.id) && !blocked(u.id, x.from === u.id ? x.to : x.from)).slice(-clampLimit(url));
      return send(req, res, 200, { data: list });
    }
    if (req.method === 'POST' && path === '/v1/messages') {
      const b = await readBody(req), t = db.users[String(b.userId || '')];
      if (!t || blocked(u.id, t.id)) return send(req, res, 404, { error: { code: 'USER_NOT_FOUND', message: 'User not found' } });
      const m = { id: randomUUID(), from: u.id, to: t.id, body: String(b.body || '').slice(0, 2000), createdAt: new Date().toISOString() };
      if (!m.body.trim()) return send(req, res, 400, { error: { code: 'VALIDATION_ERROR', message: 'Body required' } });
      db.messages[m.id] = m; save();
      return send(req, res, 201, { data: m });
    }
    if (req.method === 'POST' && path === '/v1/safety/block') {
      const b = await readBody(req), t = db.users[String(b.userId || '')];
      if (!t || t.id === u.id) return send(req, res, 404, { error: { code: 'USER_NOT_FOUND', message: 'User not found' } });
      db.blocks[u.id] = [...new Set([...(db.blocks[u.id] || []), t.id])]; save();
      return send(req, res, 201, { data: { blocked: t.id } });
    }
    if (req.method === 'POST' && path === '/v1/safety/report') {
      const b = await readBody(req);
      const reason = String(b.reason || '').slice(0, 60), target = String(b.userId || '');
      if (!db.users[target] || !reason.trim()) return send(req, res, 400, { error: { code: 'VALIDATION_ERROR', message: 'userId and reason required' } });
      db.reports.push({ id: randomUUID(), from: u.id, userId: target, reason: reason.trim(), detail: String(b.detail || '').slice(0, 2000), createdAt: new Date().toISOString() }); save();
      return send(req, res, 201, { data: { received: true } });
    }
    return send(req, res, 404, { error: { code: 'NOT_FOUND', message: 'Route not found' } });
  } catch (e) {
    return send(req, res, 400, { error: { code: 'REQUEST_FAILED', message: e instanceof Error ? e.message : 'Request failed' } });
  } finally {
    console.log(new Date().toISOString() + ' ' + req.method + ' ' + path + ' ' + (Date.now() - started) + 'ms');
  }
});
api.listen(PORT, '0.0.0.0', () => console.log('Alevi node ' + NODE_ID + ' (' + ROLE + ') listening on ' + PORT));
