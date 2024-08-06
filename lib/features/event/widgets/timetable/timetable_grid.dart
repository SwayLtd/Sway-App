// timetable_grid.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sway_events/core/widgets/image_with_error_handler.dart';
import 'package:sway_events/features/artist/artist.dart';
import 'package:sway_events/features/artist/models/artist_model.dart';
import 'package:sway_events/features/event/utils/timetable_utils.dart';
import 'package:sway_events/features/event/widgets/timetable/artist_image_rotator.dart';
import 'package:sway_events/features/user/services/user_follow_artist_service.dart';

class GridViewWidget extends StatefulWidget {
  final List<Map<String, dynamic>> eventArtists;
  final DateTime selectedDay;
  final List<String> stages;
  final List<String> selectedStages;
  final bool showOnlyFollowedArtists;

  const GridViewWidget({
    required this.eventArtists,
    required this.selectedDay,
    required this.stages,
    required this.selectedStages,
    required this.showOnlyFollowedArtists,
  });

  @override
  _GridViewWidgetState createState() => _GridViewWidgetState();
}

class _GridViewWidgetState extends State<GridViewWidget> {
  bool _isScrollInitialized = false;
  double _lastHorizontalScrollOffset = 0.0;
  double _lastVerticalScrollOffset = 0.0;
  late ScrollController _horizontalScrollController;
  late ScrollController _verticalScrollController;

  @override
  void initState() {
    super.initState();
    _loadLastScrollOffsets();
  }

  Future<void> _loadLastScrollOffsets() async {
    final prefs = await SharedPreferences.getInstance();
    final DateTime earliestTime = widget.eventArtists
        .map((e) => DateTime.parse(e['startTime'] as String))
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final DateTime latestTime = widget.eventArtists
        .map((e) => DateTime.parse(e['endTime'] as String))
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final now = DateTime.now();

    // If current time is after the end time of the event, set it to the start time of the event
    final DateTime currentTime = now.isAfter(latestTime) ? earliestTime : now;

    // Extract hours and minutes for comparison
    final int nowInMinutes = now.hour * 60 + now.minute;
    final int latestTimeInMinutes = latestTime.hour * 60 + latestTime.minute;
    final int earliestTimeInMinutes =
        earliestTime.hour * 60 + earliestTime.minute;

    // Handle cases after midnight
    final bool isAfterMidnight = currentTime.isAfter(
          DateTime(currentTime.year, currentTime.month, currentTime.day),
        ) &&
        currentTime.isBefore(
          DateTime(
            currentTime.year,
            currentTime.month,
            currentTime.day + 1,
            latestTime.hour,
            latestTime.minute,
          ),
        );

    double initialHorizontalOffset;

    if (nowInMinutes > latestTimeInMinutes) {
      // If current time is after the end time of the event, set it to the start time of the event
      initialHorizontalOffset = 0.0;
      if (nowInMinutes >= earliestTimeInMinutes &&
          nowInMinutes <= latestTimeInMinutes + 24 * 60) {
        // If current time is within the event time frame including the next day after midnight
        initialHorizontalOffset =
            ((nowInMinutes - earliestTimeInMinutes) % (24 * 60)) * 200.0 / 60.0;
      } else {
        // Default to the start time of the event
        initialHorizontalOffset = 0;
      }
    } else if (isAfterMidnight) {
      // Calculate initial offset for times after midnight
      initialHorizontalOffset =
          (24 + currentTime.hour - earliestTime.hour) * 200.0 +
              (currentTime.minute * 200.0 / 60.0);
    } else {
      // Default to the start time of the event
      initialHorizontalOffset = 0;
    }

    // Set offsets
    _lastHorizontalScrollOffset =
        prefs.getDouble('lastHorizontalScrollOffset') ??
            initialHorizontalOffset;
    _lastVerticalScrollOffset =
        prefs.getDouble('lastVerticalScrollOffset') ?? 0.0;

    // Check if scroll should be reset
    final lastVisitedTime = prefs.getString('lastVisitedTime');
    final shouldResetScroll = lastVisitedTime != null &&
        DateTime.now().difference(DateTime.parse(lastVisitedTime)).inMinutes >
            15;

    if (shouldResetScroll) {
      _lastHorizontalScrollOffset = initialHorizontalOffset;
      _lastVerticalScrollOffset = 0.0;
    }

    // Initialize scroll controllers
    _initializeScrollControllers();
    setState(() {
      _isScrollInitialized = true;
    });
  }

  void _initializeScrollControllers() {
    _horizontalScrollController = ScrollController(
      initialScrollOffset: _lastHorizontalScrollOffset,
    );
    _horizontalScrollController.addListener(_saveScrollOffsets);

    _verticalScrollController = ScrollController(
      initialScrollOffset: _lastVerticalScrollOffset,
    );
    _verticalScrollController.addListener(_saveScrollOffsets);
  }

  Future<void> _saveScrollOffsets() async {
    if (!_horizontalScrollController.hasClients ||
        !_verticalScrollController.hasClients) return;
    final prefs = await SharedPreferences.getInstance();
    final horizontalOffset = _horizontalScrollController.offset;
    final verticalOffset = _verticalScrollController.offset;
    await prefs.setDouble('lastHorizontalScrollOffset', horizontalOffset);
    await prefs.setDouble('lastVerticalScrollOffset', verticalOffset);
    await prefs.setString('lastVisitedTime', DateTime.now().toIso8601String());
  }

