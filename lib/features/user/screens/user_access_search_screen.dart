// user_access_search_screen.dart

import 'package:flutter/material.dart';
import 'package:sway_events/features/user/models/user_model.dart';
import 'package:sway_events/features/user/services/user_permission_service.dart';
import 'package:sway_events/features/user/services/user_service.dart';

class UserAccessSearchScreen extends StatefulWidget {
  final String entityId;
  final String entityType;
  final bool isCurrentUserAdmin;

  const UserAccessSearchScreen(
      {required this.entityId,
      required this.entityType,
      required this.isCurrentUserAdmin,});

  @override
  _UserAccessSearchScreenState createState() => _UserAccessSearchScreenState();
}

class _UserAccessSearchScreenState extends State<UserAccessSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<User> _searchResults = [];
  String selectedRole = 'user'; // Default role

  Future<void> _searchUsers() async {
    final users = await UserService().searchUsers(_searchController.text);
    final existingPermissions = await UserPermissionService()
        .getPermissionsByEntity(widget.entityId, widget.entityType);
    final existingUserIds =
        existingPermissions.map((permission) => permission.userId).toSet();

    setState(() {
      _searchResults =
          users.where((user) => !existingUserIds.contains(user.id)).toList();
    });
  }

  void _showRoleSelectionDialog(User user) {
    final availableRoles =
        widget.isCurrentUserAdmin ? ['admin', 'manager', 'user'] : ['user'];
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Role'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return DropdownButton<String>(
                value: selectedRole,
                items: availableRoles
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value[0].toUpperCase() + value.substring(1)),
                  );
                }).toList(),
                onChanged: (String? newRole) {
                  if (newRole != null) {
                    setState(() {
                      selectedRole = newRole;
                    });
                  }
                },
              );
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
              onPressed: () async {
                await UserPermissionService().addUserPermission(
                  user.id,
                  widget.entityId,
                  widget.entityType,
                  selectedRole,
                );
                Navigator.of(context).pop();
                setState(() {
                  _searchResults.remove(user);
                });
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Users'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search Users',
                    ),
                    onChanged: (value) {
                      _searchUsers();
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchUsers,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final user = _searchResults[index];
                return ListTile(
                  title: GestureDetector(
                    onTap: () {
                      _showRoleSelectionDialog(user);
                    },
                    child: Text(user.username),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_box),
                    onPressed: () {
                      _showRoleSelectionDialog(user);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
