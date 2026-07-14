import '../config/api_endpoints.dart';
import '../models/restaurant.dart';
import '../services/api_client.dart';
import 'restaurant_repository.dart';

class RemoteRestaurantRepository implements RestaurantRepository {
  RemoteRestaurantRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<Restaurant?> getRestaurant(String ownerUserId) async {
    try {
      final response =
          await _apiClient.get(ApiEndpoints.restaurant(ownerUserId));
      return _restaurantFromResponse(response);
    } on ApiException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<void> saveRestaurant(Restaurant restaurant) async {
    await _apiClient.put(
      ApiEndpoints.restaurant(restaurant.ownerUserId),
      body: restaurant.toJson(),
    );
  }

  Restaurant _restaurantFromResponse(ApiResponse response) {
    final data = response.data;
    if (data is! Map) {
      throw const ApiException('API yanıtında restoran bilgisi bulunamadı.');
    }
    final payload = Map<String, dynamic>.from(data);
    final rawRestaurant = payload['restaurant'] ?? payload;
    if (rawRestaurant is! Map) {
      throw const ApiException('API yanıtında restoran bilgisi bulunamadı.');
    }
    return Restaurant.fromJson(Map<String, dynamic>.from(rawRestaurant));
  }
}
