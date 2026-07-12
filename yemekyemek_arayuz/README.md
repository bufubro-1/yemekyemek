# yemekyemek_arayuz

YemekYemek? — yemek ve restoran puanlama sosyal medya platformunun **birleşik** Flutter arayüzü.

Bu proje, önceden ayrı iki uygulama olan `userprofile` (kullanıcı kaydı/girişi/profil) ve
`qr_restaurant_app` (restoran paneli) uygulamalarının tek çatı altında birleştirilmiş hâlidir.
Kayıt sırasında seçilen hesap türüne (`Kullanıcıyım` / `Restoran sahibiyim`) göre kullanıcı
otomatik olarak doğru ana ekrana yönlendirilir.

## Mimari

- **State management:** Hafif, `ChangeNotifier` (`SessionController`) + `setState`. Provider/Bloc/Riverpod yok.
- **Veri katmanı:** Repository pattern (`lib/repositories`). Şu an tüm veriler cihaz üzerinde
  JSON formatlı `.txt` dosyalarında tutuluyor (`LocalFileStore`). `AppConfig.useRemoteBackend`
  bayrağı `true` yapıldığında aynı arayüzler (`AuthRepository`, `ProfileRepository`,
  `RestaurantRepository`) gerçek bir API'ye (bkz. kök `database/` klasöründeki PostgreSQL şeması)
  bağlanacak şekilde tasarlanmıştır.
- **Roller:** `AppUser.role` (`user` / `restaurantOwner`) hangi ana ekrana
  (`HomeScreen` / `RestaurantPanelScreen`) yönlendirileceğini belirler (bkz. `lib/utils/role_navigation.dart`).

## Klasör yapısı

```
lib/
├── main.dart
├── config/            # API endpoint'leri, ortam ayarları
├── models/            # AppUser, UserProfile, Restaurant
├── repositories/       # Local + Remote (iskelet) repository'ler
├── services/           # SessionController, LocalFileStore
├── screens/
│   ├── splash_decision_screen.dart
│   ├── auth/            # login, signup (rol seçimi burada yapılır)
│   ├── home/            # normal kullanıcı ana sayfası (placeholder)
│   ├── profile/         # profil ekranı ve alt ekranlar
│   └── restaurant/      # restoran paneli, restoran formu, menü yönetimi
├── utils/               # tema, validasyon, şifre hash'leme, rol yönlendirme
└── widgets/
```

## Çalıştırma

```bash
flutter pub get
flutter run
```

Bir hata alırsan `pubspec.yaml` bağımlılıklarının tam indirildiğinden emin ol ve
`flutter pub get`'i tekrar çalıştır. Her bağımlılığın ne için kullanıldığına dair
ayrıntılı açıklama için [`DEPENDENCIES.md`](DEPENDENCIES.md)'ye bakabilirsin.

## Veritabanı

PostgreSQL şeması ve ilgili SQL scriptleri kök dizindeki [`database/`](../database) klasöründe
tutulur; şu an uygulama tarafından kullanılmıyor (uygulama hâlâ yerel dosya deposunu kullanıyor),
ancak `RemoteAuthRepository` / `RemoteProfileRepository` / `RemoteRestaurantRepository`
implemente edildiğinde bu şema referans alınacaktır.
