/// Uygulama genelinde kullanılan konfigürasyon değerleri.
///
/// Ortama göre değişen değerler `--dart-define` ile verilebilir.
class AppConfig {
  AppConfig._();

  static const bool useRemoteBackend = bool.fromEnvironment(
    'USE_REMOTE_BACKEND',
    defaultValue: true,
  );

  /// Web, iOS simulator ve macOS geliştirmede localhost çalışır.
  ///
  /// Android emulator için uygulamayı şu şekilde başlat:
  /// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/v1`
  static const String baseApiUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/v1',
  );

  static const Duration networkTimeout = Duration(seconds: 15);
}
