// Alevi YAN SUNUCU baslatici. Kullanim: klasorde `node index.js`.
// migration + api acar. API ice kapali kalir; disariya yalnizca mesh (25763)
// ve ana sunucuya giden nabiz vardir.
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

function exists(file) {
  try {
    return fs.existsSync(file);
  } catch {
    return false;
  }
}

for (const shared of ['config', 'contracts']) {
  const dir = path.join(ROOT, 'packages', shared);
  if (!exists(path.join(dir, 'node_modules', 'zod', 'package.json'))) {
    console.log(`[kurulum] bagimliliklar kuruluyor (${shared})...`);
    const installed = spawnSync('npm', ['install', '--omit=dev', '--no-audit', '--no-fund'], {
      cwd: dir,
      env: process.env,
      stdio: 'inherit',
      shell: process.platform === 'win32'
    });
    if (installed.status !== 0) {
      console.error('[hata] bagimlilik kurulumu basarisiz. Sunucuda Node.js ile gelen npm kurulu olmali.');
      process.exit(1);
    }
  }
}

if (!exists(path.join(ROOT, 'services/api', 'node_modules', 'zod', 'package.json'))) {
  console.log('[kurulum] bagimliliklar kuruluyor (api)...');
  const installed = spawnSync('npm', ['ci', '--omit=dev', '--no-audit', '--no-fund'], {
    cwd: path.join(ROOT, 'services/api'),
    env: process.env,
    stdio: 'inherit',
    shell: process.platform === 'win32'
  });
  if (installed.status !== 0) {
    console.error('[hata] bagimlilik kurulumu basarisiz. Sunucuda Node.js ile gelen npm kurulu olmali.');
    process.exit(1);
  }
}

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

const child = spawn(process.execPath, ['dist/src/server.js'], {
  cwd: path.join(ROOT, 'services/api'),
  env: process.env,
  stdio: 'inherit'
});
child.on('exit', (code) => process.exit(code ?? 1));
process.on('SIGINT', () => child.kill('SIGTERM'));
process.on('SIGTERM', () => child.kill('SIGTERM'));
console.log('[ok] yan sunucu api basladi — kapatmak icin Ctrl+C');
