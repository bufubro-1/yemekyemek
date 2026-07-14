import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// JWT erişim token'ını platformun güvenli anahtar deposunda saklar.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'auth_access_token';

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<void> writeAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  Future<void> clearAccessToken() => _storage.delete(key: _accessTokenKey);
}
