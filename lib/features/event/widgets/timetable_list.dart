// timetable_list.dart

import 'package:flutter/material.dart';
import 'package:sway_events/features/artist/artist.dart';
import 'package:sway_events/features/artist/models/artist_model.dart';
import 'package:sway_events/features/event/utils/timetable_utils.dart';

Widget buildListView(
  BuildContext context,
  List<Map<String, dynamic>> eventArtists,
  DateTime selectedDay,
) {
  final Map<String, List<Map<String, dynamic>>> artistsByStage = {};
  for (final entry in eventArtists) {
    final stage = entry['stage'] as String?;
    if (stage != null) {
      if (!artistsByStage.containsKey(stage)) {
        artistsByStage[stage] = [];
      }
      artistsByStage[stage]!.add(entry);
    }
  }

  final List<String> stages = artistsByStage.keys.toList();
  stages.sort();

  return Padding(
    padding:
        const EdgeInsets.only(top: 16.0), // Add top padding here for ListView
    child: ListView(
      children: stages.map((stage) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
              ), // Add left padding here for stage names
              child: Text(
                stage,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Column(
              children: artistsByStage[stage]?.map((entry) {
                    final artist = entry['artist'] as Artist;
                    final startTime = entry['startTime'] as String?;
                    final endTime = entry['endTime'] as String?;
                    final status = entry['status'] as String?;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ArtistScreen(artistId: artist.id),
                          ),
                        );
                      },
                      child: ListTile(
                        title: Text(
                          artist.name,
                          style: TextStyle(
                            color: status == 'cancelled' ? Colors.grey : null,
                          ),
                        ),
                        subtitle: startTime != null && endTime != null
                            ? Text(
                                '${formatTime(startTime)} - ${formatTime(endTime)}',
                              )
                            : null,
                      ),
                    );
                  }).toList() ??
                  [],
            ),
          ],
        );
      }).toList(),
    ),
  );
}
