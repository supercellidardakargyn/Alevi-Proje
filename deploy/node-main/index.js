// Alevi ANA SUNUCU baslatici. Kullanim: klasorde `node index.js`.
// migration + api(3000) + admin(3001) + gateway(25577) sirayla acar.
const { spawn, spawnSync } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');

const ROOT = __dirname;

// Node 18 alti fetch/AbortSignal.timeout/duplex destegi olmadigindan acilmaz.
const nodeMajor = Number(process.versions.node.split('.')[0] || 0);
if (!Number.isInteger(nodeMajor) || nodeMajor < 20) {
  console.error(`[hata] Node.js 20+ gerekli, bulunan: ${process.versions.node}.`);
  process.exit(1);
}

function loadEnv(file) {
  if (!fs.existsSync(file)) {
    console.error(`[hata] .env bulunamadi: ${file}`);
    process.exit(1);
  }
  for (const rawLine of fs.readFileSync(file, 'utf8').split('\n')) {
    const line = rawLine.replace(/\r$/, '');
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const cleaned = trimmed.startsWith('export ') ? trimmed.slice(7).trim() : trimmed;
    const index = cleaned.indexOf('=');
    if (index === -1) continue;
    const key = cleaned.slice(0, index).trim();
    let value = cleaned.slice(index + 1).trim();
    // Tirnakli degerler + satir ici yorumlar temizlenir.
    if ((value.startsWith('"') && value.endsWith('"') && value.length >= 2) ||
        (value.startsWith("'") && value.endsWith("'") && value.length >= 2)) {
      value = value.slice(1, -1);
    } else {
      const hashIndex = value.indexOf(' #');
      if (hashIndex !== -1) value = value.slice(0, hashIndex).trim();
    }
    if (!(key in process.env)) process.env[key] = value;
  }
}

loadEnv(path.join(ROOT, '.env'));

function readEnvFileValue(key) {
  try {
    for (const rawLine of fs.readFileSync(path.join(ROOT, '.env'), 'utf8').split('\n')) {
      const line = rawLine.replace(/\r$/, '').trim();
      if (!line || line.startsWith('#')) continue;
      const index = line.indexOf('=');
      if (index === -1) continue;
      if (line.slice(0, index).trim() === key) return line.slice(index + 1).trim();
    }
  } catch {
    // .env okunamazsa ortam degiskeniyle devam edilir.
  }
  return undefined;
}

function isAutoUpdateEnabled() {
  // Panel degiskeni .env'i ezebilir; ikisinden biri aciksa acik sayilir.
  const values = [process.env.AUTO_UPDATE, readEnvFileValue('AUTO_UPDATE')];
  return values.some((value) => {
    const normalized = String(value ?? '').trim().toLowerCase();
    return normalized === '1' || normalized === 'true' || normalized === 'yes' || normalized === 'on';
  });
}

const REQUIRED_KEYS = [
  ['DATABASE_URL', 'Supabase/Neon Postgres connection string'],
  ['JWT_ACCESS_SECRET', 'openssl rand -hex 32'],
  ['JWT_REFRESH_SECRET', 'openssl rand -hex 32 (farkli deger)'],
  ['SENSITIVE_DATA_KEY', 'openssl rand -hex 32 (64 hex karakter)'],
  ['SMTP_HOST', 'ornek: smtp.resend.com'],
  ['SMTP_USER', 'Resend icin: resend'],
  ['SMTP_PASS', 'Resend API anahtari'],
  ['GOOGLE_CLIENT_ID', 'Google Cloud Web OAuth istemcisi']
];
let missing = false;
for (const [key, hint] of REQUIRED_KEYS) {
  const value = (process.env[key] || '').trim();
  if (!value || value.includes('BURAYA') || value.includes('ORNEK')) {
    console.error(`[hata] .env eksik: ${key} (${hint})`);
    missing = true;
  }
}
if (missing) process.exit(1);

process.env.NODE_ENV = 'production';
if (!process.env.PORT) process.env.PORT = '3000';

const children = [];
let updating = false;
function run(name, command, args, options) {
  const child = spawn(command, args, { stdio: ['ignore', 'pipe', 'pipe'], ...options });
  children.push(child);
  child.stdout.on('data', (data) => process.stdout.write(`[${name}] ${data}`));
  child.stderr.on('data', (data) => process.stderr.write(`[${name}] ${data}`));
  child.on('exit', (code) => {
    if (updating) return;
    console.error(`[${name}] cikti (kod ${code}). Kapatiliyor...`);
    shutdown(1);
  });
  return child;
}

