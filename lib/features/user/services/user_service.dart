// lib/features/user/services/user_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/user/models/user_model.dart' as AppUser;
import 'package:sway/features/user/services/auth_service.dart';

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();

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

  /// Retrieves users by a list of Supabase IDs.
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

      return data
          .map<AppUser.User>((json) => AppUser.User.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching users by IDs: $e');
      return [];
    }
  }

  /// Updates user information.
  Future<void> updateUser(AppUser.User updatedUser) async {
    try {
      final response = await _supabase
          .from('users')
          .update(updatedUser.toJson())
          .eq('supabase_id', updatedUser.supabaseId);

      if (response.error != null) {
        print('Failed to update user: ${response.error!.message}');
      } else {
        print('User updated successfully.');
      }
    } catch (e) {
      print('Failed to update user: $e');
    }
  }

  /// Retrieves the currently authenticated user.
  Future<AppUser.User?> getCurrentUser() async {
    final user = _authService.getCurrentUser();
    if (user == null) {
      return null;
    }

    // Vérifiez si l'utilisateur est anonyme
    if (user.userMetadata?['is_anonymous'] == true) {
      // Traitez les utilisateurs anonymes selon vos besoins
      return null; // Ou retournez une instance spécifique si nécessaire
    }

    return await getUserBySupabaseId(user.id);
  }

  /// Signs up a new user.
  Future<void> signUp(String email, String password, String username) async {
    await _authService.signUp(email, password, username);
  }

  /// Signs in a user.
  Future<void> signIn(String email, String password) async {
    await _authService.signIn(email, password);
  }

  /// Signs in anonymously.
  Future<void> signInAnonymously() async {
    await _authService.signInAnonymously();
  }

  /// Links anonymous user to email/password account.
  Future<void> linkWithEmail(String email, String password) async {
    await _authService.linkWithEmail(email, password);
    // Additional logic if necessary
  }

  /// Links anonymous user to an OAuth provider.
  Future<void> linkWithOAuth(OAuthProvider provider) async {
    await _authService.linkWithOAuth(provider);
    // Additional logic if necessary
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _authService.signOut();
  }
}
