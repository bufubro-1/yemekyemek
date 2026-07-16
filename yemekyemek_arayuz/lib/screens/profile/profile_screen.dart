import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart'; 
 
import '../../models/user_profile.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/repository_provider.dart';
import '../../services/session_controller.dart';
import '../../utils/app_theme.dart';
import 'editable_list_screen.dart';
import 'widgets/rating_badge.dart';

/// Paylaşılan wireframe'in (PROFİL - 1) kodlanmış, editlenebilir hali.
/// Güncellenmiş Düz Tasarım (Flat Design) ve Yan Yana Önizlemeli Kart yapısını içerir.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileRepository _profileRepository = RepositoryProvider.profile;
  final AuthRepository _authRepository = RepositoryProvider.auth;

  UserProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userId = SessionController.instance.currentUser?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    final profile = await _profileRepository.getProfile(userId);
    setState(() {
      _profile = profile;
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    if (_profile == null) return;
    await _profileRepository.updateProfile(_profile!);
  }

  Future<void> _openEditableSection({
    required String title,
    required String hint,
    required List<String> items,
    required void Function(List<String>) onUpdated,
    bool editable = true,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditableListScreen(
          title: title,
          hintText: hint,
          initialItems: items,
          editable: editable,
          onSave: (updated) async {
            setState(() => onUpdated(updated));
            await _saveProfile();
          },
        ),
      ),
    );
  }

  Future<void> _editProfileDialog() async {
    final currentUser = SessionController.instance.currentUser;
    if (currentUser == null || _profile == null) return;

    final nameController = TextEditingController(text: currentUser.username);
    final bioController = TextEditingController(text: _profile!.bio);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profili düzenle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Kullanıcı adı (görünen isim)',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bioController,
                maxLength: UserProfile.bioMaxLength,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Biyografi',
                  hintText: 'Kendinden kısaca bahset...',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final newUsername = nameController.text.trim();
    final newBio = bioController.text.trim();

    if (newUsername.isNotEmpty && newUsername != currentUser.username) {
      final authResult = await _authRepository.updateUsername(
        userId: currentUser.id,
        newUsername: newUsername,
      );
      if (authResult.success) {
        SessionController.instance.updateUsername(newUsername);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authResult.errorMessage ?? 'Kullanıcı adı güncellenemedi.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    setState(() => _profile!.bio = newBio);
    await _saveProfile();
  }

  String _summaryOf(List<String> items) {
    if (items.isEmpty) return ''; 
    return items.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = SessionController.instance.currentUser;
    final profile = _profile;

    if (user == null || profile == null) {
      return const Scaffold(
        body: Center(child: Text('Profil bulunamadı.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.chevron_left),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Profili düzenle',
                          onPressed: _editProfileDialog,
                          icon: const Icon(Icons.edit_outlined),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Avatar(profile: profile),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.username,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '@${user.nickname}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _CountColumn(
                                    label: 'Takipçiler',
                                    count: profile.followersCount,
                                  ),
                                  const SizedBox(width: 24),
                                  _CountColumn(
                                    label: 'Takip',
                                    count: profile.followingCount,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        RatingBadge(badgeLabel: profile.ratingBadge),
                      ],
                    ),
                    if (profile.bio.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        profile.bio,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    _FlatSection(
                      title: 'Diyet Tercihleri',
                      content: _summaryOf(profile.dietPreferences),
                      onEdit: () => _openEditableSection(
                        title: 'Diyet Tercihleri',
                        hint: 'Örn: Vegan, gluten free...',
                        items: profile.dietPreferences,
                        onUpdated: (v) => profile.dietPreferences = v,
                      ),
                    ),
                    _FlatSection(
                      title: 'Alerjiler',
                      content: _summaryOf(profile.allergies),
                      onEdit: () => _openEditableSection(
                        title: 'Alerjiler',
                        hint: 'Örn: Fıstık, çilek...',
                        items: profile.allergies,
                        onUpdated: (v) => profile.allergies = v,
                      ),
                    ),
                    _FlatSection(
                      title: 'Geçmiş Siparişlerim',
                      content: _summaryOf(profile.pastOrders),
                      emptyText: 'Henüz sipariş vermedin.',
                      onEdit: null, // Yalnızca görüntüleme
                    ),
                    const SizedBox(height: 12),
                    
                    // Listelerim Sekmesi - Yan Yana Önizlemeli Kart Tasarımı
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _ListPreviewCard(
                            title: 'Favoriler',
                            icon: Icons.favorite,
                            iconColor: Colors.red,
                            items: profile.favoriteRestaurants,
                            onTap: () => _openEditableSection(
                              title: 'Favorilerim',
                              hint: 'Restoran adı ekle...',
                              items: profile.favoriteRestaurants,
                              onUpdated: (v) => profile.favoriteRestaurants = v,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: _ListPreviewCard(
                            title: 'Eatlist',
                            icon: Icons.restaurant,
                            iconColor: Colors.orange,
                            items: profile.eatListRestaurants,
                            onTap: () => _openEditableSection(
                              title: 'EatList',
                              hint: 'Gitmek istediğin restoranı ekle...',
                              items: profile.eatListRestaurants,
                              onUpdated: (v) => profile.eatListRestaurants = v,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    _FlatSection(
                      title: 'Yorumlarım',
                      content: _summaryOf(profile.comments),
                      emptyText: 'Henüz yorum yapmadın.',
                      onEdit: null, // Yalnızca görüntüleme
                    ),
                  ],
                ),
              ),
            ),
            const _BottomNavBar(),
          ],
        ),
      ),
    );
  }
}

