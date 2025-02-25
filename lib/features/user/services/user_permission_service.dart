// lib/features/user/services/user_permission_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/user/models/user_permission_model.dart';
import 'package:sway/features/user/services/user_service.dart';

class UserPermissionService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserService _userService = UserService();

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

  /// Vérifie si l'utilisateur a au moins le niveau de permission requis.
  Future<bool> hasPermission(
      int userId, int entityId, String entityType, int requiredLevel) async {
    // print('Required Level: $requiredLevel');

    final response = await _supabase
        .from('user_permissions')
        .select('permission_level')
        .eq('user_id', userId)
        .eq('entity_id', entityId)
        .eq('entity_type', entityType)
        .gte('permission_level', requiredLevel)
        .maybeSingle();

    // print('Permission Level response: $response');

    return response != null;
  }

  /// Vérifie la permission pour l'utilisateur actuellement connecté.
  Future<bool> hasPermissionForCurrentUser(
      int entityId, String entityType, int requiredLevel) async {
    final currentUser = await _userService.getCurrentUser();
    if (currentUser == null) {
      // print('Current user is null');
      return false;
    }
    final hasPerm = await hasPermission(
        currentUser.id, entityId, entityType, requiredLevel);
    // print('User has permission: $hasPerm for level $requiredLevel on $entityType $entityId');
    return hasPerm;
  }

  /// Ajoute une permission pour un utilisateur.
  Future<void> addUserPermission(
      int userId, int entityId, String entityType, int permissionLevel) async {
    final response = await _supabase.from('user_permissions').insert({
      'user_id': userId,
      'entity_id': entityId,
      'entity_type': entityType,
      'permission_level': permissionLevel,
    }).select();

    // If the response is null or empty, consider the insertion successful.
    if ((response.isEmpty)) {
      return;
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

    // If response is null or an empty list, consider the deletion successful.
    if (response == null || (response is List && response.isEmpty)) {
      return;
    }
  }

  /// Met à jour la permission d'un utilisateur pour une entité.
  Future<void> updateUserPermission(int userId, int entityId, String entityType,
      int newPermissionLevel) async {
    final response = await _supabase
        .from('user_permissions')
        .update({'permission_level': newPermissionLevel})
        .eq('user_id', userId)
        .eq('entity_id', entityId)
        .eq('entity_type', entityType);

    // If response is null or empty, consider the update successful.
    if (response == null || (response is List && response.isEmpty)) {
      return;
    }
  }

  /// Sauvegarde les permissions des utilisateurs localement (implémentation dépendante).
  Future<void> saveUserPermissions(List<UserPermission> permissions) async {
    // Implémentation de la logique de sauvegarde, dépend de votre stockage local
  }
}

String getRoleLabel(int level) {
  switch (level) {
    case 3:
      return "Admin";
    case 2:
      return "Manager";
    case 1:
    default:
      return "User";
  }
}
