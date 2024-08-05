// edit_event_screen.dart

import 'package:flutter/material.dart';
import 'package:sway_events/features/event/models/event_model.dart';
import 'package:sway_events/features/event/services/event_service.dart';
import 'package:sway_events/features/user/models/user_permission_model.dart';
import 'package:sway_events/features/user/screens/user_access_management_screen.dart';
import 'package:sway_events/features/user/services/user_permission_service.dart';

class EditEventScreen extends StatefulWidget {
  final Event event;

  const EditEventScreen({required this.event});

  @override
  _EditEventScreenState createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late List<String> _selectedGenres;
  late List<String> _selectedArtists;
  late List<String> _selectedPromoters;
  late String _selectedType;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _descriptionController =
        TextEditingController(text: widget.event.description);
    _priceController = TextEditingController(text: widget.event.price);
    _selectedGenres = List<String>.from(widget.event.genres);
    _selectedArtists = List<String>.from(widget.event.artists);
    _selectedPromoters = List<String>.from(widget.event.promoters);
    _selectedType = widget.event.type;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _updateEvent() async {
    final updatedEvent = Event(
      id: widget.event.id,
      title: _titleController.text,
      type: _selectedType,
      description: _descriptionController.text,
      price: _priceController.text,
      dateTime: widget.event.dateTime,
      endDateTime: widget.event.endDateTime,
      venue: widget.event.venue,
      imageUrl: widget.event.imageUrl,
      promoters: _selectedPromoters,
      distance: widget.event.distance,
      genres: _selectedGenres,
      artists: _selectedArtists,
    );
    await EventService().updateEvent(updatedEvent);
    Navigator.pop(context, updatedEvent);
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
                  widget.event.id,
                  'event',
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
        title: const Text('Edit Event'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _updateEvent,
          ),
          IconButton(
            icon: const Icon(Icons.group),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserAccessManagementScreen(
                    entityId: widget.event.id,
                    entityType: 'event',
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
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price'),
            ),
            const SizedBox(height: 20),
            DropdownButton<String>(
              value: _selectedType,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedType = newValue!;
                });
              },
              items: <String>['festival', 'party', 'concert']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8.0,
              children: _selectedGenres
                  .map(
                    (genre) => Chip(
                      label: Text(genre),
                      onDeleted: () {
                        setState(() {
                          _selectedGenres.remove(genre);
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
            Wrap(
              spacing: 8.0,
              children: _selectedArtists
                  .map(
                    (artist) => Chip(
                      label: Text(artist),
                      onDeleted: () {
                        setState(() {
                          _selectedArtists.remove(artist);
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
            Wrap(
              spacing: 8.0,
              children: _selectedPromoters
                  .map(
                    (promoter) => Chip(
                      label: Text(promoter),
                      onDeleted: () {
                        setState(() {
                          _selectedPromoters.remove(promoter);
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
            FutureBuilder<bool>(
              future: UserPermissionService().hasPermissionForCurrentUser(
                widget.event.id,
                'event',
                'admin',
              ),
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
                              entityId: widget.event.id,
                              entityType: 'event',
                              permission: 'admin',
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.red,
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: const Text('Delete Event'),
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
