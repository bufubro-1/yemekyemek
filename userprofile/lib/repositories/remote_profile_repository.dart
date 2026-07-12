import '../config/api_endpoints.dart';
import '../config/app_config.dart';
import '../models/app_user.dart';
import '../models/user_profile.dart';
import 'profile_repository.dart';

/// ============================================================
///  GELECEK BACKEND ENTEGRASYONU İÇİN HAZIR İSKELET
/// ============================================================
/// Şu anda KULLANILMIYOR. AppConfig.useRemoteBackend = true yapıldığında
/// ProfileRepositoryProvider bu sınıfı döndürmeye başlayacak.
class RemoteProfileRepository implements ProfileRepository {
  final String _baseUrl = AppConfig.baseApiUrl;

  @override
  Future<UserProfile> createEmptyProfileFor(AppUser user) async {
    // TODO: POST $_baseUrl${ApiEndpoints.userProfile(user.id)}
    throw UnimplementedError(
      'Endpoint: $_baseUrl${ApiEndpoints.userProfile(user.id)}',
    );
  }

  @override
  Future<UserProfile?> getProfile(String userId) async {
    // TODO: GET $_baseUrl${ApiEndpoints.userProfile(userId)}
    // Ayrıca ayrı ayrı da çekilebilir:
    //   GET ${ApiEndpoints.dietPreferences(userId)}
    //   GET ${ApiEndpoints.allergies(userId)}
    //   GET ${ApiEndpoints.pastOrders(userId)}
    //   GET ${ApiEndpoints.lists(userId)}
    //   GET ${ApiEndpoints.comments(userId)}
    throw UnimplementedError(
      'Endpoint: $_baseUrl${ApiEndpoints.userProfile(userId)}',
    );
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    // TODO: PUT $_baseUrl${ApiEndpoints.userProfile(profile.userId)}
    throw UnimplementedError(
      'Endpoint: $_baseUrl${ApiEndpoints.userProfile(profile.userId)}',
    );
  }
}
