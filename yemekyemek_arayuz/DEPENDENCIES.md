# Bağımlılıklar (Dependencies)

Bu dosya, `yemekyemek_arayuz` projesinin [`pubspec.yaml`](pubspec.yaml) dosyasındaki tüm
bağımlılıkları; ne için kullanıldıklarını, hangi katmanda devreye girdiklerini ve kurulum
gereksinimlerini açıklar.

## Sistem gereksinimleri

| Araç | Minimum sürüm | Not |
|---|---|---|
| Flutter SDK | 3.38.4+ (stable kanal) | `pubspec.lock` çözümlemesiyle uyumlu |
| Dart SDK | ^3.0.0 <4.0.0 | `pubspec.yaml` → `environment.sdk` |
| PostgreSQL | 13+ | Uygulamanın bağlandığı yerel Node API'nin veri deposu (bkz. [`../database`](../database)) |

Kurulum:

```bash
flutter --version   # SDK'nın kurulu ve doğru kanalda olduğunu doğrula
flutter pub get      # Tüm bağımlılıkları indir
```

## `dependencies` (uygulama çalışma zamanı)

| Paket | Sürüm | Neden kullanılıyor | Kullanıldığı yer |
|---|---|---|---|
| `flutter` | SDK | Framework'ün kendisi | Tüm proje |
| `cupertino_icons` | `^1.0.6` | iOS tarzı ikonlar (Material dışı ikon setine ihtiyaç olursa) | Genel |
| `path_provider` | `^2.1.2` | Cihazın belge dizinine erişip `.txt` (JSON) dosyaları okuma/yazma | [`lib/services/local_file_store.dart`](lib/services/local_file_store.dart) → `users.txt`, `profiles.txt`, `session.txt`, `restaurants.txt` |
| `crypto` | `^3.0.3` | Şifrelerin SHA-256 ile hash'lenmesi (düz metin şifre hiç saklanmaz) | [`lib/utils/password_hasher.dart`](lib/utils/password_hasher.dart) |
| `http` | `^1.2.0` | Node API'ye zaman aşımı ve Bearer JWT destekli REST istekleri | [`lib/services/api_client.dart`](lib/services/api_client.dart), [`lib/repositories/remote_*_repository.dart`](lib/repositories) |
| `flutter_secure_storage` | `^10.3.1` | JWT erişim tokenını platformun güvenli deposunda saklama | [`lib/services/token_storage.dart`](lib/services/token_storage.dart) |

## `dev_dependencies` (yalnızca geliştirme/test)

| Paket | Sürüm | Neden kullanılıyor |
|---|---|---|
| `flutter_test` | SDK | Widget testleri (`test/widget_test.dart`) |
| `flutter_lints` | `^3.0.0` | Statik analiz kuralları (`analysis_options.yaml`) |

## İleride gerekebilecek bağımlılıklar

Bu paketler şu an **pubspec.yaml'da yok**; sadece ilgili özellik implemente edilirken hangi
paketin gerekeceğine dair not olarak listelenmiştir:

| Paket | Ne zaman gerekir |
|---|---|
| `postgres` / bir backend servisi (Node/Dart shelf vb.) | `database/` altındaki PostgreSQL şemasına gerçekten bağlanan bir API sunucusu yazıldığında — **bu Flutter projesinin değil, ayrı bir backend projesinin bağımlılığı olacaktır** |
| `image_picker` | Profil avatarı için gerçek dosya seçme özelliği eklendiğinde (şu an `avatarLocalPath` sadece modelde var, UI'da düzenleme yok) |

## Güncelleme / bakım

Bağımlılıkları güncellemek için:

```bash
flutter pub outdated   # Güncel olmayan paketleri listele
flutter pub upgrade    # pubspec.yaml'daki sürüm aralıkları içinde güncelle
```

Sürüm aralığını (`^x.y.z`) değiştirmeden önce `flutter pub outdated` çıktısını ve ilgili
paketin CHANGELOG'unu kontrol edin.
