import 'package:flutter/material.dart';

import '../../services/session_controller.dart';
import '../../utils/app_theme.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';

/// Bu ekran şimdilik bir YER TUTUCUDUR (placeholder).
/// İleride keşfet/akış/restoran listeleri gibi asıl ana sayfa içeriği
/// buraya eklenecektir. Şu an odak noktası kullanıcı profili ekranıdır.
///
/// SessionController'ı dinler (ListenableBuilder), böylece profilde
/// kullanıcı adı değiştirildiğinde bu ekran otomatik güncellenir.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SessionController.instance,
      builder: (context, _) {
        final user = SessionController.instance.currentUser;

        return Scaffold(
          appBar: AppBar(
            title: const Text('YemekYemek?'),
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
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.restaurant_menu,
                      size: 64, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Hoş geldin${user != null ? ', ${user.username}' : ''}!',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Bu bir placeholder ana sayfadır.',
                      style: TextStyle(fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ProfileScreen()),
                      );
                    },
                    icon: const Icon(Icons.person),
                    label: const Text('Profilime Git'),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: BottomAppBar(
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const IconButton(
                  icon: Icon(Icons.home, color: AppColors.primary),
                  onPressed: null,
                ),
                const IconButton(
                  icon: Icon(Icons.search, color: AppColors.textSecondary),
                  onPressed: null,
                ),
                IconButton(
                  icon: const Icon(Icons.person_outline,
                      color: AppColors.textSecondary),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const ProfileScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
