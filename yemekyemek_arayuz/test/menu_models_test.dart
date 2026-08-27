import 'package:flutter_test/flutter_test.dart';
import 'package:yemekyemek_arayuz/config/api_endpoints.dart';
import 'package:yemekyemek_arayuz/models/menu_category.dart';
import 'package:yemekyemek_arayuz/models/restaurant_menu_item.dart';

void main() {
  group('MenuCategory', () {
    test('API kategori yanıtını modele dönüştürür', () {
      final category = MenuCategory.fromJson({
        'id': 'category-id',
        'name': 'Ana Yemekler',
        'sortOrder': 2,
        'itemCount': 4,
      });

      expect(category.id, 'category-id');
      expect(category.name, 'Ana Yemekler');
      expect(category.sortOrder, 2);
      expect(category.itemCount, 4);
    });

    test('snake_case alanlarını da okuyabilir', () {
      final category = MenuCategory.fromJson({
        'id': 'category-id',
        'name': 'Tatlılar',
        'sort_order': '3',
        'item_count': '5',
      });

      expect(category.sortOrder, 3);
      expect(category.itemCount, 5);
    });
  });

  group('RestaurantMenuItem', () {
    test('API ürün yanıtını modele dönüştürür', () {
      final item = RestaurantMenuItem.fromJson({
        'id': 'item-id',
        'categoryId': 'category-id',
        'name': 'Mercimek Çorbası',
        'description': 'Günlük hazırlanır.',
        'price': 120.5,
        'isAvailable': true,
        'sortOrder': 1,
        'createdAt': '2026-08-27T12:00:00.000Z',
      });

      expect(item.id, 'item-id');
      expect(item.categoryId, 'category-id');
      expect(item.name, 'Mercimek Çorbası');
      expect(item.description, 'Günlük hazırlanır.');
      expect(item.price, 120.5);
      expect(item.isAvailable, isTrue);
      expect(item.sortOrder, 1);
      expect(
        item.createdAt,
        DateTime.parse('2026-08-27T12:00:00.000Z'),
      );
    });

    test('PostgreSQL sayı metinlerini okuyabilir', () {
      final item = RestaurantMenuItem.fromJson({
        'id': 'item-id',
        'category_id': 'category-id',
        'name': 'Test Ürünü',
        'description': '',
        'price': '149.90',
        'is_available': false,
        'sort_order': '0',
        'created_at': '2026-08-27T12:00:00Z',
      });

      expect(item.price, 149.9);
      expect(item.isAvailable, isFalse);
      expect(item.sortOrder, 0);
    });
  });

  test('menü endpointlerini doğru oluşturur', () {
    const ownerId = 'owner-id';
    const categoryId = 'category-id';
    const itemId = 'item-id';

    expect(
      ApiEndpoints.menuCategories(ownerId),
      '/restaurants/owner/owner-id/menu/categories',
    );

    expect(
      ApiEndpoints.menuCategory(ownerId, categoryId),
      '/restaurants/owner/owner-id/menu/categories/category-id',
    );

    expect(
      ApiEndpoints.menuItems(ownerId, categoryId),
      '/restaurants/owner/owner-id/menu/categories/category-id/items',
    );

    expect(
      ApiEndpoints.menuItem(ownerId, itemId),
      '/restaurants/owner/owner-id/menu/items/item-id',
    );
  });
}
