// Alevi YAN SUNUCU baslatici. Kullanim: klasorde `node index.js`.
// migration + api acar. API ice kapali kalir; disariya yalnizca mesh (25763)
// ve ana sunucuya giden nabiz vardir.
const { spawn, spawnSync } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');

const ROOT = __dirname;

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

const REQUIRED_KEYS = [
  ['DATABASE_URL', 'Supabase/Neon Postgres connection string'],
  ['JWT_ACCESS_SECRET', 'ana sunucuyla AYNI deger olmali'],
  ['JWT_REFRESH_SECRET', 'ana sunucuyla AYNI deger olmali'],
  ['SENSITIVE_DATA_KEY', 'ana sunucuyla AYNI deger olmali'],
  ['EDGE_UPLINK_URL', 'ornek: http://127.0.0.1:25577'],
  ['EDGE_JOIN_TOKEN', 'yonetim panelindeki katilim anahtari']
];
let missing = false;
for (const [key, hint] of REQUIRED_KEYS) {
  const value = (process.env[key] || '').trim();
  if (!value || value.includes('BURAYA')) {
    console.error(`[hata] .env eksik: ${key} (${hint})`);
    missing = true;
  }
}
if (missing) process.exit(1);

process.env.NODE_ENV = 'production';
if (!process.env.PORT) process.env.PORT = '3000';

function exists(file) {
  try {
    return fs.existsSync(file);
  } catch {
    return false;
  }
}

function ensureDeps(label, dir, lock, sentinel) {
  let installed = false;
  try {
    require.resolve(sentinel, { paths: [dir] });
    installed = true;
  } catch {
    installed = exists(path.join(dir, 'node_modules', sentinel, 'package.json'));
  }
  if (installed) return;
  console.log(`[kurulum] bagimliliklar kuruluyor (${label})...`);
  const args = lock
    ? ['ci', '--omit=dev', '--no-audit', '--no-fund']
    : ['install', '--omit=dev', '--no-audit', '--no-fund'];
  let result;
  try {
    result = spawnSync('npm', args, { cwd: dir, env: process.env, stdio: 'inherit', shell: process.platform === 'win32' });
  } catch {
    console.error(`[hata] npm calistirilamadi (${label}): npm bulunamadi.`);
    process.exit(1);
  }
  if (!result || result.error || result.status !== 0) {
    console.error(`[hata] bagimlilik kurulumu basarisiz (${label}).`);
    process.exit(1);
  }
}

ensureDeps('config', path.join(ROOT, 'packages/config'), false, 'zod');
ensureDeps('contracts', path.join(ROOT, 'packages/contracts'), false, 'zod');
ensureDeps('api', path.join(ROOT, 'services/api'), true, 'zod');

console.log('[kurulum] veritabani migration calistiriliyor...');
const migrate = spawnSync(
  process.execPath,
  ['node_modules/prisma/build/index.js', 'migrate', 'deploy', '--schema', 'prisma/schema.prisma'],
  { cwd: path.join(ROOT, 'services/api'), env: process.env, stdio: 'inherit' }
);
if (migrate.status !== 0) {
  console.error('[hata] migration basarisiz. DATABASE_URL degerini kontrol edin.');
  console.error('[ipucu] Yari kalmis migration varsa: node_modules/prisma/build/index.js migrate resolve --applied "<ad>"');
  process.exit(1);
}

const child = spawn(process.execPath, ['dist/src/server.js'], {
  cwd: path.join(ROOT, 'services/api'),
  env: process.env,
  stdio: 'inherit'
});
child.on('exit', (code) => process.exit(code ?? 1));
process.on('SIGINT', () => child.kill('SIGTERM'));
process.on('SIGTERM', () => child.kill('SIGTERM'));
console.log('[ok] yan sunucu api basladi — kapatmak icin Ctrl+C');
