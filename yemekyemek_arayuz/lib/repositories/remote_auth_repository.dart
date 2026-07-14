import '../config/api_endpoints.dart';
import '../models/app_user.dart';
import '../services/api_client.dart';
import '../services/token_storage.dart';
import 'auth_repository.dart';

class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _tokenStorage = tokenStorage ?? TokenStorage(),
        _apiClient = apiClient ?? ApiClient(tokenStorage: tokenStorage);

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  @override
  Future<AuthResult> register({
    required String nickname,
    required String username,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.register,
        authenticated: false,
        body: {
          'nickname': nickname.trim().toLowerCase(),
          'username': username.trim(),
          'email': email.trim().toLowerCase(),
          'password': password,
          'role': role.toApiValue(),
        },
      );
      return await _completeAuthentication(response);
    } on ApiException catch (error) {
      return AuthResult.failure(error.message);
    } catch (error) {
      return AuthResult.failure(error.toString());
    }
  }

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        authenticated: false,
        body: {
          'email': email.trim().toLowerCase(),
          'password': password,
        },
      );
      return await _completeAuthentication(response);
    } on ApiException catch (error) {
      return AuthResult.failure(error.message);
    } catch (error) {
      return AuthResult.failure(error.toString());
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _apiClient.post(ApiEndpoints.logout);
    } catch (_) {
      // Sunucuya ulaşılamasa da cihazdaki oturum mutlaka kapatılır.
    } finally {
      await _tokenStorage.clearAccessToken();
    }
  }

  @override
  Future<AppUser?> getSavedSession() async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) return null;

    try {
      final response = await _apiClient.get(ApiEndpoints.verifyToken);
      return _userFromResponse(response);
    } on ApiException catch (error) {
      if (error.isUnauthorized) {
        await _tokenStorage.clearAccessToken();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AuthResult> updateUsername({
    required String userId,
    required String newUsername,
  }) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.userProfile(userId),
        body: {'username': newUsername.trim()},
      );
      return AuthResult.success(_userFromResponse(response));
    } on ApiException catch (error) {
      return AuthResult.failure(error.message);
    } catch (error) {
      return AuthResult.failure(error.toString());
    }
  }

  Future<AuthResult> _completeAuthentication(ApiResponse response) async {
    final payload = _payload(response);
    final token = (payload['token'] ?? payload['accessToken'])?.toString();
    if (token == null || token.isEmpty) {
      return AuthResult.failure('API yanıtında erişim tokenı bulunamadı.');
    }

    final user = _userFromPayload(payload);
    await _tokenStorage.writeAccessToken(token);
    return AuthResult.success(user);
  }

  AppUser _userFromResponse(ApiResponse response) {
    return _userFromPayload(_payload(response));
  }

  AppUser _userFromPayload(Map<String, dynamic> payload) {
    final rawUser = payload['user'] ?? payload;
    if (rawUser is! Map) {
      throw const ApiException('API yanıtında kullanıcı bilgisi bulunamadı.');
    }
    return AppUser.fromJson(Map<String, dynamic>.from(rawUser));
  }

  Map<String, dynamic> _payload(ApiResponse response) {
    final data = response.data;
    if (data is! Map) {
      throw const ApiException('API yanıtı beklenen veri yapısında değil.');
    }
    return Map<String, dynamic>.from(data);
  }
}
