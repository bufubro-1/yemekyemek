import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../screens/home/home_screen.dart';
import '../screens/restaurant/restaurant_panel_screen.dart';

/// Kullanıcının rolüne göre gitmesi gereken ana ekranı döndürür.
/// Splash, login ve signup ekranlarının hepsi aynı kararı vermesi gerektiği
/// için (DRY) tek yerden yönetilir.
Widget homeScreenForRole(UserRole role) {
  switch (role) {
    case UserRole.restaurantOwner:
      return const RestaurantPanelScreen();
    case UserRole.user:
      return const HomeScreen();
  }
}
