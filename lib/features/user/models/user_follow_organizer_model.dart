class UserFollowPromoter {
  final int userId;
  final int promoterId;

  UserFollowPromoter({
    required this.userId,
    required this.promoterId,
  });

  factory UserFollowPromoter.fromJson(Map<String, dynamic> json) {
    return UserFollowPromoter(
      userId: json['user_id'],
      promoterId: json['promoter_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'promoter_id': promoterId,
    };
  }
}
