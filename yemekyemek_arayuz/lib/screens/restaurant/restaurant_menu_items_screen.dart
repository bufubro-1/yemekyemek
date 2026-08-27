import 'package:flutter/material.dart';

import '../../models/menu_category.dart';
import '../../models/restaurant_menu_item.dart';
import '../../repositories/repository_provider.dart';
import '../../repositories/restaurant_repository.dart';
import '../../services/api_client.dart';
import 'restaurant_menu_item_form_screen.dart';

class RestaurantMenuItemsScreen extends StatefulWidget {
  const RestaurantMenuItemsScreen({
    required this.ownerUserId,
    required this.category,
    super.key,
  });

  final String ownerUserId;
  final MenuCategory category;

  @override
  State<RestaurantMenuItemsScreen> createState() =>
      _RestaurantMenuItemsScreenState();
}

class _RestaurantMenuItemsScreenState extends State<RestaurantMenuItemsScreen> {
  final RestaurantRepository _restaurantRepository =
      RepositoryProvider.restaurant;

  List<RestaurantMenuItem> _items = [];
  final Set<String> _busyItemIds = {};

  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems({
    bool showLoading = true,
  }) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final items = await _restaurantRepository.getMenuItems(
        widget.ownerUserId,
        widget.category.id,
      );

      if (!mounted) return;

      setState(() {
        _items = items;
        _isLoading = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;

      final message = _errorMessage(
        error,
        fallback: 'Menü ürünleri yüklenemedi.',
      );

      if (showLoading) {
        setState(() {
          _isLoading = false;
          _loadError = message;
        });
      } else {
        _showMessage(message);
      }
    }
  }

  Future<void> _openItemForm({
    RestaurantMenuItem? existing,
  }) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => RestaurantMenuItemFormScreen(
          ownerUserId: widget.ownerUserId,
          category: widget.category,
          existing: existing,
        ),
      ),
    );

    if (saved == true && mounted) {
      await _loadItems(showLoading: false);
    }
  }

  Future<void> _toggleAvailability(
    RestaurantMenuItem item,
    bool isAvailable,
  ) async {
    if (_busyItemIds.contains(item.id)) {
      return;
    }

    setState(() {
      _busyItemIds.add(item.id);
    });

    try {
      final updatedItem = await _restaurantRepository.updateMenuItem(
        widget.ownerUserId,
        item.id,
        isAvailable: isAvailable,
      );

      if (!mounted) return;

      setState(() {
        _items = _items.map((current) {
          return current.id == item.id ? updatedItem : current;
        }).toList();
      });
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        _errorMessage(
          error,
          fallback: 'Ürün durumu güncellenemedi.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyItemIds.remove(item.id);
        });
      }
    }
  }

  Future<void> _deleteItem(
    RestaurantMenuItem item,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Ürünü Sil'),
          content: Text(
            '"${item.name}" ürününü silmek istediğine '
            'emin misin? Bu işlem geri alınamaz.',
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

    if (shouldDelete != true || !mounted || _busyItemIds.contains(item.id)) {
      return;
    }

    setState(() {
      _busyItemIds.add(item.id);
    });

    try {
      await _restaurantRepository.deleteMenuItem(
        widget.ownerUserId,
        item.id,
      );

      if (!mounted) return;

      setState(() {
        _items = _items
            .where(
              (current) => current.id != item.id,
            )
            .toList();
      });

      _showMessage('${item.name} silindi.');
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        _errorMessage(
          error,
          fallback: 'Ürün silinemedi.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyItemIds.remove(item.id);
        });
      }
    }
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(2).replaceAll('.', ',');
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
        title: Text(widget.category.name),
      ),
      body: Column(
        children: [
          if (_busyItemIds.isNotEmpty) const LinearProgressIndicator(),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _openItemForm();
        },
        icon: const Icon(Icons.add),
        label: const Text('Ürün Ekle'),
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
      return _ItemsErrorView(
        message: _loadError!,
        onRetry: _loadItems,
      );
    }

    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () {
          return _loadItems(showLoading: false);
        },
        child: const _EmptyItemsView(),
      );
    }

    return RefreshIndicator(
      onRefresh: () {
        return _loadItems(showLoading: false);
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          96,
        ),
        itemCount: _items.length,
        separatorBuilder: (context, index) {
          return const SizedBox(height: 10);
        },
        itemBuilder: (context, index) {
          return _buildItemCard(_items[index]);
        },
      ),
    );
  }

  Widget _buildItemCard(
    RestaurantMenuItem item,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isBusy = _busyItemIds.contains(item.id);
    final hasDescription = item.description.trim().isNotEmpty;

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: item.isAvailable
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.fastfood_outlined,
                color: item.isAvailable
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            title: Text(
              item.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              hasDescription ? item.description : 'Açıklama eklenmedi.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: PopupMenuButton<_ItemAction>(
              enabled: !isBusy,
              onSelected: (action) {
                switch (action) {
                  case _ItemAction.edit:
                    _openItemForm(existing: item);
                  case _ItemAction.delete:
                    _deleteItem(item);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _ItemAction.edit,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Düzenle'),
                  ),
                ),
                PopupMenuItem(
                  value: _ItemAction.delete,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.delete_outline),
                    title: Text('Sil'),
                  ),
                ),
              ],
            ),
            onTap: isBusy
                ? null
                : () {
                    _openItemForm(existing: item);
                  },
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 8,
              top: 8,
              bottom: 8,
            ),
            child: Row(
              children: [
                Text(
                  '${_formatPrice(item.price)} ₺',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                ),
                const Spacer(),
                Text(
                  item.isAvailable ? 'Satışta' : 'Satış dışı',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: item.isAvailable
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                ),
                Switch(
                  value: item.isAvailable,
                  onChanged: isBusy
                      ? null
                      : (value) {
                          _toggleAvailability(
                            item,
                            value,
                          );
                        },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _ItemAction {
  edit,
  delete,
}

class _EmptyItemsView extends StatelessWidget {
  const _EmptyItemsView();

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
                Icons.fastfood_outlined,
                size: 80,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'Henüz ürün yok',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Bu kategoriye ilk ürünü ekleyebilirsin.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ItemsErrorView extends StatelessWidget {
  const _ItemsErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function({
    bool showLoading,
  }) onRetry;

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
              onPressed: () {
                onRetry();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}
