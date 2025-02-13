class UserPermission {
  final int userId;
  final int entityId;
  final String entityType;
  int permissionLevel;

  UserPermission({
    required this.userId,
    required this.entityId,
    required this.entityType,
    required this.permissionLevel,
  });

  factory UserPermission.fromJson(Map<String, dynamic> json) {
    return UserPermission(
      userId: json['user_id'],
      entityId: json['entity_id'],
      entityType: json['entity_type'] as String,
      permissionLevel: json['permission_level'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'entity_id': entityId,
      'entity_type': entityType,
      'permission_level': permissionLevel,
    };
  }
}
