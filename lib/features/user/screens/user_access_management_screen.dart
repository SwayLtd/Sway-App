import 'package:flutter/material.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/user/models/user_model.dart';
import 'package:sway/features/user/models/user_permission_model.dart';
import 'package:sway/features/user/screens/user_access_search_screen.dart';
import 'package:sway/features/user/screens/user_entities_screen.dart';
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
  int? currentUserId;

  @override
  void initState() {
    super.initState();
    _checkCurrentUserPermission();
  }

  Future<void> _refreshPermissions() async {
    setState(() {});
  }

  Future<void> _checkCurrentUserPermission() async {
    final currentUser = await UserService().getCurrentUser();
    if (currentUser != null) {
      currentUserId = currentUser.id;
      final isAdmin = await UserPermissionService().hasPermission(
        currentUser.id,
        widget.entityId,
        widget.entityType,
        3, // Admin level
      );
      final isManager = await UserPermissionService().hasPermission(
        currentUser.id,
        widget.entityId,
        widget.entityType,
        2, // Manager level
      );
      if (!mounted) return;
      setState(() {
        isCurrentUserAdmin = isAdmin;
        isCurrentUserManager = isManager;
      });
    }
  }

  // Shows a confirmation dialog for deletion.
  // Returns true if deletion is confirmed.
  Future<bool> _showDeleteConfirmationDialog(
    BuildContext context,
    UserPermission permission,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to remove this user?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                await UserPermissionService().deleteUserPermission(
                  permission.userId,
                  widget.entityId,
                  widget.entityType,
                );
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
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
                // Navigate to the search screen and refresh list upon return.
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserAccessSearchScreen(
                      entityId: widget.entityId,
                      entityType: widget.entityType,
                      isCurrentUserAdmin: isCurrentUserAdmin,
                    ),
                  ),
                ).then((_) {
                  setState(() {}); // refresh list
                });
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPermissions,
        child: FutureBuilder<List<UserPermission>>(
          future: UserPermissionService().getPermissionsByEntity(
            widget.entityId,
            widget.entityType,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator.adaptive());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No users found'));
            } else {
              final permissions = snapshot.data!;
              // Sort permissions in descending order: Admin (3), Manager (2), User (1)
              permissions.sort(
                  (a, b) => b.permissionLevel.compareTo(a.permissionLevel));
              // Count the number of admins.
              final int adminCount =
                  permissions.where((p) => p.permissionLevel == 3).length;
              return ListView.builder(
                itemCount: permissions.length,
                itemBuilder: (context, index) {
                  final permission = permissions[index];
                  return FutureBuilder<User?>(
                    future: UserService().getUserById(permission.userId),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const CircularProgressIndicator.adaptive();
                      } else if (userSnapshot.hasError) {
                        return ListTile(
                            title: Text('Error: ${userSnapshot.error}'));
                      } else if (!userSnapshot.hasData ||
                          userSnapshot.data == null) {
                        return const ListTile(title: Text('User not found'));
                      } else {
                        final user = userSnapshot.data!;
                        // Everyone sees the dropdown.
                        bool dropdownEnabled = false;
                        if (isCurrentUserAdmin) {
                          // Admin can modify any role.
                          dropdownEnabled = true;
                          // If it's an admin record and there's only one admin, disable dropdown.
                          if (permission.permissionLevel == 3 &&
                              adminCount == 1) {
                            dropdownEnabled = false;
                          }
                        } else if (isCurrentUserManager) {
                          // Managers cannot change roles.
                          dropdownEnabled = false;
                        } else {
                          // Regular user: dropdown is disabled.
                          dropdownEnabled = false;
                        }
                        // Determine if delete button should be enabled.
                        bool canDelete = false;
                        if (isCurrentUserAdmin) {
                          // For an admin, allow deletion unless the record is for an admin and it is the only one.
                          if (permission.permissionLevel == 3 &&
                              adminCount == 1) {
                            canDelete = false;
                          } else {
                            canDelete = true;
                          }
                        } else if (isCurrentUserManager) {
                          // For managers: they can delete permission records with level 1 for others,
                          // but they can also delete their own record even if it is level 2.
                          if (permission.userId == currentUserId) {
                            canDelete = true;
                          } else {
                            canDelete = (permission.permissionLevel == 1);
                          }
                        }

                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: ImageWithErrorHandler(
                              imageUrl: user.profilePictureUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(user.username),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DropdownButton<int>(
                                value: permission.permissionLevel,
                                items: <int>[3, 2, 1]
                                    .map((int value) => DropdownMenuItem<int>(
                                          value: value,
                                          child: Text(getRoleLabel(value)),
                                        ))
                                    .toList(),
                                onChanged: dropdownEnabled
                                    ? (int? newValue) async {
                                        if (newValue != null) {
                                          setState(() {
                                            permission.permissionLevel =
                                                newValue;
                                          });
                                          await UserPermissionService()
                                              .updateUserPermission(
                                            permission.userId,
                                            widget.entityId,
                                            widget.entityType,
                                            newValue,
                                          );
                                          await _refreshPermissions(); // Refresh after update
                                        }
                                      }
                                    : null,
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: canDelete
                                    ? () async {
                                        bool deleted =
                                            await _showDeleteConfirmationDialog(
                                                context, permission);
                                        if (deleted) {
                                          setState(() {}); // refresh list
                                          // If current user deleted their own permission, redirect.
                                          if (currentUserId != null &&
                                              permission.userId ==
                                                  currentUserId) {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    UserEntitiesScreen(
                                                        userId: currentUserId!),
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    : null,
                              ),
                            ],
                          ),
                          onTap: () {
                            // Navigation logic if necessary.
                          },
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
    );
  }
}
