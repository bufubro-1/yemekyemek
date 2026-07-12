/// Uygulama genelinde kullanılan konfigürasyon değerleri.
///
/// Şu anda tüm veriler cihaz üzerinde .txt (JSON formatlı) dosyalarda
/// tutulmaktadır. İleride gerçek bir backend / database'e geçildiğinde
/// yapılması gereken TEK şey [useRemoteBackend] değerini `true` yapmak
/// ve [baseApiUrl] adresini güncellemektir. Repository katmanı bu bayrağa
/// göre otomatik olarak Local -> Remote implementasyonuna geçecek şekilde
/// tasarlanmıştır (bkz: lib/repositories).
class AppConfig {
  AppConfig._();

  /// false  -> LocalAuthRepository / LocalProfileRepository kullanılır (txt dosyası)
  /// true   -> RemoteAuthRepository / RemoteProfileRepository kullanılır (gerçek API)
  static const bool useRemoteBackend = false;

  /// TODO(backend-team): Gerçek API base URL'si buraya girilecek.
  static const String baseApiUrl = 'https://api.yemekyemek.app/v1';

  static const Duration networkTimeout = Duration(seconds: 15);
}
