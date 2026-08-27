-- Mevcut veritabanını güvenli kategori ve ürün CRUD yapısına yükseltir.

ALTER TABLE menu_categories
    DROP CONSTRAINT IF EXISTS menu_categories_unique;

CREATE UNIQUE INDEX IF NOT EXISTS
    menu_categories_restaurant_name_ci_unique
ON menu_categories (restaurant_id, lower(name));

ALTER TABLE menu_items
    ADD COLUMN IF NOT EXISTS sort_order INTEGER NOT NULL DEFAULT 0;

CREATE INDEX IF NOT EXISTS
    idx_menu_items_category_sort
ON menu_items (category_id, sort_order);