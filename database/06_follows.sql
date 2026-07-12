-- =====================================================================
-- follows
-- Takipçi/takip ilişkisi.
-- Şu anki Flutter tarafında UserProfile sadece followersCount/
-- followingCount sayaçlarını tutuyor; bu tablo ileride gerçek bir
-- takip listesi gerektiğinde (ve sayaçların bu tablodan türetilmesi
-- gerektiğinde) kullanılmak üzere hazırlanmıştır.
-- =====================================================================

CREATE TABLE IF NOT EXISTS follows (
    follower_id  UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    followed_id  UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),

    PRIMARY KEY (follower_id, followed_id),
    CONSTRAINT follows_no_self_follow CHECK (follower_id <> followed_id)
);

CREATE INDEX IF NOT EXISTS idx_follows_followed ON follows (followed_id);
