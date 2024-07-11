// user_service.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway_events/features/user/models/user_model.dart';
import 'package:flutter/foundation.dart'; // Ajout pour debugPrint

class UserService {
  Future<User?> getUserById(String userId) async {
    final String response =
        await rootBundle.loadString('assets/databases/users.json');
    final List<dynamic> userJson = json.decode(response) as List<dynamic>;
    try {
      final user = userJson.firstWhere((user) => user['id'] == userId);
      return User.fromJson(user as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<List<User>> searchUsers(String query) async {
    debugPrint("Searching users with query: $query");
    final String response =
        await rootBundle.loadString('assets/databases/users.json');
    final List<dynamic> userJson = json.decode(response) as List<dynamic>;

    final users = userJson.map((json) {
      debugPrint("Converting JSON to User: $json");
      return User.fromJson(json as Map<String, dynamic>);
    }).toList();

    final results = users.where((user) {
      final matches = user.username.toLowerCase().contains(query.toLowerCase());
      debugPrint("Checking user: ${user.username}, Matches: $matches");
      return matches;
    }).toList();

    debugPrint("Search results: ${results.map((u) => u.username).join(', ')}");
    return results;
  }

  Future<List<User>> getUsersByIds(List<String> userIds) async {
    final String response =
        await rootBundle.loadString('assets/databases/users.json');
    final List<dynamic> usersJson = json.decode(response) as List<dynamic>;

    return usersJson
        .map((userJson) => User.fromJson(userJson as Map<String, dynamic>))
        .where((user) => userIds.contains(user.id))
        .toList();
  }

  Future<void> updateUser(User updatedUser) async {
    final String response =
        await rootBundle.loadString('assets/databases/users.json');
    final List<dynamic> usersJson = json.decode(response) as List<dynamic>;

    final index = usersJson.indexWhere((user) => user['id'] == updatedUser.id);
    if (index != -1) {
      usersJson[index] = updatedUser.toJson();
      // Save updated list back to the file (assuming you have a method for this)
      await saveUserData(usersJson);
    }
  }

  Future<void> saveUserData(List<dynamic> data) async {
    // Implement saving logic here, depending on how you manage your local storage
  }

  // Nouvelle méthode pour obtenir l'utilisateur actuellement connecté
  Future<User?> getCurrentUser() async {
    // Logic to get current user ID, for now, assuming we store current user ID in local storage
    const currentUserId = "3"; // Utilisateur actuel avec ID 3

    return getUserById(currentUserId);
  }
}
