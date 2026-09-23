// Alevi ANA SUNUCU baslatici. Kullanim: klasorde `node index.js`.
// migration + api(3000) + admin(3001) + gateway(25577) sirayla acar.
const { spawn, spawnSync } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');

const ROOT = __dirname;

function loadEnv(file) {
  if (!fs.existsSync(file)) {
    console.error(`[hata] .env bulunamadi: ${file}`);
    process.exit(1);
  }
  for (const line of fs.readFileSync(file, 'utf8').split('\n')) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const index = trimmed.indexOf('=');
    if (index === -1) continue;
    const key = trimmed.slice(0, index).trim();
    const value = trimmed.slice(index + 1).trim();
    if (!(key in process.env)) process.env[key] = value;
  }
}

loadEnv(path.join(ROOT, '.env'));

if (!process.env.DATABASE_URL || process.env.DATABASE_URL.includes('BURAYA')) {
  console.error('[hata] .env icindeki DATABASE_URL doldurulmamis.');
  console.error('Supabase/Neon ucretsiz Postgres acip connection stringi .env dosyasina yazin.');
  process.exit(1);
}

process.env.NODE_ENV = 'production';
if (!process.env.PORT) process.env.PORT = '3000';

const children = [];
function run(name, command, args, options) {
  const child = spawn(command, args, { stdio: ['ignore', 'pipe', 'pipe'], ...options });
  children.push(child);
  child.stdout.on('data', (data) => process.stdout.write(`[${name}] ${data}`));
  child.stderr.on('data', (data) => process.stderr.write(`[${name}] ${data}`));
  child.on('exit', (code) => {
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
  const sentinel = path.join(dir, 'node_modules', opts.sentinel, 'package.json');
  if (exists(sentinel)) return;
  console.log(`[kurulum] bagimliliklar kuruluyor (${label})...`);
  const args = opts.lock
    ? ['ci', '--omit=dev', '--no-audit', '--no-fund']
    : ['install', '--omit=dev', '--no-audit', '--no-fund'];
  const result = spawnSync('npm', args, { cwd: dir, env: process.env, stdio: 'inherit', shell: process.platform === 'win32' });
  if (result.status !== 0) {
    console.error(`[hata] bagimlilik kurulumu basarisiz (${label}). Sunucuda Node.js ile gelen npm kurulu olmali.`);
    process.exit(1);
  }
}

// 0) Bagimliliklar (sunucular Linux oldugu icin burada kurulur)
// file: baglantilar symlink oldugundan paylasilan paketlerin de kendi
// node_modules'u olmali (zod), yoksa API `Cannot find module` ile coker.
ensureDeps('config', path.join(ROOT, 'packages/config'), { lock: false, sentinel: 'zod' });
ensureDeps('contracts', path.join(ROOT, 'packages/contracts'), { lock: false, sentinel: 'zod' });
ensureDeps('api', path.join(ROOT, 'services/api'), { lock: true, sentinel: 'zod' });
ensureDeps('gateway', path.join(ROOT, 'services/gateway'), { lock: true, sentinel: 'express' });
ensureDeps('admin', path.join(ROOT, 'admin-standalone'), { lock: false, sentinel: 'next' });

// 1) Veritabani semasi
console.log('[kurulum] veritabani migration calistiriliyor...');
const migrate = spawnSync(
  process.execPath,
  ['node_modules/prisma/build/index.js', 'migrate', 'deploy', '--schema', 'prisma/schema.prisma'],
  { cwd: path.join(ROOT, 'services/api'), env: process.env, stdio: 'inherit' }
);
if (migrate.status !== 0) {
  console.error('[hata] migration basarisiz. DATABASE_URL degerini kontrol edin.');
  process.exit(1);
}

// 2) API
run('api', process.execPath, ['dist/src/server.js'], {
  cwd: path.join(ROOT, 'services/api'),
  env: process.env
});

// 3) Admin paneli (standalone)
run('admin', process.execPath, ['server.js'], {
  cwd: path.join(ROOT, 'admin-standalone'),
  env: { ...process.env, PORT: '3001' }
});

// 4) Gateway (dis port .env'deki GATEWAY_PORT, varsayilan 25577)
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

console.log('[ok] api=:3000 admin=:3001 gateway=:25577 — kapatmak icin Ctrl+C');
