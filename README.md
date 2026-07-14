# yemekyemek

Yemek ve restoran puanlama sosyal medya platformu.

## İçerik

- [`yemekyemek_arayuz/`](yemekyemek_arayuz) — Flutter kullanıcı ve restoran sahibi uygulaması.
- [`backend/`](backend) — Node.js, Express ve PostgreSQL API.
- [`admin/`](admin) — React tabanlı web yönetim paneli.
- [`database/`](database) — PostgreSQL şeması.

Flutter uygulaması ve web yönetim paneli aynı backend üzerinden lokal
PostgreSQL veritabanını kullanır. Eski `.txt` depolaması remote modda kullanılmaz.

## Lokal kurulum

Gereksinimler:

- Node.js 20 veya üzeri
- PostgreSQL
- Flutter SDK

### 1. Veritabanı

```bash
createdb yemekyemek
psql "postgresql://postgres:SIFRENIZ@localhost:5432/yemekyemek" \
  -f database/schema.sql
```

### 2. Backend

```bash
cp backend/.env.example backend/.env
```

`backend/.env` içindeki `DATABASE_URL`, `JWT_SECRET` ve `ADMIN_*` değerlerini
kendi lokal ortamınıza göre değiştirin. Ardından:

```bash
npm --prefix backend install
npm --prefix backend run dev
```

API `http://localhost:3000/v1`, sağlık kontrolü
`http://localhost:3000/health` adresinde çalışır. Backend ilk açılışta
`ADMIN_*` bilgileriyle bcrypt hash'li yönetici hesabını idempotent olarak oluşturur.

### 3. Web yönetim paneli

```bash
npm --prefix admin install
npm --prefix admin run dev
```

Paneli `http://localhost:5173` adresinden açın ve `backend/.env` içindeki
`ADMIN_EMAIL` / `ADMIN_PASSWORD` ile giriş yapın.

### 4. Flutter

```bash
cd yemekyemek_arayuz
flutter pub get
flutter run
```

Varsayılan API adresi `http://localhost:3000/v1`'dir. Farklı bir adres
gerektiğinde:

```bash
flutter run --dart-define=API_BASE_URL=http://HOST:3000/v1
```

Android emülatöründen ana makineye erişmek için `HOST` değeri `10.0.2.2` olmalıdır.

## Günlük çalıştırma

Kurulum ve veritabanı şeması bir kez tamamlandıktan sonra iki ayrı terminal açın.

Terminal 1 — backend:

```bash
npm --prefix backend run dev
```

Terminal 2 — web admin:

```bash
npm --prefix admin run dev
```

Ardından:

- API: `http://localhost:3000/v1`
- Sağlık kontrolü: `http://localhost:3000/health`
- Admin paneli: `http://localhost:5173`

Sunucuları durdurmak için ilgili terminalde `Ctrl+C` kullanın.

## Kontroller

```bash
npm --prefix backend test
npm --prefix admin run lint
npm --prefix admin run build
cd yemekyemek_arayuz && flutter analyze && flutter test
```
 
