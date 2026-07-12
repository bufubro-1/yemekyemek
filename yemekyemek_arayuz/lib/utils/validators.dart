/// Kayıt/giriş formlarında kullanılan standart validasyon kuralları.
class Validators {
  Validators._();

  static final RegExp _emailRegExp =
      RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'E-posta adresi gerekli';
    }
    if (!_emailRegExp.hasMatch(value.trim())) {
      return 'Geçerli bir e-posta adresi girin';
    }
    return null;
  }

  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Kullanıcı adı gerekli';
    }
    if (value.trim().length < 3) {
      return 'Kullanıcı adı en az 3 karakter olmalı';
    }
    return null;
  }

  static final RegExp _nicknameRegExp = RegExp(r'^[a-z0-9_.]+$');

  /// Nickname eşsiz olacağı için (Instagram/Twitter tarzı) sade bir format
  /// zorunluluğu getirilir: sadece küçük harf, rakam, alt çizgi ve nokta.
  static String? nickname(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nickname gerekli';
    }
    final trimmed = value.trim();
    if (trimmed.length < 3) {
      return 'Nickname en az 3 karakter olmalı';
    }
    if (!_nicknameRegExp.hasMatch(trimmed)) {
      return 'Sadece küçük harf, rakam, "_" ve "." kullanılabilir';
    }
    return null;
  }

  /// Standart şifre kuralları:
  /// - En az 8 karakter
  /// - En az 1 büyük harf
  /// - En az 1 küçük harf
  /// - En az 1 rakam
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre gerekli';
    }
    if (value.length < 8) {
      return 'Şifre en az 8 karakter olmalıdır';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Şifre en az bir büyük harf içermelidir';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Şifre en az bir küçük harf içermelidir';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Şifre en az bir rakam içermelidir';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) {
      return 'Şifreyi tekrar girin';
    }
    if (value != original) {
      return 'Şifreler eşleşmiyor';
    }
    return null;
  }
}
