import 'package:flutter/material.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() {
    return _MenuPageState();
  }
}

class _MenuPageState extends State<MenuPage> {
  final List<String> _categories = [];

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
      _categories.add(categoryName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menüyü Yönet'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: _categories.isEmpty
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
