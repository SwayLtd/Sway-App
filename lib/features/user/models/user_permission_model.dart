class UserPermission {
  final int userId;
  final int entityId;
  final String entityType;
  String permission; // Change from final to mutable

  UserPermission({
    required this.userId,
    required this.entityId,
    required this.entityType,
    required this.permission,
  });

  factory UserPermission.fromJson(Map<String, dynamic> json) {
    return UserPermission(
      userId: json['userId'],
      entityId: json['entityId'],
      entityType: json['entityType'] as String,
      permission: json['permission'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'entityId': entityId,
      'entityType': entityType,
      'permission': permission,
    };
  }
}
