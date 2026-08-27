import 'package:flutter/material.dart';

import '../../models/menu_category.dart';
import '../../repositories/repository_provider.dart';
import '../../repositories/restaurant_repository.dart';
import '../../services/api_client.dart';
import '../../services/session_controller.dart';
import 'restaurant_menu_items_screen.dart';

class RestaurantMenuScreen extends StatefulWidget {
  const RestaurantMenuScreen({super.key});

  @override
  State<RestaurantMenuScreen> createState() => _RestaurantMenuScreenState();
}

class _RestaurantMenuScreenState extends State<RestaurantMenuScreen> {
  final RestaurantRepository _restaurantRepository =
      RepositoryProvider.restaurant;

  List<MenuCategory> _categories = [];
  bool _isLoading = true;
  bool _isMutating = false;
  String? _loadError;

  String? get _ownerUserId => SessionController.instance.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final ownerUserId = _ownerUserId;

    if (ownerUserId == null) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _loadError = 'Oturum bilgisi bulunamadı.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final categories =
          await _restaurantRepository.getMenuCategories(ownerUserId);

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _loadError = _errorMessage(
          error,
          fallback: 'Menü kategorileri yüklenemedi.',
        );
      });
    }
  }

  Future<void> _addCategory() async {
    final categoryName = await _showCategoryDialog();

    if (categoryName == null || !mounted) {
      return;
    }

    final ownerUserId = _ownerUserId;

    if (ownerUserId == null) {
      _showMessage('Oturum bilgisi bulunamadı.');
      return;
    }

    setState(() {
      _isMutating = true;
    });

    try {
      final category = await _restaurantRepository.createMenuCategory(
        ownerUserId,
        name: categoryName,
      );

      if (!mounted) return;

      setState(() {
        _categories = [..._categories, category]..sort(
            (first, second) => first.sortOrder.compareTo(second.sortOrder),
          );
      });

      _showMessage('$categoryName kategorisi eklendi.');
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        _errorMessage(
          error,
          fallback: 'Kategori eklenemedi.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isMutating = false;
        });
      }
    }
  }

  Future<void> _editCategory(
    MenuCategory category,
  ) async {
    final categoryName = await _showCategoryDialog(
      existing: category,
    );

    if (categoryName == null || categoryName == category.name || !mounted) {
      return;
    }

    final ownerUserId = _ownerUserId;

    if (ownerUserId == null) {
      _showMessage('Oturum bilgisi bulunamadı.');
      return;
    }

    setState(() {
      _isMutating = true;
    });

    try {
      final response = await _restaurantRepository.updateMenuCategory(
        ownerUserId,
        category.id,
        name: categoryName,
      );

      final updatedCategory = MenuCategory(
        id: response.id,
        name: response.name,
        sortOrder: response.sortOrder,
        itemCount: category.itemCount,
      );

      if (!mounted) return;

      setState(() {
        _categories = _categories.map((current) {
          return current.id == category.id ? updatedCategory : current;
        }).toList();
      });

      _showMessage('Kategori adı güncellendi.');
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        _errorMessage(
          error,
          fallback: 'Kategori güncellenemedi.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isMutating = false;
        });
      }
    }
  }

  Future<void> _deleteCategory(
    MenuCategory category,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Kategoriyi Sil'),
          content: Text(
            category.itemCount > 0
                ? '"${category.name}" kategorisini ve içindeki '
                    '${category.itemCount} ürünü silmek istediğine '
                    'emin misin? Bu işlem geri alınamaz.'
                : '"${category.name}" kategorisini silmek '
                    'istediğine emin misin?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    final ownerUserId = _ownerUserId;

    if (ownerUserId == null) {
      _showMessage('Oturum bilgisi bulunamadı.');
      return;
    }

    setState(() {
      _isMutating = true;
    });

    try {
      await _restaurantRepository.deleteMenuCategory(
        ownerUserId,
        category.id,
      );

      if (!mounted) return;

      setState(() {
        _categories = _categories
            .where(
              (current) => current.id != category.id,
            )
            .toList();
      });

      _showMessage('${category.name} kategorisi silindi.');
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        _errorMessage(
          error,
          fallback: 'Kategori silinemedi.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isMutating = false;
        });
      }
    }
  }

  Future<String?> _showCategoryDialog({
    MenuCategory? existing,
  }) async {
    final formKey = GlobalKey<FormState>();
    String enteredCategoryName = existing?.name ?? '';

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            existing == null ? 'Kategori Ekle' : 'Kategoriyi Düzenle',
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              initialValue: enteredCategoryName,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Kategori adı',
                hintText: 'Örneğin Ana Yemekler',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                enteredCategoryName = value;
              },
              validator: (value) {
                final trimmedName = value?.trim() ?? '';

                if (trimmedName.isEmpty) {
                  return 'Kategori adı boş bırakılamaz.';
                }

                final normalizedName = trimmedName.toLowerCase();

                final categoryExists = _categories.any(
                  (category) =>
                      category.id != existing?.id &&
                      category.name.toLowerCase() == normalizedName,
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
                if (!formKey.currentState!.validate()) {
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  enteredCategoryName.trim(),
                );
              },
              child: Text(
                existing == null ? 'Ekle' : 'Kaydet',
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openCategory(
    MenuCategory category,
  ) async {
    final ownerUserId = _ownerUserId;

    if (ownerUserId == null) {
      _showMessage('Oturum bilgisi bulunamadı.');
      return;
    }

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => RestaurantMenuItemsScreen(
          ownerUserId: ownerUserId,
          category: category,
        ),
      ),
    );

    if (mounted) {
      await _loadCategories();
    }
  }

  String _errorMessage(
    Object error, {
    required String fallback,
  }) {
    if (error is ApiException) {
      return error.message;
    }

    if (error is UnsupportedError) {
      return error.message?.toString() ?? fallback;
    }

    return fallback;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menüyü Yönet'),
      ),
      body: Column(
        children: [
          if (_isMutating) const LinearProgressIndicator(),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isMutating ? null : _addCategory,
        icon: const Icon(Icons.add),
        label: const Text('Kategori Ekle'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_loadError != null) {
      return _ErrorView(
        message: _loadError!,
        onRetry: _loadCategories,
      );
    }

    if (_categories.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadCategories,
        child: const _EmptyMenuView(),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCategories,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          96,
        ),
        itemCount: _categories.length,
        separatorBuilder: (context, index) {
          return const SizedBox(height: 8);
        },
        itemBuilder: (context, index) {
          final category = _categories[index];

          return Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Text(
                  '${category.itemCount}',
                ),
              ),
              title: Text(
                category.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                category.itemCount == 0
                    ? 'Henüz ürün yok'
                    : '${category.itemCount} ürün',
              ),
              onTap: _isMutating
                  ? null
                  : () {
                      _openCategory(category);
                    },
              trailing: PopupMenuButton<_CategoryAction>(
                enabled: !_isMutating,
                onSelected: (action) {
                  switch (action) {
                    case _CategoryAction.edit:
                      _editCategory(category);
                    case _CategoryAction.delete:
                      _deleteCategory(category);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _CategoryAction.edit,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Düzenle'),
                    ),
                  ),
                  PopupMenuItem(
                    value: _CategoryAction.delete,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.delete_outline),
                      title: Text('Sil'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

enum _CategoryAction {
  edit,
  delete,
}

class _EmptyMenuView extends StatelessWidget {
  const _EmptyMenuView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.55,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.menu_book_outlined,
                size: 80,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'Henüz menü kategorisi yok',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Ürün eklemek için önce bir kategori oluştur.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}
