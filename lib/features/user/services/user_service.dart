import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway_events/features/user/models/user_model.dart';

class UserService {
  Future<User?> getUserById(String userId) async {
    final String response = await rootBundle.loadString('assets/databases/users.json');
    final List<dynamic> userJson = json.decode(response) as List<dynamic>;
    try {
      final user = userJson.firstWhere((user) => user['id'] == userId);
      return User.fromJson(user as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<List<User>> getUsersByIds(List<String> userIds) async {
    final String response = await rootBundle.loadString('assets/databases/users.json');
    final List<dynamic> usersJson = json.decode(response) as List<dynamic>;

    return usersJson
        .map((userJson) => User.fromJson(userJson as Map<String, dynamic>))
        .where((user) => userIds.contains(user.id))
        .toList();
  }

  Future<void> updateUser(User updatedUser) async {
    final String response = await rootBundle.loadString('assets/databases/users.json');
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
}
