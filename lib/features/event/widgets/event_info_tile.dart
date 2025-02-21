import 'package:flutter/material.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/services/event_service.dart';
import 'package:sway/features/event/event.dart'; // Pour naviguer vers EventScreen, par exemple

class EventInfoTile extends StatefulWidget {
  // A refreshKey is provided by the parent so that the widget is rebuilt on refresh.
  final Key refreshKey;
  const EventInfoTile({required this.refreshKey, Key? key}) : super(key: key);

  @override
  _EventInfoTileState createState() => _EventInfoTileState();
}

class _EventInfoTileState extends State<EventInfoTile> {
  final EventService _eventService = EventService();
  Event? _currentEvent;
  Event? _todayEvent;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEventInfo();
  }

  // Fetches event information and determines if there is an event in progress or scheduled for today.
  Future<void> _fetchEventInfo() async {
    setState(() => _isLoading = true);
    try {
      // Retrieve all events (this could be optimized with a specific RPC call)
      List<Event> events = await _eventService.getEvents();
      final now = DateTime.now();

      // Find an event that is in progress: start time passed and end time in the future.
      final inProgress = events.where((event) =>
          event.eventDateTime.isBefore(now) &&
          event.eventEndDateTime.isAfter(now));
      _currentEvent = inProgress.isNotEmpty ? inProgress.first : null;

      // If no event is in progress, find an event scheduled for today (same day and start time after now)
      final todayEvents = events.where((event) =>
          event.eventDateTime.day == now.day &&
          event.eventDateTime.isAfter(now));
      _todayEvent = todayEvents.isNotEmpty ? todayEvents.first : null;
    } catch (e) {
      print("Error fetching event info: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Border color similar to other tiles, adapting to the theme.
    final borderColor =
        Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.5);

    if (_isLoading) {
      return SizedBox.shrink();
    }

    // Function to build the leading widget: use event image if available, otherwise fallback icon.
    Widget buildLeading(Event event) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: event.imageUrl.isNotEmpty
            ? ImageWithErrorHandler(
                imageUrl: event.imageUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              )
            : Icon(
                event == _currentEvent ? Icons.event : Icons.nightlife,
                color: Theme.of(context).colorScheme.primary,
                size: 50,
              ),
      );
    }

    // Build the card for an event.
    Card buildEventCard(
        {required Event event,
        required String titlePrefix,
        required String timeText}) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 2.0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: buildLeading(event),
            title: Text(
              "$titlePrefix: ${event.title}",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              timeText,
              style: const TextStyle(fontSize: 14),
            ),
            onTap: () {
              // Navigate to event details screen
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => EventScreen(event: event)),
              );
            },
          ),
        ),
      );
    }

    if (_currentEvent != null) {
      return buildEventCard(
        event: _currentEvent!,
        titlePrefix: "In Progress",
        timeText:
            "Ends at ${_currentEvent!.eventEndDateTime.toLocal().toString().substring(11, 16)}",
      );
    } else if (_todayEvent != null) {
      return buildEventCard(
        event: _todayEvent!,
        titlePrefix: "Today",
        timeText:
            "Starts at ${_todayEvent!.eventDateTime.toLocal().toString().substring(11, 16)}",
      );
    } else {
      // No relevant event to display.
      return const SizedBox.shrink();
    }
  }
}
