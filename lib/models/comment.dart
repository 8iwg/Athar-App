class Comment {
  final String id;
  final String spotId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String text;
  final DateTime createdAt;
  final int likes;
  final List<String> likedBy;

  Comment({
    required this.id,
    required this.spotId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.text,
    required this.createdAt,
    this.likes = 0,
    this.likedBy = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'spotId': spotId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'likes': likes,
      'likedBy': likedBy,
    };
  }

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? '',
      spotId: json['spotId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userAvatar: json['userAvatar'],
      text: json['text'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      likes: json['likes'] ?? 0,
      likedBy: List<String>.from(json['likedBy'] ?? []),
    );
  }

  Comment copyWith({
    String? id,
    String? spotId,
    String? userId,
    String? userName,
    String? userAvatar,
    String? text,
    DateTime? createdAt,
    int? likes,
    List<String>? likedBy,
  }) {
    return Comment(
      id: id ?? this.id,
      spotId: spotId ?? this.spotId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      likedBy: likedBy ?? this.likedBy,
    );
  }
}
