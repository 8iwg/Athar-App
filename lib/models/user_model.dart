class UserModel {
  final String id;
  final String email;
  final String username;
  final String nickname;
  final String? avatarUrl;
  final String region; // المنطقة
  final String city; // المدينة
  final DateTime createdAt;
  final String? bio;
  final int followersCount;
  final int followingCount;
  final int spotsCount;
  final DateTime? lastPostTime; // آخر وقت نشر بوست
  
  // معلومات تسجيل الدخول
  final AuthProviderType authProvider; // apple, google, email
  final bool isEmailVerified;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.nickname,
    this.avatarUrl,
    required this.region,
    required this.city,
    required this.createdAt,
    this.bio,
    this.followersCount = 0,
    this.followingCount = 0,
    this.spotsCount = 0,
    this.lastPostTime,
    required this.authProvider,
    this.isEmailVerified = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      nickname: json['nickname'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      region: json['region'] as String,
      city: json['city'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      bio: json['bio'] as String?,
      followersCount: json['followersCount'] as int? ?? 0,
      followingCount: json['followingCount'] as int? ?? 0,
      spotsCount: json['spotsCount'] as int? ?? 0,
      lastPostTime: json['lastPostTime'] != null ? DateTime.parse(json['lastPostTime'] as String) : null,
      authProvider: AuthProviderType.values.firstWhere(
        (e) => e.toString() == 'AuthProviderType.${json['authProvider']}',
        orElse: () => AuthProviderType.email,
      ),
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'nickname': nickname,
      'avatarUrl': avatarUrl,
      'region': region,
      'city': city,
      'createdAt': createdAt.toIso8601String(),
      'bio': bio,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'spotsCount': spotsCount,
      'lastPostTime': lastPostTime?.toIso8601String(),
      'authProvider': authProvider.toString().split('.').last,
      'isEmailVerified': isEmailVerified,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? username,
    String? nickname,
    String? avatarUrl,
    String? region,
    String? city,
    DateTime? createdAt,
    String? bio,
    int? followersCount,
    int? followingCount,
    int? spotsCount,
    AuthProviderType? authProvider,
    bool? isEmailVerified,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      region: region ?? this.region,
      city: city ?? this.city,
      createdAt: createdAt ?? this.createdAt,
      bio: bio ?? this.bio,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      spotsCount: spotsCount ?? this.spotsCount,
      authProvider: authProvider ?? this.authProvider,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }
}

enum AuthProviderType {
  apple,
  google,
  email,
}
