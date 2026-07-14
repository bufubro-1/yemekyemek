import '../models/app_user.dart';
import '../services/local_file_store.dart';
import '../utils/password_hasher.dart';
import 'auth_repository.dart';
import 'local_profile_repository.dart';
import 'profile_repository.dart';

/// Kullanıcı hesaplarını cihaz üzerindeki users.txt dosyasında JSON olarak
/// tutan repository. Şu anki (prototip) implementasyon budur.
class LocalAuthRepository implements AuthRepository {
  final LocalFileStore _store = LocalFileStore.instance;
  final ProfileRepository _profileRepository;

  LocalAuthRepository({ProfileRepository? profileRepository})
      : _profileRepository = profileRepository ?? LocalProfileRepository();

  Future<List<AppUser>> _readAllUsers() async {
    final rawUsers = await _store.readList(LocalFileNames.users);
    return rawUsers
        .map((e) => AppUser.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> _writeAllUsers(List<AppUser> users) async {
    await _store.writeList(
      LocalFileNames.users,
      users.map((u) => u.toLocalJson()).toList(),
    );
  }

  @override
  Future<AuthResult> register({
    required String nickname,
    required String username,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedNickname = nickname.trim().toLowerCase();
    final users = await _readAllUsers();

    final emailTaken =
        users.any((u) => u.email.toLowerCase() == normalizedEmail);
    if (emailTaken) {
      return AuthResult.failure('Bu e-posta adresiyle zaten bir hesap var.');
    }

    // Nickname eşsiz olmalıdır.
    final nicknameTaken =
        users.any((u) => u.nickname.toLowerCase() == normalizedNickname);
    if (nicknameTaken) {
      return AuthResult.failure('Bu nickname zaten kullanılıyor.');
    }

    final newUser = AppUser(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nickname: normalizedNickname,
      username: username.trim(),
      email: normalizedEmail,
      passwordHash: PasswordHasher.hash(password),
      createdAt: DateTime.now(),
      role: role,
    );

    users.add(newUser);
    await _writeAllUsers(users);

    // Yeni hesap için boş bir profil de otomatik oluşturulur.
    await _profileRepository.createEmptyProfileFor(newUser);

    await _saveSession(newUser);
    return AuthResult.success(newUser);
  }

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final users = await _readAllUsers();

    final match = users.where((u) => u.email == normalizedEmail).toList();
    if (match.isEmpty) {
      return AuthResult.failure('Bu e-posta ile kayıtlı bir hesap bulunamadı.');
    }

    final user = match.first;
    if (!PasswordHasher.verify(password, user.passwordHash)) {
      return AuthResult.failure('Şifre hatalı.');
    }

    await _saveSession(user);
    return AuthResult.success(user);
  }

  @override
  Future<void> logout() async {
    await _store.clearFile(LocalFileNames.session);
  }

  @override
  Future<AppUser?> getSavedSession() async {
    final map = await _store.readMap(LocalFileNames.session);
    if (map == null) return null;
    try {
      return AppUser.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AuthResult> updateUsername({
    required String userId,
    required String newUsername,
  }) async {
    final users = await _readAllUsers();
    final index = users.indexWhere((u) => u.id == userId);
    if (index == -1) {
      return AuthResult.failure('Kullanıcı bulunamadı.');
    }

    final updated = users[index].copyWith(username: newUsername.trim());
    users[index] = updated;
    await _writeAllUsers(users);

    // Aktif oturum bu kullanıcıya aitse session.txt da güncellenir.
    final session = await _store.readMap(LocalFileNames.session);
    if (session != null && session['id'] == userId) {
      await _saveSession(updated);
    }

    return AuthResult.success(updated);
  }

  Future<void> _saveSession(AppUser user) async {
    await _store.writeMap(LocalFileNames.session, user.toJson());
  }
}
