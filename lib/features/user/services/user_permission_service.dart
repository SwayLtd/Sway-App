// user_permission_service.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway_events/features/user/models/user_permission_model.dart';
import 'package:sway_events/features/user/services/user_service.dart'; // Assurez-vous que vous avez un service pour obtenir l'utilisateur actuel

class UserPermissionService {
  Future<List<UserPermission>> getUserPermissions() async {
    final String response = await rootBundle
        .loadString('assets/databases/join_table/user_permissions.json');
    final List<dynamic> permissionsJson =
        json.decode(response) as List<dynamic>;
    return permissionsJson
        .map((json) => UserPermission.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<UserPermission>> getPermissionsByUserId(String userId) async {
    final permissions = await getUserPermissions();
    return permissions
        .where((permission) => permission.userId == userId)
        .toList();
  }

  Future<List<UserPermission>> getPermissionsByUserIdAndType(
      String userId, String entityType) async {
    final permissions = await getPermissionsByUserId(userId);
    return permissions
        .where((permission) => permission.entityType == entityType)
        .toList();
  }

  Future<bool> hasPermission(String userId, String entityId, String entityType,
      String requiredPermission) async {
    final permissions = await getPermissionsByUserId(userId);
    return permissions.any((permission) =>
        permission.entityId == entityId &&
        permission.entityType == entityType &&
        (permission.permission == requiredPermission ||
            (requiredPermission == 'edit' &&
                (permission.permission == 'owner' ||
                    permission.permission == 'manager')) ||
            (requiredPermission == 'insight' &&
                (permission.permission == 'owner' ||
                    permission.permission == 'manager' ||
                    permission.permission == 'user'))));
  }

  Future<bool> hasPermissionForCurrentUser(
      String entityId, String entityType, String requiredPermission) async {
    final currentUser = await UserService().getCurrentUser();
    if (currentUser == null) {
      return false;
    }
    return hasPermission(
        currentUser.id, entityId, entityType, requiredPermission);
  }

  Future<void> saveUserPermissions(List<UserPermission> permissions) async {
    // Implement saving logic here, depending on how you manage your local storage
  }
}