function shutdown(code) {
  for (const child of children) {
    try {
      child.kill('SIGTERM');
    } catch {
      // Zaten kapanmis olabilir.
    }
  }
  setTimeout(() => process.exit(code), 3000).unref();
}
process.on('SIGINT', () => shutdown(0));
process.on('SIGTERM', () => shutdown(0));

function exists(file) {
  try {
    return fs.existsSync(file);
  } catch {
    return false;
  }
}

function ensureDeps(label, dir, opts) {
  let installed = false;
  try {
    require.resolve(opts.sentinel, { paths: [dir] });
    installed = true;
  } catch {
    installed = exists(path.join(dir, 'node_modules', opts.sentinel, 'package.json'));
  }
  if (installed) return;
  console.log(`[kurulum] bagimliliklar kuruluyor (${label})...`);
  const args = opts.lock
    ? ['ci', '--omit=dev', '--no-audit', '--no-fund']
    : ['install', '--omit=dev', '--no-audit', '--no-fund'];
  let result;
  try {
    result = spawnSync('npm', args, { cwd: dir, env: process.env, stdio: 'inherit', shell: process.platform === 'win32' });
  } catch (error) {
    console.error(`[hata] npm calistirilamadi (${label}): npm bulunamadi. Node.js ile gelen npm kurulu olmali.`);
    process.exit(1);
  }
  if (!result || result.error || result.status !== 0) {
    if (result && result.error) console.error(`[hata] npm hatasi (${label}): ${result.error.message}`);
    console.error(`[hata] bagimlilik kurulumu basarisiz (${label}).`);
    process.exit(1);
  }
}

// 0) Bagimliliklar (sunucular Linux oldugu icin burada kurulur)
// file: baglantilar symlink oldugundan paylasilan paketlerin de kendi
// node_modules'u olmali (zod), yoksa API `Cannot find module` ile coker.
function installAllDeps() {
  ensureDeps('config', path.join(ROOT, 'packages/config'), { lock: false, sentinel: 'zod' });
  ensureDeps('contracts', path.join(ROOT, 'packages/contracts'), { lock: false, sentinel: 'zod' });
  ensureDeps('api', path.join(ROOT, 'services/api'), { lock: true, sentinel: 'zod' });
  ensureDeps('gateway', path.join(ROOT, 'services/gateway'), { lock: true, sentinel: 'express' });
  ensureDeps('admin', path.join(ROOT, 'admin-standalone'), { lock: false, sentinel: 'next' });
}
installAllDeps();

// 1) Veritabani semasi
function runMigrations() {
  console.log('[kurulum] veritabani migration calistiriliyor...');
  const migrate = spawnSync(
    process.execPath,
    ['node_modules/prisma/build/index.js', 'migrate', 'deploy', '--schema', 'prisma/schema.prisma'],
    { cwd: path.join(ROOT, 'services/api'), env: process.env, stdio: 'inherit' }
  );
  if (migrate.status !== 0) {
    console.error('[hata] migration basarisiz. DATABASE_URL degerini kontrol edin.');
    console.error('[ipucu] Yari kalmis migration varsa: services/api/node_modules/prisma/build/index.js migrate resolve --applied "<ad>"');
    process.exit(1);
  }
}
runMigrations();

// 2-4) Servisler
function bootChildren() {
  run('api', process.execPath, ['dist/src/server.js'], {
    cwd: path.join(ROOT, 'services/api'),
    env: process.env
  });
  run('admin', process.execPath, ['server.js'], {
    cwd: path.join(ROOT, 'admin-standalone'),
    env: { ...process.env, PORT: '3001' }
  });
  run('gateway', process.execPath, ['index.js'], {
    cwd: path.join(ROOT, 'services/gateway'),
    env: {
      ...process.env,
      PORT: process.env.GATEWAY_PORT || '25577',
      SITE_DIR: path.join(ROOT, 'site'),
      API_UPSTREAM: 'http://127.0.0.1:3000',
      ADMIN_UPSTREAM: 'http://127.0.0.1:3001'
    }
  });
}

function stopChildren() {
  for (const child of children.splice(0)) {
    try {
      child.kill('SIGTERM');
    } catch {
      // Zaten kapanmis olabilir.
    }
  }
}
bootChildren();

console.log(`[ok] api=:3000 admin=:3001 gateway=:${process.env.GATEWAY_PORT || '25577'} — kapatmak icin Ctrl+C`);
console.log('[not] tek komutla calisir; arka planda tutmak icin ornek: npm i -g pm2 && pm2 start index.js --name alevi');

