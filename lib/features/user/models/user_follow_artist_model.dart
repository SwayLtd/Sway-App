class UserFollowArtist {
  final String userId;
  final String artistId;

  UserFollowArtist({
    required this.userId,
    required this.artistId,
  });

  factory UserFollowArtist.fromJson(Map<String, dynamic> json) {
    return UserFollowArtist(
      userId: json['userId'] as String,
      artistId: json['artistId'] as String,
    );
  }
}
