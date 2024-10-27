// lib/features/ticketing/screens/add_event_details_screen.dart

import 'package:flutter/material.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/services/event_service.dart';
import 'package:sway/features/ticketing/models/ticket_model.dart';
import 'package:sway/features/ticketing/services/ticket_service.dart';
import 'package:sway/features/event/services/event_venue_service.dart';
import 'package:sway/features/venue/models/venue_model.dart';

class AddEventDetailsScreen extends StatefulWidget {
  final Ticket ticket;

  const AddEventDetailsScreen({required this.ticket});

  @override
  _AddEventDetailsScreenState createState() => _AddEventDetailsScreenState();
}

class _AddEventDetailsScreenState extends State<AddEventDetailsScreen> {
  final EventService _eventService = EventService();
  final TicketService _ticketService = TicketService();
  final EventVenueService _eventVenueService = EventVenueService();

  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _eventLocationController = TextEditingController();
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
      _events = await _eventService.searchEvents(_searchController.text, _filters);
      setState(() {
        _filteredEvents = _events.take(5).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching events: $e')),
      );
    }
  }

  void _onSearchChanged() async {
    await _loadEvents();
  }

  Future<void> _saveDetails() async {
    final updatedTicket = Ticket(
      id: widget.ticket.id,
      filePath: widget.ticket.filePath,
      eventId: _selectedEvent?.id,
      eventName: _selectedEvent?.title ?? _eventNameController.text,
      eventDate: _eventDate,
      eventLocation: _eventLocationController.text,
      ticketType: widget.ticket.ticketType,
      importedDate: widget.ticket.importedDate,
    );

    try {
      await _ticketService.updateTicket(updatedTicket);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving event details: $e')),
      );
    }
  }

  Future<void> _selectEvent(Event event) async {
    Venue? venue = await _eventVenueService.getVenueByEventId(event.id);
    setState(() {
      _selectedEvent = event;
      _eventNameController.text = event.title;
      _eventDate = event.dateTime;
      _eventLocationController.text = venue?.name ?? 'Venue not found';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Event Details'),
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
              decoration: InputDecoration(
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
                              ? Image.network(
                                  event.imageUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                )
                              : Icon(Icons.event, size: 50),
                          title: Text(event.title),
                          subtitle: Text('${event.dateTime.toLocal().toString().split(' ')[0]}'),
                          onTap: () => _selectEvent(event),
                        );
                      },
                    )
                  : Center(
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
                    setState(() {
                      _eventDate = pickedDate;
                    });
                  }
                }
              },
            ),
            const SizedBox(height: 16),
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
