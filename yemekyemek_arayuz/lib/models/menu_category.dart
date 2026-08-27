class MenuCategory {
  const MenuCategory({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.itemCount,
  });

  final String id;
  final String name;
  final int sortOrder;
  final int itemCount;

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    return MenuCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      sortOrder: _readInt(
        json['sortOrder'] ?? json['sort_order'],
      ),
      itemCount: _readInt(
        json['itemCount'] ?? json['item_count'],
      ),
    );
  }
}

int _readInt(dynamic value) {
  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}
