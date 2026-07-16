# YemekYemek Agent Rehberi

Bu dosya, repoda çalışan tüm kodlama agentları için genel kuralları içerir.

## İletişim

- Kullanıcıyla Türkçe iletişim kur.
- Belirsiz veya riskli değişikliklerde varsayım yapmak yerine kısa bir soru sor.
- Gerçek `.env` içeriğini, parolaları ve tokenları okuma, yazdırma veya commit etme.

## Mimari

- `yemekyemek_arayuz/`: Flutter kullanıcı ve restoran sahibi uygulaması.
- `backend/`: Node.js 20+, Express 5 ve PostgreSQL API.
- `admin/`: Vite + React web yönetim paneli.
- `database/`: Sıralı PostgreSQL şema dosyaları.
- Flutter ve admin PostgreSQL'e doğrudan bağlanmaz; yalnızca backend API kullanır.
- Lokal servis adresleri: API `localhost:3000`, admin `localhost:5173`, PostgreSQL `localhost:5432`.

## Güvenlik

- Parolaları yalnızca bcrypt ile sakla; API yanıtlarında `password_hash` döndürme.
- JWT'yi Flutter'da `flutter_secure_storage` ile sakla.
- Admin endpointlerini hem JWT hem `role=admin` kontrolüyle koru.
- SQL değerlerini parametreli sorgularla gönder.
- Dinamik tablo/sütun adlarını `information_schema` üzerinden doğrulamadan sorguya ekleme.
- Adminin kendi hesabını silmesine veya kendi admin rolünü kaldırmasına izin verme.

## Veri ve API

- Ortam ayarları `backend/.env` dosyasından okunur; örnek değerler `backend/.env.example` içinde tutulur.
- Yeni şema değişikliklerini numaralı SQL dosyası olarak ekle ve `database/schema.sql` içine dahil et.
- Migration/şema işlemleri tekrar çalıştırılabilir olmalı.
- Flutter rolü `restaurantOwner`, API/PostgreSQL karşılığı `restaurant_owner` şeklindedir.
- Tarihleri API'de ISO 8601 formatında döndür.
- Backend mesajını istemcide önceliklendir; kullanıcı mesajlarını dağınık şekilde hardcode etme.
- Admin arayüzündeki metinleri `admin/src/messages.js` içinde merkezileştir.

## Kod Değişiklikleri

- Mevcut repository arayüzlerini ve API sözleşmelerini birlikte güncelle.
- Flutter paketlerini paket yöneticisiyle ekle; üretilen plugin kayıt dosyalarını elle düzenleme.
- Kullanıcının mevcut ve ilgisiz değişikliklerini geri alma.
- İstenen kapsam dışında toplu refactor veya biçimlendirme yapma.
- `.env`, `node_modules/`, `dist/` ve gizli bilgileri commit etme.
- Kullanıcı açıkça istemedikçe commit veya push yapma.

## Doğrulama

Değişiklikten etkilenen kontrolleri çalıştır:

```bash
npm --prefix backend test
npm --prefix admin run lint
npm --prefix admin run build
cd yemekyemek_arayuz && flutter analyze && flutter test
```

Veritabanı değişikliğinde mümkünse şemayı boş bir lokal PostgreSQL veritabanında çalıştır.
Sonuçta yapılan değişiklikleri, kontrolleri ve çalıştırılamayan doğrulamaları kısa biçimde bildir.
