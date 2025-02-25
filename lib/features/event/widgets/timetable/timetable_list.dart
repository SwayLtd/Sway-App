import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sway/core/utils/date_utils.dart';
import 'package:sway/core/utils/text_formatting.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/artist/artist.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/utils/timetable_utils.dart';
import 'package:sway/features/event/widgets/timetable/artist_image_rotator.dart';
import 'package:sway/features/user/services/user_follow_artist_service.dart';
import 'package:sway/features/notification/services/notification_service.dart';
import 'package:sway/features/user/services/user_service.dart';
import 'package:sway/features/user/widgets/following_button_widget.dart';
import 'package:sway/features/user/widgets/snackbar_login.dart';

class TimetableListView extends StatefulWidget {
  final List<Map<String, dynamic>> eventArtists;
  final List<String> stages;
  final List<String> selectedStages;
  final bool showOnlyFollowedArtists;
  final Set<int>? followedArtistIds;
  final Event event;

  const TimetableListView({
    Key? key,
    required this.event,
    required this.eventArtists,
    required this.stages,
    required this.selectedStages,
    required this.showOnlyFollowedArtists,
    this.followedArtistIds,
  }) : super(key: key);

  @override
  _TimetableListViewState createState() => _TimetableListViewState();
}

class _TimetableListViewState extends State<TimetableListView> {
  Set<int> _notifiedArtistIds = {}; // Track notified artists
  bool isLoadingNotify = false; // For notification action

  @override
  void initState() {
    super.initState();
    _loadNotifiedIds();
  }

  Future<void> _loadNotifiedIds() async {
    final loadedIds = await _loadNotifiedArtistIds(widget.event.id!);
    setState(() {
      _notifiedArtistIds = loadedIds;
    });
  }

  Future<void> _addNotifiedArtistId(int artistId) async {
    setState(() {
      _notifiedArtistIds.add(artistId);
    });
    await _saveNotifiedArtistIds(widget.event.id!, _notifiedArtistIds);
  }

  // Function to load notified artist IDs from SharedPreferences
  Future<Set<int>> _loadNotifiedArtistIds(int eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final idsString = prefs.getString('notifiedArtistIds_$eventId') ?? '';
    if (idsString.isEmpty) return {};
    // Assuming IDs are stored as a comma-separated string
    return idsString
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .toSet();
  }

// Function to save notified artist IDs to SharedPreferences
  Future<void> _saveNotifiedArtistIds(int eventId, Set<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final idsString = ids.join(',');
    await prefs.setString('notifiedArtistIds_$eventId', idsString);
  }

