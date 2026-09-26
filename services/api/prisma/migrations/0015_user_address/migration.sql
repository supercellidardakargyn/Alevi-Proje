-- Kullanici acik adresi (ozel alan: asla herkese acik profilde donulmez)
ALTER TABLE "users" ADD COLUMN "address" VARCHAR(500);
