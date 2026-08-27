-- =====================================================================
-- menu_categories / menu_items
-- Restoran kategori ve ürün yönetimi.
-- =====================================================================

CREATE TABLE IF NOT EXISTS menu_categories (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    restaurant_id  UUID NOT NULL REFERENCES restaurants (id) ON DELETE CASCADE,
    name           VARCHAR(80) NOT NULL,
    sort_order     INTEGER NOT NULL DEFAULT 0
);

-- Aynı restoranda "Tatlılar" ve "tatlılar" ayrı kategori olamaz.
CREATE UNIQUE INDEX IF NOT EXISTS
    menu_categories_restaurant_name_ci_unique
ON menu_categories (restaurant_id, lower(name));

CREATE TABLE IF NOT EXISTS menu_items (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id   UUID NOT NULL REFERENCES menu_categories (id) ON DELETE CASCADE,
    name          VARCHAR(120) NOT NULL,
    description   TEXT NOT NULL DEFAULT '',
    price         NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
    is_available  BOOLEAN NOT NULL DEFAULT true,
    sort_order    INTEGER NOT NULL DEFAULT 0,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS
    idx_menu_categories_restaurant
ON menu_categories (restaurant_id);

CREATE INDEX IF NOT EXISTS
    idx_menu_items_category
ON menu_items (category_id);

CREATE INDEX IF NOT EXISTS
    idx_menu_items_category_sort
ON menu_items (category_id, sort_order);