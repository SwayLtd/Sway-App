// lib/features/user/models/user_model.dart

class User {
  final int id;
  final String username;
  final String email;
  final String profilePictureUrl;
  final String supabaseId; // References Supabase Auth
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.profilePictureUrl,
    required this.supabaseId,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      profilePictureUrl: json['profile_picture_url'] as String? ?? '',
      supabaseId: json['supabase_id'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
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
      'created_at': createdAt.toIso8601String(),
    };
  }

  User copyWith({
    String? username,
    String? email,
    String? profilePictureUrl,
    String? supabaseId,
    DateTime? createdAt,
  }) {
    return User(
      id: id,
      username: username ?? this.username,
      email: email ?? this.email,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      supabaseId: supabaseId ?? this.supabaseId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
