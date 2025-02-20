// lib/features/user/services/user_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/core/utils/connectivity_helper.dart';
import 'package:sway/core/services/database_service.dart';
import 'package:sway/features/user/models/user_model.dart' as AppUser;
import 'package:sway/features/user/models/isar_user.dart';
import 'package:isar/isar.dart';

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;
  // Utilisation de l'instance Isar centralisée
  late final Future<Isar> _isarFuture = DatabaseService().isar;

  /// Updates the user's profile picture.
  Future<void> updateUserProfilePicture({
    required String supabaseId,
    required String profilePictureUrl,
  }) async {
    final online = await isConnected();
    if (!online) throw Exception("No internet connection.");

    final data = await _supabase
        .from('users')
        .update({'profile_picture_url': profilePictureUrl})
        .eq('supabase_id', supabaseId)
        .select();
    if ((data as List).isEmpty) {
      throw Exception('Error updating profile picture: No rows affected');
    }
    final user = AppUser.User.fromJson(data.first);
    final isar = await _isarFuture;
    await _storeUserInIsar(isar, user);
  }

  /// Retrieves a user by their Supabase ID.
  Future<AppUser.User?> getUserBySupabaseId(String supabaseId) async {
    final online = await isConnected();
    final isar = await _isarFuture;
    if (online) {
      final data = await _supabase
          .from('users')
          .select()
          .eq('supabase_id', supabaseId)
          .maybeSingle();
      if (data == null) {
        // Return cached data if available.
        return await _loadUserFromIsarBySupabaseId(supabaseId, isar: isar);
      }
      final user = AppUser.User.fromJson(data);
      await _storeUserInIsar(isar, user);
      return user;
    } else {
      // Offline: load user from cache.
      return await _loadUserFromIsarBySupabaseId(supabaseId, isar: isar);
    }
  }

  /// Retrieves the currently authenticated user.
  Future<AppUser.User?> getCurrentUser() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return null;
    return await getUserBySupabaseId(authUser.id);
  }

  /// Updates the user's username.
  Future<void> updateUsername({
    required String supabaseId,
    required String newUsername,
  }) async {
    final online = await isConnected();
    if (!online) throw Exception("No internet connection.");

    final data = await _supabase
        .from('users')
        .update({'username': newUsername})
        .eq('supabase_id', supabaseId)
        .select();
    if ((data as List).isEmpty) {
      throw Exception('Error updating username: No rows affected');
    }
    final user = AppUser.User.fromJson(data.first);
    final isar = await _isarFuture;
    await _storeUserInIsar(isar, user);
  }

  /// Updates the user's email.
  Future<void> updateUserEmail({
    required String supabaseId,
    required String newEmail,
  }) async {
    final online = await isConnected();
    if (!online) throw Exception("No internet connection.");

    final data = await _supabase
        .from('users')
        .update({'email': newEmail})
        .eq('supabase_id', supabaseId)
        .select();
    if ((data as List).isEmpty) {
      throw Exception(
          'Failed to update email in users table: No rows affected');
    }
    final user = AppUser.User.fromJson(data.first);
    final isar = await _isarFuture;
    await _storeUserInIsar(isar, user);
  }

  /// Updates the user's bio.
  Future<void> updateUserBio({
    required String supabaseId,
    required String newBio,
  }) async {
    final online = await isConnected();
    if (!online) throw Exception("No internet connection.");

    final data = await _supabase
        .from('users')
        .update({'bio': newBio})
        .eq('supabase_id', supabaseId)
        .select();
    if ((data as List).isEmpty) {
      throw Exception('Error updating the bio');
    }
    final user = AppUser.User.fromJson(data.first);
    final isar = await _isarFuture;
    await _storeUserInIsar(isar, user);
  }

  /// Retrieves a user by their internal ID.
  Future<AppUser.User?> getUserById(int userId) async {
    final online = await isConnected();
    final isar = await _isarFuture;
    if (online) {
      final data =
          await _supabase.from('users').select().eq('id', userId).maybeSingle();
      if (data == null) {
        return await _loadUserFromIsarById(userId, isar: isar);
      }
      final user = AppUser.User.fromJson(data);
      await _storeUserInIsar(isar, user);
      return user;
    } else {
      return await _loadUserFromIsarById(userId, isar: isar);
    }
  }

  /// Searches users by username.
  Future<List<AppUser.User>> searchUsers(String query) async {
    final online = await isConnected();
    final isar = await _isarFuture;
    if (online) {
      final data =
          await _supabase.from('users').select().ilike('username', '%$query%');
      if ((data as List).isEmpty) return [];
      final fetchedUsers = data
          .map<AppUser.User>((json) => AppUser.User.fromJson(json))
          .toList();
      for (final user in fetchedUsers) {
        await _storeUserInIsar(isar, user);
      }
      return fetchedUsers;
    } else {
      return await _localUserSearch(query, isar);
    }
  }

  /// Retrieves users by a list of Supabase IDs.
  Future<List<AppUser.User>> getUsersBySupabaseIds(
      List<String> supabaseIds) async {
    if (supabaseIds.isEmpty) return [];
    final online = await isConnected();
    final isar = await _isarFuture;
    if (online) {
      final data = await _supabase
          .from('users')
          .select()
          .filter('supabase_id', 'in', '(${supabaseIds.join(",")})');
      if ((data as List).isEmpty) return [];
      final users = data
          .map<AppUser.User>((json) => AppUser.User.fromJson(json))
          .toList();
      for (final user in users) {
        await _storeUserInIsar(isar, user);
      }
      return users;
    } else {
      return await _loadUsersFromIsarBySupabaseIds(supabaseIds, isar: isar);
    }
  }

  /// Retrieves users by a list of internal IDs.
  Future<List<AppUser.User>> getUsersByIds(List<int> userIds) async {
    if (userIds.isEmpty) return [];
    final online = await isConnected();
    final isar = await _isarFuture;
    if (online) {
      final data = await _supabase
          .from('users')
          .select()
          .filter('id', 'in', '(${userIds.join(",")})');
      if ((data as List).isEmpty) return [];
      final users = data
          .map<AppUser.User>((json) => AppUser.User.fromJson(json))
          .toList();
      for (final user in users) {
        await _storeUserInIsar(isar, user);
      }
      return users;
    } else {
      return await _loadUsersFromIsarByIds(userIds, isar: isar);
    }
  }

  /// Retrieves recommended users by calling a Supabase RPC.
  Future<List<AppUser.User>> getRecommendedUsers(
      {int? userId, int limit = 5}) async {
    final online = await isConnected();
    final isar = await _isarFuture;
    if (online) {
      final params = <String, dynamic>{
        'p_user_id': userId,
        'p_limit': limit,
      };
      final response =
          await _supabase.rpc('get_recommended_users', params: params);
      if (response == null || (response as List).isEmpty) return [];
      final users = (response)
          .map<AppUser.User>(
              (json) => AppUser.User.fromJson(json as Map<String, dynamic>))
          .toList();
      for (final user in users) {
        await _storeUserInIsar(isar, user);
      }
      return users;
    } else {
      return await _loadAllUsersFromIsar(isar);
    }
  }

  // --------------------------------------------------------------------------
  // HELPER METHODS FOR CACHE (User & Links)
  // --------------------------------------------------------------------------

  /// Stores a User in Isar (wrapped in a transaction).
  Future<void> _storeUserInIsar(Isar isar, AppUser.User user) async {
    await isar.writeTxn(() async {
      // Try to find an existing record with the same remoteId.
      final existing =
          await isar.isarUsers.filter().remoteIdEqualTo(user.id).findFirst();
      final isarUser = existing ?? IsarUser();
      isarUser.remoteId = user.id;
      isarUser.username = user.username;
      isarUser.email = user.email;
      isarUser.bio = user.bio;
      isarUser.profilePictureUrl = user.profilePictureUrl;
      isarUser.supabaseId = user.supabaseId;
      isarUser.createdAt = user.createdAt;
      await isar.isarUsers.put(isarUser);
    });
  }

  /// Loads a single User from Isar by internal ID.
  Future<AppUser.User?> _loadUserFromIsarById(int userId,
      {required Isar isar}) async {
    final isarUser =
        await isar.isarUsers.filter().remoteIdEqualTo(userId).findFirst();
    if (isarUser == null) return null;
    return AppUser.User(
      id: isarUser.remoteId,
      username: isarUser.username,
      email: isarUser.email,
      bio: isarUser.bio,
      profilePictureUrl: isarUser.profilePictureUrl,
      supabaseId: isarUser.supabaseId,
      createdAt: isarUser.createdAt,
    );
  }

  /// Loads a single User from Isar by Supabase ID.
  Future<AppUser.User?> _loadUserFromIsarBySupabaseId(String supabaseId,
      {required Isar isar}) async {
    final isarUser =
        await isar.isarUsers.filter().supabaseIdEqualTo(supabaseId).findFirst();
    if (isarUser == null) return null;
    return AppUser.User(
      id: isarUser.remoteId,
      username: isarUser.username,
      email: isarUser.email,
      bio: isarUser.bio,
      profilePictureUrl: isarUser.profilePictureUrl,
      supabaseId: isarUser.supabaseId,
      createdAt: isarUser.createdAt,
    );
  }

  /// Loads all Users from Isar.
  Future<List<AppUser.User>> _loadAllUsersFromIsar(Isar isar) async {
    final users = await isar.isarUsers.where().findAll();
    return users
        .map((isarUser) => AppUser.User(
              id: isarUser.remoteId,
              username: isarUser.username,
              email: isarUser.email,
              bio: isarUser.bio,
              profilePictureUrl: isarUser.profilePictureUrl,
              supabaseId: isarUser.supabaseId,
              createdAt: isarUser.createdAt,
            ))
        .toList();
  }

  /// Loads Users from Isar filtering by a list of internal IDs.
  Future<List<AppUser.User>> _loadUsersFromIsarByIds(List<int> userIds,
      {required Isar isar}) async {
    final users = await isar.isarUsers
        .filter()
        .anyOf(userIds, (q, id) => q.remoteIdEqualTo(id))
        .findAll();
    return users
        .map((isarUser) => AppUser.User(
              id: isarUser.remoteId,
              username: isarUser.username,
              email: isarUser.email,
              bio: isarUser.bio,
              profilePictureUrl: isarUser.profilePictureUrl,
              supabaseId: isarUser.supabaseId,
              createdAt: isarUser.createdAt,
            ))
        .toList();
  }

  /// Loads Users from Isar filtering by a list of Supabase IDs.
  Future<List<AppUser.User>> _loadUsersFromIsarBySupabaseIds(
      List<String> supabaseIds,
      {required Isar isar}) async {
    final users = await isar.isarUsers
        .filter()
        .anyOf(supabaseIds, (q, id) => q.supabaseIdEqualTo(id))
        .findAll();
    return users
        .map((isarUser) => AppUser.User(
              id: isarUser.remoteId,
              username: isarUser.username,
              email: isarUser.email,
              bio: isarUser.bio,
              profilePictureUrl: isarUser.profilePictureUrl,
              supabaseId: isarUser.supabaseId,
              createdAt: isarUser.createdAt,
            ))
        .toList();
  }

  Future<List<AppUser.User>> _localUserSearch(String query, Isar isar) async {
    // Rechercher dans le cache via le champ "username" de IsarUser
    final isarUsers = await isar.isarUsers
        .filter()
        .usernameContains(query, caseSensitive: false)
        .findAll();

    // Utiliser une Map pour garantir l'unicité (clé = remoteId)
    final Map<int, AppUser.User> result = {};
    for (final isarUser in isarUsers) {
      result[isarUser.remoteId] = AppUser.User(
        id: isarUser.remoteId,
        username: isarUser.username,
        email: isarUser.email,
        bio: isarUser.bio,
        profilePictureUrl: isarUser.profilePictureUrl,
        supabaseId: isarUser.supabaseId,
        createdAt: isarUser.createdAt,
      );
    }
    return result.values.toList();
  }
}
