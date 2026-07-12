-- =====================================================================
-- restaurants
-- Restoran paneli tarafında girilen bilgiler.
-- Flutter tarafındaki Restaurant modelinin karşılığı
-- (bkz. yemekyemek_arayuz/lib/models/restaurant.dart,
--       yemekyemek_arayuz/lib/screens/restaurant/restaurant_form_screen.dart)
-- =====================================================================

CREATE TABLE IF NOT EXISTS restaurants (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Restoranı yöneten kullanıcı; role = 'restaurant_owner' olmalıdır.
    -- Şu anki UI tek kullanıcı = tek restoran varsayımıyla çalışır (UNIQUE).
    owner_id     UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,

    name         VARCHAR(120) NOT NULL,
    description  TEXT NOT NULL DEFAULT '',

    -- Normalize edilmiş Türkiye telefon formatı: +90XXXXXXXXXX
    -- (bkz. RestaurantFormScreen._normalizeTurkishPhone)
    phone        VARCHAR(20)  NOT NULL,

    address      VARCHAR(500) NOT NULL,

    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT restaurants_owner_unique UNIQUE (owner_id)
);

CREATE INDEX IF NOT EXISTS idx_restaurants_owner ON restaurants (owner_id);
