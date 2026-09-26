-- Harita gorunurligu (kisisel konum) ve etkinlik koordinatlari
ALTER TABLE "users" ADD COLUMN "show_map_location" BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE "events" ADD COLUMN "latitude" DOUBLE PRECISION;
ALTER TABLE "events" ADD COLUMN "longitude" DOUBLE PRECISION;

CREATE INDEX "events_latitude_longitude_idx" ON "events" ("latitude", "longitude");
CREATE INDEX "users_show_map_location_idx" ON "users" ("show_map_location");
