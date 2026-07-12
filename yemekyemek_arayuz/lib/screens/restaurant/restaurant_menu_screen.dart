import 'package:flutter/material.dart';

import '../../models/restaurant.dart';
import '../../repositories/repository_provider.dart';
import '../../repositories/restaurant_repository.dart';
import '../../services/session_controller.dart';

/// Menü kategorilerini listeleme/ekleme ekranı. Görünüm orijinal
/// qr_restaurant_app'teki MenuPage ile aynıdır.
///
/// Bug fix: eskiden kategoriler yalnızca widget state'inde tutuluyordu ve
/// sayfa kapanınca kayboluyordu. Artık RestaurantRepository üzerinden
/// restoranın [Restaurant.menuCategories] alanına kalıcı olarak yazılıyor.
class RestaurantMenuScreen extends StatefulWidget {
  const RestaurantMenuScreen({super.key});

  @override
  State<RestaurantMenuScreen> createState() {
    return _RestaurantMenuScreenState();
  }
}

class _RestaurantMenuScreenState extends State<RestaurantMenuScreen> {
  final RestaurantRepository _restaurantRepository =
      RepositoryProvider.restaurant;

  Restaurant? _restaurant;
  List<String> _categories = [];
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
      _categories = restaurant?.menuCategories ?? [];
      _isLoading = false;
    });
  }

  Future<void> _persistCategories() async {
    final userId = SessionController.instance.currentUser?.id;
    if (userId == null) return;

    final restaurant = _restaurant ??
        Restaurant(ownerUserId: userId, name: '', phone: '', address: '');
    restaurant.menuCategories = _categories;
    await _restaurantRepository.saveRestaurant(restaurant);
    _restaurant = restaurant;
  }

  Future<void> _showAddCategoryDialog() async {
    final formKey = GlobalKey<FormState>();
    final categoryController = TextEditingController();

    final categoryName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Kategori Ekle'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: categoryController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Kategori adı',
                hintText: 'Örneğin Ana Yemekler',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Kategori adı boş bırakılamaz.';
                }

                final enteredName = value.trim().toLowerCase();

                final categoryExists = _categories.any(
                  (category) => category.toLowerCase() == enteredName,
                );

                if (categoryExists) {
                  return 'Bu kategori zaten bulunuyor.';
                }

                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () {
                final formIsValid = formKey.currentState!.validate();

                if (!formIsValid) {
                  return;
                }

                Navigator.pop(dialogContext, categoryController.text.trim());
              },
              child: const Text('Ekle'),
            ),
          ],
        );
      },
    );

    categoryController.dispose();

    if (categoryName == null || !mounted) {
      return;
    }

    setState(() {
      _categories = [..._categories, categoryName];
    });
    await _persistCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menüyü Yönet'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? const _EmptyMenuView()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _categories.length,
                  separatorBuilder: (context, index) {
                    return const SizedBox(height: 8);
                  },
                  itemBuilder: (context, index) {
                    final category = _categories[index];

                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.restaurant_menu),
                        ),
                        title: Text(
                          category,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text('Henüz ürün yok'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          debugPrint('$category kategorisi açıldı.');
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCategoryDialog,
        icon: const Icon(Icons.add),
        label: const Text('Kategori Ekle'),
      ),
    );
  }
}

class _EmptyMenuView extends StatelessWidget {
  const _EmptyMenuView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Henüz menü kategorisi yok',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Ürün eklemek için önce bir kategori oluştur.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