  @override
  Widget build(BuildContext context) {
    // 1. Filter assignments by "Only followed artists"
    List<Map<String, dynamic>> filteredAssignments = [];
    if (widget.showOnlyFollowedArtists && widget.followedArtistIds != null) {
      for (final assignment in widget.eventArtists) {
        final List<Artist> artists =
            (assignment['artists'] as List<dynamic>).cast<Artist>();
        if (artists
            .any((artist) => widget.followedArtistIds!.contains(artist.id))) {
          filteredAssignments.add(assignment);
        }
      }
    } else {
      filteredAssignments = List.from(widget.eventArtists);
    }

    // 2. Group assignments by stage
    final Map<String, List<Map<String, dynamic>>> artistsByStage = {};
    for (final assignment in filteredAssignments) {
      final stage = assignment['stage'] as String?;
      if (stage == null) continue;
      if (!widget.selectedStages.contains(stage)) continue;
      artistsByStage.putIfAbsent(stage, () => []).add(assignment);
    }

    // 3. Sort assignments by start time
    for (final stage in artistsByStage.keys) {
      artistsByStage[stage]!.sort((a, b) {
        final DateTime? startA = a['start_time'] as DateTime?;
        final DateTime? startB = b['start_time'] as DateTime?;
        return startA!.compareTo(startB!);
      });
    }

    // 4. Filter out stages without any artists
    final List<String> filteredStages = widget.selectedStages
        .where((s) => (artistsByStage[s]?.isNotEmpty ?? false))
        .toList();

    // 5. Build the list view with SliverStickyHeader
    return CustomScrollView(slivers: [
      ...filteredStages.map((stage) {
        final entries = artistsByStage[stage] ?? [];
        return SliverStickyHeader(
          header: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Text(
              capitalizeFirst(stage),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final entry = entries[index];
                final List<Artist> artists =
                    (entry['artists'] as List<dynamic>).cast<Artist>();
                final customName = entry['custom_name'] as String?;
                final displayedName = (customName != null &&
                        customName.isNotEmpty)
                    ? customName
                    : artists.map((artist) => artist.name).join(', '); // B2B
                final DateTime? startTime = entry['start_time'];
                final DateTime? endTime = entry['end_time'];
                final status = entry['status'];

                return FutureBuilder<bool>(
                  future: Future.wait(
                    artists
                        .map((artist) => UserFollowArtistService()
                            .isFollowingArtist(artist.id!))
                        .toList(),
                  ).then(
                      (results) => results.any((isFollowing) => isFollowing)),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return ListTile(
                        leading: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(formatTime(startTime!),
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold)),
                            Text(formatTime(endTime!),
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        title: Row(
                          children: [
                            Container(
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
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10.0),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: Text(
                                displayedName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        trailing: Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.favorite_border,
                                  color: Colors.transparent),
                              SizedBox(width: 24.0),
                              Icon(
                                Icons.add_alert_outlined,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return ListTile(
                        leading: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(formatTime(startTime!),
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold)),
                            Text(formatTime(endTime!),
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        title: Expanded(
                          child: Text(
                            displayedName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        trailing: const Icon(Icons.error, color: Colors.red),
                      );
                    } else {
                      final bool isFollowing = snapshot.data ?? false;
                      if (widget.showOnlyFollowedArtists && !isFollowing) {
                        return const SizedBox.shrink();
                      }

                      // Check if multiple artists are in this time slot
                      if (artists.length > 1) {
                        return GestureDetector(
                          onTap: () {
                            // Display the bottom sheet with the artists' list
                            showArtistsBottomSheet(context, artists);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isFollowing
                                  ? Theme.of(context)
                                      .primaryColor
                                      .withValues(alpha: 0.3)
                                  : null,
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: ListTile(
                              leading: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(formatTime(startTime!),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold)),
                                  Text(formatTime(endTime!),
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                              title: Row(
                                children: [
                                  if (artists.length == 1) ...[
                                    Container(
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
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        child: ImageWithErrorHandler(
                                          imageUrl: artists.first.imageUrl,
                                          width: 40,
                                          height: 40,
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    ArtistImageRotator(artists: artists),
                                  ],
                                  const SizedBox(width: 8.0),
                                  Expanded(
                                    child: Text(
                                      displayedName,
                                      style: TextStyle(
                                        color: status == 'cancelled'
                                            ? Colors.redAccent
                                            : null,
                                        fontWeight: isFollowing
                                            ? FontWeight.bold
                                            : null,
                                        decoration: status == 'cancelled'
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.favorite_border,
                                      color: Colors.transparent),
                                  SizedBox(width: 12.0),
                                  IconButton(
                                    icon: Icon(
                                      isLoadingNotify
                                          ? Icons.add_alert_outlined
                                          : (_notifiedArtistIds
                                                  .contains(artists.first.id!)
                                              ? Icons.notifications_active
                                              : Icons.add_alert_outlined),
                                      color:
                                          isLoadingNotify ? Colors.grey : null,
                                    ),
                                    onPressed: isLoadingNotify
                                        ? null
                                        : () async {
                                            if (_notifiedArtistIds
                                                .contains(artists.first.id!)) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      "Notification already scheduled."),
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                ),
                                              );
                                              return;
                                            }

                                            setState(() {
                                              isLoadingNotify = true;
                                            });

                                            final currentUser =
                                                await UserService()
                                                    .getCurrentUser();
                                            final supabaseId =
                                                currentUser?.supabaseId;

                                            if (supabaseId == null) {
                                              SnackbarLogin.showLoginSnackBar(
                                                  context);
                                              setState(() {
                                                isLoadingNotify = false;
                                              });
                                              return;
                                            }

                                            final notificationTime = startTime
                                                .subtract(const Duration(
                                                    minutes: 15));

                                            try {
                                              await NotificationService()
                                                  .addEventArtistNotification(
                                                supabaseId: supabaseId,
                                                artistId: artists.first.id!,
                                                eventTitle: widget.event.title,
                                                stage: entry['stage'] ?? '',
                                                scheduledTime: notificationTime,
                                                artistName: artists.first.name,
                                                customName:
                                                    entry['custom_name'] ?? '',
                                              );
                                              await _addNotifiedArtistId(
                                                  artists.first.id!);
                                              setState(() {
                                                isLoadingNotify = false;
                                              });
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        "Notification scheduled."),
                                                    behavior: SnackBarBehavior
                                                        .floating),
                                              );
                                            } catch (e) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      "Error scheduling notification: $e"),
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                ),
                                              );
                                              setState(() {
                                                isLoadingNotify = false;
                                              });
                                            }
                                          },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      // Single artist logic
                      return Container(
                        decoration: BoxDecoration(
                          color: isFollowing
                              ? Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.3)
                              : null,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap: () {
                                // Display the artist's profile
                                if (artists.length == 1) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ArtistScreen(
                                          artistId: artists.first.id!),
                                    ),
                                  );
                                }
                              },
                              child: ListTile(
                                leading: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      formatTime(startTime!),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      formatTime(endTime!),
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                title: Row(
                                  children: [
                                    if (artists.length == 1) ...[
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary
                                                .withValues(alpha: 0.5),
                                            width: 2.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          child: ImageWithErrorHandler(
                                            imageUrl: artists.first.imageUrl,
                                            width: 40,
                                            height: 40,
                                          ),
                                        ),
                                      ),
                                    ] else ...[
                                      ArtistImageRotator(artists: artists),
                                    ],
                                    const SizedBox(width: 8.0),
                                    Expanded(
                                      child: Text(
                                        displayedName,
                                        style: TextStyle(
                                          color: status == 'cancelled'
                                              ? Colors.redAccent
                                              : null,
                                          fontWeight: isFollowing
                                              ? FontWeight.bold
                                              : null,
                                          decoration: status == 'cancelled'
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FollowingButtonWidget(
                                      entityId: artists.first.id!,
                                      entityType: 'artist',
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        isLoadingNotify
                                            ? Icons.add_alert_outlined
                                            : (_notifiedArtistIds
                                                    .contains(artists.first.id!)
                                                ? Icons.notifications_active
                                                : Icons.add_alert_outlined),
                                        color: isLoadingNotify ||
                                                status == 'cancelled'
                                            ? Colors.grey
                                            : null, // Gris pour "cancelled"
                                      ),
                                      onPressed: isLoadingNotify ||
                                              status == 'cancelled'
                                          ? null
                                          : () async {
                                              if (_notifiedArtistIds.contains(
                                                  artists.first.id!)) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        "Notification already scheduled."),
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                  ),
                                                );
                                                return;
                                              }

                                              setState(() {
                                                isLoadingNotify = true;
                                              });

                                              final currentUser =
                                                  await UserService()
                                                      .getCurrentUser();
                                              final supabaseId =
                                                  currentUser?.supabaseId;

                                              if (supabaseId == null) {
                                                SnackbarLogin.showLoginSnackBar(
                                                    context);
                                                setState(() {
                                                  isLoadingNotify = false;
                                                });
                                                return;
                                              }

                                              final notificationTime = startTime
                                                  .subtract(const Duration(
                                                      minutes: 15));

                                              try {
                                                await NotificationService()
                                                    .addEventArtistNotification(
                                                  supabaseId: supabaseId,
                                                  artistId: artists.first.id!,
                                                  eventTitle:
                                                      widget.event.title,
                                                  stage: entry['stage'] ?? '',
                                                  scheduledTime:
                                                      notificationTime,
                                                  artistName:
                                                      artists.first.name,
                                                  customName:
                                                      entry['custom_name'] ??
                                                          '',
                                                );

                                                await _addNotifiedArtistId(
                                                    artists.first.id!);

                                                setState(() {
                                                  isLoadingNotify = false;
                                                });
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          "Notification scheduled."),
                                                      behavior: SnackBarBehavior
                                                          .floating),
                                                );
                                              } catch (e) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        "Error scheduling notification: $e"),
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                  ),
                                                );
                                                setState(() {
                                                  isLoadingNotify = false;
                                                });
                                              }
                                            },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                );
              },
              childCount: artistsByStage[stage]?.length ?? 0,
            ),
          ),
        );
      }).toList(),
    ]);
  }
}
