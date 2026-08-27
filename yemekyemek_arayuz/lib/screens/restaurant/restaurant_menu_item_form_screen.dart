import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/menu_category.dart';
import '../../models/restaurant_menu_item.dart';
import '../../repositories/repository_provider.dart';
import '../../repositories/restaurant_repository.dart';
import '../../services/api_client.dart';

class RestaurantMenuItemFormScreen extends StatefulWidget {
  const RestaurantMenuItemFormScreen({
    required this.ownerUserId,
    required this.category,
    this.existing,
    super.key,
  });

  final String ownerUserId;
  final MenuCategory category;
  final RestaurantMenuItem? existing;

  @override
  State<RestaurantMenuItemFormScreen> createState() =>
      _RestaurantMenuItemFormScreenState();
}

class _RestaurantMenuItemFormScreenState
    extends State<RestaurantMenuItemFormScreen> {
  final RestaurantRepository _restaurantRepository =
      RepositoryProvider.restaurant;

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;

  late bool _isAvailable;
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();

    final existing = widget.existing;

    _nameController = TextEditingController(
      text: existing?.name ?? '',
    );
    _descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    _priceController = TextEditingController(
      text: existing == null
          ? ''
          : existing.price.toStringAsFixed(2).replaceAll('.', ','),
    );
    _isAvailable = existing?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  double? _parsePrice(String value) {
    final normalizedValue =
        value.trim().replaceAll(' ', '').replaceAll(',', '.');

    return double.tryParse(normalizedValue);
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final price = _parsePrice(_priceController.text);

    if (price == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final existing = widget.existing;

      if (existing == null) {
        await _restaurantRepository.createMenuItem(
          widget.ownerUserId,
          widget.category.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: price,
          isAvailable: _isAvailable,
        );
      } else {
        await _restaurantRepository.updateMenuItem(
          widget.ownerUserId,
          existing.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: price,
          isAvailable: _isAvailable,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Ürün güncellendi.' : 'Ürün menüye eklendi.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _errorMessage(error),
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _errorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    if (error is UnsupportedError) {
      return error.message?.toString() ?? 'Bu işlem kullanılamıyor.';
    }

    return _isEditing ? 'Ürün güncellenemedi.' : 'Ürün eklenemedi.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Ürünü Düzenle' : 'Ürün Ekle',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildCategoryHeader(context),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                enabled: !_isSaving,
                autofocus: !_isEditing,
                textCapitalization: TextCapitalization.words,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Ürün adı',
                  hintText: 'Örneğin Mercimek Çorbası',
                  prefixIcon: Icon(Icons.fastfood_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final name = value?.trim() ?? '';

                  if (name.isEmpty) {
                    return 'Ürün adı boş bırakılamaz.';
                  }

                  if (name.length > 120) {
                    return 'Ürün adı en fazla 120 karakter olabilir.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                enabled: !_isSaving,
                textCapitalization: TextCapitalization.sentences,
                minLines: 3,
                maxLines: 5,
                maxLength: 5000,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  hintText: 'Ürünün içeriği veya kısa açıklaması',
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                enabled: !_isSaving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[0-9,.]'),
                  ),
                ],
                decoration: const InputDecoration(
                  labelText: 'Fiyat',
                  hintText: '0,00',
                  prefixIcon: Icon(Icons.payments_outlined),
                  suffixText: '₺',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final trimmedValue = value?.trim() ?? '';

                  if (trimmedValue.isEmpty) {
                    return 'Fiyat boş bırakılamaz.';
                  }

                  final price = _parsePrice(trimmedValue);

                  if (price == null) {
                    return 'Geçerli bir fiyat gir.';
                  }

                  if (price < 0) {
                    return 'Fiyat sıfırdan küçük olamaz.';
                  }

                  if (price > 99999999.99) {
                    return 'Girilen fiyat çok yüksek.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              Card(
                child: SwitchListTile(
                  value: _isAvailable,
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          setState(() {
                            _isAvailable = value;
                          });
                        },
                  secondary: Icon(
                    _isAvailable
                        ? Icons.check_circle_outline
                        : Icons.remove_circle_outline,
                  ),
                  title: const Text('Satışta'),
                  subtitle: Text(
                    _isAvailable
                        ? 'Ürün müşterilere gösterilecek.'
                        : 'Ürün geçici olarak satış dışı.',
                  ),
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _isSaving ? null : _saveItem,
                icon: _isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        _isEditing ? Icons.save_outlined : Icons.add,
                      ),
                label: Text(
                  _isSaving
                      ? 'Kaydediliyor...'
                      : _isEditing
                          ? 'Değişiklikleri Kaydet'
                          : 'Ürünü Ekle',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.restaurant_menu,
              color: colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kategori',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.category.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
