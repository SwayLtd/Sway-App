// lib/features/user/services/user_permission_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/user/models/user_permission_model.dart';
import 'package:sway/features/user/services/user_service.dart';

class UserPermissionService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserService _userService = UserService();

  // Définir la hiérarchie des rôles
  final Map<String, int> _roleHierarchy = {
    'user': 1,
    'manager': 2,
    'admin': 3,
  };

  Future<List<UserPermission>> getUserPermissions() async {
    final response = await _supabase.from('user_permissions').select();
    return response.map((json) => UserPermission.fromJson(json)).toList();
  }

  Future<List<UserPermission>> getPermissionsByUserId(int userId) async {
    final response =
        await _supabase.from('user_permissions').select().eq('user_id', userId);
    return response.map((json) => UserPermission.fromJson(json)).toList();
  }

  Future<List<UserPermission>> getPermissionsByEntity(
      int entityId, String entityType) async {
    final response = await _supabase
        .from('user_permissions')
        .select()
        .eq('entity_id', entityId)
        .eq('entity_type', entityType);
    return response.map((json) => UserPermission.fromJson(json)).toList();
  }

  Future<List<UserPermission>> getPermissionsByUserIdAndType(
      int userId, String entityType) async {
    final response = await _supabase
        .from('user_permissions')
        .select()
        .eq('user_id', userId)
        .eq('entity_type', entityType);
    return response.map((json) => UserPermission.fromJson(json)).toList();
  }

  /// Vérifie si l'utilisateur a la permission requise en tenant compte de la hiérarchie des rôles.
  Future<bool> hasPermission(int userId, int entityId, String entityType,
      String requiredPermission) async {
    final permissions = await getPermissionsByUserIdAndType(userId, entityType);

    // Définir le niveau requis basé sur la permission requise
    int requiredLevel;
    switch (requiredPermission) {
      case 'admin':
        requiredLevel = _roleHierarchy['admin']!;
        break;
      case 'manager':
        requiredLevel = _roleHierarchy['manager']!;
        break;
      case 'user':
        requiredLevel = _roleHierarchy['user']!;
        break;
      case 'edit':
        requiredLevel =
            _roleHierarchy['manager']!; // 'edit' nécessite 'manager' ou 'admin'
        break;
      case 'insight':
        requiredLevel = _roleHierarchy[
            'user']!; // 'insight' nécessite 'user', 'manager' ou 'admin'
        break;
      default:
        requiredLevel = 0;
    }

    for (var permission in permissions) {
      if (permission.entityId == entityId) {
        final userRoleLevel = _roleHierarchy[permission.permission] ?? 0;
        if (userRoleLevel >= requiredLevel) {
          return true;
        }
      }
    }

    return false;
  }

  /// Vérifie la permission pour l'utilisateur actuellement connecté.
  Future<bool> hasPermissionForCurrentUser(
      int entityId, String entityType, String requiredPermission) async {
    final currentUser = await _userService.getCurrentUser();
    if (currentUser == null) {
      return false;
    }
    return hasPermission(
        currentUser.id, entityId, entityType, requiredPermission);
  }

  Future<void> addUserPermission(
      int userId, int entityId, String entityType, String permission) async {
    final response = await _supabase.from('user_permissions').insert({
      'user_id': userId,
      'entity_id': entityId,
      'entity_type': entityType,
      'permission': permission,
    });

    if (response.isEmpty) {
      throw Exception('Failed to add user permission.');
    }
  }

  Future<void> deleteUserPermission(
      int userId, int entityId, String entityType) async {
    final response = await _supabase
        .from('user_permissions')
        .delete()
        .eq('user_id', userId)
        .eq('entity_id', entityId)
        .eq('entity_type', entityType);

    if (response.isEmpty) {
      throw Exception('Failed to delete user permission.');
    }
  }

  Future<void> saveUserPermissions(List<UserPermission> permissions) async {
    // Implémentation de la logique de sauvegarde, dépend de votre stockage local
  }
}
