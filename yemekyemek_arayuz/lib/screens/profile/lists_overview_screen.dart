import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../utils/app_theme.dart';
import 'editable_list_screen.dart';

/// "Listelerim" bölümünün yeni hali: yan yana iki kutucuk
/// ("Favorilerim" ve "EatList"). Her kutucuk kendi restoran listesini
/// tutar ve ayrı ayrı düzenlenebilir.
class ListsOverviewScreen extends StatefulWidget {
  final UserProfile profile;
  final Future<void> Function() onChanged;

  const ListsOverviewScreen({
    super.key,
    required this.profile,
    required this.onChanged,
  });

  @override
  State<ListsOverviewScreen> createState() => _ListsOverviewScreenState();
}

class _ListsOverviewScreenState extends State<ListsOverviewScreen> {
  Future<void> _openFavorites() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditableListScreen(
          title: 'Favorilerim',
          hintText: 'Restoran adı ekle...',
          initialItems: widget.profile.favoriteRestaurants,
          onSave: (updated) async {
            setState(() => widget.profile.favoriteRestaurants = updated);
            await widget.onChanged();
          },
        ),
      ),
    );
    setState(() {});
  }

  Future<void> _openEatList() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditableListScreen(
          title: 'EatList',
          hintText: 'Gitmek istediğin restoranı ekle...',
          initialItems: widget.profile.eatListRestaurants,
          onSave: (updated) async {
            setState(() => widget.profile.eatListRestaurants = updated);
            await widget.onChanged();
          },
        ),
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Listelerim')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ListBox(
                  title: 'Favorilerim',
                  icon: Icons.favorite_outline,
                  items: widget.profile.favoriteRestaurants,
                  onTap: _openFavorites,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _ListBox(
                  title: 'EatList',
                  icon: Icons.bookmark_outline,
                  items: widget.profile.eatListRestaurants,
                  onTap: _openEatList,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListBox extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> items;
  final VoidCallback onTap;

  const _ListBox({
    required this.title,
    required this.icon,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.sectionBackground,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 220),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primary, size: 28),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${items.length} restoran',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const Text(
                  'Henüz eklenmedi',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                )
              else
                ...items.take(4).map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• $e',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
              if (items.length > 4)
                Text(
                  '+${items.length - 4} daha',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
