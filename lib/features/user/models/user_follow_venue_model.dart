class UserFollowVenue {
  final String userId;
  final String venueId;

  UserFollowVenue({required this.userId, required this.venueId});

  factory UserFollowVenue.fromJson(Map<String, dynamic> json) {
    return UserFollowVenue(
      userId: json['userId'] as String,
      venueId: json['venueId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'venueId': venueId,
    };
  }
}
