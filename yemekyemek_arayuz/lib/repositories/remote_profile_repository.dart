import '../config/api_endpoints.dart';
import '../models/app_user.dart';
import '../models/user_profile.dart';
import '../services/api_client.dart';
import 'profile_repository.dart';

class RemoteProfileRepository implements ProfileRepository {
  RemoteProfileRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<UserProfile> createEmptyProfileFor(AppUser user) async {
    final profile = UserProfile.empty(userId: user.id);
    final response = await _apiClient.post(
      ApiEndpoints.userProfile(user.id),
      body: profile.toJson(),
    );
    return response.body == null ? profile : _profileFromResponse(response);
  }

  @override
  Future<UserProfile?> getProfile(String userId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.userProfile(userId));
      return _profileFromResponse(response);
    } on ApiException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    await _apiClient.put(
      ApiEndpoints.userProfile(profile.userId),
      body: profile.toJson(),
    );
  }

  UserProfile _profileFromResponse(ApiResponse response) {
    final data = response.data;
    if (data is! Map) {
      throw const ApiException('API yanıtında profil bilgisi bulunamadı.');
    }
    final payload = Map<String, dynamic>.from(data);
    final rawProfile = payload['profile'] ?? payload;
    if (rawProfile is! Map) {
      throw const ApiException('API yanıtında profil bilgisi bulunamadı.');
    }
    return UserProfile.fromJson(Map<String, dynamic>.from(rawProfile));
  }
}
