class UserFollowPromoter {
  final String userId;
  final String promoterId;

  UserFollowPromoter({
    required this.userId,
    required this.promoterId,
  });

  factory UserFollowPromoter.fromJson(Map<String, dynamic> json) {
    return UserFollowPromoter(
      userId: json['userId'] as String,
      promoterId: json['promoterId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'promoterId': promoterId,
    };
  }
}
