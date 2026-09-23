// Alevi tek-port gateway (saf Node.js + express).
// Disaridan acik tek port: 25577. Host adina gore dagitir:
//   sonalis.com.tr (+www)      -> /srv/site statik dosya (+ /indir/*.apk)
//   api.sonalis.com.tr         -> api:3000
//   yonetim.sonalis.com.tr     -> admin:3000
// TLS, onundeki Cloudflare proxy'den gelir; burada duz HTTP konusulur.
const express = require('express');
const path = require('path');

const PORT = Number(process.env.PORT || 25577);
const SITE_DIR = process.env.SITE_DIR || '/srv/site';
const API_UPSTREAM = (process.env.API_UPSTREAM || 'http://api:3000').replace(/\/$/, '');
const ADMIN_UPSTREAM = (process.env.ADMIN_UPSTREAM || 'http://admin:3000').replace(/\/$/, '');

const app = express();
app.disable('x-powered-by');
app.set('trust proxy', true);

app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
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
      const lower = key.toLowerCase();
      if (['transfer-encoding', 'connection', 'content-encoding', 'content-length'].includes(lower)) return;
      res.setHeader(key, value);
    });
    if (upstreamRes.body) {
      for await (const chunk of upstreamRes.body) {
        if (!res.write(chunk)) await new Promise((resolve) => res.once('drain', resolve));
      }
    }
    res.end();
  } catch {
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
      if (filePath.endsWith('.apk')) res.setHeader('Content-Type', 'application/vnd.android.package-archive');
      if (filePath.endsWith('.html')) res.setHeader('Cache-Control', 'no-cache');
    }
  })
);

app.use((req, res) => {
  res.status(404).sendFile(path.join(SITE_DIR, 'index.html'), (error) => {
    if (error) res.status(404).end();
  });
});

app.listen(PORT, '0.0.0.0', () => console.log(`Alevi gateway listening on 0.0.0.0:${PORT}`));
