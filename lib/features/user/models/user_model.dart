// lib/features/user/models/user_model.dart

class User {
  final int id;
  final String username;
  final String email;
  final String profilePictureUrl;
  final String supabaseId; // References Supabase Auth
  final bool isAnonymous;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.profilePictureUrl,
    required this.supabaseId,
    required this.isAnonymous,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      profilePictureUrl: json['profile_picture_url'] ?? '',
      supabaseId: json['supabase_id'] ?? '',
      isAnonymous: json['is_anonymous'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'profile_picture_url': profilePictureUrl,
      'supabase_id': supabaseId,
      'is_anonymous': isAnonymous,
      'created_at': createdAt.toIso8601String(),
    };
  }

  User copyWith({
    String? username,
    String? email,
    String? profilePictureUrl,
    String? supabaseId,
    bool? isAnonymous,
  }) {
    return User(
      id: id,
      username: username ?? this.username,
      email: email ?? this.email,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      supabaseId: supabaseId ?? this.supabaseId,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      createdAt: createdAt,
    );
  }
}
