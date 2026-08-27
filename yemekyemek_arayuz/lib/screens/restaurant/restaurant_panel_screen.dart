import 'package:flutter/material.dart';

import '../../models/restaurant.dart';
import '../../repositories/repository_provider.dart';
import '../../repositories/restaurant_repository.dart';
import '../../services/session_controller.dart';
import '../auth/login_screen.dart';
import 'restaurant_form_screen.dart';
import 'restaurant_menu_screen.dart';

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
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadRestaurant();
  }

  Future<void> _loadRestaurant() async {
    final userId = SessionController.instance.currentUser?.id;

    if (userId == null) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _loadError = 'Oturum bilgisi bulunamadı.';
      });
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final restaurant = await _restaurantRepository.getRestaurant(userId);

      if (!mounted) return;

      setState(() {
        _restaurant = restaurant;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _loadError = 'Restoran bilgileri yüklenemedi.';
      });
    }
  }

  Future<void> _openRestaurantForm() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => RestaurantFormScreen(
          existing: _restaurant,
        ),
      ),
    );

    if (saved == true) {
      await _loadRestaurant();
    }
  }

  Future<void> _openMenu() async {
    if (_restaurant == null) {
      return;
    }

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => const RestaurantMenuScreen(),
      ),
    );

    await _loadRestaurant();
  }

  Future<void> _logout() async {
    await SessionController.instance.logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  String _displayPhone(String phone) {
    if (phone.startsWith('+90')) {
      return '0${phone.substring(3)}';
    }

    return phone;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restoranım'),
        actions: [
          IconButton(
            tooltip: 'Çıkış yap',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_loadError != null) {
      return _buildErrorState();
    }

    final restaurant = _restaurant;

    if (restaurant == null) {
      return _buildEmptyState();
    }

    return _buildRestaurantProfile(restaurant);
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loadRestaurant,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 52,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                Icons.storefront_outlined,
                size: 52,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Restoran profilini oluşturalım',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Menünü yönetebilmek ve müşterilere görünmek için '
              'önce restoran bilgilerini eklemelisin.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _openRestaurantForm,
              icon: const Icon(Icons.add_business),
              label: const Text('Restoran Profili Oluştur'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantProfile(Restaurant restaurant) {
    return RefreshIndicator(
      onRefresh: _loadRestaurant,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          _buildProfileHeader(restaurant),
          const SizedBox(height: 16),
          _buildActionButtons(),
          const SizedBox(height: 28),
          _buildSectionTitle(
            icon: Icons.info_outline,
            title: 'Restoran Bilgileri',
          ),
          const SizedBox(height: 10),
          _buildInformationCard(restaurant),
          const SizedBox(height: 28),
          _buildSectionTitle(
            icon: Icons.menu_book_outlined,
            title: 'Menü Özeti',
          ),
          const SizedBox(height: 10),
          _buildMenuSummary(restaurant),
          const SizedBox(height: 28),
          _buildSectionTitle(
            icon: Icons.visibility_outlined,
            title: 'Müşteri Görünümü',
          ),
          const SizedBox(height: 10),
          _buildCustomerPreview(restaurant),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(Restaurant restaurant) {
    final colorScheme = Theme.of(context).colorScheme;
    final description = restaurant.description.trim();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 42,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                Icons.restaurant,
                size: 42,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              restaurant.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              description.isEmpty
                  ? 'Henüz restoran açıklaması eklenmedi.'
                  : description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            const Chip(
              avatar: Icon(
                Icons.check_circle_outline,
                size: 18,
              ),
              label: Text('Restoran profili'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final profileButton = FilledButton.icon(
          onPressed: _openRestaurantForm,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Profili Düzenle'),
        );

        final menuButton = OutlinedButton.icon(
          onPressed: _openMenu,
          icon: const Icon(Icons.restaurant_menu),
          label: const Text('Menüyü Yönet'),
        );

        if (constraints.maxWidth < 420) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              profileButton,
              const SizedBox(height: 10),
              menuButton,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: profileButton),
            const SizedBox(width: 12),
            Expanded(child: menuButton),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(icon, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildInformationCard(Restaurant restaurant) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _InformationRow(
              icon: Icons.phone_outlined,
              label: 'Telefon',
              value: _displayPhone(restaurant.phone),
            ),
            const Divider(height: 28),
            _InformationRow(
              icon: Icons.location_on_outlined,
              label: 'Adres',
              value: restaurant.address,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSummary(Restaurant restaurant) {
    final categories = restaurant.menuCategories;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.secondaryContainer,
                  child: Icon(
                    Icons.category_outlined,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    categories.isEmpty
                        ? 'Henüz kategori eklenmedi'
                        : '${categories.length} kategori bulunuyor',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            if (categories.isEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Menünü oluşturmaya kategori ekleyerek başlayabilirsin.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in categories.take(5))
                    Chip(label: Text(category)),
                  if (categories.length > 5)
                    Chip(
                      label: Text(
                        '+${categories.length - 5} kategori',
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _openMenu,
              icon: const Icon(Icons.arrow_forward),
              label: Text(
                categories.isEmpty
                    ? 'Menü Oluşturmaya Başla'
                    : 'Menüyü Görüntüle',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerPreview(Restaurant restaurant) {
    final colorScheme = Theme.of(context).colorScheme;
    final description = restaurant.description.trim();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: colorScheme.primaryContainer,
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.surface,
                  child: Icon(
                    Icons.storefront,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    restaurant.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description.isEmpty
                      ? 'Bu restoran henüz bir açıklama eklemedi.'
                      : description,
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(restaurant.address),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Paylaşımlar ve müşteri feed görünümü, ürün yönetimi '
                  'tamamlandıktan sonra bu bölüme eklenecek.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
