import 'package:flutter/material.dart';
import 'screens/restaurant_form.dart';
import 'screens/menu.dart';

void main() {
  runApp(const RestaurantApp());
}

class RestaurantApp extends StatelessWidget {
  const RestaurantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QR Restoran',
      theme: ThemeData(colorSchemeSeed: Colors.deepOrange, useMaterial3: true),
      home: const RestaurantPanelPage(),
    );
  }
}

class RestaurantPanelPage extends StatelessWidget {
  const RestaurantPanelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restoran Paneli'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Restoranım',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Card(
              child: ListTile(
                leading: CircleAvatar(child: Icon(Icons.restaurant)),
                title: Text('Henüz restoran eklenmedi'),
                subtitle: Text(
                  'Restoran bilgilerini ekleyerek başlayabilirsin.',
                ),
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RestaurantFormPage(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Restoran Bilgilerini Ekle'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MenuPage()),
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
