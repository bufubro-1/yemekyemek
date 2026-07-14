/// Kayıt sırasında seçilen hesap türü. Uygulamanın hangi ana ekrana
/// yönlendirileceğini belirler (bkz: SplashDecisionScreen, LoginScreen,
/// SignUpScreen).
enum UserRole {
  user,
  restaurantOwner;

  String toJson() => name;

  String toApiValue() {
    switch (this) {
      case UserRole.user:
        return 'user';
      case UserRole.restaurantOwner:
        return 'restaurant_owner';
    }
  }

  static UserRole fromJson(String? value) {
    if (value == 'restaurant_owner' || value == 'restaurantOwner') {
      return UserRole.restaurantOwner;
    }
    return UserRole.user;
  }
}

/// Auth (hesap oluşturma/giriş) için kullanılan temel kullanıcı modeli.
/// Bu model users.txt dosyasında JSON formatında saklanır.
///
/// [nickname]  -> eşsizdir (iki kullanıcı aynı nickname'i alamaz), profilde
///                "@nickname" şeklinde gösterilir, ID sisteminin yerini alır.
/// [username]  -> görünen isimdir (Aybüke gibi), eşsiz OLMAK ZORUNDA DEĞİLDİR,
///                profilde büyük başlık olarak gösterilir ve kullanıcı
///                tarafından istediği zaman değiştirilebilir.
/// [role]      -> normal kullanıcı mı yoksa restoran sahibi mi olduğunu
///                belirler; giriş/kayıt sonrası yönlendirme buna göre yapılır.
class AppUser {
  final String id;
  final String nickname;
  final String username;
  final String email;

  /// Şifrenin kendisi DEĞİL, hash'i saklanır (bkz: PasswordHasher).
  final String passwordHash;
  final DateTime createdAt;
  final UserRole role;

  AppUser({
    required this.id,
    required this.nickname,
    required this.username,
    required this.email,
    required this.passwordHash,
    required this.createdAt,
    this.role = UserRole.user,
  });

  AppUser copyWith({String? username, String? nickname, UserRole? role}) {
    return AppUser(
      id: id,
      nickname: nickname ?? this.nickname,
      username: username ?? this.username,
      email: email,
      passwordHash: passwordHash,
      createdAt: createdAt,
      role: role ?? this.role,
    );
  }

  /// UI/oturum serileştirmesi. Parola özeti bu çıktıya bilinçli olarak
  /// eklenmez; yalnızca yerel kullanıcı deposu [toLocalJson] kullanır.
  Map<String, dynamic> toJson() => {
        'id': id,
        'nickname': nickname,
        'username': username,
        'email': email,
        'createdAt': createdAt.toIso8601String(),
        'role': role.toJson(),
      };

  Map<String, dynamic> toLocalJson() => {
        ...toJson(),
        'passwordHash': passwordHash,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'].toString(),
        nickname:
            json['nickname'] as String? ?? 'kullanici${json['id'].toString()}',
        username: json['username'] as String? ?? '',
        email: json['email'] as String? ?? '',
        // Uzak API parola özetini hiçbir zaman döndürmez.
        passwordHash:
            (json['passwordHash'] ?? json['password_hash']) as String? ?? '',
        createdAt: DateTime.tryParse(
              (json['createdAt'] ?? json['created_at'])?.toString() ?? '',
            ) ??
            DateTime.fromMillisecondsSinceEpoch(0),
        // Eski kayıtlarda (birleştirme öncesi) 'role' alanı yoktu; bu
        // durumda geriye dönük uyumluluk için varsayılan 'user' kullanılır.
        role: UserRole.fromJson(json['role']?.toString()),
      );
}
