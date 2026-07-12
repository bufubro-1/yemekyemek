/// İleride bağlanılacak backend endpoint'lerinin tek merkezden yönetildiği
/// dosya. Şu an hiçbiri çağrılmıyor (useRemoteBackend = false), ancak
/// RemoteAuthRepository ve RemoteProfileRepository bu path'leri kullanmaya
/// hazır şekilde yazılmıştır.
class ApiEndpoints {
  ApiEndpoints._();

  // ---------------- AUTH ----------------
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String verifyToken = '/auth/verify-token';
  static const String refreshToken = '/auth/refresh-token';
  static const String googleSignIn = '/auth/google';
  static const String appleSignIn = '/auth/apple';

  // ---------------- PROFILE ----------------
  static String userProfile(String userId) => '/users/$userId/profile';
  static String dietPreferences(String userId) =>
      '/users/$userId/diet-preferences';
  static String allergies(String userId) => '/users/$userId/allergies';
  static String pastOrders(String userId) => '/users/$userId/orders';
  static String lists(String userId) => '/users/$userId/lists';
  static String comments(String userId) => '/users/$userId/comments';
  static String followers(String userId) => '/users/$userId/followers';
  static String following(String userId) => '/users/$userId/following';
  static String avatarUpload(String userId) => '/users/$userId/avatar';

  // ---------------- RESTAURANT ----------------
  static String restaurant(String ownerUserId) =>
      '/restaurants/owner/$ownerUserId';
  static String restaurantMenu(String ownerUserId) =>
      '/restaurants/owner/$ownerUserId/menu';
}
