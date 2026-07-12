import 'package:flutter/material.dart';

import '../../models/restaurant.dart';
import '../../repositories/repository_provider.dart';
import '../../repositories/restaurant_repository.dart';
import '../../services/session_controller.dart';
import '../auth/login_screen.dart';
import 'restaurant_form_screen.dart';
import 'restaurant_menu_screen.dart';

/// Restoran sahibi rolündeki kullanıcıların giriş/kayıt sonrası yönlendiği
/// ana panel. Görünüm (deepOrange tema, kart/buton yerleşimi) orijinal
/// qr_restaurant_app'teki RestaurantPanelPage ile birebir aynıdır; tek fark,
/// artık kayıtlı restoran bilgisini gerçekten okuyup göstermesidir (eskiden
/// hep "Henüz restoran eklenmedi" sabit metni gösteriliyordu).
class RestaurantPanelScreen extends StatefulWidget {
  const RestaurantPanelScreen({super.key});

  @override
  State<RestaurantPanelScreen> createState() => _RestaurantPanelScreenState();
}

class _RestaurantPanelScreenState extends State<RestaurantPanelScreen> {
  final RestaurantRepository _restaurantRepository =
      RepositoryProvider.restaurant;

  Restaurant? _restaurant;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRestaurant();
  }

  Future<void> _loadRestaurant() async {
    final userId = SessionController.instance.currentUser?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    final restaurant = await _restaurantRepository.getRestaurant(userId);
    if (!mounted) return;
    setState(() {
      _restaurant = restaurant;
      _isLoading = false;
    });
  }

  Future<void> _openRestaurantForm() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => RestaurantFormScreen(existing: _restaurant),
      ),
    );

    if (saved == true) {
      _loadRestaurant();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restoran Paneli'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Çıkış yap',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await SessionController.instance.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Restoranım',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.restaurant),
                      ),
                      title: Text(
                        _restaurant?.name ?? 'Henüz restoran eklenmedi',
                      ),
                      subtitle: Text(
                        _restaurant?.address ??
                            'Restoran bilgilerini ekleyerek başlayabilirsin.',
                      ),
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _openRestaurantForm,
                    icon: Icon(_restaurant == null ? Icons.add : Icons.edit),
                    label: Text(
                      _restaurant == null
                          ? 'Restoran Bilgilerini Ekle'
                          : 'Restoran Bilgilerini Düzenle',
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RestaurantMenuScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.menu_book),
                    label: const Text('Menüyü Yönet'),
                  ),
                ],
              ),
            ),
    );
  }
}
