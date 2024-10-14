// user_permission_service.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway/features/user/models/user_permission_model.dart';
import 'package:sway/features/user/services/user_service.dart'; // Assurez-vous que vous avez un service pour obtenir l'utilisateur actuel

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

  Future<List<UserPermission>> getPermissionsByUserId(int userId) async {
    final permissions = await getUserPermissions();
    return permissions
        .where((permission) => permission.userId == userId)
        .toList();
  }

  Future<List<UserPermission>> getPermissionsByEntity(
      int entityId, String entityType,) async {
    final permissions = await getUserPermissions();
    return permissions
        .where((permission) =>
            permission.entityId == entityId &&
            permission.entityType == entityType,)
        .toList();
  }

  Future<List<UserPermission>> getPermissionsByUserIdAndType(
      int userId, String entityType,) async {
    final permissions = await getPermissionsByUserId(userId);
    return permissions
        .where((permission) => permission.entityType == entityType)
        .toList();
  }

  Future<bool> hasPermission(int userId, int entityId, String entityType,
      String requiredPermission,) async {
    final permissions = await getPermissionsByUserId(userId);
    return permissions.any((permission) =>
        permission.entityId == entityId &&
        permission.entityType == entityType &&
        (permission.permission == requiredPermission ||
            (requiredPermission == 'edit' &&
                (permission.permission == 'admin' ||
                    permission.permission == 'manager')) ||
            (requiredPermission == 'insight' &&
                (permission.permission == 'admin' ||
                    permission.permission == 'manager' ||
                    permission.permission == 'user'))),);
  }

  Future<bool> hasPermissionForCurrentUser(
      int entityId, String entityType, String requiredPermission,) async {
    final currentUser = await UserService().getCurrentUser();
    if (currentUser == null) {
      return false;
    }
    return hasPermission(
        currentUser.id, entityId, entityType, requiredPermission,);
  }

  Future<void> addUserPermission(int userId, int entityId,
      String entityType, String permission,) async {
    final permissions = await getUserPermissions();
    permissions.add(UserPermission(
        userId: userId,
        entityId: entityId,
        entityType: entityType,
        permission: permission,),);
    await saveUserPermissions(permissions);
  }

  Future<void> deleteUserPermission(
      int userId, int entityId, String entityType,) async {
    final permissions = await getUserPermissions();
    permissions.removeWhere((permission) =>
        permission.userId == userId &&
        permission.entityId == entityId &&
        permission.entityType == entityType,);
    await saveUserPermissions(permissions);
  }

  Future<void> saveUserPermissions(List<UserPermission> permissions) async {
    // Implémentation de la logique de sauvegarde, dépend de votre stockage local
  }
}
