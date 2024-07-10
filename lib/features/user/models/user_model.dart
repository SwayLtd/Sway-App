class User {
  final String id;
  final String username;
  final String profilePictureUrl;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.profilePictureUrl,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      profilePictureUrl: json['profilePictureUrl'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
