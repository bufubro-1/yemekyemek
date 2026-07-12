-- Tüm şemayı doğru sırada kurmak için tek giriş noktası.
-- Çalıştırmak için:
--   psql "postgresql://kullanici:sifre@localhost:5432/yemekyemek" -f schema.sql
--
-- \ir (relative include) kullanıldığı için bu dosyanın bulunduğu klasörden
-- çalıştırılması gerekmez; psql script'in kendi konumuna göre include eder.

\ir 00_extensions.sql
\ir 01_users.sql
\ir 02_profiles.sql
\ir 03_restaurants.sql
\ir 04_menu.sql
\ir 05_profile_lists.sql
\ir 06_follows.sql
