// timetable_grid.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sway_events/features/artist/models/artist_model.dart';

Widget buildGridView(
  List<Map<String, dynamic>> eventArtists,
  DateTime selectedDay,
) {
  final List<String> stages =
      eventArtists.map((e) => e['stage'] as String).toSet().toList();
  stages.sort();

  final DateTime earliestTime = eventArtists
      .map((e) => DateTime.parse(e['startTime'] as String))
      .reduce((a, b) => a.isBefore(b) ? a : b);
  final DateTime latestTime = eventArtists
      .map((e) => DateTime.parse(e['endTime'] as String))
      .reduce((a, b) => a.isAfter(b) ? a : b);

  final List<DateTime> hours = [];
  DateTime currentTime = DateTime(
    selectedDay.year,
    selectedDay.month,
    selectedDay.day,
    earliestTime.hour,
  );
  while (currentTime.isBefore(latestTime) ||
      currentTime.isAtSameMomentAs(latestTime)) {
    hours.add(currentTime);
    currentTime = currentTime.add(const Duration(hours: 1));
  }

  return Stack(
    children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Column(
                  children: [
                    Container(height: 50), // The height of the hour row
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 100, // Reduced width for the first hour
                            margin: const EdgeInsets.only(
                              top: 20,
                            ), // Adjust top margin to lower the lines
                            decoration: const BoxDecoration(
                              border: Border(
                                right: BorderSide(
                                  color: Colors.grey,
                                  width: 0.5,
                                ),
                              ),
                            ),
                          ),
                          ...hours.skip(1).map(
                                (hour) => Container(
                                  width: 200,
                                  margin: const EdgeInsets.only(
                                    top: 20,
                                  ), // Adjust top margin to lower the lines
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      right: BorderSide(
                                        color: Colors.grey,
                                        width: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(
                      width: 50,
                      height: 100,
                    ), // Reduced width for hours
                    Container(
                      width: 100, // Reduced width for the first hour
                      height: 100,
                      alignment: Alignment.centerLeft, // Align to the left
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 30.0,
                        ), // Increase padding to move right
                        child: Text(
                          DateFormat.Hm().format(hours.first),
                        ),
                      ),
                    ),
                    ...hours.skip(1).map(
                          (hour) => Container(
                            width: 200,
                            height: 100,
                            alignment:
                                Alignment.centerLeft, // Align to the left
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 130.0,
                              ), // Increase padding to move right
                              child: Text(
                                DateFormat.Hm().format(hour),
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
                ...stages.map((stage) {
                  final List<Widget> stageRow = [
                    Container(
                      width: 100,
                    ),
                  ];

                  double accumulatedOffset = 0;

                  for (final artistMap
                      in eventArtists.where((e) => e['stage'] == stage)) {
                    final artist = artistMap['artist'] as Artist;
                    final startTime =
                        DateTime.parse(artistMap['startTime'] as String);
                    final endTime =
                        DateTime.parse(artistMap['endTime'] as String);
                    final durationInHours =
                        endTime.difference(startTime).inMinutes / 60.0;
                    final offsetInHours =
                        startTime.difference(hours.first).inMinutes / 60.0 -
                            accumulatedOffset;

                    if (offsetInHours > 0) {
                      stageRow.add(
                        SizedBox(width: 200 * offsetInHours, height: 100),
                      );
                    }

                    stageRow.add(
                      SizedBox(
                        width: 200 * durationInHours,
                        height: 100,
                        child: Card(
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(color: Colors.amber),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        artist.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${DateFormat.Hm().format(startTime)} - ${DateFormat.Hm().format(endTime)}',
                                        style: const TextStyle(
                                          fontSize: 12.0, // Reduced font size
                                          color: Colors.grey, // Grey color
                                        ),
                                        overflow: TextOverflow
                                            .ellipsis, // Prevent line break
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.add_alert_outlined,
                                    size: 20.0,
                                  ), // Updated icon and size
                                  onPressed: () {
                                    // Action to handle when the alert icon is pressed
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );

                    accumulatedOffset += offsetInHours + durationInHours;
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Row(children: stageRow),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
      Positioned(
        top: 30, // The height of the hour row
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: stages.map((stage) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 60.0),
              child: Container(
                //height: 100,
                alignment: Alignment.centerLeft,
                color: Colors.white, // Background color for stage names
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                ), // Padding around the stage names
                child: Text(
                  stage,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black, // Text color for stage names
                    overflow: TextOverflow.ellipsis, // Ensure no line break
                  ),
                  maxLines: 1, // Ensure no line break
                ),
              ),
            );
          }).toList(),
        ),
      ),
    ],
  );
}
