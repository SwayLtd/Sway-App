// user_access_management_screen.dart

import 'package:flutter/material.dart';
import 'package:sway_events/features/user/models/user_model.dart';
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
  void _showDeleteConfirmationDialog(
      BuildContext context, UserPermission permission) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text(
              'Are you sure you want to delete this user from the entity?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Fermer la boîte de dialogue
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                await UserPermissionService().deleteUserPermission(
                  permission.userId,
                  permission.entityId,
                  permission.entityType,
                );
                Navigator.of(context).pop(); // Fermer la boîte de dialogue
                setState(() {}); // Redessiner l'écran après suppression
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
        title: const Text('User Access Management'),
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
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(user.username)),
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
}
