import 'package:flutter/material.dart';
import 'package:sway_events/features/organizer/models/organizer_model.dart';
import 'package:sway_events/features/organizer/services/organizer_service.dart';
import 'package:sway_events/features/user/models/user_permission_model.dart';
import 'package:sway_events/features/user/services/user_permission_service.dart';
import 'package:sway_events/features/user/screens/user_access_management_screen.dart';

class EditOrganizerScreen extends StatefulWidget {
  final Organizer organizer;

  const EditOrganizerScreen({required this.organizer});

  @override
  _EditOrganizerScreenState createState() => _EditOrganizerScreenState();
}

class _EditOrganizerScreenState extends State<EditOrganizerScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.organizer.name);
    _descriptionController =
        TextEditingController(text: widget.organizer.description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updateOrganizer() async {
    final updatedOrganizer = Organizer(
      id: widget.organizer.id,
      name: _nameController.text,
      description: _descriptionController.text,
      imageUrl: widget.organizer.imageUrl,
      upcomingEvents: widget.organizer.upcomingEvents,
    );
    await OrganizerService().updateOrganizer(updatedOrganizer);
    Navigator.pop(context, updatedOrganizer);
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
                    permission.userId, widget.organizer.id, 'organizer');
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
        title: const Text('Edit Organizer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _updateOrganizer,
          ),
          IconButton(
            icon: const Icon(Icons.group),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserAccessManagementScreen(
                    entityId: widget.organizer.id,
                    entityType: 'organizer',
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
                  widget.organizer.id, 'organizer', 'admin'),
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
                                  userId: 'currentUser',
                                  entityId: widget.organizer.id,
                                  entityType: 'organizer',
                                  permission: 'admin'));
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.red,
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: const Text('Delete Organizer'),
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
