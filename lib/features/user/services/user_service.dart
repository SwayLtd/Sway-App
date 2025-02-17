// lib/features/user/services/user_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/user/models/user_model.dart' as AppUser;

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Met à jour l'URL de l'image de profil de l'utilisateur
  Future<void> updateUserProfilePicture({
    required String supabaseId,
    required String profilePictureUrl,
  }) async {
    try {
      final data = await _supabase
          .from('users')
          .update({'profile_picture_url': profilePictureUrl})
          .eq('supabase_id', supabaseId)
          .select(); // Ajout de .select() pour récupérer les données mises à jour

      // Logs pour débogage
      print('Update Profile Picture Data: $data');

      // Vérifier que la mise à jour a affecté au moins une ligne
      if ((data.isEmpty)) {
        throw Exception('Error updating profile picture: No rows affected');
      }
    } catch (e) {
      print('Error updating profile picture: $e');
      throw Exception('Error updating profile picture');
    }
  }

  /// Retrieves a user by their Supabase ID.
  Future<AppUser.User?> getUserBySupabaseId(String supabaseId) async {
    try {
      final data = await _supabase
          .from('users')
          .select()
          .eq('supabase_id', supabaseId)
          .maybeSingle();

      if (data == null) {
        return null;
      }

      return AppUser.User.fromJson(data);
    } catch (e) {
      print('Error fetching user by Supabase ID: $e');
      return null;
    }
  }

  /// Retrieves the currently authenticated user.
  Future<AppUser.User?> getCurrentUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return null;
    }

    return await getUserBySupabaseId(user.id);
  }

  /// Met à jour le nom d'utilisateur de l'utilisateur dans la table 'users'
  Future<void> updateUsername({
    required String supabaseId,
    required String newUsername,
  }) async {
    try {
      final data = await _supabase
          .from('users')
          .update({'username': newUsername})
          .eq('supabase_id', supabaseId)
          .select(); // Ajout de .select()

      // Logs pour débogage
      print('Update Username Data: $data');

      if ((data.isEmpty)) {
        throw Exception('Error updating username: No rows affected');
      }
    } catch (e) {
      print('Error updating username: $e');
      throw Exception('Error updating username: $e');
    }
  }

  /// Met à jour l'adresse email de l'utilisateur dans la table 'users'
  Future<void> updateUserEmail({
    required String supabaseId,
    required String newEmail,
  }) async {
    try {
      final data = await _supabase
          .from('users')
          .update({'email': newEmail})
          .eq('supabase_id', supabaseId)
          .select(); // Ajout de .select()

      // Logs pour débogage
      print('Update Email Data: $data');

      if ((data.isEmpty)) {
        throw Exception(
            'Failed to update email in users table: No rows affected');
      }
    } catch (e) {
      print('Error updating email in users table: $e');
      throw Exception('Error updating email in users table.');
    }
  }

  /// Retrieves a user by their internal ID.
  Future<AppUser.User?> getUserById(int userId) async {
    try {
      final data =
          await _supabase.from('users').select().eq('id', userId).maybeSingle();

      if (data == null) {
        return null;
      }

      return AppUser.User.fromJson(data);
    } catch (e) {
      print('Error fetching user by ID: $e');
      return null;
    }
  }

  /// Searches users by username.
  Future<List<AppUser.User>> searchUsers(String query) async {
    try {
      final data =
          await _supabase.from('users').select().ilike('username', '%$query%');

      return (data as List<dynamic>)
          .map<AppUser.User>((json) => AppUser.User.fromJson(json))
          .toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  /// Retrieves users by a list of Supabase IDs.
  Future<List<AppUser.User>> getUsersBySupabaseIds(
      List<String> supabaseIds) async {
    if (supabaseIds.isEmpty) {
      return [];
    }

    try {
      final data = await _supabase
          .from('users')
          .select()
          .filter('supabase_id', 'in', '(${supabaseIds.join(",")})');

      return (data as List<dynamic>)
          .map<AppUser.User>((json) => AppUser.User.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching users by Supabase IDs: $e');
      return [];
    }
  }

  /// Retrieves users by a list of internal IDs.
  Future<List<AppUser.User>> getUsersByIds(List<int> userIds) async {
    if (userIds.isEmpty) {
      return [];
    }

    try {
      final data = await _supabase
          .from('users')
          .select()
          .filter('id', 'in', '(${userIds.join(",")})');

      return (data as List<dynamic>)
          .map<AppUser.User>((json) => AppUser.User.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching users by IDs: $e');
      return [];
    }
  }

  Future<List<User>> getRecommendedUsers({int? userId, int limit = 5}) async {
    try {
      final params = <String, dynamic>{
        'p_user_id': userId,
        'p_limit': limit,
      };

      final response =
          await _supabase.rpc('get_recommended_users', params: params);

      if (response == null || (response as List).isEmpty) {
        return [];
      }

      return (response)
          .map<User>((json) => User.fromJson(json as Map<String, dynamic>)!)
          .toList();
    } catch (e) {
      print('Error fetching recommended users: $e');
      throw e;
    }
  }
}
