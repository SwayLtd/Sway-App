// timetable.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sway_events/features/event/models/event_model.dart';
import 'package:sway_events/features/event/services/event_artist_service.dart';
import 'package:sway_events/features/event/utils/timetable_utils.dart';
import 'package:sway_events/features/event/widgets/timetable_grid.dart';
import 'package:sway_events/features/event/widgets/timetable_list.dart';

class TimetableWidget extends StatefulWidget {
  final Event event;

  const TimetableWidget({required this.event});

  @override
  _TimetableWidgetState createState() => _TimetableWidgetState();
}

class _TimetableWidgetState extends State<TimetableWidget> {
  bool isGridView = false;
  DateTime selectedDay = DateTime.now();
  List<Map<String, dynamic>> eventArtists = [];

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DateTime>>(
      future: calculateFestivalDays(widget.event),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No festival days found'));
        } else {
          List<DateTime> festivalDays = snapshot.data!;
          if (!festivalDays.contains(selectedDay)) {
            selectedDay = festivalDays.first;
          }

          // Exclure la date du 5 septembre
          festivalDays = festivalDays
              .where((date) => date.isBefore(DateTime(2024, 9, 5)))
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: DropdownButton<DateTime>(
                        value: selectedDay,
                        onChanged: (DateTime? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedDay = newValue;
                            });
                          }
                        },
                        items: festivalDays.map((DateTime date) {
                          return DropdownMenuItem<DateTime>(
                            value: date,
                            child: Text(
                              DateFormat('EEEE, MMM d').format(date),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isGridView ? Icons.view_list : Icons.grid_view,
                      ),
                      onPressed: () {
                        setState(() {
                          isGridView = !isGridView;
                        });
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: EventArtistService().getArtistsByEventIdAndDay(
                      widget.event.id,
                      selectedDay,
                    ),
                    builder: (context, artistSnapshot) {
                      if (artistSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      } else if (artistSnapshot.hasError) {
                        return Center(
                          child: Text('Error: ${artistSnapshot.error}'),
                        );
                      } else if (!artistSnapshot.hasData ||
                          artistSnapshot.data!.isEmpty) {
                        return const Center(child: Text('No events found'));
                      } else {
                        eventArtists = artistSnapshot.data!;

                        return isGridView
                            ? buildGridView(
                                context,
                                eventArtists,
                                selectedDay,
                              )
                            : buildListView(
                                context,
                                eventArtists,
                                selectedDay,
                              );
                      }
                    },
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }
}
