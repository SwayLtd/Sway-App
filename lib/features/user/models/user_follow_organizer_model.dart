class UserFollowPromoter {
  final int userId;
  final int promoterId;

  UserFollowPromoter({
    required this.userId,
    required this.promoterId,
  });

  factory UserFollowPromoter.fromJson(Map<String, dynamic> json) {
    return UserFollowPromoter(
      userId: json['userId'],
      promoterId: json['promoterId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'promoterId': promoterId,
    };
  }
}
