import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sway/core/utils/text_formatting.dart';
import 'package:sway/features/artist/artist.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/utils/timetable_utils.dart';
import 'package:sway/features/user/services/user_follow_artist_service.dart';

class CompactGridViewWidget extends StatefulWidget {
  final Event event; // Add event field
  final List<Map<String, dynamic>> eventArtists;
  final bool showOnlyFollowedArtists;
  final List<String> stages;
  final List<String> selectedStages;
  final Set<int>? followedArtistIds;

  const CompactGridViewWidget({
    Key? key,
    required this.event,
    required this.eventArtists,
    required this.showOnlyFollowedArtists,
    required this.stages,
    required this.selectedStages,
    this.followedArtistIds,
  }) : super(key: key);

  @override
  State<CompactGridViewWidget> createState() => _CompactGridViewWidgetState();
}

class _CompactGridViewWidgetState extends State<CompactGridViewWidget> {
  bool _isScrollInitialized = false;
  double _lastHorizontalScrollOffset = 0.0;
  double _lastVerticalScrollOffset = 0.0;
  late ScrollController _horizontalScrollController;
  late ScrollController _verticalScrollController;
  UserFollowArtistService userFollowService = UserFollowArtistService();

// Ajoutez cette ligne ici
  bool isLoadingNotify = false;

