// lib/features/event/widgets/timetable/timetable.dart

import 'package:flutter/material.dart';
import 'package:sway/core/utils/date_utils.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/services/event_artist_service.dart';
import 'package:sway/features/event/widgets/timetable/timetable_grid.dart';
import 'package:sway/features/event/widgets/timetable/timetable_list.dart';
import 'package:sway/features/event/widgets/timetable/timetable_compact_grid.dart';
import 'package:sway/core/utils/text_formatting.dart';
import 'package:sway/features/user/services/user_follow_artist_service.dart';
import 'package:sway/features/user/services/user_service.dart';

class TimetableWidget extends StatefulWidget {
  final Event event;

  const TimetableWidget({Key? key, required this.event}) : super(key: key);

  @override
  State<TimetableWidget> createState() => _TimetableWidgetState();
}

class _TimetableWidgetState extends State<TimetableWidget> {
  bool isGridView = false;
  bool showOnlyFollowedArtists = false;
  Set<int> _followedArtistIds = {};
  bool useCompactGridView = true;

  final UserService _userService = UserService();
  bool _isLoggedIn = false;

  /// Index du jour sélectionné dans `metadata['festival_info']['days']`
  int _selectedDayIndex = 0;

  List<Map<String, dynamic>> _festivalDays =
      []; // [{"name":"Day 1","start":"...","end":"..."},...]
  List<String> _stages = []; // Liste pour l'affichage des stages dans l'ordre
  List<String> selectedStages =
      []; // Liste pour les stages sélectionnées (cochées)
  List<String> initialStages = []; // Pour réinitialiser l'ordre

  @override
  void initState() {
    super.initState();
    _loadMetadataFestivalInfo();
    _loadArtistStages();
    _preloadFollowedArtistIds(); // Ajout de cette méthode
    _loadUserStatus();
  }

  Future<void> _loadUserStatus() async {
    try {
      final currentUser = await _userService.getCurrentUser();
      if (!mounted) return;
      setState(() {
        _isLoggedIn = currentUser != null;
      });
    } catch (e) {
      print('Error loading user status: $e');
      if (!mounted) return;
      setState(() {
        _isLoggedIn = false;
      });
    }
  }

  Future<void> _preloadFollowedArtistIds() async {
    final userFollowService = UserFollowArtistService();
    // Supposons que chaque assignation contient une liste d'artistes,
    // on parcourt toutes les assignations pour récupérer tous les IDs.
    final assignments =
        await EventArtistService().getArtistsByEventId(widget.event.id!);
    // On récupère tous les IDs uniques des artistes présents dans l'event.
    final allArtistIds = assignments.expand((a) {
      final ids =
          (a['artists'] as List<Artist>).map((artist) => artist.id!).toList();
      return ids;
    }).toSet();
    // Filtrer par ceux qui sont suivis.
    final Set<int> followedIds = {};
    for (final id in allArtistIds) {
      if (await userFollowService.isFollowingArtist(id)) {
        followedIds.add(id);
      }
    }
    setState(() {
      _followedArtistIds = followedIds;
    });
  }

  /// 1) On lit le metadata['festival_info']
  void _loadMetadataFestivalInfo() {
    final metadata = widget.event.metadata ?? {};
    final festivalInfo = metadata['festival_info'] as Map<String, dynamic>?;
    if (festivalInfo == null) {
      // Pas d'infos festival => on peut le signaler
      return;
    }
    final days = festivalInfo['days'] as List<dynamic>? ?? [];
    _festivalDays = days.map((obj) {
      return {
        'name': (obj['name'] as String?) ?? 'Day',
        // Conversion en local pour que la comparaison se fasse dans le même fuseau horaire que les assignations
        'start': DateTime.parse(obj['start'] as String).toLocal(),
        'end': DateTime.parse(obj['end'] as String).toLocal(),
      };
    }).toList();

    final stages = festivalInfo['stages'] as List<dynamic>? ?? [];
    // On peut aussi normaliser ici en minuscule
    _stages = stages.map((s) => (s as String)).toList();
  }

