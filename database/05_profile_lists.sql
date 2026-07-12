-- =====================================================================
-- Profildeki liste alanlarının normalize edilmiş hâli.
-- Flutter tarafında UserProfile içinde List<String> olarak tutulan
-- (dietPreferences, allergies, pastOrders, favoriteRestaurants,
-- eatListRestaurants, comments) alanların her biri, tekrarlı satırlara
-- izin veren ayrı bir tabloya karşılık gelir.
-- =====================================================================

-- Diyet tercihleri (Vegan, gluten free, laktoz free vb.)
CREATE TABLE IF NOT EXISTS diet_preferences (
    id       BIGSERIAL PRIMARY KEY,
    user_id  UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    label    VARCHAR(64) NOT NULL,

    CONSTRAINT diet_preferences_unique UNIQUE (user_id, label)
);

-- Alerjiler (Fıstık, çilek vb.)
CREATE TABLE IF NOT EXISTS allergies (
    id       BIGSERIAL PRIMARY KEY,
    user_id  UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    label    VARCHAR(64) NOT NULL,

    CONSTRAINT allergies_unique UNIQUE (user_id, label)
);

-- Geçmiş siparişler (salt okunur; ileride sipariş modülünden beslenecek)
CREATE TABLE IF NOT EXISTS past_orders (
    id           BIGSERIAL PRIMARY KEY,
    user_id      UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    description  VARCHAR(255) NOT NULL,
    ordered_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- "Favorilerim" kutucuğu
CREATE TABLE IF NOT EXISTS favorite_restaurants (
    id             BIGSERIAL PRIMARY KEY,
    user_id        UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    restaurant_id  UUID NOT NULL REFERENCES restaurants (id) ON DELETE CASCADE,
    added_at       TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT favorite_restaurants_unique UNIQUE (user_id, restaurant_id)
);

-- "EatList" kutucuğu (gitmek istedikleri)
CREATE TABLE IF NOT EXISTS eat_list_restaurants (
    id             BIGSERIAL PRIMARY KEY,
    user_id        UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    restaurant_id  UUID NOT NULL REFERENCES restaurants (id) ON DELETE CASCADE,
    added_at       TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT eat_list_restaurants_unique UNIQUE (user_id, restaurant_id)
);

-- Kullanıcının yaptığı yorumlar (salt okunur; ileride restoran yorumu
-- modülüne bağlanabilir, bu yüzden restaurant_id opsiyoneldir)
CREATE TABLE IF NOT EXISTS comments (
    id             BIGSERIAL PRIMARY KEY,
    user_id        UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    restaurant_id  UUID REFERENCES restaurants (id) ON DELETE SET NULL,
    body           VARCHAR(500) NOT NULL,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_diet_preferences_user ON diet_preferences (user_id);
CREATE INDEX IF NOT EXISTS idx_allergies_user         ON allergies (user_id);
CREATE INDEX IF NOT EXISTS idx_past_orders_user       ON past_orders (user_id);
CREATE INDEX IF NOT EXISTS idx_favorite_restaurants_user ON favorite_restaurants (user_id);
CREATE INDEX IF NOT EXISTS idx_eat_list_restaurants_user ON eat_list_restaurants (user_id);
CREATE INDEX IF NOT EXISTS idx_comments_user          ON comments (user_id);
