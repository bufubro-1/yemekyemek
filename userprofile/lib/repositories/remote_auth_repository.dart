import '../config/api_endpoints.dart';
import '../config/app_config.dart';
import '../models/app_user.dart';
import 'auth_repository.dart';

/// ============================================================
///  GELECEK BACKEND ENTEGRASYONU İÇİN HAZIR İSKELET
/// ============================================================
/// Şu anda KULLANILMIYOR. AppConfig.useRemoteBackend = true yapıldığında
/// AuthRepositoryProvider bu sınıfı döndürmeye başlayacak.
///
/// Yapılması gerekenler (backend hazır olduğunda):
///  1. `http` (veya dio) paketiyle gerçek istekleri yaz.
///  2. Endpoint path'leri [ApiEndpoints] içinde zaten tanımlı.
///  3. Dönen JWT/token'ı güvenli depoya (örn. flutter_secure_storage) kaydet.
///  4. AppConfig.useRemoteBackend = true yap.
class RemoteAuthRepository implements AuthRepository {
  final String _baseUrl = AppConfig.baseApiUrl;

  @override
  Future<AuthResult> register({
    required String nickname,
    required String username,
    required String email,
    required String password,
  }) async {
    // TODO: POST $_baseUrl${ApiEndpoints.register}
    // body: { "nickname": nickname, "username": username, "email": email, "password": password }
    throw UnimplementedError(
      'RemoteAuthRepository henüz aktif değil. '
      'AppConfig.useRemoteBackend = true yapılıp backend bağlandığında '
      'bu metod implemente edilecek. Endpoint: $_baseUrl${ApiEndpoints.register}',
    );
  }

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    // TODO: POST $_baseUrl${ApiEndpoints.login}
    throw UnimplementedError(
      'Endpoint: $_baseUrl${ApiEndpoints.login}',
    );
  }

  @override
  Future<void> logout() async {
    // TODO: POST $_baseUrl${ApiEndpoints.logout}
    throw UnimplementedError('Endpoint: $_baseUrl${ApiEndpoints.logout}');
  }

  @override
  Future<AppUser?> getSavedSession() async {
    // TODO: GET $_baseUrl${ApiEndpoints.verifyToken} (saklanan token ile)
    throw UnimplementedError(
      'Endpoint: $_baseUrl${ApiEndpoints.verifyToken}',
    );
  }

  @override
  Future<AuthResult> updateUsername({
    required String userId,
    required String newUsername,
  }) async {
    // TODO: PUT $_baseUrl${ApiEndpoints.userProfile(userId)} (username alanı)
    throw UnimplementedError(
      'Endpoint: $_baseUrl${ApiEndpoints.userProfile(userId)}',
    );
  }
}
