import 'package:flutter/material.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/promoter/services/promoter_service.dart';
import 'package:sway/features/user/models/user_permission_model.dart';
import 'package:sway/features/user/screens/user_access_management_screen.dart';
import 'package:sway/features/user/services/user_permission_service.dart';

class EditPromoterScreen extends StatefulWidget {
  final Promoter promoter;

  const EditPromoterScreen({required this.promoter});

  @override
  _EditPromoterScreenState createState() => _EditPromoterScreenState();
}

class _EditPromoterScreenState extends State<EditPromoterScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.promoter.name);
    _descriptionController =
        TextEditingController(text: widget.promoter.description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updatePromoter() async {
    final updatedPromoter = Promoter(
      id: widget.promoter.id,
      name: _nameController.text,
      description: _descriptionController.text,
      imageUrl: widget.promoter.imageUrl,
      upcomingEvents: widget.promoter.upcomingEvents,
    );
    await PromoterService().updatePromoter(updatedPromoter);
    Navigator.pop(context, updatedPromoter);
  }

  Future<void> _showDeleteConfirmationDialog(
      BuildContext context, UserPermission permission,) async {
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
                    permission.userId, widget.promoter.id, 'promoter',);
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
        title: const Text('Edit Promoter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _updatePromoter,
          ),
          IconButton(
            icon: const Icon(Icons.group),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserAccessManagementScreen(
                    entityId: widget.promoter.id,
                    entityType: 'promoter',
                  ),
                ),
              );
              setState(() {});
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 20),
            FutureBuilder<bool>(
              future: UserPermissionService().hasPermissionForCurrentUser(
                  widget.promoter.id, 'promoter', 'admin',),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError ||
                    !snapshot.hasData ||
                    !snapshot.data!) {
                  return const SizedBox.shrink();
                } else {
                  return Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: ElevatedButton(
                        onPressed: () {
                          _showDeleteConfirmationDialog(
                              context,
                              UserPermission(
                                  userId: 3,
                                  entityId: widget.promoter.id,
                                  entityType: 'promoter',
                                  permission: 'admin',),);
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.red,
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: const Text('Delete Promoter'),
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