  @override
  void initState() {
    super.initState();
    _loadLastScrollOffsets();
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
    // Vérifier que les controllers sont attachés
    if (!_horizontalScrollController.hasClients ||
        !_verticalScrollController.hasClients) return;

    // Exécuter l'enregistrement après le rendu de la frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
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
    });
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
      future: _buildCompactGridView(context),
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
  Future<Widget> _buildCompactGridView(BuildContext context) async {
    // 1. Filtrer les assignations selon showOnlyFollowedArtists
    List<Map<String, dynamic>> artistsToShow = [];
    if (widget.showOnlyFollowedArtists && widget.followedArtistIds != null) {
      for (final assignment in widget.eventArtists) {
        final List<Artist> artists =
            (assignment['artists'] as List<dynamic>).cast<Artist>();
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

    // 2. Filtrer les stages selon widget.selectedStages
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

    // 4. Déterminer la plage horaire
    final earliestTime = artistsToShow
        .map((e) => e['start_time'] as DateTime)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final latestTime = artistsToShow
        .map((e) => e['end_time'] as DateTime)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    // 5. Construire la liste des heures
    final List<DateTime> hours = [];
    DateTime currentHour = DateTime(earliestTime.year, earliestTime.month,
        earliestTime.day, earliestTime.hour);
    while (!currentHour.isAfter(latestTime)) {
      hours.add(currentHour);
      currentHour = currentHour.add(const Duration(hours: 1));
    }

    final currentTime = DateTime.now();
    double? currentOffset;

    int startMinutes = hours.first.hour * 60 + hours.first.minute;
    int endMinutes = hours.last.hour * 60 + hours.last.minute;
    int currentMinutes = currentTime.hour * 60 + currentTime.minute;

    // Si la plage traverse minuit, ajuster endMinutes (et currentMinutes si nécessaire)
    if (endMinutes < startMinutes) {
      endMinutes += 1440;
      if (currentMinutes < startMinutes) {
        currentMinutes += 1440;
      }
    }

    if (currentMinutes >= startMinutes && currentMinutes <= endMinutes) {
      final diffMinutes = currentMinutes - startMinutes;
      // Exemple : 150 pixels par heure et 100 pixels de décalage initial pour les labels
      currentOffset = 100 + (diffMinutes * 150 / 60);
    } else {
      print("The current time is not within the range displayed.");
    }

    // 6. Regrouper les assignations par stage
    final Map<String, List<Map<String, dynamic>>> artistsByStage = {};
    for (final assignment in artistsToShow) {
      final String? stage = assignment['stage'] as String?;
      if (stage == null) continue;
      if (!widget.selectedStages.contains(stage)) continue;
      artistsByStage.putIfAbsent(stage, () => []).add(assignment);
    }

    // 7. Construire la grille compact
    return LayoutBuilder(
      builder: (ctx, constraints) {
        return SingleChildScrollView(
          controller: _verticalScrollController,
          child: Stack(
            children: [
              // Fond de grille (timeline, etc.)
              SingleChildScrollView(
                controller: _horizontalScrollController,
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Stack(
                      children: [
                        // Timeline background simplifié
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Column(
                              children: [
                                Container(height: 40), // Hauteur réduite
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 80,
                                        margin: const EdgeInsets.only(top: 15),
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            right: BorderSide(
                                                color: Colors.grey, width: 0.5),
                                          ),
                                        ),
                                      ),
                                      ...hours.skip(1).map((hour) {
                                        return Container(
                                          width: 150,
                                          margin:
                                              const EdgeInsets.only(top: 15),
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

                        // Ligne rouge indiquant l'heure actuelle
                        if (currentOffset != null) ...[
                          Positioned(
                            left: currentOffset,
                            top: 55, // 40 (Container) + 15 (margin)
                            bottom: 0,
                            child: Container(
                              width: 2,
                              color: Colors.red.withValues(alpha: 0.5),
                            ),
                          ),
                        ],

                        // Les rows par stage
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Ligne des heures
                            Row(
                              children: [
                                const SizedBox(width: 40, height: 60),
                                Container(
                                  width: 80,
                                  height: 60,
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.only(left: 20),
                                  child:
                                      Text(DateFormat.Hm().format(hours.first)),
                                ),
                                ...hours.skip(1).map((hour) {
                                  return Container(
                                    width: 150,
                                    height: 60,
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.only(left: 100),
                                    child: Text(DateFormat.Hm().format(hour)),
                                  );
                                }).toList(),
                              ],
                            ),

                            // Pour chaque stage filtré
                            ...filteredStages.map((stage) {
                              final List<Widget> stageRow = [
                                const SizedBox(
                                    width:
                                        100) // décalage pour le label du stage
                              ];
                              double accumulatedOffset = 0;
                              DateTime? lastEndTime;
                              final stageAssignments = artistsToShow
                                  .where((a) => a['stage'] == stage)
                                  .toList();

                              for (final artistMap in stageAssignments) {
                                final List<Artist> artists =
                                    (artistMap['artists'] as List<dynamic>)
                                        .cast<Artist>();
                                final customName =
                                    artistMap['custom_name'] as String?;
                                final nameToShow = (customName != null &&
                                        customName.isNotEmpty)
                                    ? customName
                                    : artists.map((a) => a.name).join(', ');
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

                                // Récupérer le statut de l'artiste (ex: "cancelled")
                                final status =
                                    artistMap['status'] as String? ?? '';

                                // Gestion de l'overlap
                                if (lastEndTime != null &&
                                    startTime.isBefore(lastEndTime)) {
                                  continue;
                                }
                                if (offsetInHours > 0) {
                                  stageRow.add(SizedBox(
                                    width: 150 * offsetInHours,
                                    height: 60,
                                  ));
                                }

                                // Carte d'artiste compacte : sans image et sans icône
                                stageRow.add(
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 24.0),
                                    child: SizedBox(
                                      width: 150 * durationInHours,
                                      height: 60,
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
                                                    artistId:
                                                        artists.first.id!),
                                              ),
                                            );
                                          }
                                        },
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: Card(
                                            color: (widget.followedArtistIds !=
                                                        null &&
                                                    widget.followedArtistIds!
                                                        .contains(
                                                            artists.first.id!))
                                                ? Theme.of(context)
                                                    .primaryColor
                                                    .withValues(alpha: 0.3)
                                                : Theme.of(context).cardColor,
                                            shape: RoundedRectangleBorder(
                                              side: BorderSide(
                                                  color: Theme.of(context)
                                                      .primaryColor),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8.0),
                                              // Alignement à gauche
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start, // aligner à gauche
                                                  children: [
                                                    // Nom de l'artiste avec style conditionnel pour "cancelled"
                                                    Text(
                                                      nameToShow,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize:
                                                            14, // police réduite
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
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      textAlign: TextAlign.left,
                                                    ),
                                                    // Plage horaire avec alignement à gauche
                                                    Text(
                                                      '${DateFormat.Hm().format(startTime)} - ${DateFormat.Hm().format(endTime)}',
                                                      style: const TextStyle(
                                                        fontSize: 10.0,
                                                        color: Colors.grey,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      textAlign: TextAlign.left,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
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

                              // Réduire l'espacement vertical entre stages (padding vertical)
                              return Row(children: stageRow);
                            }).toList(),
                          ],
                        ),

                        if (currentOffset != null) ...[
                          // Texte indiquant l'heure actuelle, si besoin de le superposer à la timeline
                          Positioned(
                            left: currentOffset - 30,
                            top: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 2.0, horizontal: 4),
                              decoration: BoxDecoration(
                                borderRadius: new BorderRadius.circular(8.0),
                                border: Border.all(
                                    color: Colors.red.withValues(alpha: 0.8)),
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                              ),
                              height: 28,
                              width: 60,
                              alignment: Alignment.topCenter,
                              // padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                DateFormat.Hm().format(currentTime),
                                style: TextStyle(
                                  color: Colors.red.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              // Label des stages à gauche
              Positioned(
                top: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: filteredStages.map((stage) {
                    final hasAssignments =
                        artistsToShow.any((a) => a['stage'] == stage);
                    if (!hasAssignments) return const SizedBox.shrink();
                    return Padding(
                      // Augmenter le padding vertical pour espacer les stages
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        decoration: const BoxDecoration(color: Colors.white),
                        child: Text(
                          capitalizeFirst(stage),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 12, // police réduite pour le stage
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
