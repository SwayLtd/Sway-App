// lib/features/event/widgets/timetable/timetable.dart

import 'package:flutter/material.dart';
import 'package:sway/core/utils/date_utils.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/services/event_artist_service.dart';
import 'package:sway/features/event/widgets/timetable/timetable_list.dart';
import 'package:sway/features/event/widgets/timetable/timetable_grid.dart';
import 'package:sway/core/utils/text_formatting.dart';
import 'package:sway/features/user/services/user_follow_artist_service.dart';

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

  /// Index du jour sélectionné dans `metadata['festival_info']['days']`
  int _selectedDayIndex = 0;

  List<Map<String, dynamic>> _festivalDays =
      []; // [{"name":"Day 1","start":"...","end":"..."},...]
  List<String> _stages = []; // ["Main Stage","Second Stage",...]
  List<String> selectedStages = [];
  List<String> initialStages = [];

  @override
  void initState() {
    super.initState();
    _loadMetadataFestivalInfo();
    _loadArtistStages();
    _preloadFollowedArtistIds(); // Ajout de cette méthode
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
        'start': DateTime.parse(obj['start'] as String),
        'end': DateTime.parse(obj['end'] as String),
      };
    }).toList();

    final stages = festivalInfo['stages'] as List<dynamic>? ?? [];
    _stages = stages.map((s) => s as String).toList();
  }

  /// 2) Charger toutes les assignations (pour l'évent), extraire la liste des stages
  ///    et initialiser selectedStages
  Future<void> _loadArtistStages() async {
    final assignments =
        await EventArtistService().getArtistsByEventId(widget.event.id!);
    // Récupérer tous les stages distincts
    final stageSet = assignments.map((a) => a['stage'] as String).toSet();
    // Fusionner stageSet + _stages (venant du metadata) si tu veux
    // ou alors tu décides que c'est le metadata qui prime
    // Ici, on fait un simple union:
    // final unionStages = <String>{..._stages, ...stageSet}.toList();

    setState(() {
      initialStages = stageSet.toList();
      selectedStages = List.from(stageSet);
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
                return Center(child: Text("Error: ${snapshot.error}"));
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
              if (!isGridView) {
                return FutureBuilder<Widget>(
                  future: buildListView(
                    context: context,
                    eventArtists:
                        filtered, // assignations filtrées pour le jour sélectionné
                    showOnlyFollowedArtists: showOnlyFollowedArtists,
                    stages: _stages,
                    selectedStages: selectedStages,
                    followedArtistIds:
                        _followedArtistIds, // Ajouté ici si buildListView accepte ce paramètre
                  ),
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator.adaptive());
                    }
                    if (snap.hasError) {
                      return Center(child: Text("Error: ${snap.error}"));
                    }
                    return snap.data ?? const SizedBox.shrink();
                  },
                );
              } else {
                // Grid
                return GridViewWidget(
                  event: widget.event,
                  eventArtists: filtered,
                  showOnlyFollowedArtists: showOnlyFollowedArtists,
                  stages: _stages,
                  selectedStages: selectedStages,
                  followedArtistIds:
                      _followedArtistIds, // Transmet la liste préchargée
                );
              }
            },
          ),
        ),
        // Barre du bas : boutons PERSONNAL / FULL
        _buildBottomButtons(context),
      ],
    );
  }

  // Méthode qui fetch TOUTES les assignations => puis on filtre par le jour
  Future<List<Map<String, dynamic>>> _fetchDayAssignments() async {
    final all =
        await EventArtistService().getArtistsByEventId(widget.event.id!);
    if (_selectedDayIndex >= _festivalDays.length) return [];
    final dayInfo = _festivalDays[_selectedDayIndex];
    // Utilise les créneaux du metadata
    final dayStart = dayInfo['start'] as DateTime;
    final dayEnd = dayInfo['end'] as DateTime;

    return all.where((assignment) {
      final st = assignment['start_time'] as DateTime?;
      final et = assignment['end_time'] as DateTime?;
      if (st == null) return false;
      final eTime = et ?? st;
      // On inclut si le créneau chevauche le créneau du metadata
      return eTime.isAfter(dayStart) && st.isBefore(dayEnd);
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
                        : Colors.grey[600],
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
                        : Colors.grey[600],
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
      builder: (ctx) {
        return StatefulBuilder(
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
                          icon: const Icon(Icons.refresh),
                          onPressed: () {
                            setModalState(() {
                              selectedStages = List.from(initialStages);
                              showOnlyFollowedArtists = false;
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
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Expanded(
                  child: ReorderableListView(
                    onReorder: (oldIndex, newIndex) {
                      if (newIndex > oldIndex) {
                        newIndex -= 1;
                      }
                      setModalState(() {
                        final String stage = selectedStages.removeAt(oldIndex);
                        selectedStages.insert(newIndex, stage);
                      });
                    },
                    children: selectedStages.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final stage = entry.value;
                      return Column(
                        key: Key(stage),
                        children: [
                          ListTile(
                            leading: const Icon(Icons.drag_handle),
                            title: Text(capitalizeFirst(stage)),
                            trailing: Checkbox(
                              value: selectedStages.contains(stage),
                              onChanged: (bool? val) {
                                if (val == null) return;
                                setModalState(() {
                                  if (val == true &&
                                      !selectedStages.contains(stage)) {
                                    selectedStages.add(stage);
                                  } else if (!val) {
                                    selectedStages.remove(stage);
                                  }
                                });
                              },
                            ),
                          ),
                          if (idx < selectedStages.length - 1)
                            const Divider(color: Colors.grey, height: 1),
                        ],
                      );
                    }).toList(),
                  ),
                ),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {}); // Forcer refresh sur l'écran principal
                      },
                      child: const Text('APPLY',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
