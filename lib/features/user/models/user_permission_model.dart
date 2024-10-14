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
      userId: json['user_id'],
      entityId: json['entity_id'],
      entityType: json['entity_type'] as String,
      permission: json['permission'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'entity_id': entityId,
      'entity_type': entityType,
      'permission': permission,
    };
  }
}
