import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sway_events/core/widgets/image_with_error_handler.dart';
import 'package:sway_events/features/artist/artist.dart';
import 'package:sway_events/features/artist/models/artist_model.dart';
import 'package:sway_events/features/user/services/user_follow_artist_service.dart';

Future<Widget> buildGridView(
  BuildContext context,
  List<Map<String, dynamic>> eventArtists,
  DateTime selectedDay,
  List<String> stages,
  List<String> selectedStages,
  bool showOnlyFollowedArtists,
) async {
  final UserFollowArtistService userFollowArtistService =
      UserFollowArtistService();
  List<Map<String, dynamic>> artistsToShow = eventArtists;

  if (showOnlyFollowedArtists) {
    artistsToShow = [];
    for (final artistMap in eventArtists) {
      final artist = artistMap['artist'] as Artist;
      final bool isFollowing =
          await userFollowArtistService.isFollowingArtist(artist.id);
      if (isFollowing) {
        artistsToShow.add(artistMap);
      }
    }
  }

  final List<String> filteredStages = stages
      .where((stage) => selectedStages.contains(stage))
      .where((stage) => artistsToShow.any((artist) => artist['stage'] == stage))
      .toList();

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

  return LayoutBuilder(
    builder: (context, constraints) {
      return SingleChildScrollView(
        child: Stack(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Column(
                            children: [
                              Container(
                                height: 50,
                              ), // The height of the hour row
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 100,
                                      margin: const EdgeInsets.only(
                                        top: 20,
                                      ),
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
                                            ),
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
                              ),
                              Container(
                                width: 100,
                                height: 100,
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 30.0),
                                  child: Text(
                                    DateFormat.Hm().format(hours.first),
                                  ),
                                ),
                              ),
                              ...hours.skip(1).map(
                                    (hour) => Container(
                                      width: 200,
                                      height: 100,
                                      alignment: Alignment.centerLeft,
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(left: 130.0),
                                        child: Text(
                                          DateFormat.Hm().format(hour),
                                        ),
                                      ),
                                    ),
                                  ),
                            ],
                          ),
                          ...filteredStages.map((stage) {
                            final List<Widget> stageRow = [
                              Container(
                                width: 100,
                              ),
                            ];

                            double accumulatedOffset = 0;

                            for (final artistMap in artistsToShow
                                .where((e) => e['stage'] == stage)) {
                              final artist = artistMap['artist'] as Artist;
                              final startTime = DateTime.parse(
                                artistMap['startTime'] as String,
                              );
                              final endTime = DateTime.parse(
                                artistMap['endTime'] as String,
                              );
                              final durationInHours =
                                  endTime.difference(startTime).inMinutes /
                                      60.0;
                              final offsetInHours =
                                  startTime.difference(hours.first).inMinutes /
                                          60.0 -
                                      accumulatedOffset;

                              if (offsetInHours > 0) {
                                stageRow.add(
                                  SizedBox(
                                    width: 200 * offsetInHours,
                                    height: 100,
                                  ),
                                );
                              }

                              stageRow.add(
                                SizedBox(
                                  width: 200 * durationInHours,
                                  height: 100,
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ArtistScreen(artistId: artist.id),
                                        ),
                                      );
                                    },
                                    child: FutureBuilder<bool>(
                                      future: userFollowArtistService
                                          .isFollowingArtist(artist.id),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Card(
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 8.0,
                                              ),
                                              child: Row(
                                                children: [
                                                  CircularProgressIndicator(),
                                                ],
                                              ),
                                            ),
                                          );
                                        } else if (snapshot.hasError) {
                                          return const Card(
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 8.0,
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.error,
                                                    color: Colors.red,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        } else {
                                          final bool isFollowing =
                                              snapshot.data ?? false;
                                          return Card(
                                            color: isFollowing
                                                ? Theme.of(context).primaryColor
                                                : null,
                                            shape: RoundedRectangleBorder(
                                              side: BorderSide(
                                                color: Theme.of(context)
                                                    .primaryColor,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8.0,
                                              ),
                                              child: Row(
                                                children: [
                                                  if (100 * durationInHours >=
                                                      100)
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        8.0,
                                                      ),
                                                      child:
                                                          ImageWithErrorHandler(
                                                        imageUrl:
                                                            artist.imageUrl,
                                                        width: 40,
                                                        height: 40,
                                                      ),
                                                    ),
                                                  const SizedBox(width: 8.0),
                                                  Expanded(
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          artist.name,
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: isFollowing
                                                                ? Colors.black
                                                                : Theme.of(
                                                                    context,
                                                                  )
                                                                    .textTheme
                                                                    .bodyMedium
                                                                    ?.color,
                                                          ),
                                                        ),
                                                        Text(
                                                          '${DateFormat.Hm().format(startTime)} - ${DateFormat.Hm().format(endTime)}',
                                                          style: TextStyle(
                                                            fontSize: 12.0,
                                                            color: isFollowing
                                                                ? Colors
                                                                    .grey[800]
                                                                : Colors.grey,
                                                          ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const Padding(
                                                    padding: EdgeInsets.only(
                                                      right: 8.0,
                                                    ),
                                                    child: Icon(
                                                      Icons.add_alert_outlined,
                                                      size: 20.0,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              );

                              accumulatedOffset +=
                                  offsetInHours + durationInHours;
                            }

                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 20.0),
                              child: Row(children: stageRow),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 30, // The height of the hour row
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: filteredStages.map((stage) {
                  return artistsToShow.any((artist) => artist['stage'] == stage)
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 60.0),
                          child: Container(
                            alignment: Alignment.centerLeft,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                            ),
                            child: Text(
                              stage,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                overflow: TextOverflow.ellipsis,
                              ),
                              maxLines: 1,
                            ),
                          ),
                        )
                      : const SizedBox.shrink();
                }).toList(),
              ),
            ),
          ],
        ),
      );
    },
  );
}
