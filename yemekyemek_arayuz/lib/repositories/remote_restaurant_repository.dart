import '../config/api_endpoints.dart';
import '../models/menu_category.dart';
import '../models/restaurant.dart';
import '../models/restaurant_menu_item.dart';
import '../services/api_client.dart';
import 'restaurant_repository.dart';

class RemoteRestaurantRepository implements RestaurantRepository {
  RemoteRestaurantRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<Restaurant?> getRestaurant(
    String ownerUserId,
  ) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.restaurant(ownerUserId),
      );

      return _restaurantFromResponse(response);
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        return null;
      }

      rethrow;
    }
  }

  @override
  Future<void> saveRestaurant(
    Restaurant restaurant,
  ) async {
    await _apiClient.put(
      ApiEndpoints.restaurant(restaurant.ownerUserId),
      body: restaurant.toJson(),
    );
  }

  @override
  Future<List<MenuCategory>> getMenuCategories(
    String ownerUserId,
  ) async {
    final response = await _apiClient.get(
      ApiEndpoints.menuCategories(ownerUserId),
    );

    final payload = _responseObject(response);
    final rawCategories = payload['categories'];

    if (rawCategories is! List) {
      throw const ApiException(
        'API yanıtında menü kategorileri bulunamadı.',
      );
    }

    return rawCategories.map((rawCategory) {
      if (rawCategory is! Map) {
        throw const ApiException(
          'API geçersiz bir menü kategorisi döndürdü.',
        );
      }

      return MenuCategory.fromJson(
        Map<String, dynamic>.from(rawCategory),
      );
    }).toList();
  }

  @override
  Future<MenuCategory> createMenuCategory(
    String ownerUserId, {
    required String name,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.menuCategories(ownerUserId),
      body: {
        'name': name,
      },
    );

    return _menuCategoryFromResponse(response);
  }

  @override
  Future<MenuCategory> updateMenuCategory(
    String ownerUserId,
    String categoryId, {
    String? name,
    int? sortOrder,
  }) async {
    final response = await _apiClient.patch(
      ApiEndpoints.menuCategory(
        ownerUserId,
        categoryId,
      ),
      body: {
        if (name != null) 'name': name,
        if (sortOrder != null) 'sortOrder': sortOrder,
      },
    );

    return _menuCategoryFromResponse(response);
  }

  @override
  Future<void> deleteMenuCategory(
    String ownerUserId,
    String categoryId,
  ) async {
    await _apiClient.delete(
      ApiEndpoints.menuCategory(
        ownerUserId,
        categoryId,
      ),
    );
  }

  @override
  Future<List<RestaurantMenuItem>> getMenuItems(
    String ownerUserId,
    String categoryId,
  ) async {
    final response = await _apiClient.get(
      ApiEndpoints.menuItems(
        ownerUserId,
        categoryId,
      ),
    );

    final payload = _responseObject(response);
    final rawItems = payload['items'];

    if (rawItems is! List) {
      throw const ApiException(
        'API yanıtında menü ürünleri bulunamadı.',
      );
    }

    return rawItems.map((rawItem) {
      if (rawItem is! Map) {
        throw const ApiException(
          'API geçersiz bir menü ürünü döndürdü.',
        );
      }

      return RestaurantMenuItem.fromJson(
        Map<String, dynamic>.from(rawItem),
      );
    }).toList();
  }

  @override
  Future<RestaurantMenuItem> createMenuItem(
    String ownerUserId,
    String categoryId, {
    required String name,
    String description = '',
    required double price,
    bool isAvailable = true,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.menuItems(
        ownerUserId,
        categoryId,
      ),
      body: {
        'name': name,
        'description': description,
        'price': price,
        'isAvailable': isAvailable,
      },
    );

    return _menuItemFromResponse(response);
  }

  @override
  Future<RestaurantMenuItem> updateMenuItem(
    String ownerUserId,
    String itemId, {
    String? name,
    String? description,
    double? price,
    bool? isAvailable,
    int? sortOrder,
  }) async {
    final response = await _apiClient.patch(
      ApiEndpoints.menuItem(
        ownerUserId,
        itemId,
      ),
      body: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (price != null) 'price': price,
        if (isAvailable != null) 'isAvailable': isAvailable,
        if (sortOrder != null) 'sortOrder': sortOrder,
      },
    );

    return _menuItemFromResponse(response);
  }

  @override
  Future<void> deleteMenuItem(
    String ownerUserId,
    String itemId,
  ) async {
    await _apiClient.delete(
      ApiEndpoints.menuItem(
        ownerUserId,
        itemId,
      ),
    );
  }

  Restaurant _restaurantFromResponse(
    ApiResponse response,
  ) {
    final data = response.data;

    if (data is! Map) {
      throw const ApiException(
        'API yanıtında restoran bilgisi bulunamadı.',
      );
    }

    final payload = Map<String, dynamic>.from(data);
    final rawRestaurant = payload['restaurant'] ?? payload;

    if (rawRestaurant is! Map) {
      throw const ApiException(
        'API yanıtında restoran bilgisi bulunamadı.',
      );
    }

    return Restaurant.fromJson(
      Map<String, dynamic>.from(rawRestaurant),
    );
  }

  MenuCategory _menuCategoryFromResponse(
    ApiResponse response,
  ) {
    final payload = _responseObject(response);
    final rawCategory = payload['category'];

    if (rawCategory is! Map) {
      throw const ApiException(
        'API yanıtında menü kategorisi bulunamadı.',
      );
    }

    return MenuCategory.fromJson(
      Map<String, dynamic>.from(rawCategory),
    );
  }

  RestaurantMenuItem _menuItemFromResponse(
    ApiResponse response,
  ) {
    final payload = _responseObject(response);
    final rawItem = payload['item'];

    if (rawItem is! Map) {
      throw const ApiException(
        'API yanıtında menü ürünü bulunamadı.',
      );
    }

    return RestaurantMenuItem.fromJson(
      Map<String, dynamic>.from(rawItem),
    );
  }

  Map<String, dynamic> _responseObject(
    ApiResponse response,
  ) {
    final data = response.data;

    if (data is! Map) {
      throw const ApiException(
        'API yanıtı beklenen JSON nesnesi değil.',
      );
    }

    return Map<String, dynamic>.from(data);
  }
}
