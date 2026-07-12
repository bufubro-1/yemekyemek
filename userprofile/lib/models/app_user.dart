/// Auth (hesap oluşturma/giriş) için kullanılan temel kullanıcı modeli.
/// Bu model users.txt dosyasında JSON formatında saklanır.
///
/// [nickname]  -> eşsizdir (iki kullanıcı aynı nickname'i alamaz), profilde
///                "@nickname" şeklinde gösterilir, ID sisteminin yerini alır.
/// [username]  -> görünen isimdir (Aybüke gibi), eşsiz OLMAK ZORUNDA DEĞİLDİR,
///                profilde büyük başlık olarak gösterilir ve kullanıcı
///                tarafından istediği zaman değiştirilebilir.
class AppUser {
  final String id;
  final String nickname;
  final String username;
  final String email;

  /// Şifrenin kendisi DEĞİL, hash'i saklanır (bkz: PasswordHasher).
  final String passwordHash;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.nickname,
    required this.username,
    required this.email,
    required this.passwordHash,
    required this.createdAt,
  });

  AppUser copyWith({String? username, String? nickname}) {
    return AppUser(
      id: id,
      nickname: nickname ?? this.nickname,
      username: username ?? this.username,
      email: email,
      passwordHash: passwordHash,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nickname': nickname,
        'username': username,
        'email': email,
        'passwordHash': passwordHash,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        nickname: json['nickname'] as String? ?? 'kullanici${json['id']}',
        username: json['username'] as String,
        email: json['email'] as String,
        passwordHash: json['passwordHash'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
