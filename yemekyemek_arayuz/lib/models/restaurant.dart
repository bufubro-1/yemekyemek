/// Restoran paneli tarafında girilen restoran bilgilerini temsil eder.
/// restaurants.txt dosyasında [ownerUserId] anahtarıyla JSON olarak saklanır.
///
/// Not: [menuCategories] şu an sadece kategori adlarından oluşan basit bir
/// listedir (ürün seviyesi henüz UI'da yok, bkz. RestaurantMenuScreen).
class Restaurant {
  final String ownerUserId;
  String name;
  String description;
  String phone;
  String address;
  List<String> menuCategories;

  Restaurant({
    required this.ownerUserId,
    required this.name,
    this.description = '',
    required this.phone,
    required this.address,
    List<String>? menuCategories,
  }) : menuCategories = menuCategories ?? [];

  Map<String, dynamic> toJson() => {
        'ownerUserId': ownerUserId,
        'name': name,
        'description': description,
        'phone': phone,
        'address': address,
        'menuCategories': menuCategories,
      };

  factory Restaurant.fromJson(Map<String, dynamic> json) => Restaurant(
        ownerUserId: (json['ownerUserId'] ?? json['owner_user_id']).toString(),
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        address: json['address'] as String? ?? '',
        menuCategories:
            ((json['menuCategories'] ?? json['menu_categories']) as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [],
      );
}
