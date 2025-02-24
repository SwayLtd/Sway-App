import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sway/core/utils/date_utils.dart';
import 'package:sway/features/user/services/user_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/user/services/user_interest_event_service.dart';
import 'package:sway/features/event/services/event_venue_service.dart';

// Internal class to associate an event with its status.
class _UserEvent {
  final Event event;
  final String status; // "interested" or "going"

  _UserEvent({required this.event, required this.status});
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final UserInterestEventService _userInterestEventService =
      UserInterestEventService();
  // Group _UserEvent by date (year, month, day)
  Map<DateTime, List<_UserEvent>> _events = {};
  // Selected day (default is today)
  DateTime _selectedDay = DateTime.now();
  List<_UserEvent> _selectedEvents = [];
  bool _isLoading = true;
  final EventVenueService _eventVenueService = EventVenueService();

  @override
  void initState() {
    super.initState();
    _loadUserEvents();
  }

  Future<void> _loadUserEvents() async {
    final UserService _userService = UserService();
    // Retrieve the current user's id using the user service.
    final user = await _userService.getCurrentUser();
    final currentUserId = user?.id;
    if (currentUserId != null) {
      // Retrieve events where the user is "interested".
      List<Event> interestedEvents = await _userInterestEventService
          .getInterestedEventsByUserId(currentUserId);
      // Retrieve events where the user is "going".
      List<Event> goingEvents =
          await _userInterestEventService.getGoingEventsByUserId(currentUserId);

      // Combine events with their respective status.
      List<_UserEvent> allUserEvents = [];
      allUserEvents.addAll(interestedEvents
          .map((e) => _UserEvent(event: e, status: 'interested')));
      allUserEvents.addAll(
          goingEvents.map((e) => _UserEvent(event: e, status: 'going')));

      // Group events by date (considering only year, month, and day).
      Map<DateTime, List<_UserEvent>> eventsMap = {};
      for (var userEvent in allUserEvents) {
        DateTime dateKey = DateTime(
          userEvent.event.eventDateTime.year,
          userEvent.event.eventDateTime.month,
          userEvent.event.eventDateTime.day,
        );
        eventsMap.putIfAbsent(dateKey, () => []).add(userEvent);
      }

      setState(() {
        _events = eventsMap;
        _selectedEvents = _getEventsForDay(_selectedDay);
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Returns the list of events for the given day.
  List<_UserEvent> _getEventsForDay(DateTime day) {
    DateTime dateKey = DateTime(day.year, day.month, day.day);
    return _events[dateKey] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your calendar')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.now().subtract(const Duration(days: 365)),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: _selectedDay,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Month'
                  },
                  onFormatChanged: (format) {},
                  eventLoader: (day) =>
                      _getEventsForDay(day).map((ue) => ue.event).toList(),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _selectedEvents = _getEventsForDay(selectedDay);
                    });
                  },
                  calendarStyle: CalendarStyle(
                    outsideTextStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.grey[500]
                          : Colors.grey[800],
                      fontSize: 13,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(fontSize: 13),
                    weekendStyle: TextStyle(fontSize: 13),
                  ),
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      final today = DateTime.now();
                      final currentDay = DateTime(day.year, day.month, day.day);
                      final todayDate =
                          DateTime(today.year, today.month, today.day);
                      final isPast = currentDay.isBefore(todayDate);
                      final isLight =
                          Theme.of(context).brightness == Brightness.light;
                      return Container(
                        margin: const EdgeInsets.all(6.0),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            day.day.toString(),
                            style: TextStyle(
                              color: isPast
                                  ? (isLight
                                      ? Colors.grey[500]
                                      : Colors.grey[800])
                                  : null,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                    selectedBuilder: (context, day, focusedDay) {
                      return Container(
                        margin: const EdgeInsets.all(6.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            day.day.toString(),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                          ),
                        ),
                      );
                    },
                    markerBuilder: (context, day, events) {
                      final userEvents = _getEventsForDay(day);
                      if (userEvents.isEmpty) return const SizedBox();
                      final List<Widget> markers = [];
                      // "interested": primary with opacity 0.3.
                      if (userEvents.any((ue) => ue.status == 'interested')) {
                        markers.add(Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.3),
                          ),
                        ));
                      }
                      // "going": primary full opacity.
                      if (userEvents.any((ue) => ue.status == 'going')) {
                        markers.add(Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ));
                      }
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: markers,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8.0),
                // Afficher la date sélectionnée formatée au-dessus de la liste
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatEventDate(_selectedDay),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _selectedEvents.length,
                    itemBuilder: (context, index) {
                      final userEvent = _selectedEvents[index];
                      return ListTile(
                        isThreeLine: true,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        // Utilisation directe de la couleur pour le fond du tile.
                        tileColor: Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withValues(alpha: 0.1),
                        leading: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimary
                                  .withValues(alpha: 0.5),
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          // L'image est affichée en format 16:9.
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Image.network(
                                userEvent.event.imageUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          userEvent.event.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${userEvent.event.eventDateTime.hour.toString().padLeft(2, '0')}:${userEvent.event.eventDateTime.minute.toString().padLeft(2, '0')}'
                              '${userEvent.event.eventEndDateTime != null ? ' - ${userEvent.event.eventEndDateTime!.hour.toString().padLeft(2, '0')}:${userEvent.event.eventEndDateTime!.minute.toString().padLeft(2, '0')}' : ''} - ${userEvent.status.toLowerCase()}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            FutureBuilder(
                              future: _eventVenueService
                                  .getVenueByEventId(userEvent.event.id!),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const SizedBox();
                                } else if (snapshot.hasData &&
                                    snapshot.data != null) {
                                  final venue = snapshot.data as dynamic;
                                  return Text(
                                    venue.name,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  );
                                }
                                return const SizedBox();
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          if (userEvent.event.id != null) {
                            context.push('/event/${userEvent.event.id}');
                          }
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
