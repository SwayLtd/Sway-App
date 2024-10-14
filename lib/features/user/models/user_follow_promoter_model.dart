class UserFollowPromoter {
  final int userId; // Changement de String à int
  final int promoterId; // Changement de String à int

  UserFollowPromoter({
    required this.userId,
    required this.promoterId,
  });

  factory UserFollowPromoter.fromJson(Map<String, dynamic> json) {
    return UserFollowPromoter(
      userId: json['user_id'], // Utilisation de int
      promoterId: json['promoter_id'], // Utilisation de int
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'promoter_id': promoterId,
    };
  }
}
