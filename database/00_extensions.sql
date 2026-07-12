-- Gerekli PostgreSQL extension'ları.
-- uuid_generate_v4() / gen_random_uuid() ile sunucu tarafında eşsiz id üretimi için.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";
