-- =====================================================================
-- menu_categories / menu_items
-- Restoran menü yönetimi.
-- Flutter tarafındaki Restaurant.menuCategories (kategori adı listesi)
-- karşılığıdır (bkz. yemekyemek_arayuz/lib/screens/restaurant/restaurant_menu_screen.dart).
--
-- NOT: Şu anki UI'da yalnızca kategori seviyesi var (ürünler "Henüz ürün
-- yok" placeholder'ı gösteriyor); menu_items tablosu ileride ürün ekleme
-- özelliği geldiğinde kullanılmak üzere şimdiden hazırlanmıştır.
-- =====================================================================

CREATE TABLE IF NOT EXISTS menu_categories (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    restaurant_id  UUID NOT NULL REFERENCES restaurants (id) ON DELETE CASCADE,
    name           VARCHAR(80) NOT NULL,
    sort_order     INTEGER NOT NULL DEFAULT 0,

    -- Kategori adı case-insensitive eşsiz olmalı (bkz. MenuScreen'deki
    -- "Bu kategori zaten bulunuyor." validasyonu).
    CONSTRAINT menu_categories_unique UNIQUE (restaurant_id, name)
);

CREATE TABLE IF NOT EXISTS menu_items (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id   UUID NOT NULL REFERENCES menu_categories (id) ON DELETE CASCADE,
    name          VARCHAR(120) NOT NULL,
    description   TEXT NOT NULL DEFAULT '',
    price         NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
    is_available  BOOLEAN NOT NULL DEFAULT true,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_menu_categories_restaurant ON menu_categories (restaurant_id);
CREATE INDEX IF NOT EXISTS idx_menu_items_category        ON menu_items (category_id);
