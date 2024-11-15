// lib/features/user/services/user_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/user/models/user_model.dart' as AppUser;

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

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
      final data = await _supabase
          .from('users')
          .select()
          .ilike('username', '%$query%') as List<dynamic>?;

      if (data == null) {
        return [];
      }

      return data
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
          .filter('supabase_id', 'in', '($supabaseIds)');
      ;

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
          .filter('id', 'in', '($userIds)');
      ;

      return data
          .map<AppUser.User>((json) => AppUser.User.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching users by IDs: $e');
      return [];
    }
  }

  /// Updates the profile picture URL of a user.
  Future<void> updateUserProfilePicture({
    required String supabaseId,
    required String profilePictureUrl,
  }) async {
    try {
      final response = await _supabase
          .from('users')
          .update({'profile_picture_url': profilePictureUrl}).eq(
              'supabase_id', supabaseId);

      if (response.error != null) {
        throw Exception(
            'Failed to update profile picture: ${response.error!.message}');
      }
    } catch (e) {
      print('Error updating profile picture: $e');
      throw Exception('Error updating profile picture.');
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
}
