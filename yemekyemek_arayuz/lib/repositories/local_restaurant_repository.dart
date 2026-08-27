import '../models/restaurant.dart';
import '../services/local_file_store.dart';
import 'restaurant_repository.dart';
import '../models/menu_category.dart';
import '../models/restaurant_menu_item.dart';

/// Restoran verilerini cihaz üzerindeki restaurants.txt dosyasında JSON
/// olarak tutan repository. Şu anki (prototip) implementasyon budur.
class LocalRestaurantRepository implements RestaurantRepository {
  final LocalFileStore _store = LocalFileStore.instance;

  Future<List<Restaurant>> _readAll() async {
    final raw = await _store.readList(LocalFileNames.restaurants);
    return raw
        .map((e) => Restaurant.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> _writeAll(List<Restaurant> restaurants) async {
    await _store.writeList(
      LocalFileNames.restaurants,
      restaurants.map((r) => r.toJson()).toList(),
    );
  }

  @override
  Future<Restaurant?> getRestaurant(String ownerUserId) async {
    final restaurants = await _readAll();
    final match =
        restaurants.where((r) => r.ownerUserId == ownerUserId).toList();
    if (match.isEmpty) return null;
    return match.first;
  }

  @override
  Future<void> saveRestaurant(Restaurant restaurant) async {
    final restaurants = await _readAll();
    final index =
        restaurants.indexWhere((r) => r.ownerUserId == restaurant.ownerUserId);
    if (index == -1) {
      restaurants.add(restaurant);
    } else {
      restaurants[index] = restaurant;
    }
    await _writeAll(restaurants);
  }

  @override
  Future<List<MenuCategory>> getMenuCategories(
    String ownerUserId,
  ) =>
      _unsupportedMenuOperation();

  @override
  Future<MenuCategory> createMenuCategory(
    String ownerUserId, {
    required String name,
  }) =>
      _unsupportedMenuOperation();

  @override
  Future<MenuCategory> updateMenuCategory(
    String ownerUserId,
    String categoryId, {
    String? name,
    int? sortOrder,
  }) =>
      _unsupportedMenuOperation();

  @override
  Future<void> deleteMenuCategory(
    String ownerUserId,
    String categoryId,
  ) =>
      _unsupportedMenuOperation();

  @override
  Future<List<RestaurantMenuItem>> getMenuItems(
    String ownerUserId,
    String categoryId,
  ) =>
      _unsupportedMenuOperation();

  @override
  Future<RestaurantMenuItem> createMenuItem(
    String ownerUserId,
    String categoryId, {
    required String name,
    String description = '',
    required double price,
    bool isAvailable = true,
  }) =>
      _unsupportedMenuOperation();

  @override
  Future<RestaurantMenuItem> updateMenuItem(
    String ownerUserId,
    String itemId, {
    String? name,
    String? description,
    double? price,
    bool? isAvailable,
    int? sortOrder,
  }) =>
      _unsupportedMenuOperation();

  @override
  Future<void> deleteMenuItem(
    String ownerUserId,
    String itemId,
  ) =>
      _unsupportedMenuOperation();

  Future<T> _unsupportedMenuOperation<T>() {
    return Future<T>.error(
      UnsupportedError(
        'Yeni menü yönetimi remote backend gerektirir.',
      ),
    );
  }
}
