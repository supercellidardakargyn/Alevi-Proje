-- Davet zinciri + ilgi etiketleri (farklilasma: referansli guven + ilgi eslesmesi)
ALTER TABLE "users" ADD COLUMN "interests" TEXT[] NOT NULL DEFAULT '{}';
ALTER TABLE "users" ADD COLUMN "invite_code" VARCHAR(12) NOT NULL DEFAULT substr(md5(random()::text), 1, 8);
ALTER TABLE "users" ADD COLUMN "invited_by" UUID;

-- CreateIndex
CREATE UNIQUE INDEX "users_invite_code_key" ON "users"("invite_code");
CREATE INDEX "users_invited_by_idx" ON "users"("invited_by");

-- AddForeignKey
ALTER TABLE "users" ADD CONSTRAINT "users_invited_by_fkey" FOREIGN KEY ("invited_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
