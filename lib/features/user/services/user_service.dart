// lib/features/user/services/user_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/user/models/user_model.dart' as AppUser;

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Récupère un utilisateur par son ID.
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

  /// Recherche des utilisateurs par nom d'utilisateur.
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

  /// Récupère des utilisateurs par une liste d'IDs.
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

  /// Met à jour les informations d'un utilisateur.
  Future<void> updateUser(AppUser.User updatedUser) async {
    try {
      await _supabase
          .from('users')
          .update(updatedUser.toJson())
          .eq('id', updatedUser.id);

      print('User updated successfully.');
    } catch (e) {
      print('Failed to update user: $e');
    }
  }

  /// Récupère l'utilisateur actuellement connecté.
  Future<AppUser.User?> getCurrentUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return null;
    }

    try {
      final data = await _supabase
          .from('users')
          .select()
          .eq('supabase_id', user.id)
          .maybeSingle();

      if (data == null) {
        return null;
      }

      return AppUser.User.fromJson(data);
    } catch (e) {
      print('Error fetching current user: $e');
      return null;
    }
  }

  /// Inscrit un nouvel utilisateur avec email, mot de passe et username.
  Future<void> signUp(String email, String password, String username) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Utilisateur non créé.');
      }

      // Créer une entrée dans la table users
      await _supabase.from('users').insert({
        'supabase_id': user.id,
        'username': username,
        'email': email,
        'profile_picture_url': 'https://via.placeholder.com/150',
        'created_at': DateTime.now().toIso8601String(),
      });

      print('User signed up successfully.');
    } catch (e) {
      throw Exception('Échec de l\'inscription: $e');
    }
  }

  /// Connecte un utilisateur avec email et mot de passe.
  Future<void> signIn(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Vérifie si une session a été établie
      final session = response.session;
      if (session == null) {
        throw Exception('Session non établie.');
      }

      print('User signed in successfully.');
    } catch (e) {
      throw Exception('Échec de la connexion: $e');
    }
  }

  /// Déconnecte l'utilisateur actuellement connecté.
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      print('User signed out successfully.');
    } catch (e) {
      print('Error signing out: $e');
    }
  }
}
