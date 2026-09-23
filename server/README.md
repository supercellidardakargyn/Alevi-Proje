# Alevi standalone server (demo/prototip — kanonik yol değil)

> Üretimde kanonik API `services/api` (Express + PostgreSQL + Redis) kullanılır.
> Bu klasör zero-dependency demo/prototiptir; yeni feature, auth değişikliği veya
> güvenlik düzeltmesi buraya değil `services/api` + `packages/contracts` içine yapılır.

Bu klasör Node.js 22 ile ek paket gerektirmeden çalışır.

```bash
cp .env.example .env
node index.js
```

Health endpointleri:

- `GET /health/live`
- `GET /health/ready`
- `GET /health/mesh`

Demo web istemcisi:

- `GET /app` — kayıt/giriş, keşfet, aktif kullanıcılar, topluluk akışı, mesajlar (`server/public/app.html`)
- Tarayıcıda `http://127.0.0.1:3000/app` aç, kayıt ol, tüm akışı tek sayfadan kullan.

İki node için ortak veritabanı olmadan yalnızca bir node yazma primary olarak kullanılmalıdır. Diğer node standby/edge rolünde heartbeat peer durumunu izler. Gerçek active-active yazma için PostgreSQL + Redis/managed HA gerekir; SQLite dosyasını iki makine arasında kopyalamayın.

Güvenlik: production'da `JWT_ACCESS_SECRET`, `MESH_JOIN_SECRET` ve `SENSITIVE_DATA_KEY` secret manager/environment üzerinden verilmeli; `.env` veya `data/alevi.sqlite.json` commit edilmemelidir. HTTPS reverse proxy arkasında yayınlayın.
