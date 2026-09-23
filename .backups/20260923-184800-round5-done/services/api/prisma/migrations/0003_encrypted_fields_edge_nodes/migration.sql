-- Sifreli alanlar TEXT'e cevrilir (sifre cozumu uygulama katmaninda)
ALTER TABLE "messages" ALTER COLUMN "body" TYPE TEXT;
ALTER TABLE "community_posts" ALTER COLUMN "body" TYPE TEXT;
ALTER TABLE "reports" ALTER COLUMN "details" TYPE TEXT;

-- CreateTable
CREATE TABLE "edge_nodes" (
    "id" UUID NOT NULL,
    "name" VARCHAR(80) NOT NULL,
    "mesh_host" VARCHAR(255) NOT NULL,
    "mesh_port" INTEGER NOT NULL,
    "token_hash" VARCHAR(128) NOT NULL,
    "status" VARCHAR(16) NOT NULL DEFAULT 'pending',
    "last_seen_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "edge_nodes_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "edge_nodes_status_last_seen_at_idx" ON "edge_nodes"("status", "last_seen_at");
