// user_access_management_screen.dart

import 'package:flutter/material.dart';
import 'package:sway/features/user/models/user_model.dart';
import 'package:sway/features/user/models/user_permission_model.dart';
import 'package:sway/features/user/screens/user_access_search_screen.dart';
import 'package:sway/features/user/services/user_permission_service.dart';
import 'package:sway/features/user/services/user_service.dart';

class UserAccessManagementScreen extends StatefulWidget {
  final int entityId;
  final String entityType;

  const UserAccessManagementScreen({
    required this.entityId,
    required this.entityType,
  });

  @override
  _UserAccessManagementScreenState createState() =>
      _UserAccessManagementScreenState();
}

class _UserAccessManagementScreenState
    extends State<UserAccessManagementScreen> {
  bool isCurrentUserAdmin = false;
  bool isCurrentUserManager = false;

  @override
  void initState() {
    super.initState();
    _checkCurrentUserPermission();
  }

  Future<void> _checkCurrentUserPermission() async {
    final currentUser = await UserService().getCurrentUser();
    if (currentUser != null) {
      final isAdmin = await UserPermissionService().hasPermission(
        currentUser.id,
        widget.entityId,
        widget.entityType,
        'admin',
      );
      final isManager = await UserPermissionService().hasPermission(
        currentUser.id,
        widget.entityId,
        widget.entityType,
        'manager',
      );
      setState(() {
        isCurrentUserAdmin = isAdmin;
        isCurrentUserManager = isManager;
      });
    }
  }

  Future<void> _showDeleteConfirmationDialog(
    BuildContext context,
    UserPermission permission,
  ) async {
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
                  permission.userId,
                  widget.entityId,
                  widget.entityType,
                );
                Navigator.of(context).pop();
                setState(() {});
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
        actions: [
          if (isCurrentUserAdmin || isCurrentUserManager)
            IconButton(
              icon: const Icon(Icons.group_add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserAccessSearchScreen(
                      entityId: widget.entityId,
                      entityType: widget.entityType,
                      isCurrentUserAdmin: isCurrentUserAdmin,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<UserPermission>>(
              future: UserPermissionService().getPermissionsByEntity(
                widget.entityId,
                widget.entityType,
              ),
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
                                  if (isCurrentUserAdmin)
                                    DropdownButton<String>(
                                      value: permission.permission,
                                      items: <String>[
                                        'admin',
                                        'manager',
                                        'user',
                                      ].map<DropdownMenuItem<String>>(
                                          (String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value[0].toUpperCase() +
                                              value.substring(1),),
                                        );
                                      }).toList(),
                                      onChanged: (String? newRole) {
                                        if (newRole != null) {
                                          setState(() {
                                            permission.permission = newRole;
                                            UserPermissionService()
                                                .saveUserPermissions(
                                              permissions,
                                            );
                                          });
                                        }
                                      },
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      _showDeleteConfirmationDialog(
                                        context,
                                        permission,
                                      );
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
          ),
        ],
      ),
    );
  }
}