  @override
  void dispose() {
    _horizontalScrollController.removeListener(_saveScrollOffsets);
    _horizontalScrollController.dispose();
    _verticalScrollController.removeListener(_saveScrollOffsets);
    _verticalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isScrollInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return FutureBuilder<Widget>(
      future: _buildGridView(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          return snapshot.data!;
        }
      },
    );
  }

  Future<Widget> _buildGridView(BuildContext context) async {
    final UserFollowArtistService userFollowArtistService =
        UserFollowArtistService();
    List<Map<String, dynamic>> artistsToShow = widget.eventArtists;

    if (widget.showOnlyFollowedArtists) {
      artistsToShow = [];
      for (final artistMap in widget.eventArtists) {
        final List<Artist> artists = (artistMap['artists'] as List<dynamic>)
            .map((artist) => artist as Artist)
            .toList();
        for (final artist in artists) {
          final bool isFollowing =
              await userFollowArtistService.isFollowingArtist(artist.id);
          if (isFollowing) {
            artistsToShow.add(artistMap);
            break;
          }
        }
      }
    }

    final List<String> filteredStages = widget.stages
        .where((stage) => widget.selectedStages.contains(stage))
        .where(
          (stage) => artistsToShow.any((artist) => artist['stage'] == stage),
        )
        .toList();

    final DateTime earliestTime = widget.eventArtists
        .map((e) => DateTime.parse(e['startTime'] as String))
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final DateTime latestTime = widget.eventArtists
        .map((e) => DateTime.parse(e['endTime'] as String))
        .reduce((a, b) => a.isAfter(b) ? a : b);

    final List<DateTime> hours = [];
    DateTime currentTime = DateTime(
      widget.selectedDay.year,
      widget.selectedDay.month,
      widget.selectedDay.day,
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
          controller: _verticalScrollController,
          child: Stack(
            children: [
              SingleChildScrollView(
                controller: _horizontalScrollController,
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
                                          padding: const EdgeInsets.only(
                                            left: 130.0,
                                          ),
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
                                final List<Artist> artists =
                                    (artistMap['artists'] as List<dynamic>)
                                        .map((artist) => artist as Artist)
                                        .toList();
                                final customName =
                                    artistMap['customName'] as String?;
                                final startTime = DateTime.parse(
                                  artistMap['startTime'] as String,
                                );
                                final endTime = DateTime.parse(
                                  artistMap['endTime'] as String,
                                );
                                final durationInHours =
                                    endTime.difference(startTime).inMinutes /
                                        60.0;
                                final offsetInHours = startTime
                                            .difference(hours.first)
                                            .inMinutes /
                                        60.0 -
                                    accumulatedOffset;
                                final status = artistMap['status'] as String?;

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
                                        if (artists.length > 1) {
                                          showArtistsBottomSheet(
                                            context,
                                            artists,
                                          );
                                        } else {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ArtistScreen(
                                                artistId: artists.first.id,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      child: FutureBuilder<bool>(
                                        future: Future.wait(
                                          artists
                                              .map(
                                                (artist) =>
                                                    userFollowArtistService
                                                        .isFollowingArtist(
                                                  artist.id,
                                                ),
                                              )
                                              .toList(),
                                        ).then(
                                          (results) => results.any(
                                            (isFollowing) => isFollowing,
                                          ),
                                        ),
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
                                                  ? Theme.of(context)
                                                      .primaryColor
                                                  : Theme.of(context).cardColor,
                                              shape: RoundedRectangleBorder(
                                                side: BorderSide(
                                                  color: Theme.of(context)
                                                      .primaryColor,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                              ),
                                              child: Stack(
                                                children: [
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 8.0,
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        if (100 *
                                                                durationInHours >=
                                                            100)
                                                          ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                              8.0,
                                                            ),
                                                            child: artists
                                                                        .length ==
                                                                    1
                                                                ? ImageWithErrorHandler(
                                                                    imageUrl: artists
                                                                        .first
                                                                        .imageUrl,
                                                                    width: 40,
                                                                    height: 40,
                                                                  )
                                                                : ArtistImageRotator(
                                                                    artists:
                                                                        artists,
                                                                  ),
                                                          ),
                                                        const SizedBox(
                                                          width: 8.0,
                                                        ),
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
                                                                customName ??
                                                                    artists
                                                                        .map(
                                                                          (artist) =>
                                                                              artist.name,
                                                                        )
                                                                        .join(
                                                                          ' B2B ',
                                                                        ),
                                                                style:
                                                                    TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: status ==
                                                                          'cancelled'
                                                                      ? Colors
                                                                          .red
                                                                      : isFollowing
                                                                          ? Colors
                                                                              .black
                                                                          : Theme.of(context)
                                                                              .textTheme
                                                                              .bodyMedium
                                                                              ?.color,
                                                                  decoration: status ==
                                                                          'cancelled'
                                                                      ? TextDecoration
                                                                          .lineThrough
                                                                      : null,
                                                                ),
                                                              ),
                                                              Text(
                                                                '${DateFormat.Hm().format(startTime)} - ${DateFormat.Hm().format(endTime)}',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize:
                                                                      12.0,
                                                                  color: isFollowing
                                                                      ? Colors.grey[
                                                                          800]
                                                                      : Colors
                                                                          .grey,
                                                                ),
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        const Padding(
                                                          padding:
                                                              EdgeInsets.only(
                                                            right: 8.0,
                                                          ),
                                                          child: Icon(
                                                            Icons
                                                                .add_alert_outlined,
                                                            size: 20.0,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  if (status == 'cancelled')
                                                    Positioned.fill(
                                                      child: Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.red
                                                              .withOpacity(0.3),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                            10.0,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
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
                    return artistsToShow
                            .any((artist) => artist['stage'] == stage)
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
}
