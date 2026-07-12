import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../repositories/auth_repository.dart';
import '../repositories/repository_provider.dart';

/// Basit bir ChangeNotifier tabanlı oturum yöneticisi. Uygulama küçük
/// olduğu için ağır bir state-management paketine ihtiyaç yok; ileride
/// Provider/Riverpod/Bloc'a geçiş kolayca yapılabilir çünkü tüm iş mantığı
/// zaten repository katmanında.
class SessionController extends ChangeNotifier {
  SessionController._internal();
  static final SessionController instance = SessionController._internal();

  final AuthRepository _authRepository = RepositoryProvider.auth;

  AppUser? currentUser;
  bool isInitializing = true;

  Future<void> restoreSession() async {
    isInitializing = true;
    notifyListeners();
    currentUser = await _authRepository.getSavedSession();
    isInitializing = false;
    notifyListeners();
  }

  void setUser(AppUser user) {
    currentUser = user;
    notifyListeners();
  }

  /// Görünen isim değiştiğinde çağrılır; SessionController bir
  /// ChangeNotifier olduğu için bunu dinleyen tüm ekranlar (örn. ana sayfa)
  /// otomatik olarak güncellenir.
  void updateUsername(String newUsername) {
    if (currentUser == null) return;
    currentUser = currentUser!.copyWith(username: newUsername);
    notifyListeners();
  }

  Future<void> logout() async {
    await _authRepository.logout();
    currentUser = null;
    notifyListeners();
  }
}
