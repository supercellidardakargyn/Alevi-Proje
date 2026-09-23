# Alevi Admin

Next.js + React + TypeScript ile hazırlanmış düşük bağımlılıklı operasyon paneli iskeletidir.

## Geliştirme

```powershell
cd apps/admin
npm install
npm run dev
```

`NEXT_PUBLIC_ADMIN_API_URL` varsayılan olarak `/v1/admin` değerini kullanır. Panel, yönetici oturumunu Secure/HttpOnly çerez üzerinden API'ye bırakır; access token'ı localStorage veya sessionStorage'a yazmaz.

## Beklenen API

- `GET /v1/admin/overview`
- `GET /v1/admin/mesh/health`
- `POST /v1/admin/users/:id/suspend`
- `POST /v1/admin/reports/:id/resolve`

Gerçek yetkilendirme, MFA, CSRF, RBAC, rate limit ve audit kontrolü sunucuda uygulanmalıdır. UI'da bir öğeyi gizlemek güvenlik kontrolü değildir.
