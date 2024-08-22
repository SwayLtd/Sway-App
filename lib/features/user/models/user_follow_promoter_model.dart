class UserFollowPromoter {
  final int userId; // Changement de String à int
  final int promoterId; // Changement de String à int

  UserFollowPromoter({
    required this.userId,
    required this.promoterId,
  });

  factory UserFollowPromoter.fromJson(Map<String, dynamic> json) {
    return UserFollowPromoter(
      userId: json['userId'], // Utilisation de int
      promoterId: json['promoterId'], // Utilisation de int
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'promoterId': promoterId,
    };
  }
}
