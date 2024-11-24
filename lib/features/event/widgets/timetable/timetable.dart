// timetable.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/services/event_artist_service.dart';
import 'package:sway/features/event/utils/timetable_utils.dart';
import 'package:sway/features/event/widgets/timetable/timetable_grid.dart';
import 'package:sway/features/event/widgets/timetable/timetable_list.dart';

class TimetableWidget extends StatefulWidget {
  final Event event;

  const TimetableWidget({required this.event});

  @override
  _TimetableWidgetState createState() => _TimetableWidgetState();
}

class _TimetableWidgetState extends State<TimetableWidget> {
  bool isGridView = false;
  bool showOnlyFollowedArtists = false;
  DateTime selectedDay = DateTime.now();
  List<Map<String, dynamic>> eventArtists = [];
  List<String> stages = [];
  List<String> selectedStages = [];
  List<String> initialStages = [];

  @override
  void initState() {
    super.initState();
    _initializeStages();
  }

  Future<void> _initializeStages() async {
    final artists =
        await EventArtistService().getArtistsByEventId(widget.event.id);
    final stageSet = artists.map((e) => e['stage'] as String).toSet().toList();

    setState(() {
      stages = stageSet;
      selectedStages = List.from(stageSet);
      initialStages = List.from(stageSet); // Save initial order of stages
    });

    await _initializeSelectedDay();

    // Forcer la mise à jour de la vue après l'initialisation des artistes
    setState(() {
      eventArtists = artists;
    });
  }

  Future<void> _initializeSelectedDay() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final festivalDays = await calculateFestivalDays(widget.event);

    final lastSelectedDayString = prefs.getString('lastSelectedDay');
    final lastSelectedDay = lastSelectedDayString != null
        ? DateTime.parse(lastSelectedDayString)
        : null;
    final lastSelectedTimeString = prefs.getString('lastSelectedTime');
    final lastSelectedTime = lastSelectedTimeString != null
        ? DateTime.parse(lastSelectedTimeString)
        : null;

    final shouldResetDay = lastSelectedTime == null ||
        now.difference(lastSelectedTime).inMinutes > 15;

    setState(() {
      if (shouldResetDay || lastSelectedDay == null) {
        selectedDay = festivalDays.firstWhere(
          (day) =>
              day.day == now.day &&
              day.month == now.month &&
              day.year == now.year,
          orElse: () => festivalDays.first,
        );
      } else if (!festivalDays.contains(lastSelectedDay)) {
        selectedDay = festivalDays.first;
      } else {
        selectedDay = lastSelectedDay;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DateTime>>(
      future: calculateFestivalDays(widget.event),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator.adaptive());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No festival days found'));
        } else {
          final List<DateTime> festivalDays = snapshot.data!;

          // Déterminer le jour sélectionné effectif sans appeler setState
          final DateTime effectiveSelectedDay =
              festivalDays.contains(selectedDay)
                  ? selectedDay
                  : festivalDays.first;

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
                        value: effectiveSelectedDay,
                        onChanged: (DateTime? newValue) async {
                          if (newValue != null && newValue != selectedDay) {
                            setState(() {
                              selectedDay = newValue;
                            });
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString(
                                'lastSelectedDay', newValue.toIso8601String());
                            await prefs.setString('lastSelectedTime',
                                DateTime.now().toIso8601String());
                          }
                        },
                        items: festivalDays.map((DateTime date) {
                          return DropdownMenuItem<DateTime>(
                            value: date,
                            child: Text(DateFormat('EEEE, MMM d').format(date)),
                          );
                        }).toList(),
                      ),
                    ),
                    Row(
                      children: [
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
                        IconButton(
                          icon: const Icon(Icons.filter_list),
                          onPressed: _showFilterDialog,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: EventArtistService()
                      .getArtistsByEventIdAndDay(widget.event.id, selectedDay),
                  builder: (context, artistSnapshot) {
                    if (artistSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator.adaptive());
                    } else if (artistSnapshot.hasError) {
                      return Center(
                        child: Text('Error: ${artistSnapshot.error}'),
                      );
                    } else if (!artistSnapshot.hasData ||
                        artistSnapshot.data!.isEmpty) {
                      return const Center(child: Text('No events found'));
                    } else {
                      eventArtists = artistSnapshot.data!;

                      final filteredArtists = eventArtists
                          .where(
                            (artist) =>
                                selectedStages.contains(artist['stage']),
                          )
                          .toList();

                      if (filteredArtists.isEmpty) {
                        return const Center(
                          child: Text(
                            'No programming available on selected stages for the selected day',
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      return isGridView
                          ? GridViewWidget(
                              eventArtists: filteredArtists,
                              selectedDay: selectedDay,
                              stages: stages,
                              selectedStages: selectedStages,
                              showOnlyFollowedArtists: showOnlyFollowedArtists,
                            )
                          : FutureBuilder<Widget>(
                              future: buildListView(
                                context,
                                filteredArtists,
                                selectedDay,
                                stages,
                                selectedStages,
                                showOnlyFollowedArtists,
                              ),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator.adaptive(),
                                  );
                                } else if (snapshot.hasError) {
                                  return Center(
                                    child: Text('Error: ${snapshot.error}'),
                                  );
                                } else {
                                  return snapshot.data!;
                                }
                              },
                            );
                    }
                  },
                ),
              ),
              Row(
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
              ),
            ],
          );
        }
      },
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
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
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          right: 8.0,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () {
                            setState(() {
                              selectedStages = List.from(initialStages);
                              stages = List.from(initialStages);
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ReorderableListView(
                    onReorder: (int oldIndex, int newIndex) {
                      if (newIndex > oldIndex) {
                        newIndex -= 1;
                      }
                      setState(() {
                        final String stage = stages.removeAt(oldIndex);
                        stages.insert(newIndex, stage);
                      });
                    },
                    children: stages.asMap().entries.map((entry) {
                      final int idx = entry.key;
                      final String stage = entry.value;
                      return Column(
                        key: Key(stage),
                        children: [
                          ListTile(
                            leading: const Icon(Icons.drag_handle),
                            title: Text(stage),
                            trailing: Checkbox(
                              value: selectedStages.contains(stage),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    selectedStages.add(stage);
                                  } else {
                                    selectedStages.remove(stage);
                                  }
                                });
                              },
                            ),
                          ),
                          if (idx < stages.length - 1)
                            const Divider(
                              color: Colors.grey,
                              height: 1,
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                SwitchListTile.adaptive(
                  title: const Text('Only followed artists'),
                  value: showOnlyFollowedArtists,
                  onChanged: (bool value) {
                    setState(() {
                      showOnlyFollowedArtists = value;
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
                        setState(() {
                          Navigator.pop(context);
                        });
                        this.setState(() {});
                      },
                      child: const Text(
                        'APPLY',
                        style: TextStyle(color: Colors.white),
                      ),
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
