// lib/features/user/services/auth_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// S'assure qu'un utilisateur est connecté. Si aucun utilisateur n'est connecté, se connecte anonymement.
  Future<void> ensureUser() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      final response = await _supabase.auth.signInAnonymously();

      if (response.user == null) {
        throw Exception('Anonymous user not created.');
      }

      // Optionnellement, gérer des actions supplémentaires après la création d'un utilisateur anonyme.
    }
  }

  /// Connecte un utilisateur avec email et mot de passe.
  Future<void> signIn(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw AuthenticationException('User not found.', '');
    }
  }

  /// Inscrit un nouvel utilisateur avec email, mot de passe et nom d'utilisateur.
  Future<void> signUp(String email, String password, String username) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'username': username
      }, // Ajout du nom d'utilisateur dans raw_user_meta_data
    );

    final user = response.user;
    if (user == null) {
      throw AuthenticationException('User not created.', '');
    }

    // L'insertion dans la table 'users' est gérée automatiquement par le déclencheur PostgreSQL.
  }

  /// Connecte anonymement un utilisateur.
  Future<void> signInAnonymously() async {
    final response = await _supabase.auth.signInAnonymously();

    if (response.user == null) {
      throw Exception('Anonymous user not created.');
    }
  }

  /// Lie l'utilisateur anonyme actuel à un compte email/mot de passe.
  Future<void> linkWithEmail(String email, String password) async {
    await _supabase.auth.updateUser(
      UserAttributes(
        email: email,
        password: password,
      ),
    );

    // L'insertion ou la mise à jour dans la table 'users' peut être gérée par un autre déclencheur si nécessaire.
  }

  /// Lie l'utilisateur anonyme actuel à un fournisseur OAuth.
  Future<void> linkWithOAuth(OAuthProvider provider) async {
    await _supabase.auth.linkIdentity(provider);

    // Optionnellement, gérer des mises à jour supplémentaires dans la table 'users' si nécessaire.
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
