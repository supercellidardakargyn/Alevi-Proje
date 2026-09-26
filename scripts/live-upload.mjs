async function main() {
  const bytes = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82]);
  const form = new FormData();
  form.append('avatar', new Blob([bytes], { type: 'image/png' }), 'test.png');
  const started = Date.now();
  const res = await fetch('https://api.canmeydani.com.tr/v1/profile/avatar', { method: 'POST', body: form, signal: AbortSignal.timeout(30000) });
  console.log('status:', res.status, 'sure:', ((Date.now() - started) / 1000).toFixed(1) + 's');
  console.log((await res.text()).slice(0, 300));
}
main().catch((e) => { console.error('HATA:', e.message); process.exit(1); });
