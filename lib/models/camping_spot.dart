class CampingSpot {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final List<String> imageUrls;
  final String userId;
  final String userName;
  final DateTime createdAt;
  final int likes;
  final List<String> likedBy;
  final double rating; // التقييم من 5
  final List<String> pros; // الإيجابيات
  final List<String> cons; // السلبيات
  final List<String> warnings; // التنبيهات والأشياء التي يجب الانتباه لها
  final List<String> accessDifficulty; // صعوبة الوصول (دبل، طرق وعرة، إلخ)
  final String category; // التصنيف: جبال، كشتة، وديان، إلخ
  final String region; // المنطقة: الرياض، مكة، عسير، إلخ
  final String city; // المدينة

  CampingSpot({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.imageUrls,
    required this.userId,
    required this.userName,
    required this.createdAt,
    this.likes = 0,
    this.likedBy = const [],
    this.rating = 5.0,
    this.pros = const [],
    this.category = 'كشتة',
    this.region = 'الرياض',
    this.city = 'الرياض',
    this.cons = const [],
    this.warnings = const [],
    this.accessDifficulty = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrls': imageUrls,
      'userId': userId,
      'userName': userName,
      'createdAt': createdAt.toIso8601String(),
      'likes': likes,
      'likedBy': likedBy,
      'rating': rating,
      'pros': pros,
      'cons': cons,
      'accessDifficulty': accessDifficulty,
      'warnings': warnings,
      'category': category,
      'region': region,
      'city': city,
    };
  }

  factory CampingSpot.fromJson(Map<String, dynamic> json) {
    return CampingSpot(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      likes: json['likes'] ?? 0,
      likedBy: List<String>.from(json['likedBy'] ?? []),
      rating: (json['rating'] ?? 5.0).toDouble(),
      pros: List<String>.from(json['pros'] ?? []),
      cons: List<String>.from(json['cons'] ?? []),
      accessDifficulty: List<String>.from(json['accessDifficulty'] ?? []),
      warnings: List<String>.from(json['warnings'] ?? []),
      category: json['category'] ?? 'كشتة',
      region: json['region'] ?? 'الرياض',
      city: json['city'] ?? 'الرياض',
    );
  }

  CampingSpot copyWith({
    String? id,
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    List<String>? imageUrls,
    String? userId,
    String? userName,
    DateTime? createdAt,
    int? likes,
    List<String>? likedBy,
    double? rating,
    List<String>? pros,
    List<String>? cons,
    List<String>? warnings,
    List<String>? accessDifficulty,
    String? category,
    String? region,
    String? city,
  }) {
    return CampingSpot(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrls: imageUrls ?? this.imageUrls,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      likedBy: likedBy ?? this.likedBy,
      rating: rating ?? this.rating,
      pros: pros ?? this.pros,
      cons: cons ?? this.cons,
      warnings: warnings ?? this.warnings,
      accessDifficulty: accessDifficulty ?? this.accessDifficulty,
      category: category ?? this.category,
      region: region ?? this.region,
      city: city ?? this.city,
    );
  }
}
