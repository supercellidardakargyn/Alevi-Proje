async function main() {
  const res = await fetch('https://api.canmeydani.com.tr/v1/auth/google', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ idToken: 'x'.repeat(64), consentVersion: 'kvkk-v1', ageConfirmed: true }),
    signal: AbortSignal.timeout(20000)
  });
  console.log('status:', res.status);
  console.log((await res.text()).slice(0, 300));
}
main().catch((e) => { console.error('HATA:', e.message); process.exit(1); });
