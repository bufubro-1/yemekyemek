-- =====================================================================
-- users
-- Flutter tarafındaki AppUser modelinin karşılığı
-- (bkz. yemekyemek_arayuz/lib/models/app_user.dart)
-- =====================================================================

CREATE TYPE user_role AS ENUM ('user', 'restaurant_owner');

CREATE TABLE IF NOT EXISTS users (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Eşsizdir, profilde "@nickname" olarak gösterilir; ID sisteminin
    -- yerini alır (AppUser.nickname).
    nickname       VARCHAR(32)  NOT NULL,

    -- Görünen isim; eşsiz OLMAK ZORUNDA DEĞİL (AppUser.username).
    username       VARCHAR(64)  NOT NULL,

    email          VARCHAR(255) NOT NULL,

    -- Şifrenin kendisi değil, hash'i (bkz. PasswordHasher / SHA-256).
    -- Production'da bcrypt/argon2 gibi salt'lı bir algoritmaya geçilmesi
    -- önerilir.
    password_hash  VARCHAR(255) NOT NULL,

    -- Kayıt sırasında seçilen hesap türü; giriş sonrası hangi ana ekrana
    -- (kullanıcı ana sayfası / restoran paneli) yönlendirileceğini belirler.
    role           user_role    NOT NULL DEFAULT 'user',

    created_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT users_email_unique    UNIQUE (email),
    CONSTRAINT users_nickname_unique UNIQUE (nickname)
);

CREATE INDEX IF NOT EXISTS idx_users_email    ON users (email);
CREATE INDEX IF NOT EXISTS idx_users_nickname ON users (nickname);
