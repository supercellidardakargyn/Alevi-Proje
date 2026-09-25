-- Kullanici foto galerisi (en fazla 6, uygulama katmaninda sinirlanir)
ALTER TABLE "users" ADD COLUMN "photos" TEXT[] NOT NULL DEFAULT '{}';
