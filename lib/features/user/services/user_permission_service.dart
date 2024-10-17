// user_permission_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/user/models/user_permission_model.dart';
import 'package:sway/features/user/services/user_service.dart';

class UserPermissionService {
  final _supabase = Supabase.instance.client;

  Future<List<UserPermission>> getUserPermissions() async {
    final response = await _supabase.from('user_permissions').select();

    return response
        .map((json) => UserPermission.fromJson(json))
        .toList();
  }

  Future<List<UserPermission>> getPermissionsByUserId(int userId) async {
    final response = await _supabase
        .from('user_permissions')
        .select()
        .eq('user_id', userId);

    return response
        .map((json) => UserPermission.fromJson(json))
        .toList();
  }

  Future<List<UserPermission>> getPermissionsByEntity(
      int entityId, String entityType) async {
    final response = await _supabase
        .from('user_permissions')
        .select()
        .eq('entity_id', entityId)
        .eq('entity_type', entityType);

    return response
        .map((json) => UserPermission.fromJson(json))
        .toList();
  }

  Future<List<UserPermission>> getPermissionsByUserIdAndType(
      int userId, String entityType) async {
    final response = await _supabase
        .from('user_permissions')
        .select()
        .eq('user_id', userId)
        .eq('entity_type', entityType);

    return response
        .map((json) => UserPermission.fromJson(json))
        .toList();
  }

  Future<bool> hasPermission(int userId, int entityId, String entityType,
      String requiredPermission) async {
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
                    permission.permission == 'user'))));
  }

  Future<bool> hasPermissionForCurrentUser(
      int entityId, String entityType, String requiredPermission) async {
    final currentUser = await UserService().getCurrentUser();
    if (currentUser == null) {
      return false;
    }
    return hasPermission(
        currentUser.id, entityId, entityType, requiredPermission);
  }

  Future<void> addUserPermission(int userId, int entityId, String entityType,
      String permission) async {
    await _supabase.from('user_permissions').insert({
      'user_id': userId,
      'entity_id': entityId,
      'entity_type': entityType,
      'permission': permission,
    });
  }

  Future<void> deleteUserPermission(
      int userId, int entityId, String entityType) async {
    await _supabase
        .from('user_permissions')
        .delete()
        .eq('user_id', userId)
        .eq('entity_id', entityId)
        .eq('entity_type', entityType);
  }

  Future<void> saveUserPermissions(List<UserPermission> permissions) async {
    // Implémentation de la logique de sauvegarde, dépend de votre stockage local
  }
}
