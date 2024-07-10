class UserPermission {
  final String userId;
  final String entityId;
  final String entityType;
  final String permission;

  UserPermission({
    required this.userId,
    required this.entityId,
    required this.entityType,
    required this.permission,
  });

  factory UserPermission.fromJson(Map<String, dynamic> json) {
    return UserPermission(
      userId: json['userId'] as String,
      entityId: json['entityId'] as String,
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
