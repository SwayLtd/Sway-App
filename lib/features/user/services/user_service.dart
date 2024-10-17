// user_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/user/models/user_model.dart' as AppUser;

class UserService {
  final _supabase = Supabase.instance.client;

  Future<AppUser.User?> getUserById(int userId) async {
    final response = await _supabase
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return AppUser.User.fromJson(response);
  }

  Future<List<AppUser.User>> searchUsers(String query) async {
    final response = await _supabase
        .from('users')
        .select()
        .ilike('username', '%$query%');

    if (response.isEmpty) {
      print('No users found.');
    }

    return response
        .map<AppUser.User>((json) => AppUser.User.fromJson(json))
        .toList();
  }

  Future<List<AppUser.User>> getUsersByIds(List<int> userIds) async {
    if (userIds.isEmpty) {
      return [];
    }

    final ids = userIds.join(',');

    final response = await _supabase
        .from('users')
        .select()
        .filter('id', 'in', '($ids)');

    if (response.isEmpty) {
      print('No users found.');
    }

    return response
        .map<AppUser.User>((json) => AppUser.User.fromJson(json))
        .toList();
  }

  Future<void> updateUser(AppUser.User updatedUser) async {
    final response = await _supabase
        .from('users')
        .update(updatedUser.toJson())
        .eq('id', updatedUser.id);

    if (response == null || response.isEmpty) {
      print('Failed to update user.');
    }
  }

  // Méthode pour obtenir l'utilisateur actuellement connecté
  Future<AppUser.User?> getCurrentUser() async {
    const currentUserId = 3; // Utilisateur actuel avec ID 3
    return getUserById(currentUserId);
  }
}
