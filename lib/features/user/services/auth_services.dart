// lib/features/user/services/auth_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Signs in a user with email and password.
  Future<void> signIn(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('User not found.');
    }
  }

  /// Signs up a new user with email, password, and username.
  Future<void> signUp(String email, String password, String username) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw Exception('User not created.');
    }

    // Assuming you have a 'users' table to store additional user info
    final insertResponse = await _supabase.from('users').insert({
      'supabase_id': user.id,
      'username': username,
      'email': email,
      'profile_picture_url': 'https://via.placeholder.com/150',
      'created_at': DateTime.now().toIso8601String(),
      'is_anonymous': false,
      'role': 'user', // Assign default role
    });

    if (insertResponse.error != null) {
      throw Exception(
          'Failed to create user entry: ${insertResponse.error!.message}');
    }
  }

  /// Signs in anonymously.
  Future<void> signInAnonymously() async {
    final response = await _supabase.auth.signInAnonymously();

    if (response.user == null) {
      throw Exception('Anonymous user not created.');
    }

    // Optionally, create a user entry in 'users' table for anonymous user
    final user = response.user;
    final insertResponse = await _supabase.from('users').insert({
      'supabase_id': user?.id,
      'username': 'Anonymous',
      'email': '',
      'profile_picture_url': 'https://via.placeholder.com/150',
      'created_at': DateTime.now().toIso8601String(),
      'is_anonymous': true,
      'role': 'user', // Assign default role
    });

    if (insertResponse.error != null) {
      throw Exception(
          'Failed to create anonymous user entry: ${insertResponse.error!.message}');
    }
  }

  /// Links the current anonymous user to an email/password account.
  Future<void> linkWithEmail(String email, String password) async {
    await _supabase.auth.updateUser(
      UserAttributes(
        email: email,
        password: password,
      ),
    );
  }

  /// Links the current anonymous user to an OAuth provider.
  Future<void> linkWithOAuth(OAuthProvider provider) async {
    await _supabase.auth.linkIdentity(provider);
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Returns the current authenticated user.
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }
}
