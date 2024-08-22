class UserFollowGenre {
  final int userId;
  final int genreId;

  UserFollowGenre({
    required this.userId,
    required this.genreId,
  });

  factory UserFollowGenre.fromJson(Map<String, dynamic> json) {
    return UserFollowGenre(
      userId: json['userId'],
      genreId: json['genreId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'genreId': genreId,
    };
  }
}
