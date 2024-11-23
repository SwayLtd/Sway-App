// lib/features/user/services/auth_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Ensures that a user is logged in. If no user is logged in, logs in anonymously.
  Future<void> ensureUser() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      final response = await _supabase.auth.signInAnonymously();

      if (response.user == null) {
        throw Exception('Anonymous user not created.');
      }

      // Optionally, manage additional actions after the creation of an anonymous user.
    }
  }

  /// Connect a user anonymously.
  Future<void> signInAnonymously() async {
    final response = await _supabase.auth.signInAnonymously();

    if (response.user == null) {
      throw Exception('Anonymous user not created.');
    }
  }

  /// Déconnecte l'utilisateur et reconnecte anonymement.
  Future<void> signOut() async {
    await _supabase.auth.signOut();

    // Après la déconnexion, se reconnecter anonymement.
    await ensureUser();
  }

  /// Retourne l'utilisateur authentifié actuel.
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  /// Met à jour l'adresse email de l'utilisateur actuellement connecté
  Future<void> updateEmail(String newEmail) async {
    await _supabase.auth.updateUser(
      UserAttributes(
        email: newEmail,
      ),
    );

    // Supabase envoie automatiquement un email de confirmation à la nouvelle adresse
  }

  /// Async method to check if username already exists
  Future<bool> _doesUsernameExist(String username) async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('users')
        .select('username')
        .eq('username', username)
        .maybeSingle();

    return response != null;
  }
}

/// Exception personnalisée pour gérer les erreurs d'authentification.
class AuthenticationException implements Exception {
  final String message;
  final String? details;

  AuthenticationException(this.message, this.details);

  @override
  String toString() {
    if (details != null && details!.isNotEmpty) {
      return '$message: $details';
    }
    return message;
  }
}