// YENİ BİLEŞEN: Liste Elemanlarını İçinde Gösteren Kart
class _ListPreviewCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<String> items;
  final VoidCallback onTap;

  const _ListPreviewCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias, // Tıklama efektinin kart sınırlarından taşmasını önler
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${items.length} restoran',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              if (items.isEmpty)
                const Text(
                  '',
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey),
                )
              else ...[
                // İlk 4 elemanı listele
                ...items.take(4).map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 2.0),
                  child: Text(
                    '• $e',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                )),
                // 4'ten fazla varsa 3 nokta ekle
                if (items.length > 4)
                  const Text(
                    '...',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// YENİ BİLEŞEN: Düz ve sade görünüm (ProfileSectionTile yerine geçer)
class _FlatSection extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback? onEdit;
  final String emptyText; // Boş durumda gösterilecek özelleştirilebilir metin

  const _FlatSection({
    required this.title,
    required this.content,
    this.onEdit,
    this.emptyText = 'henüz eklenmedi',
  });

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = content.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit, size: 20.0, color: Colors.grey),
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          isEmpty ? emptyText : content,
          style: isEmpty
              ? const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                )
              : const TextStyle(fontSize: 14.0, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Divider(thickness: 1.0, color: Colors.grey.shade300),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final UserProfile profile;
  const _Avatar({required this.profile});

  @override
  Widget build(BuildContext context) {
    final hasLocalAvatar = !kIsWeb && profile.avatarLocalPath != null;

    return CircleAvatar(
      radius: 34,
      backgroundColor: Colors.black,
      backgroundImage:
          hasLocalAvatar ? FileImage(File(profile.avatarLocalPath!)) : null,
      child: hasLocalAvatar
          ? null
          : const Icon(Icons.person, color: Colors.white, size: 34),
    );
  }
}

class _CountColumn extends StatelessWidget {
  final String label;
  final int count;
  const _CountColumn({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '$count',
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            icon: const Icon(Icons.home_outlined,
                color: AppColors.textSecondary),
          ),
          const IconButton(
            onPressed: null,
            icon: Icon(Icons.search, color: AppColors.textSecondary),
          ),
          const IconButton(
            onPressed: null,
            icon: Icon(Icons.person, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}