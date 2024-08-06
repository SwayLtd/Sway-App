import 'package:flutter/material.dart';
import 'package:sway_events/features/user/models/user_permission_model.dart';
import 'package:sway_events/features/user/screens/user_access_management_screen.dart';
import 'package:sway_events/features/user/services/user_permission_service.dart';
import 'package:sway_events/features/venue/models/venue_model.dart';
import 'package:sway_events/features/venue/services/venue_service.dart';

class EditVenueScreen extends StatefulWidget {
  final Venue venue;

  const EditVenueScreen({required this.venue});

  @override
  _EditVenueScreenState createState() => _EditVenueScreenState();
}

class _EditVenueScreenState extends State<EditVenueScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.venue.name);
    _descriptionController =
        TextEditingController(text: widget.venue.description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updateVenue() async {
    final updatedVenue = Venue(
      id: widget.venue.id,
      name: _nameController.text,
      description: _descriptionController.text,
      imageUrl: widget.venue.imageUrl,
      location: widget.venue.location,
    );
    await VenueService().updateVenue(updatedVenue);
    Navigator.pop(context, updatedVenue);
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
                    permission.userId, widget.venue.id, 'venue',);
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
        title: const Text('Edit Venue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _updateVenue,
          ),
          IconButton(
            icon: const Icon(Icons.group),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserAccessManagementScreen(
                    entityId: widget.venue.id,
                    entityType: 'venue',
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
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
              ],
            ),
            FutureBuilder<bool>(
              future: UserPermissionService().hasPermissionForCurrentUser(
                  widget.venue.id, 'venue', 'admin',),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError ||
                    !snapshot.hasData ||
                    !snapshot.data!) {
                  return const SizedBox.shrink();
                } else {
                  return Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: ElevatedButton(
                      onPressed: () {
                        _showDeleteConfirmationDialog(
                            context,
                            UserPermission(
                                userId: 'currentUser',
                                entityId: widget.venue.id,
                                entityType: 'venue',
                                permission: 'admin',),);
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.red,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text('Delete Venue'),
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
