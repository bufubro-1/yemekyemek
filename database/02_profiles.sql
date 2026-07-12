-- =====================================================================
-- profiles
-- Flutter tarafındaki UserProfile modelinin taban alanları
-- (bkz. yemekyemek_arayuz/lib/models/user_profile.dart)
--
-- NOT: Görünen isim (username) ve nickname 'users' tablosunda tutulur;
-- bu tablo yalnızca profile özgü verileri (bio, sayaçlar, rozet) içerir.
-- Liste alanları (diyet, alerji, favoriler vb.) 03_profile_lists.sql'de
-- ayrı ilişkisel tablolara normalize edilmiştir.
-- =====================================================================

CREATE TABLE IF NOT EXISTS profiles (
    user_id           UUID PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,

    avatar_path       TEXT,

    -- UserProfile.bioMaxLength (150) UI tarafında da uygulanır; burada da
    -- CHECK ile veritabanı seviyesinde garanti edilir.
    bio               VARCHAR(150) NOT NULL DEFAULT '',

    followers_count   INTEGER NOT NULL DEFAULT 0 CHECK (followers_count >= 0),
    following_count   INTEGER NOT NULL DEFAULT 0 CHECK (following_count >= 0),

    -- Örn: "Yeni Üye", "Gurme" (bkz. RatingBadge widget'ı)
    rating_badge      VARCHAR(32) NOT NULL DEFAULT 'Yeni Üye'
);
