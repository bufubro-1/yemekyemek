# YemekYemek Backend

Express, PostgreSQL, bcrypt, JWT ve Zod kullanan API.

## Kurulum

```bash
cp .env.example .env
npm install
npm start
```

Önce `database/schema.sql` çalıştırılmalıdır. `ADMIN_*` değişkenlerinin tamamı
tanımlanırsa backend her başlangıçta yönetici hesabını idempotent olarak hazırlar.
Parola uygulamada bcrypt ile hash edilir; düz metin parola veritabanına yazılmaz.

JWT erişim token'ları 7 gün geçerlidir. İstemci token'ı
`Authorization: Bearer <token>` başlığıyla gönderir.
Endpoint'ler `/api/v1` (Flutter) ve `/v1` (yönetim arayüzü) altında sunulur.

## Ana endpoint'ler

- `POST /auth/register`, `POST /auth/login`
- `GET /auth/verify-token`, `POST /auth/refresh-token`, `POST /auth/logout`
- `GET|POST|PUT /users/:userId/profile`
- `GET|PUT /restaurants/owner/:userId`
- `GET|PUT /restaurants/owner/:userId/menu`
- `GET /admin/overview`, `GET /admin/users`
- `PATCH|DELETE /admin/users/:id`
- `GET /admin/tables`
- `GET|POST /admin/tables/:table`
- `PATCH|DELETE /admin/tables/:table/rows`

Yönetici güncelleme isteği `{ "pk": {...}, "values": {...} }`, silme isteği
`{ "pk": {...} }` biçimindedir. Birleşik birincil anahtarların tüm alanları
gönderilmelidir. Tablo ve sütun adları yalnızca `information_schema` içinden
doğrulanır; değerler PostgreSQL parametreleriyle gönderilir. `password_hash`
gezgin sonuçlarına dahil edilmez ve bu alan gezgin üzerinden değiştirilemez.
