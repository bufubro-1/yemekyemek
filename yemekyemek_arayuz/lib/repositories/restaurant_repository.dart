import '../models/menu_category.dart';
import '../models/restaurant.dart';
import '../models/restaurant_menu_item.dart';

abstract class RestaurantRepository {
  Future<Restaurant?> getRestaurant(String ownerUserId);

  Future<void> saveRestaurant(Restaurant restaurant);

  Future<List<MenuCategory>> getMenuCategories(
    String ownerUserId,
  );

  Future<MenuCategory> createMenuCategory(
    String ownerUserId, {
    required String name,
  });

  Future<MenuCategory> updateMenuCategory(
    String ownerUserId,
    String categoryId, {
    String? name,
    int? sortOrder,
  });

  Future<void> deleteMenuCategory(
    String ownerUserId,
    String categoryId,
  );

  Future<List<RestaurantMenuItem>> getMenuItems(
    String ownerUserId,
    String categoryId,
  );

  Future<RestaurantMenuItem> createMenuItem(
    String ownerUserId,
    String categoryId, {
    required String name,
    String description = '',
    required double price,
    bool isAvailable = true,
  });

  Future<RestaurantMenuItem> updateMenuItem(
    String ownerUserId,
    String itemId, {
    String? name,
    String? description,
    double? price,
    bool? isAvailable,
    int? sortOrder,
  });

  Future<void> deleteMenuItem(
    String ownerUserId,
    String itemId,
  );
}
