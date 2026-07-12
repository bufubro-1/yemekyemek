import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/repository_provider.dart';
import '../../services/session_controller.dart';
import '../../utils/app_theme.dart';
import 'editable_list_screen.dart';
import 'lists_overview_screen.dart';
import 'widgets/profile_section_tile.dart';
import 'widgets/rating_badge.dart';

/// Paylaşılan wireframe'in (PROFİL - 1) kodlanmış, editlenebilir hali.
///
/// Görünen isim + nickname AppUser (session) üzerinden, diğer tüm profil
/// verileri (bio, tercihler, listeler) UserProfile (profiles.txt) üzerinden
/// okunur/yazılır.
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

  /// "Profili düzenle": görünen isim (username, AppUser'da tutulur) ve
  /// bio (UserProfile'da tutulur) birlikte düzenlenir.
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
        // ChangeNotifier üzerinden tüm ekranlar (örn. ana sayfa) otomatik
        // güncellenir.
        SessionController.instance.updateUsername(newUsername);
      }
    }

    setState(() => _profile!.bio = newBio);
    await _saveProfile();
  }

  String _summaryOf(List<String> items) {
    if (items.isEmpty) return 'Henüz eklenmedi';
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
                                  color: AppColors.textSecondary,
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
                          fontSize: 13.5,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    ProfileSectionTile(
                      title: 'Diyet Tercihleri',
                      subtitle: _summaryOf(profile.dietPreferences),
                      onTap: () => _openEditableSection(
                        title: 'Diyet Tercihleri',
                        hint: 'Örn: Vegan, gluten free...',
                        items: profile.dietPreferences,
                        onUpdated: (v) => profile.dietPreferences = v,
                      ),
                    ),
                    ProfileSectionTile(
                      title: 'Alerjiler',
                      subtitle: _summaryOf(profile.allergies),
                      onTap: () => _openEditableSection(
                        title: 'Alerjiler',
                        hint: 'Örn: Fıstık, çilek...',
                        items: profile.allergies,
                        onUpdated: (v) => profile.allergies = v,
                      ),
                    ),
                    ProfileSectionTile(
                      title: 'Geçmiş Siparişlerim',
                      subtitle: _summaryOf(profile.pastOrders),
                      onTap: () => _openEditableSection(
                        title: 'Geçmiş Siparişlerim',
                        hint: '',
                        items: profile.pastOrders,
                        editable: false,
                        onUpdated: (v) => profile.pastOrders = v,
                      ),
                    ),
                    ProfileSectionTile(
                      title: 'Listelerim',
                      subtitle:
                          'Favoriler: ${profile.favoriteRestaurants.length}, '
                          'EatList: ${profile.eatListRestaurants.length}',
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ListsOverviewScreen(
                              profile: profile,
                              onChanged: _saveProfile,
                            ),
                          ),
                        );
                        setState(() {});
                      },
                    ),
                    ProfileSectionTile(
                      title: 'Yorumlarım',
                      subtitle: _summaryOf(profile.comments),
                      onTap: () => _openEditableSection(
                        title: 'Yorumlarım',
                        hint: '',
                        items: profile.comments,
                        editable: false,
                        onUpdated: (v) => profile.comments = v,
                      ),
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

class _Avatar extends StatelessWidget {
  final UserProfile profile;
  const _Avatar({required this.profile});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 34,
      backgroundColor: Colors.black,
      backgroundImage: profile.avatarLocalPath != null
          ? FileImage(File(profile.avatarLocalPath!))
          : null,
      child: profile.avatarLocalPath == null
          ? const Icon(Icons.person, color: Colors.white, size: 34)
          : null,
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
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(
          '$count',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
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
            icon: const Icon(Icons.home_outlined),
          ),
          const IconButton(
            onPressed: null,
            icon: Icon(Icons.search, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
