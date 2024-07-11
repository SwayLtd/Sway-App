// edit_organizer_screen.dart

import 'package:flutter/material.dart';
import 'package:sway_events/features/organizer/models/organizer_model.dart';
import 'package:sway_events/features/organizer/services/organizer_service.dart';
import 'package:sway_events/features/user/screens/user_access_management_screen.dart';
import 'package:sway_events/features/user/services/user_permission_service.dart';

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

  Future<void> _showDeleteConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button for dialog to close
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content:
              const Text('Are you sure you want to delete this organizer?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                await _deleteOrganizer();
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteOrganizer() async {
    await OrganizerService().deleteOrganizer(widget.organizer.id);
    Navigator.pop(context, true); // Retourner un indicateur de suppression
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
          FutureBuilder<bool>(
            future: UserPermissionService().hasPermissionForCurrentUser(
                widget.organizer.id, 'organizer', 'owner'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              } else if (snapshot.hasError ||
                  !snapshot.hasData ||
                  !snapshot.data!) {
                return const SizedBox.shrink();
              } else {
                return IconButton(
                  icon: const Icon(Icons.account_tree),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserAccessManagementScreen(
                            entityId: widget.organizer.id,
                            entityType: 'organizer'),
                      ),
                    );
                  },
                );
              }
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
                  widget.organizer.id, 'organizer', 'owner'),
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
                        onPressed: _showDeleteConfirmationDialog,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.red,
                          minimumSize: const Size.fromHeight(
                              50), // Set width to fill the screen
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
