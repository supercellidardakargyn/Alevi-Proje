// Alevi tek-port gateway (saf Node.js + express).
// Disaridan acik tek port: GATEWAY_PORT (varsayilan 25577). Host adina gore dagitir:
//   sonalis.com.tr (+www)      -> /srv/site statik dosya (+ /indir/*.apk)
//   api.sonalis.com.tr         -> api:3000
//   yonetim.sonalis.com.tr     -> admin:3000
// TLS, onundeki Cloudflare proxy'den gelir; burada duz HTTP konusulur.
// Cloudflare panelinde Always Use HTTPS + HSTS acik olmalidir.
const express = require('express');
const path = require('path');

const PORT = Number(process.env.PORT || 25577);
const SITE_DIR = process.env.SITE_DIR || '/srv/site';
const API_UPSTREAM = (process.env.API_UPSTREAM || 'http://api:3000').replace(/\/$/, '');
const ADMIN_UPSTREAM = (process.env.ADMIN_UPSTREAM || 'http://admin:3000').replace(/\/$/, '');

const SECURITY_HEADERS = {
  'X-Content-Type-Options': 'nosniff',
  'X-Frame-Options': 'DENY',
  'Referrer-Policy': 'strict-origin-when-cross-origin',
  'Permissions-Policy': 'camera=(), microphone=(), geolocation=(), payment=()',
  'Content-Security-Policy': "default-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; font-src 'self'; object-src 'none'; base-uri 'self'; frame-ancestors 'none'",
  // Cloudflare arkasinda HTTPS zorunludur; HSTS yalnizca guvenli baglamda anlamlidir.
  'Strict-Transport-Security': 'max-age=31536000; includeSubDomains'
};

const UPSTREAM_STRIPPED = new Set([
  'transfer-encoding', 'connection', 'content-encoding', 'content-length',
  'content-security-policy', 'strict-transport-security', 'x-frame-options',
  'x-content-type-options', 'referrer-policy', 'permissions-policy'
]);

const app = express();
app.disable('x-powered-by');
app.set('trust proxy', true);

app.use((req, res, next) => {
  for (const [key, value] of Object.entries(SECURITY_HEADERS)) res.setHeader(key, value);
  next();
});

async function proxy(req, res, upstream) {
  const target = upstream + req.originalUrl;
  const headers = { ...req.headers, host: new URL(upstream).host };
  delete headers['connection'];
  // Govdesiz POST (content-length: 0 / govde yok) stream olarak iletilirse
  // upstream asili kalir; bu durumda govde gonderilmez.
  const hasBody = req.headers['transfer-encoding'] != null ||
    (req.headers['content-length'] != null && req.headers['content-length'] !== '0');
  const started = Date.now();
  try {
    const upstreamRes = await fetch(target, {
      method: req.method,
      headers,
      body: !hasBody || ['GET', 'HEAD'].includes(req.method) ? undefined : req,
      // Node 18+: stream govde icin zorunlu, yoksa POST/PUT/PATCH 502 olur.
      duplex: 'half',
      redirect: 'manual',
      signal: AbortSignal.timeout(30_000)
    });
    res.status(upstreamRes.status);
    upstreamRes.headers.forEach((value, key) => {
      if (UPSTREAM_STRIPPED.has(key.toLowerCase())) return;
      res.setHeader(key, value);
    });
    if (upstreamRes.body) {
      for await (const chunk of upstreamRes.body) {
        if (!res.write(chunk)) await new Promise((resolve) => res.once('drain', resolve));
      }
    }
    res.end();
  } catch (error) {
    const timedOut = error && (error.name === 'TimeoutError' || error.name === 'AbortError');
    console.error(`[gateway] ${req.method} ${req.originalUrl} -> ${upstream} basarisiz (${Date.now() - started}ms): ${timedOut ? 'zaman asimi' : (error && error.message) || 'bilinmeyen'}`);
    if (timedOut) return res.status(504).json({ error: { code: 'UPSTREAM_TIMEOUT', message: 'Upstream service timed out' } });
    res.status(502).json({ error: { code: 'UPSTREAM_UNAVAILABLE', message: 'Upstream service is unavailable' } });
  }
}

// Dogrudan IP ile gelene de site gosterilir (host eslesmezse asagiya duser).
app.use((req, res, next) => {
  const host = (req.hostname || '').toLowerCase();
  if (host === 'api.sonalis.com.tr') return proxy(req, res, API_UPSTREAM);
  if (host === 'yonetim.sonalis.com.tr') return proxy(req, res, ADMIN_UPSTREAM);
  next();
});

app.get('/indir/*', (req, res, next) => {
  res.setHeader('Content-Disposition', 'attachment');
  next();
});

app.use(
  express.static(SITE_DIR, {
    extensions: ['html'],
    setHeaders: (res, filePath) => {
      const normalized = filePath.split(path.sep).join('/');
      if (normalized.includes('/web/')) {
        // Flutter web: CDN (gstatic/fonts) + wasm + Google girisi gerektirir.
        res.setHeader(
          'Content-Security-Policy',
          "default-src 'self' https: data: blob:; " +
          "script-src 'self' 'unsafe-inline' 'wasm-unsafe-eval' https:; " +
          "style-src 'self' 'unsafe-inline' https:; " +
          "font-src 'self' https: data:; " +
          "img-src 'self' data: blob: https:; " +
          "connect-src 'self' https: wss:; " +
          "frame-src https://accounts.google.com; " +
          "object-src 'none'; base-uri 'self'; frame-ancestors 'none'"
        );
      }
      if (filePath.endsWith('.apk')) {
        res.setHeader('Content-Type', 'application/vnd.android.package-archive');
        res.setHeader('Cache-Control', 'public, max-age=86400');
      } else if (filePath.endsWith('.zip')) {
        res.setHeader('Content-Type', 'application/zip');
        res.setHeader('Cache-Control', 'public, max-age=86400');
      } else if (filePath.endsWith('.html')) {
        res.setHeader('Cache-Control', 'no-cache');
      } else {
        res.setHeader('Cache-Control', 'public, max-age=3600');
      }
    }
  })
);

app.use((req, res) => {
  if (req.path.startsWith('/indir/')) return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Dosya bulunamadi' } });
  res.status(404).sendFile(path.join(SITE_DIR, 'index.html'), (error) => {
    if (error) res.status(404).end();
  });
});

app.listen(PORT, '0.0.0.0', () => console.log(`Alevi gateway listening on 0.0.0.0:${PORT}`));
