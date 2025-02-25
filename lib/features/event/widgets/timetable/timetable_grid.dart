import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sway/core/utils/text_formatting.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/artist/artist.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/utils/timetable_utils.dart';
import 'package:sway/features/event/widgets/timetable/artist_image_rotator.dart';
import 'package:sway/features/notification/services/notification_service.dart';
import 'package:sway/features/user/services/user_follow_artist_service.dart';
import 'package:sway/features/user/services/user_service.dart';
import 'package:sway/features/user/widgets/snackbar_login.dart';

class GridViewWidget extends StatefulWidget {
  final Event event; // Add event field
  final List<Map<String, dynamic>> eventArtists;
  final bool showOnlyFollowedArtists;
  final List<String> stages;
  final List<String> selectedStages;
  final Set<int>? followedArtistIds;

  const GridViewWidget({
    Key? key,
    required this.event,
    required this.eventArtists,
    required this.showOnlyFollowedArtists,
    required this.stages,
    required this.selectedStages,
    this.followedArtistIds,
  }) : super(key: key);

  @override
  State<GridViewWidget> createState() => _GridViewWidgetState();
}

class _GridViewWidgetState extends State<GridViewWidget> {
  bool _isScrollInitialized = false;
  double _lastHorizontalScrollOffset = 0.0;
  double _lastVerticalScrollOffset = 0.0;
  late ScrollController _horizontalScrollController;
  late ScrollController _verticalScrollController;
  UserFollowArtistService userFollowService = UserFollowArtistService();

  Set<int> _notifiedArtistIds = {}; // Ajoutez cette ligne ici
  bool isLoadingNotify = false;

