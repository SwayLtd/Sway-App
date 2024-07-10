class UserFollowGenre {
  final String userId;
  final String genreId;

  UserFollowGenre({
    required this.userId,
    required this.genreId,
  });

  factory UserFollowGenre.fromJson(Map<String, dynamic> json) {
    return UserFollowGenre(
      userId: json['userId'] as String,
      genreId: json['genreId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'genreId': genreId,
    };
  }
}
