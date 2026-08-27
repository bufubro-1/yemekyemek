class RestaurantMenuItem {
  const RestaurantMenuItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    required this.isAvailable,
    required this.sortOrder,
    this.createdAt,
  });

  final String id;
  final String categoryId;
  final String name;
  final String description;
  final double price;
  final bool isAvailable;
  final int sortOrder;
  final DateTime? createdAt;

  factory RestaurantMenuItem.fromJson(
    Map<String, dynamic> json,
  ) {
    return RestaurantMenuItem(
      id: json['id']?.toString() ?? '',
      categoryId: (json['categoryId'] ?? json['category_id'])?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: _readDouble(json['price']),
      isAvailable: json['isAvailable'] ?? json['is_available'] ?? true,
      sortOrder: _readInt(
        json['sortOrder'] ?? json['sort_order'],
      ),
      createdAt: _readDateTime(
        json['createdAt'] ?? json['created_at'],
      ),
    );
  }
}

double _readDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _readInt(dynamic value) {
  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _readDateTime(dynamic value) {
  if (value == null) {
    return null;
  }

  return DateTime.tryParse(value.toString());
}
