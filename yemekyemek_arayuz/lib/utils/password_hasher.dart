import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Şifreleri düz metin olarak SAKLAMAMAK için basit bir SHA-256 hash yardımcı
/// sınıfı. Backend'e geçildiğinde bu iş sunucu tarafında (örn. bcrypt/argon2
/// ile) yapılmalıdır; bu sınıf yalnızca lokal-prototip aşaması içindir.
class PasswordHasher {
  PasswordHasher._();

  static String hash(String plainPassword) {
    final bytes = utf8.encode(plainPassword);
    return sha256.convert(bytes).toString();
  }

  static bool verify(String plainPassword, String hash) {
    return PasswordHasher.hash(plainPassword) == hash;
  }
}
