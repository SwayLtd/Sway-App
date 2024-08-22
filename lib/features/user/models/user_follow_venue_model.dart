class UserFollowVenue {
  final int userId;
  final int venueId;

  UserFollowVenue({required this.userId, required this.venueId});

  factory UserFollowVenue.fromJson(Map<String, dynamic> json) {
    return UserFollowVenue(
      userId: json['userId'],
      venueId: json['venueId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'venueId': venueId,
    };
  }
}
