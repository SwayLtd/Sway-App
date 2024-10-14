class UserFollowArtist {
  final int userId;
  final int artistId;

  UserFollowArtist({
    required this.userId,
    required this.artistId,
  });

  factory UserFollowArtist.fromJson(Map<String, dynamic> json) {
    return UserFollowArtist(
      userId: json['user_id'],
      artistId: json['artist_id'],
    );
  }
}
