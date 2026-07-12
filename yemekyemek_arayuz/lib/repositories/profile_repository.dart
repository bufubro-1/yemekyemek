import '../models/app_user.dart';
import '../models/user_profile.dart';

/// Profil verilerinin (diyet tercihleri, alerjiler, geçmiş siparişler,
/// listeler, yorumlar vb.) okunup yazılması için sözleşme.
abstract class ProfileRepository {
  /// Yeni kayıt olan kullanıcı için boş bir profil oluşturur.
  Future<UserProfile> createEmptyProfileFor(AppUser user);

  Future<UserProfile?> getProfile(String userId);

  Future<void> updateProfile(UserProfile profile);
}
