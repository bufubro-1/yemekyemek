import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/restaurant.dart';
import '../../repositories/repository_provider.dart';
import '../../repositories/restaurant_repository.dart';
import '../../services/session_controller.dart';

/// Restoran bilgilerini oluşturma/düzenleme formu. Görünüm orijinal
/// qr_restaurant_app'teki RestaurantFormPage ile aynıdır.
///
/// Bug fix: eskiden bu form kaydı sadece debugPrint + SnackBar ile
/// "simüle ediyordu", hiçbir yerde saklanmıyordu ve panel hep "Henüz
/// restoran eklenmedi" gösteriyordu. Artık RestaurantRepository üzerinden
/// gerçekten kaydediliyor.
class RestaurantFormScreen extends StatefulWidget {
  final Restaurant? existing;

  const RestaurantFormScreen({super.key, this.existing});

  @override
  State<RestaurantFormScreen> createState() {
    return _RestaurantFormScreenState();
  }
}

class _RestaurantFormScreenState extends State<RestaurantFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final _nameController =
      TextEditingController(text: widget.existing?.name);
  late final _descriptionController =
      TextEditingController(text: widget.existing?.description);
  late final _phoneController =
      TextEditingController(text: widget.existing?.phone);
  late final _addressController =
      TextEditingController(text: widget.existing?.address);

  final RestaurantRepository _restaurantRepository =
      RepositoryProvider.restaurant;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String _normalizeTurkishPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');

    if (digits.length == 11 && digits.startsWith('0')) {
      return '+90${digits.substring(1)}';
    }

    if (digits.length == 10) {
      return '+90$digits';
    }

    return phone;
  }

  Future<void> _saveRestaurant() async {
    final formIsValid = _formKey.currentState!.validate();

    if (!formIsValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen hatalı veya eksik alanları düzelt.'),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    final userId = SessionController.instance.currentUser?.id;
    if (userId == null) return;

    final restaurantName = _nameController.text.trim();
    final restaurantDescription = _descriptionController.text.trim();
    final restaurantPhone = _normalizeTurkishPhone(
      _phoneController.text.trim(),
    );
    final restaurantAddress = _addressController.text.trim();

    setState(() => _isSaving = true);

    final restaurant = Restaurant(
      ownerUserId: userId,
      name: restaurantName,
      description: restaurantDescription,
      phone: restaurantPhone,
      address: restaurantAddress,
      menuCategories: widget.existing?.menuCategories ?? [],
    );

    await _restaurantRepository.saveRestaurant(restaurant);

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$restaurantName kaydedildi.'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restoran Bilgileri'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Restoranını oluştur',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Önce restoranın temel bilgilerini girelim.'),

                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Restoran adı',
                      hintText: 'Örneğin YemekYemek Cafe',
                      prefixIcon: Icon(Icons.restaurant),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Restoran adı boş bırakılamaz.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Restoran açıklaması',
                      hintText: 'Restoranını kısaca tanıt.',
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),

                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    maxLength: 11,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Telefon numarası',
                      hintText: '0XXX XXX XX XX',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Telefon numarası boş bırakılamaz.';
                      }

                      final phone = value.trim();

                      final phonePattern = RegExp(
                        r'^(?:[2-5]\d{9}|0[2-5]\d{9})$',
                      );

                      if (!phonePattern.hasMatch(phone)) {
                        return 'Geçerli bir Türkiye telefon numarası gir.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Adres',
                      hintText: 'Mahalle, cadde, sokak ve bina bilgileri',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Adres boş bırakılamaz.';
                      }

                      if (value.trim().length < 10) {
                        return 'Biraz daha ayrıntılı bir adres gir.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _saveRestaurant,
                    icon: _isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Restoranı Kaydet'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
