import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RestaurantFormPage extends StatefulWidget {
  const RestaurantFormPage({super.key});

  @override
  State<RestaurantFormPage> createState() {
    return _RestaurantFormPageState();
  }
}

class _RestaurantFormPageState extends State<RestaurantFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

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

  void _saveRestaurant() {
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

    final restaurantName = _nameController.text.trim();
    final restaurantDescription = _descriptionController.text.trim();

    final restaurantPhone = _normalizeTurkishPhone(
      _phoneController.text.trim(),
    );

    final restaurantAddress = _addressController.text.trim();

    debugPrint('Restoran adı: $restaurantName');
    debugPrint('Açıklama: $restaurantDescription');
    debugPrint('Telefon: $restaurantPhone');
    debugPrint('Adres: $restaurantAddress');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$restaurantName kaydedilmeye hazır.'),
        backgroundColor: Colors.green,
      ),
    );
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
                    onPressed: _saveRestaurant,
                    icon: const Icon(Icons.save),
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
