import '../config/api_endpoints.dart';
import '../config/app_config.dart';
import '../models/restaurant.dart';
import 'restaurant_repository.dart';

/// ============================================================
///  GELECEK BACKEND ENTEGRASYONU İÇİN HAZIR İSKELET
/// ============================================================
/// Şu anda KULLANILMIYOR. AppConfig.useRemoteBackend = true yapıldığında
/// RepositoryProvider bu sınıfı döndürmeye başlayacak.
class RemoteRestaurantRepository implements RestaurantRepository {
  final String _baseUrl = AppConfig.baseApiUrl;

  @override
  Future<Restaurant?> getRestaurant(String ownerUserId) async {
    // TODO: GET $_baseUrl${ApiEndpoints.restaurant(ownerUserId)}
    throw UnimplementedError(
      'Endpoint: $_baseUrl${ApiEndpoints.restaurant(ownerUserId)}',
    );
  }

  @override
  Future<void> saveRestaurant(Restaurant restaurant) async {
    // TODO: PUT $_baseUrl${ApiEndpoints.restaurant(restaurant.ownerUserId)}
    throw UnimplementedError(
      'Endpoint: $_baseUrl${ApiEndpoints.restaurant(restaurant.ownerUserId)}',
    );
  }
}
