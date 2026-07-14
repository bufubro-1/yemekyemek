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
  static String userProfile(String userId) =>
      '/users/${Uri.encodeComponent(userId)}/profile';
  static String dietPreferences(String userId) =>
      '/users/${Uri.encodeComponent(userId)}/diet-preferences';
  static String allergies(String userId) =>
      '/users/${Uri.encodeComponent(userId)}/allergies';
  static String pastOrders(String userId) =>
      '/users/${Uri.encodeComponent(userId)}/orders';
  static String lists(String userId) =>
      '/users/${Uri.encodeComponent(userId)}/lists';
  static String comments(String userId) =>
      '/users/${Uri.encodeComponent(userId)}/comments';
  static String followers(String userId) =>
      '/users/${Uri.encodeComponent(userId)}/followers';
  static String following(String userId) =>
      '/users/${Uri.encodeComponent(userId)}/following';
  static String avatarUpload(String userId) =>
      '/users/${Uri.encodeComponent(userId)}/avatar';

  // ---------------- RESTAURANT ----------------
  static String restaurant(String ownerUserId) =>
      '/restaurants/owner/${Uri.encodeComponent(ownerUserId)}';
  static String restaurantMenu(String ownerUserId) =>
      '/restaurants/owner/${Uri.encodeComponent(ownerUserId)}/menu';
}
