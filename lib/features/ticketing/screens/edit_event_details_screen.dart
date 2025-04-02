// lib/features/ticketing/screens/edit_event_details_screen.dart

import 'package:flutter/material.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/services/event_service.dart';
import 'package:sway/features/ticketing/models/ticket_model.dart';
import 'package:sway/features/ticketing/services/ticket_service.dart';
import 'package:sway/features/event/services/event_venue_service.dart';
import 'package:sway/features/ticketing/ticketing.dart';
import 'package:sway/features/venue/models/venue_model.dart';
import 'package:sway/features/notification/services/notification_service.dart';
import 'package:sway/features/user/services/user_service.dart';

class EditEventDetailsScreen extends StatefulWidget {
  final Ticket ticket;

  const EditEventDetailsScreen({required this.ticket});

  @override
  _EditEventDetailsScreenState createState() => _EditEventDetailsScreenState();
}

class _EditEventDetailsScreenState extends State<EditEventDetailsScreen> {
  final EventService _eventService = EventService();
  final TicketService _ticketService = TicketService();
  final EventVenueService _eventVenueService = EventVenueService();

  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _eventLocationController =
      TextEditingController();
  DateTime? _eventDate;
  Event? _selectedEvent;
  List<Event> _events = [];
  List<Event> _filteredEvents = [];
  final TextEditingController _searchController = TextEditingController();
  final Map<String, dynamic> _filters = {};

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _eventNameController.text = widget.ticket.eventName ?? '';
    _eventLocationController.text = widget.ticket.eventLocation ?? '';
    _eventDate = widget.ticket.eventDate;

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _eventLocationController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    try {
      _events =
          await _eventService.searchEvents(_searchController.text, _filters);
      if (!mounted) return;
      setState(() {
        _filteredEvents = _events.take(5).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Error fetching events: $e'),
        ),
      );
    }
  }

  void _onSearchChanged() async {
    await _loadEvents();
  }

  Future<void> _saveDetails() async {
    debugPrint('[_saveDetails] Start saving details'); // Log
    final updatedTicket = Ticket(
      id: widget.ticket.id,
      filePath: widget.ticket.filePath,
      eventId: _selectedEvent?.id,
      eventName: _selectedEvent?.title ?? _eventNameController.text,
      eventDate: _eventDate,
      eventLocation: _eventLocationController.text,
      ticketType: widget.ticket.ticketType,
      importedDate: widget.ticket.importedDate,
      groupId: widget.ticket.groupId,
    );

    debugPrint(
        '[_saveDetails] Updated ticket: ${updatedTicket.toMap()}'); // Log

    try {
      await _ticketService.updateTicket(updatedTicket);
      debugPrint('[_saveDetails] Ticket updated in local storage'); // Log

      if (updatedTicket.groupId != null) {
        debugPrint(
            '[_saveDetails] groupId found, updating related tickets'); // Log
        List<Ticket> allTickets = await _ticketService.getTickets();
        List<Ticket> relatedTickets = allTickets
            .where((t) =>
                t.groupId == updatedTicket.groupId && t.id != updatedTicket.id)
            .toList();

        for (Ticket t in relatedTickets) {
          t.eventId = updatedTicket.eventId;
          t.eventName = updatedTicket.eventName;
          t.eventDate = updatedTicket.eventDate;
          t.eventLocation = updatedTicket.eventLocation;
          t.ticketType = updatedTicket.ticketType;

          debugPrint(
              '[_saveDetails] Updating related ticket with id ${t.id}'); // Log
          await _ticketService.updateTicket(t);
        }
      }

      // Vérifier si l'événement n'est pas terminé
      if (_selectedEvent != null && _eventDate != null) {
        debugPrint(
            '[_saveDetails] Event selected. Attempting to set notification.'); // Log

        // Si l'événement est déjà passé, on ne programme pas de notif
        final now = DateTime.now();
        if (_eventDate!.isBefore(now)) {
          debugPrint(
              '[_saveDetails] Event ended. No ticket notification scheduled.');
        } else {
          final user = await UserService().getCurrentUser();
          if (user != null && user.supabaseId.isNotEmpty) {
            final supabaseId = user.supabaseId;
            debugPrint('[_saveDetails] User supabaseId: $supabaseId'); // Log

            debugPrint(
                '[_saveDetails] Calling upsertTicketNotification...'); // Log
            await NotificationService().upsertTicketNotification(
              supabaseId: supabaseId,
              ticket: updatedTicket,
              eventStartTime: _eventDate!,
            );
            debugPrint('[_saveDetails] Notification upserted'); // Log
          } else {
            debugPrint(
                '[_saveDetails] No user found or supabaseId is empty, cannot set notification');
          }
        }
      } else {
        debugPrint(
            '[_saveDetails] No event selected, attempting to delete notification'); // Log
        final user = await UserService().getCurrentUser();
        if (user != null && user.supabaseId.isNotEmpty) {
          final supabaseId = user.supabaseId;
          debugPrint('[_saveDetails] User supabaseId: $supabaseId'); // Log

          await NotificationService().deleteTicketNotification(
            supabaseId: supabaseId,
            ticketId: updatedTicket.id,
          );
          debugPrint('[_saveDetails] Notification deleted'); // Log
        } else {
          debugPrint(
              '[_saveDetails] No user found or supabaseId is empty, cannot delete notification');
        }
      }

      debugPrint('[_saveDetails] Navigation to TicketingScreen'); // Log
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TicketingScreen(),
        ),
      );
    } catch (e) {
      debugPrint('[_saveDetails] Error saving event details: $e'); // Log error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Error saving event details: $e'),
        ),
      );
    }
  }

  Future<void> _selectEvent(Event event) async {
    debugPrint(
        '[_selectEvent] Event selected: ${event.id!} - ${event.title}'); // Log
    Venue? venue = await _eventVenueService.getVenueByEventId(event.id!);
    if (!mounted) return;
    setState(() {
      _selectedEvent = event;
      _eventNameController.text = event.title;
      _eventDate = event.eventDateTime;
      _eventLocationController.text = venue?.name ?? 'Venue not found';
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[EditEventDetailsScreen] build called'); // Log
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add event details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveDetails,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Event Field
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Events',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Search Results
            Expanded(
              child: _filteredEvents.isNotEmpty
                  ? ListView.builder(
                      itemCount: _filteredEvents.length,
                      itemBuilder: (context, index) {
                        Event event = _filteredEvents[index];
                        return ListTile(
                          leading: event.imageUrl.isNotEmpty
                              ? ImageWithErrorHandler(
                                  imageUrl: event.imageUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.event, size: 50),
                          title: Text(
                            event.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                              '${event.eventDateTime.toLocal().toString().split(' ')[0]}'),
                          onTap: () => _selectEvent(event),
                        );
                      },
                    )
                  : const Center(
                      child: Text(
                        'No events found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            // Event Name
            TextField(
              controller: _eventNameController,
              decoration: const InputDecoration(labelText: 'Event Name'),
              readOnly: true,
            ),
            const SizedBox(height: 16),
            // Event Date
            ListTile(
              title: Text(
                _eventDate != null
                    ? _eventDate!.toLocal().toString().split(' ')[0]
                    : 'Select Event Date',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                if (_selectedEvent != null) {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _eventDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    if (!mounted) return;
                    setState(() {
                      _eventDate = pickedDate;
                    });
                  }
                }
              },
            ),

            // Event Location
            TextField(
              controller: _eventLocationController,
              decoration: const InputDecoration(labelText: 'Event Location'),
              readOnly: true,
            ),
          ],
        ),
      ),
    );
  }
}