  @override
  void initState() {
    super.initState();
    _loadLastScrollOffsets();
    _loadNotifiedIds(); // Ajoutez cette ligne ici
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

  Future<void> _loadLastScrollOffsets() async {
    final prefs = await SharedPreferences.getInstance();

    // Copie du eventArtists pour le manipuler
    List<Map<String, dynamic>> artistsToShow = List.from(widget.eventArtists);

    // 1) Filtrer si “showOnlyFollowedArtists”
    if (widget.showOnlyFollowedArtists) {
      final List<Map<String, dynamic>> filtered = [];
      for (final artistMap in artistsToShow) {
        final List<Artist> artists =
            (artistMap['artists'] as List<dynamic>).cast<Artist>();
        bool foundFollowing = false;
        for (final art in artists) {
          final isF = await userFollowService.isFollowingArtist(art.id!);
          if (isF) {
            foundFollowing = true;
            break;
          }
        }
        if (foundFollowing) {
          filtered.add(artistMap);
        }
      }
      artistsToShow = filtered;
    }

    // 2) Tri par start_time
    if (artistsToShow.isEmpty) {
      // Aucun créneau => pas de reduce(...) possible
      _initializeScrollControllers();
      setState(() => _isScrollInitialized = true);
      return;
    }
    artistsToShow.sort((a, b) {
      final dtA = a['start_time'] as DateTime?;
      final dtB = b['start_time'] as DateTime?;
      return dtA!.compareTo(dtB!);
    });

    double initialHorizontalOffset = 0.0;

    // On lit le offset stocké
    _lastHorizontalScrollOffset =
        prefs.getDouble('lastHorizontalScrollOffset') ??
            initialHorizontalOffset;
    _lastVerticalScrollOffset =
        prefs.getDouble('lastVerticalScrollOffset') ?? 0.0;

    // Check lastVisitedTime
    final lastVisitedTime = prefs.getString('lastVisitedTime');
    final shouldResetScroll = lastVisitedTime != null &&
        DateTime.now().difference(DateTime.parse(lastVisitedTime)).inMinutes >
            15;
    if (shouldResetScroll) {
      _lastHorizontalScrollOffset = initialHorizontalOffset;
      _lastVerticalScrollOffset = 0.0;
    }

    _initializeScrollControllers();
    setState(() {
      _isScrollInitialized = true;
    });
  }

  void _initializeScrollControllers() {
    _horizontalScrollController = ScrollController(
      initialScrollOffset: _lastHorizontalScrollOffset,
    );
    _verticalScrollController = ScrollController(
      initialScrollOffset: _lastVerticalScrollOffset,
    );

    _horizontalScrollController.addListener(_saveScrollOffsets);
    _verticalScrollController.addListener(_saveScrollOffsets);
  }

  Future<void> _saveScrollOffsets() async {
    if (!_horizontalScrollController.hasClients ||
        !_verticalScrollController.hasClients) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(
      'lastHorizontalScrollOffset',
      _horizontalScrollController.offset,
    );
    await prefs.setDouble(
      'lastVerticalScrollOffset',
      _verticalScrollController.offset,
    );
    await prefs.setString(
      'lastVisitedTime',
      DateTime.now().toIso8601String(),
    );
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
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    return FutureBuilder<Widget>(
      future: _buildGridView(context),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator.adaptive());
        } else if (snapshot.hasError) {
          return Text("Grid Error: ${snapshot.error}");
        } else {
          return snapshot.data ?? const SizedBox.shrink();
        }
      },
    );
  }

  /// -----------
  /// LE BUILD GRID
  /// -----------
  Future<Widget> _buildGridView(BuildContext context) async {
    // 1. Filtrer les assignations selon showOnlyFollowedArtists en utilisant followedArtistIds
    List<Map<String, dynamic>> artistsToShow = [];
    if (widget.showOnlyFollowedArtists && widget.followedArtistIds != null) {
      for (final assignment in widget.eventArtists) {
        final List<Artist> artists =
            (assignment['artists'] as List<dynamic>).cast<Artist>();
        // Si au moins un artiste de cette assignation est suivi, on l'inclut
        if (artists
            .any((artist) => widget.followedArtistIds!.contains(artist.id))) {
          artistsToShow.add(assignment);
        }
      }
    } else {
      artistsToShow = List.from(widget.eventArtists);
    }

    if (artistsToShow.isEmpty) {
      return const Center(child: Text("No assignments on selected stages"));
    }

    // 2. Filtrer les stages en se basant sur widget.selectedStages (pour respecter l'ordre des filtres)
    final List<String> filteredStages = widget.selectedStages
        .where((stage) => artistsToShow.any((a) => a['stage'] == stage))
        .toList();

    if (filteredStages.isEmpty) {
      return const Center(child: Text("No assignments on selected stages"));
    }

    // 3. Trier les assignations par heure de début
    artistsToShow.sort((a, b) {
      final stA = a['start_time'] as DateTime;
      final stB = b['start_time'] as DateTime;
      return stA.compareTo(stB);
    });

    // 4. Calculer l'heure la plus tôt et la plus tardive
    final earliestTime = artistsToShow
        .map((e) => e['start_time'] as DateTime)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final latestTime = artistsToShow
        .map((e) => e['end_time'] as DateTime)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    // 5. Construire la liste d'heures horizontales
    final List<DateTime> hours = [];
    DateTime current = DateTime(earliestTime.year, earliestTime.month,
        earliestTime.day, earliestTime.hour);
    while (!current.isAfter(latestTime)) {
      hours.add(current);
      current = current.add(const Duration(hours: 1));
    }

    // 6. Regrouper les assignations par stage (en se basant sur widget.selectedStages)
    final Map<String, List<Map<String, dynamic>>> artistsByStage = {};
    for (final assignment in artistsToShow) {
      final String? stage = assignment['stage'] as String?;
      if (stage == null) continue;
      if (!widget.selectedStages.contains(stage)) continue;
      artistsByStage.putIfAbsent(stage, () => []).add(assignment);
    }

    // 7. Construction de la grille
    return LayoutBuilder(
      builder: (ctx, constraints) {
        return SingleChildScrollView(
          controller: _verticalScrollController,
          child: Stack(
            children: [
              // 1) La grille "fond"
              SingleChildScrollView(
                controller: _horizontalScrollController,
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Stack(
                      children: [
                        // Le background "timeline"
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Column(
                              children: [
                                Container(height: 50),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 100,
                                        margin: const EdgeInsets.only(top: 20),
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            right: BorderSide(
                                                color: Colors.grey, width: 0.5),
                                          ),
                                        ),
                                      ),
                                      ...hours.skip(1).map((hour) {
                                        return Container(
                                          width: 200,
                                          margin:
                                              const EdgeInsets.only(top: 20),
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              right: BorderSide(
                                                  color: Colors.grey,
                                                  width: 0.5),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // 2) Les "rows" par stage
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // La "row" d'heures
                            Row(
                              children: [
                                const SizedBox(width: 50, height: 100),
                                Container(
                                  width: 100,
                                  height: 100,
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 30.0),
                                    child: Text(
                                        DateFormat.Hm().format(hours.first)),
                                  ),
                                ),
                                ...hours.skip(1).map((hour) {
                                  return Container(
                                    width: 200,
                                    height: 100,
                                    alignment: Alignment.centerLeft,
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(left: 130.0),
                                      child: Text(DateFormat.Hm().format(hour)),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                            // Pour chaque stage filtré
                            ...filteredStages.map((stage) {
                              // On construit la "row" horizontale
                              final List<Widget> stageRow = [
                                const SizedBox(width: 100)
                              ];
                              double accumulatedOffset = 0;
                              DateTime? lastEndTime;

                              // Parcourir les artists sur ce stage
                              final stageAssignments = artistsToShow
                                  .where((a) => a['stage'] == stage)
                                  .toList();

                              for (final artistMap in stageAssignments) {
                                final artists =
                                    (artistMap['artists'] as List<dynamic>)
                                        .cast<Artist>();
                                final customName =
                                    artistMap['custom_name'] as String?;
                                final nameToShow = (customName != null &&
                                        customName.isNotEmpty)
                                    ? customName
                                    : artists
                                        .map((a) => a.name)
                                        .join(', '); // B2B

                                final startTime =
                                    artistMap['start_time'] as DateTime;
                                final endTime =
                                    artistMap['end_time'] as DateTime;
                                final durationInHours =
                                    endTime.difference(startTime).inMinutes /
                                        60.0;
                                final offsetInHours = (startTime
                                            .difference(hours.first)
                                            .inMinutes /
                                        60.0) -
                                    accumulatedOffset;
                                final status =
                                    artistMap['status'] as String? ?? '';

                                // Overlap skip
                                if (lastEndTime != null &&
                                    startTime.isBefore(lastEndTime)) {
                                  continue;
                                }

                                // Espace libre
                                if (offsetInHours > 0) {
                                  stageRow.add(SizedBox(
                                    width: 200 * offsetInHours,
                                    height: 100,
                                  ));
                                }

                                // Check overlap pour le marker
                                for (final other in stageAssignments) {
                                  if (identical(other, artistMap)) continue;
                                  final oStart =
                                      other['start_time'] as DateTime?;
                                  final oEnd = other['end_time'] as DateTime?;
                                  if (oStart != null && oEnd != null) {
                                    if (startTime.isBefore(oEnd) &&
                                        endTime.isAfter(oStart)) {
                                      break;
                                    }
                                  }
                                }

                                // On ajoute la "carte" d'artiste
                                stageRow.add(
                                  SizedBox(
                                    width: 200 * durationInHours,
                                    height: 100,
                                    child: GestureDetector(
                                      onTap: () {
                                        if (artists.length > 1) {
                                          showArtistsBottomSheet(
                                              context, artists);
                                        } else {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (ctx) => ArtistScreen(
                                                  artistId: artists.first.id!),
                                            ),
                                          );
                                        }
                                      },
                                      child: Card(
                                        color: Theme.of(context).cardColor,
                                        shape: RoundedRectangleBorder(
                                          side: BorderSide(
                                            color:
                                                Theme.of(context).primaryColor,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0),
                                          child: Row(
                                            children: [
                                              // Artist Image
                                              if (artists.length == 1) ...[
                                                Container(
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onPrimary
                                                          .withOpacity(0.5),
                                                      width: 2.0,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10.0),
                                                    child:
                                                        ImageWithErrorHandler(
                                                      imageUrl: artists
                                                          .first.imageUrl,
                                                      width: 40,
                                                      height: 40,
                                                    ),
                                                  ),
                                                ),
                                              ] else ...[
                                                ArtistImageRotator(
                                                    artists: artists),
                                              ],
                                              const SizedBox(width: 8.0),
                                              Expanded(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      nameToShow,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: status ==
                                                                'cancelled'
                                                            ? Colors.redAccent
                                                            : null,
                                                        decoration: status ==
                                                                'cancelled'
                                                            ? TextDecoration
                                                                .lineThrough
                                                            : null,
                                                      ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    Text(
                                                      '${DateFormat.Hm().format(startTime)} - ${DateFormat.Hm().format(endTime)}',
                                                      style: const TextStyle(
                                                          fontSize: 12.0,
                                                          color: Colors.grey),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Conditional notification button display
                                              if (status !=
                                                  'cancelled') // Hide button for cancelled artists
                                                IconButton(
                                                  icon: Icon(
                                                    _notifiedArtistIds.contains(
                                                            artists.first.id!)
                                                        ? Icons
                                                            .notifications_active
                                                        : Icons
                                                            .add_alert_outlined,
                                                  ),
                                                  onPressed: isLoadingNotify
                                                      ? null
                                                      : () async {
                                                          if (_notifiedArtistIds
                                                              .contains(artists
                                                                  .first.id!)) {
                                                            ScaffoldMessenger
                                                                    .of(context)
                                                                .showSnackBar(
                                                              const SnackBar(
                                                                content: Text(
                                                                    "You will be notified for this artist."),
                                                                behavior:
                                                                    SnackBarBehavior
                                                                        .floating,
                                                              ),
                                                            );
                                                            return;
                                                          }

                                                          setState(() {
                                                            isLoadingNotify =
                                                                true;
                                                          });

                                                          final currentUser =
                                                              await UserService()
                                                                  .getCurrentUser();
                                                          final supabaseId =
                                                              currentUser
                                                                  ?.supabaseId;
                                                          if (supabaseId ==
                                                              null) {
                                                            SnackbarLogin
                                                                .showLoginSnackBar(
                                                                    context);
                                                            setState(() {
                                                              isLoadingNotify =
                                                                  false;
                                                            });
                                                            return;
                                                          }

                                                          final notificationTime =
                                                              startTime.subtract(
                                                                  const Duration(
                                                                      minutes:
                                                                          15));

                                                          try {
                                                            await NotificationService()
                                                                .addEventArtistNotification(
                                                              supabaseId:
                                                                  supabaseId,
                                                              artistId: artists
                                                                  .first.id!,
                                                              eventTitle: widget
                                                                  .event.title,
                                                              stage: capitalizeFirst(
                                                                  artistMap[
                                                                          'stage'] ??
                                                                      ''),
                                                              scheduledTime:
                                                                  notificationTime,
                                                              artistName:
                                                                  artists.first
                                                                      .name,
                                                              customName: artistMap[
                                                                      'custom_name'] ??
                                                                  '',
                                                            );

                                                            await _addNotifiedArtistId(
                                                                artists
                                                                    .first.id!);

                                                            setState(() {
                                                              _notifiedArtistIds
                                                                  .add(artists
                                                                      .first
                                                                      .id!);
                                                              isLoadingNotify =
                                                                  false;
                                                            });

                                                            ScaffoldMessenger
                                                                    .of(context)
                                                                .showSnackBar(
                                                              const SnackBar(
                                                                content: Text(
                                                                    "Notification scheduled."),
                                                                behavior:
                                                                    SnackBarBehavior
                                                                        .floating,
                                                              ),
                                                            );
                                                          } catch (e) {
                                                            ScaffoldMessenger
                                                                    .of(context)
                                                                .showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                    "Error scheduling notification: $e"),
                                                                behavior:
                                                                    SnackBarBehavior
                                                                        .floating,
                                                              ),
                                                            );
                                                            setState(() {
                                                              isLoadingNotify =
                                                                  false;
                                                            });
                                                          }
                                                        },
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );

                                accumulatedOffset +=
                                    offsetInHours + durationInHours;
                                lastEndTime = endTime;
                              }

                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20.0),
                                child: Row(children: stageRow),
                              );
                            }).toList(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // 3) Sur la gauche, on affiche le label du stage
              Positioned(
                top: 26,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: filteredStages.map((stage) {
                    // On check si ce stage a des assignments
                    final hasAssignments =
                        artistsToShow.any((a) => a['stage'] == stage);
                    if (!hasAssignments) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60.0),
                      child: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        decoration: const BoxDecoration(color: Colors.white),
                        child: Text(
                          capitalizeFirst(stage),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            overflow: TextOverflow.ellipsis,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    );
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

class NotificationIcon extends StatefulWidget {
  final int artistId;
  final bool isNotified;
  final Function onPressed;

  const NotificationIcon({
    Key? key,
    required this.artistId,
    required this.isNotified,
    required this.onPressed,
  }) : super(key: key);

  @override
  _NotificationIconState createState() => _NotificationIconState();
}

class _NotificationIconState extends State<NotificationIcon> {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        widget.isNotified
            ? Icons.notifications_active
            : Icons.add_alert_outlined,
      ),
      onPressed: () async {
        widget.onPressed(widget.artistId);
        setState(
            () {}); // Met à jour localement l'icône sans rafraîchir tout l'écran
      },
    );
  }
}
