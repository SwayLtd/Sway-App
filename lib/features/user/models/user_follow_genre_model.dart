class UserFollowGenre {
  final int userId;
  final int genreId;

  UserFollowGenre({
    required this.userId,
    required this.genreId,
  });

  factory UserFollowGenre.fromJson(Map<String, dynamic> json) {
    return UserFollowGenre(
      userId: json['user_id'],
      genreId: json['genre_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'genre_id': genreId,
    };
  }
}
