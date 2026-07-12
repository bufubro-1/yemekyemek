import '../models/restaurant.dart';
import '../services/local_file_store.dart';
import 'restaurant_repository.dart';

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
}
