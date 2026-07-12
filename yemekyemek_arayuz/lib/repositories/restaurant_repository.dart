import '../models/restaurant.dart';

/// Restoran verilerinin (bilgiler + menü kategorileri) okunup yazılması
/// için sözleşme. [ProfileRepository] ile aynı desen izlenir.
abstract class RestaurantRepository {
  Future<Restaurant?> getRestaurant(String ownerUserId);

  Future<void> saveRestaurant(Restaurant restaurant);
}
