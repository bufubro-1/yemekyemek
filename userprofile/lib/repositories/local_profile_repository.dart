import '../models/app_user.dart';
import '../models/user_profile.dart';
import '../services/local_file_store.dart';
import 'profile_repository.dart';

/// Profil verilerini cihaz üzerindeki profiles.txt dosyasında JSON olarak
/// tutan repository. Şu anki (prototip) implementasyon budur.
class LocalProfileRepository implements ProfileRepository {
  final LocalFileStore _store = LocalFileStore.instance;

  @override
  Future<UserProfile> createEmptyProfileFor(AppUser user) async {
    final rawProfiles = await _store.readList(LocalFileNames.profiles);
    final profiles = rawProfiles
        .map((e) => UserProfile.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final newProfile = UserProfile.empty(userId: user.id);

    profiles.add(newProfile);
    await _store.writeList(
      LocalFileNames.profiles,
      profiles.map((p) => p.toJson()).toList(),
    );
    return newProfile;
  }

  @override
  Future<UserProfile?> getProfile(String userId) async {
    final rawProfiles = await _store.readList(LocalFileNames.profiles);
    final profiles = rawProfiles
        .map((e) => UserProfile.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final match = profiles.where((p) => p.userId == userId).toList();
    if (match.isEmpty) return null;
    return match.first;
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    final rawProfiles = await _store.readList(LocalFileNames.profiles);
    final profiles = rawProfiles
        .map((e) => UserProfile.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final index = profiles.indexWhere((p) => p.userId == profile.userId);
    if (index == -1) {
      profiles.add(profile);
    } else {
      profiles[index] = profile;
    }

    await _store.writeList(
      LocalFileNames.profiles,
      profiles.map((p) => p.toJson()).toList(),
    );
  }
}
