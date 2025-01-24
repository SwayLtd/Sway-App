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

  /// Récupère toutes les permissions des utilisateurs.
  Future<List<UserPermission>> getUserPermissions() async {
    final response = await _supabase.from('user_permissions').select();
    return response.map((json) => UserPermission.fromJson(json)).toList();
  }

  /// Récupère les permissions d'un utilisateur spécifique.
  Future<List<UserPermission>> getPermissionsByUserId(int userId) async {
    final response =
        await _supabase.from('user_permissions').select().eq('user_id', userId);
    return response.map((json) => UserPermission.fromJson(json)).toList();
  }

  /// Récupère les permissions pour une entité spécifique.
  Future<List<UserPermission>> getPermissionsByEntity(
      int entityId, String entityType) async {
    final response = await _supabase
        .from('user_permissions')
        .select()
        .eq('entity_id', entityId)
        .eq('entity_type', entityType);
    return response.map((json) => UserPermission.fromJson(json)).toList();
  }

  /// Récupère les permissions d'un utilisateur pour un type d'entité spécifique.
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
    final requiredLevel = _roleHierarchy[requiredPermission] ?? 0;
    print('Required Level for $requiredPermission: $requiredLevel');

    final response = await _supabase
        .from('user_permissions')
        .select('permission_level')
        .eq('user_id', userId)
        .eq('entity_id', entityId)
        .eq('entity_type', entityType)
        .gte('permission_level', requiredLevel)
        .maybeSingle();

    print('Permission Level response: $response');

    return response != null;
  }

  /// Vérifie la permission pour l'utilisateur actuellement connecté.
  Future<bool> hasPermissionForCurrentUser(
      int entityId, String entityType, String requiredPermission) async {
    final currentUser = await _userService.getCurrentUser();
    if (currentUser == null) {
      print('Current user is null');
      return false;
    }
    final hasPerm = await hasPermission(
        currentUser.id, entityId, entityType, requiredPermission);
    print(
        'User has permission: $hasPerm for $requiredPermission on $entityType $entityId');
    return hasPerm;
  }

  /// Ajoute une permission pour un utilisateur.
  Future<void> addUserPermission(
      int userId, int entityId, String entityType, String permission) async {
    final permissionLevel = _roleHierarchy[permission] ?? 0;

    final response = await _supabase.from('user_permissions').insert({
      'user_id': userId,
      'entity_id': entityId,
      'entity_type': entityType,
      'permission': permission,
      'permission_level': permissionLevel,
    });

    if (response.isEmpty) {
      throw Exception('Failed to add user permission.');
    }
  }

  /// Supprime une permission pour un utilisateur.
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

  /// Sauvegarde les permissions des utilisateurs localement (implémentation dépendante).
  Future<void> saveUserPermissions(List<UserPermission> permissions) async {
    // Implémentation de la logique de sauvegarde, dépend de votre stockage local
  }
}
