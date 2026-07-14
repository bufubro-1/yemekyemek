-- =====================================================================
-- Yönetici rolü
--
-- Yönetici parolası burada seed edilmez. SQL, çalışma zamanı ortam
-- değişkenindeki parolayı güvenli biçimde bcrypt ile hash edemez. Backend
-- başlangıcındaki seedAdmin servisi ADMIN_* değişkenlerini kullanarak
-- bcrypt hash üretir ve kullanıcıyı idempotent olarak upsert eder.
-- =====================================================================

ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'admin';
