import '../models/app_user.dart';

/// Auth işlemlerinin sonucunu taşıyan basit bir "either" benzeri yapı.
class AuthResult {
  final bool success;
  final String? errorMessage;
  final AppUser? user;

  AuthResult.success(this.user)
      : success = true,
        errorMessage = null;

  AuthResult.failure(this.errorMessage)
      : success = false,
        user = null;
}

/// Auth kaynağının (local dosya ya da uzak API) uyması gereken sözleşme.
/// Bu sayede UI katmanı (login/signup ekranları) hangi implementasyonun
/// kullanıldığını bilmek zorunda kalmaz.
abstract class AuthRepository {
  Future<AuthResult> register({
    required String nickname,
    required String username,
    required String email,
    required String password,
    required UserRole role,
  });

  Future<AuthResult> login({
    required String email,
    required String password,
  });

  Future<void> logout();

  /// Uygulama yeniden açıldığında aktif oturumu kontrol eder.
  Future<AppUser?> getSavedSession();

  /// Görünen ismi (username) değiştirir. Nickname eşsiz olduğu için
  /// değiştirilemez; sadece username (görünen isim) güncellenebilir.
  Future<AuthResult> updateUsername({
    required String userId,
    required String newUsername,
  });
}