// --- Otomatik guncelleme -------------------------------------------------
// AUTO_UPDATE=1 ise GitHub `latest` release 10 dakikada bir kontrol edilir.
// Yeni surum varsa indirilir, acilir, bagimliliklar tazelenir, migration
// calisir ve servisler ana process kapanmadan yeniden baslatilir.
// .env ve uploads/ korunur. Paneldeki sabit komut degismez.
const UPDATE_REPO = process.env.UPDATE_REPO || 'supercellidardakargyn/Alevi-Proje';
const UPDATE_ASSET = 'alevi-main.tar.gz';
const UPDATE_CHECK_MS = Number(process.env.UPDATE_CHECK_MS || 600_000);
const UPDATE_STATE_FILE = path.join(ROOT, '.update-state.json');

function readUpdateState() {
  try {
    return JSON.parse(fs.readFileSync(UPDATE_STATE_FILE, 'utf8'));
  } catch {
    return {};
  }
}

function writeUpdateState(state) {
  try {
    fs.writeFileSync(UPDATE_STATE_FILE, JSON.stringify(state), { mode: 0o600 });
  } catch {
    // Guncelleme durumu yazilamazsa bir sonraki tur tekrar dener.
  }
}

async function githubJson(url) {
  const response = await fetch(url, {
    headers: { 'user-agent': 'alevi-updater', accept: 'application/vnd.github+json' },
    signal: AbortSignal.timeout(20_000)
  });
  if (!response.ok) throw new Error(`GitHub yanıtı: ${response.status}`);
  return response.json();
}

async function checkForUpdate() {
  if (process.env.AUTO_UPDATE !== '1') return;
  try {
    const release = await githubJson(`https://api.github.com/repos/${UPDATE_REPO}/releases/tags/latest`);
    const state = readUpdateState();
    if (state.releaseId === release.id) return;
    const asset = (release.assets || []).find((entry) => entry.name === UPDATE_ASSET);
    if (!asset) {
      console.error('[guncelle] release bulundu ama paket yok, atlaniyor.');
      return;
    }
    console.log(`[guncelle] yeni surum: ${release.tag_name || release.id}, indiriliyor...`);
    await applyUpdate(asset);
    writeUpdateState({ releaseId: release.id, at: new Date().toISOString() });
    console.log('[guncelle] tamam, servisler yeni surumle baslatildi.');
  } catch (error) {
    console.error(`[guncelle] kontrol basarisiz, 10 dk sonra tekrar: ${(error && error.message) || error}`);
  }
}

async function applyUpdate(asset) {
  const tmpFile = path.join(ROOT, '.update-pending.tgz');
  const download = await fetch(asset.url, {
    headers: { 'user-agent': 'alevi-updater', accept: 'application/octet-stream' },
    signal: AbortSignal.timeout(120_000)
  });
  if (!download.ok || !download.body) throw new Error(`Indirme basarisiz: ${download.status}`);
  const file = fs.createWriteStream(tmpFile, { mode: 0o600 });
  await new Promise((resolve, reject) => {
    download.body.pipe(file);
    download.body.on('error', reject);
    file.on('finish', resolve);
    file.on('error', reject);
  });
  updating = true;
  stopChildren();
  await new Promise((resolve) => setTimeout(resolve, 2000));
  const extract = spawnSync('tar', ['-xzf', tmpFile, '-C', ROOT, '--strip-components=1'], { stdio: 'inherit' });
  fs.rmSync(tmpFile, { force: true });
  if (extract.status !== 0) {
    console.error('[guncelle] acma basarisiz, eski surumle devam icin yeniden baslatin.');
    updating = false;
    bootChildren();
    return;
  }
  // Bagimlilik degismis olabilir: kilit dosyasina gore taze kurulum.
  for (const dir of [
    path.join(ROOT, 'services/api/node_modules'),
    path.join(ROOT, 'services/gateway/node_modules'),
    path.join(ROOT, 'admin-standalone/node_modules'),
    path.join(ROOT, 'packages/config/node_modules'),
    path.join(ROOT, 'packages/contracts/node_modules')
  ]) {
    fs.rmSync(dir, { recursive: true, force: true });
  }
  installAllDeps();
  runMigrations();
  bootChildren();
  updating = false;
}

function startAutoUpdate() {
  if (!isAutoUpdateEnabled()) {
    console.log('[guncelle] kapali (acmak icin .env: AUTO_UPDATE=1)');
    return;
  }
  console.log(`[guncelle] acik: ${UPDATE_REPO} her 10 dakikada kontrol edilecek.`);
  const timer = setInterval(() => {
    void checkForUpdate();
  }, Number.isFinite(UPDATE_CHECK_MS) && UPDATE_CHECK_MS > 0 ? UPDATE_CHECK_MS : 600_000);
  timer.unref?.();
  setTimeout(() => {
    void checkForUpdate();
  }, 30_000).unref?.();
}

startAutoUpdate();
