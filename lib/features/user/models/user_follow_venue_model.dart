class UserFollowVenue {
  final int userId;
  final int venueId;

  UserFollowVenue({required this.userId, required this.venueId});

  factory UserFollowVenue.fromJson(Map<String, dynamic> json) {
    return UserFollowVenue(
      userId: json['user_id'],
      venueId: json['venue_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'venue_id': venueId,
    };
  }
}
