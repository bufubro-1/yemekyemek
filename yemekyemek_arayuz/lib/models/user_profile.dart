/// Profil ekranındaki (bkz. wireframe) tüm alanları temsil eden model.
/// profiles.txt dosyasında userId anahtarıyla JSON olarak saklanır.
///
/// NOT: Görünen isim (username) ve eşsiz nickname artık AppUser içinde
/// tutuluyor (bkz. models/app_user.dart); bu model yalnızca profile özgü
/// verileri (bio, tercihler, listeler vb.) içerir.
class UserProfile {
  final String userId;
  String? avatarLocalPath;

  /// Kullanıcının kendinden bahsettiği kısa biyografi. Karakter sınırı
  /// UI tarafında (bio_max_length) uygulanır.
  String bio;

  int followersCount;
  int followingCount;

  /// Profil derecelendirme rozeti (örn: "Gurme", "Yeni Üye")
  String ratingBadge;

  List<String> dietPreferences; // Vegan, gluten free, laktoz free vs.
  List<String> allergies; // Fıstık, çilek vs.
  List<String> pastOrders; // Geçmiş siparişler
  List<String> favoriteRestaurants; // Favorilerim kutucuğu
  List<String> eatListRestaurants; // EatList kutucuğu (gitmek istediklerim)
  List<String> comments; // Yorumlarım

  static const int bioMaxLength = 150;

  UserProfile({
    required this.userId,
    this.avatarLocalPath,
    this.bio = '',
    this.followersCount = 0,
    this.followingCount = 0,
    this.ratingBadge = 'Yeni Üye',
    List<String>? dietPreferences,
    List<String>? allergies,
    List<String>? pastOrders,
    List<String>? favoriteRestaurants,
    List<String>? eatListRestaurants,
    List<String>? comments,
  })  : dietPreferences = dietPreferences ?? [],
        allergies = allergies ?? [],
        pastOrders = pastOrders ?? [],
        favoriteRestaurants = favoriteRestaurants ?? [],
        eatListRestaurants = eatListRestaurants ?? [],
        comments = comments ?? [];

  /// Yeni bir hesap oluşturulduğunda oluşturulan varsayılan (boş) profil.
  factory UserProfile.empty({required String userId}) {
    return UserProfile(userId: userId);
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'avatarLocalPath': avatarLocalPath,
        'bio': bio,
        'followersCount': followersCount,
        'followingCount': followingCount,
        'ratingBadge': ratingBadge,
        'dietPreferences': dietPreferences,
        'allergies': allergies,
        'pastOrders': pastOrders,
        'favoriteRestaurants': favoriteRestaurants,
        'eatListRestaurants': eatListRestaurants,
        'comments': comments,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        userId: json['userId'] as String,
        avatarLocalPath: json['avatarLocalPath'] as String?,
        bio: json['bio'] as String? ?? '',
        followersCount: json['followersCount'] as int? ?? 0,
        followingCount: json['followingCount'] as int? ?? 0,
        ratingBadge: json['ratingBadge'] as String? ?? 'Yeni Üye',
        dietPreferences: (json['dietPreferences'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        allergies:
            (json['allergies'] as List?)?.map((e) => e.toString()).toList() ??
                [],
        pastOrders: (json['pastOrders'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        favoriteRestaurants: (json['favoriteRestaurants'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            // Eski "lists" alanından göç (varsa) - geriye dönük uyumluluk
            (json['lists'] as List?)?.map((e) => e.toString()).toList() ??
            [],
        eatListRestaurants: (json['eatListRestaurants'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        comments: (json['comments'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}