  /// 2) Charger toutes les assignations (pour l'évent), extraire la liste des stages
  ///    et initialiser selectedStages
  Future<void> _loadArtistStages() async {
    final assignments =
        await EventArtistService().getArtistsByEventId(widget.event.id!);

    final stageSet = assignments.map((a) => (a['stage'] as String)).toSet();

    setState(() {
      _stages = stageSet.toList(); // Storing stages in the correct order
      initialStages = List.from(_stages); // Keep the initial order
      selectedStages = List.from(_stages); // Initially all stages are selected
    });
  }

  @override
  Widget build(BuildContext context) {
    // Si _festivalDays est vide => on affiche un message
    if (_festivalDays.isEmpty) {
      return const Center(
        child: Text("No festival_info in metadata"),
      );
    }
    return Column(
      children: [
        // Barre du haut (dropdown Days + switch list/grid + bouton filtrer)
        _buildTopControls(context),
        // Corps : on fetch TOUTES les assignations => on filtre par [start; end] du jour
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchDayAssignments(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator.adaptive());
              }
              if (snapshot.hasError) {
                return Center(child: Text("You're offline."));
              }
              final dayAssignments = snapshot.data ?? [];
              if (dayAssignments.isEmpty) {
                return const Center(child: Text("No programming for this day"));
              }

              // Filtrer par selectedStages
              final filtered = dayAssignments
                  .where(
                    (a) => selectedStages.contains(a['stage'] as String),
                  )
                  .toList();
              if (filtered.isEmpty) {
                return const Center(
                    child: Text("No programming on selected stages"));
              }

              // Choix final : ListView ou GridView
              // In the build() method, update the grid view choice:
              if (!isGridView) {
                return TimetableListView(
                  event: widget.event,
                  eventArtists: filtered,
                  showOnlyFollowedArtists: showOnlyFollowedArtists,
                  stages: _stages,
                  selectedStages: selectedStages,
                  followedArtistIds: _followedArtistIds,
                );
              } else {
                return useCompactGridView
                    ? CompactGridViewWidget(
                        event: widget.event,
                        eventArtists: filtered,
                        showOnlyFollowedArtists: showOnlyFollowedArtists,
                        stages: _stages,
                        selectedStages: selectedStages,
                        followedArtistIds: _followedArtistIds,
                      )
                    : GridViewWidget(
                        event: widget.event,
                        eventArtists: filtered,
                        showOnlyFollowedArtists: showOnlyFollowedArtists,
                        stages: _stages,
                        selectedStages: selectedStages,
                        followedArtistIds: _followedArtistIds,
                      );
              }
            },
          ),
        ),
        // Barre du bas : boutons PERSONNAL / FULL
        if (_isLoggedIn) _buildBottomButtons(context),
      ],
    );
  }

  // Méthode qui fetch TOUTES les assignations => puis on filtre par le jour
  Future<List<Map<String, dynamic>>> _fetchDayAssignments() async {
    final all =
        await EventArtistService().getArtistsByEventId(widget.event.id!);
    if (_selectedDayIndex >= _festivalDays.length) return [];
    final dayInfo = _festivalDays[_selectedDayIndex];
    final dayStart = dayInfo['start'] as DateTime;
    final dayEnd = dayInfo['end'] as DateTime;

    return all.where((assignment) {
      final st = assignment['start_time'] as DateTime?;
      final et = assignment['end_time'] as DateTime?;
      if (st == null) return false;
      final eTime = et ?? st;
      // On inclut si le créneau chevauche le créneau défini dans le metadata
      return eTime.isAfter(dayStart) && st.isBefore(dayEnd);
    }).where((assignment) {
      // Pour la comparaison, on met le stage en minuscules
      final stage = (assignment['stage'] as String);
      return selectedStages.contains(stage);
    }).toList();
  }

  Widget _buildTopControls(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, left: 8.0, right: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Dropdown des "days"
          DropdownButton<int>(
            value: _selectedDayIndex,
            onChanged: (newVal) {
              if (newVal == null) return;
              setState(() {
                _selectedDayIndex = newVal;
              });
            },
            items: List.generate(_festivalDays.length, (index) {
              final dayInfo = _festivalDays[index];
              final dayName = dayInfo['name'] as String; // ex. "Day 1"
              final start =
                  dayInfo['start'] as DateTime; // la date de début du jour
              // Utilise formatShortDate (défini dans date_utils.dart) pour formater la date
              final formattedDate = formatShortDate(start); // ex. "27/06"
              final displayText = "$dayName ($formattedDate)";
              return DropdownMenuItem<int>(
                value: index,
                child: Text(displayText),
              );
            }),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(isGridView ? Icons.view_list : Icons.grid_view),
                onPressed: () {
                  setState(() {
                    isGridView = !isGridView;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                showOnlyFollowedArtists = true;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: showOnlyFollowedArtists
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).disabledColor,
              shape: const RoundedRectangleBorder(),
              padding: const EdgeInsets.symmetric(vertical: 12.0),
            ),
            child: Text(
              'PERSONAL',
              style: TextStyle(
                color: showOnlyFollowedArtists
                    ? Colors.white
                    : Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[300]
                        : Colors.grey[500],
              ),
            ),
          ),
        ),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                showOnlyFollowedArtists = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: !showOnlyFollowedArtists
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).disabledColor,
              shape: const RoundedRectangleBorder(),
              padding: const EdgeInsets.symmetric(vertical: 12.0),
            ),
            child: Text(
              'FULL',
              style: TextStyle(
                color: !showOnlyFollowedArtists
                    ? Colors.white
                    : Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[300]
                        : Colors.grey[500],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permet d'utiliser toute la hauteur disponible
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height *
              0.7, // 70% de la hauteur de l'écran
          child: StatefulBuilder(
            builder: (ctx, setModalState) {
              return Column(
                children: [
                  Container(
                    height: 5,
                    width: 50,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  Stack(
                    children: [
                      const Center(
                        child: Text(
                          'FILTERS',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: IconButton(
                            icon: const Icon(Icons.restore),
                            onPressed: () {
                              setModalState(() {
                                // Réinitialiser l'ordre des stages
                                selectedStages = List.from(initialStages);
                                _stages = List.from(initialStages);
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'STAGES',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ReorderableListView(
                      onReorder: (oldIndex, newIndex) {
                        setModalState(() {
                          final String stage =
                              selectedStages.removeAt(oldIndex);
                          selectedStages.insert(newIndex, stage);
                          _stages.removeAt(oldIndex);
                          _stages.insert(newIndex, stage);
                        });
                      },
                      children: _stages.map((stage) {
                        final isChecked = selectedStages.contains(stage);
                        return Column(
                          key: Key(stage),
                          children: [
                            ListTile(
                              leading: const Icon(Icons.drag_handle),
                              title: Text(capitalizeFirst(stage)),
                              trailing: Checkbox(
                                value: isChecked,
                                onChanged: (bool? val) {
                                  if (val == null) return;
                                  setModalState(() {
                                    if (val &&
                                        !selectedStages.contains(stage)) {
                                      selectedStages.add(stage);
                                    } else if (!val) {
                                      selectedStages.remove(stage);
                                    }
                                  });
                                },
                              ),
                            ),
                            const Divider(color: Colors.grey, height: 1),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  SwitchListTile.adaptive(
                    title: const Text('Compact grid view'),
                    value: useCompactGridView,
                    onChanged: (bool val) {
                      setModalState(() {
                        useCompactGridView = val;
                      });
                    },
                  ),
                  if (_isLoggedIn)
                    SwitchListTile.adaptive(
                      title: const Text('Only followed artists'),
                      value: showOnlyFollowedArtists,
                      onChanged: (bool val) {
                        setModalState(() {
                          showOnlyFollowedArtists = val;
                        });
                      },
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {});
                        },
                        child: const Text('APPLY'),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
