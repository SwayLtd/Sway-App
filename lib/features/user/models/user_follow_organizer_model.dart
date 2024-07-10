class UserFollowOrganizer {
  final String userId;
  final String organizerId;

  UserFollowOrganizer({
    required this.userId,
    required this.organizerId,
  });

  factory UserFollowOrganizer.fromJson(Map<String, dynamic> json) {
    return UserFollowOrganizer(
      userId: json['userId'] as String,
      organizerId: json['organizerId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'organizerId': organizerId,
    };
  }
}
