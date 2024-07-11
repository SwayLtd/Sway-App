import 'package:flutter/material.dart';
import 'package:sway_events/features/user/models/user_model.dart';
import 'package:sway_events/features/user/screens/user_search_screen.dart';
import 'package:sway_events/features/user/services/user_permission_service.dart';
import 'package:sway_events/features/user/models/user_permission_model.dart';
import 'package:sway_events/features/user/services/user_service.dart';

class UserAccessManagementScreen extends StatefulWidget {
  final String entityId;
  final String entityType;

  const UserAccessManagementScreen(
      {required this.entityId, required this.entityType});

  @override
  _UserAccessManagementScreenState createState() =>
      _UserAccessManagementScreenState();
}

class _UserAccessManagementScreenState
    extends State<UserAccessManagementScreen> {
  List<User> _currentUsers = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentUsers();
  }

  Future<void> _loadCurrentUsers() async {
    final permissions = await UserPermissionService()
        .getPermissionsByEntity(widget.entityId, widget.entityType);
    final users = await Future.wait(permissions
        .map((permission) => UserService().getUserById(permission.userId)));
    setState(() {
      _currentUsers = users.whereType<User>().toList();
    });
  }

  void _addUser(User user, String role) {
    setState(() {
      _currentUsers.add(user);
      UserPermissionService()
          .addUserPermission(user.id, widget.entityId, widget.entityType, role);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Access Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserSearchScreen(
                    excludedUsers: _currentUsers,
                    onUserSelected: (user, role) {
                      _addUser(user, role);
                    },
                  ),
                ),
              );
              _loadCurrentUsers();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<UserPermission>>(
        future: UserPermissionService()
            .getPermissionsByEntity(widget.entityId, widget.entityType),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No users found'));
          } else {
            final permissions = snapshot.data!;
            return ListView.builder(
              itemCount: permissions.length,
              itemBuilder: (context, index) {
                final permission = permissions[index];
                return FutureBuilder<User?>(
                  future: UserService().getUserById(permission.userId),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (userSnapshot.hasError) {
                      return ListTile(
                        title: Text('Error: ${userSnapshot.error}'),
                      );
                    } else if (!userSnapshot.hasData ||
                        userSnapshot.data == null) {
                      return const ListTile(
                        title: Text('User not found'),
                      );
                    } else {
                      final user = userSnapshot.data!;
                      return ListTile(
                        title: Text(user.username),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DropdownButton<String>(
                              value: permission.permission,
                              items: <String>[
                                'owner',
                                'manager',
                                'user'
                              ].map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (String? newRole) {
                                if (newRole != null) {
                                  setState(() {
                                    permission.permission = newRole;
                                    UserPermissionService()
                                        .saveUserPermissions(permissions);
                                  });
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                _showDeleteConfirmationDialog(
                                    context, permission);
                              },
                            ),
                          ],
                        ),
                      );
                    }
                  },
                );
              },
            );
          }
        },
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(
      BuildContext context, UserPermission permission) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to remove this user?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                await UserPermissionService().deleteUserPermission(
                    permission.userId, widget.entityId, widget.entityType);
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }
}
