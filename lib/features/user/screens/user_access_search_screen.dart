import 'package:flutter/material.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/user/models/user_model.dart';
import 'package:sway/features/user/services/user_permission_service.dart';
import 'package:sway/features/user/services/user_service.dart';

class UserAccessSearchScreen extends StatefulWidget {
  final int entityId;
  final String entityType;
  final bool isCurrentUserAdmin;

  const UserAccessSearchScreen({
    required this.entityId,
    required this.entityType,
    required this.isCurrentUserAdmin,
  });

  @override
  _UserAccessSearchScreenState createState() => _UserAccessSearchScreenState();
}

class _UserAccessSearchScreenState extends State<UserAccessSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<User> _searchResults = [];
  int selectedRole = 1; // Default role is User (level 1)

  // Fonction locale pour obtenir le libellé du rôle
  String getRoleLabel(int level) {
    switch (level) {
      case 3:
        return "Admin";
      case 2:
        return "Manager";
      case 1:
      default:
        return "User";
    }
  }

  Future<void> _searchUsers() async {
    final users = await UserService().searchUsers(_searchController.text);
    final existingPermissions = await UserPermissionService()
        .getPermissionsByEntity(widget.entityId, widget.entityType);
    final existingUserIds =
        existingPermissions.map((permission) => permission.userId).toSet();

    if (!mounted) return;
    setState(() {
      _searchResults =
          users.where((user) => !existingUserIds.contains(user.id)).toList();
    });
  }

  void _showRoleSelectionDialog(User user) {
    // If current user is admin, allow roles 3, 2, 1; otherwise, only 1.
    final availableRoles = widget.isCurrentUserAdmin ? [3, 2, 1] : [1];

    // Descriptions pour chaque rôle
    String getRoleDescription(int role) {
      switch (role) {
        case 3:
          return "Allows modifying, deleting the entity and managing full access.";
        case 2:
          return "Allows modifying the entity and managing part of the access.";
        case 1:
        default:
          return "Allows viewing information related to the entity.";
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Role'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButton<int>(
                    value: selectedRole,
                    items:
                        availableRoles.map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(getRoleLabel(value)),
                      );
                    }).toList(),
                    onChanged: (int? newRole) {
                      if (newRole != null) {
                        if (!mounted) return;
                        setState(() {
                          selectedRole = newRole;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    getRoleDescription(selectedRole),
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
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
                if (!mounted) return;
                setState(() {
                  _searchResults.remove(user);
                });
                // Afficher la snackbar flottante
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Text(
                      "Permission '${getRoleLabel(selectedRole)}' added to ${user.username}",
                    ),
                  ),
                );
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
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: ImageWithErrorHandler(
                      imageUrl: user.profilePictureUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(
                    user.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_box),
                    onPressed: () {
                      _showRoleSelectionDialog(user);
                    },
                  ),
                  onTap: () {
                    _showRoleSelectionDialog(user);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
