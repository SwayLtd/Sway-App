// user_search_screen.dart

import 'package:flutter/material.dart';
import 'package:sway_events/features/user/models/user_model.dart';
import 'package:sway_events/features/user/services/user_service.dart';

class UserSearchScreen extends StatefulWidget {
  final List<User> excludedUsers;
  final Function(User, String) onUserSelected;

  const UserSearchScreen({required this.excludedUsers, required this.onUserSelected});

  @override
  _UserSearchScreenState createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<User> _searchResults = [];

  Future<void> _searchUsers() async {
    final allUsers = await UserService().searchUsers(_searchController.text);
    final results = allUsers.where((user) => !widget.excludedUsers.any((excludedUser) => excludedUser.id == user.id)).toList();
    setState(() {
      _searchResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _searchUsers,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Users',
              ),
              onChanged: (value) {
                _searchUsers();
              },
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  return ListTile(
                    title: Text(user.username),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_box),
                      onPressed: () {
                        _showRoleDialog(context, user);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRoleDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String selectedRole = 'user';
        return AlertDialog(
          title: const Text('Select Role'),
          content: DropdownButton<String>(
            value: selectedRole,
            items: <String>['owner', 'manager', 'user']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newRole) {
              if (newRole != null) {
                setState(() {
                  selectedRole = newRole;
                });
              }
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                widget.onUserSelected(user, selectedRole);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
