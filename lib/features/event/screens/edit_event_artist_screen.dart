import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sway/core/constants/dimensions.dart';
import 'package:sway/core/utils/date_utils.dart'; // formatEventDate, formatEventTime
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/artist/services/artist_service.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/services/event_artist_service.dart';
import 'package:sway/features/event/services/event_service.dart';
import 'package:sway/features/user/services/user_permission_service.dart';
import 'package:sway/features/user/services/user_service.dart';

/// Modèle pour représenter une journée de festival
class FestivalDay {
  final String id;
  String name;
  DateTime start;
  DateTime end;

  FestivalDay({
    String? id,
    required this.name,
    required this.start,
    required this.end,
  }) : id = id ?? UniqueKey().toString();
}

/// Screen dedicated to managing artist assignments for an event.
/// L'événement est récupéré automatiquement via son ID.
class EditEventArtistsScreen extends StatefulWidget {
  final int eventId;
  const EditEventArtistsScreen({Key? key, required this.eventId})
      : super(key: key);

  @override
  _EditEventArtistsScreenState createState() => _EditEventArtistsScreenState();
}

class _EditEventArtistsScreenState extends State<EditEventArtistsScreen> {
  final EventArtistService _eventArtistService = EventArtistService();
  final EventService _eventService = EventService();
  final UserPermissionService _permissionService = UserPermissionService();
  final UserService _userService = UserService();

  List<Map<String, dynamic>> _assignments = [];
  bool _isLoading = true;
  bool _canEdit = false; // true if user is manager or admin
  Event? _currentEvent; // récupère les dates réelles de l'event

  @override
  void initState() {
    super.initState();
    _fetchEvent();
    _checkPermissions();
    _fetchAssignments();
  }

  Future<void> _fetchEvent() async {
    try {
      final event = await _eventService.getEventById(widget.eventId);
      if (mounted) {
        setState(() {
          _currentEvent = event;
        });
      }
    } catch (e) {
      print('Error fetching event: $e');
    }
  }

  Future<void> _checkPermissions() async {
    final currentUser = await _userService.getCurrentUser();
    if (currentUser != null) {
      // Pour éditer, il faut au moins le niveau manager (2)
      final canEdit = await _permissionService.hasPermissionForCurrentUser(
          widget.eventId, 'event', 2);
      setState(() {
        _canEdit = canEdit;
      });
    }
  }

  bool get _timetableActive => _currentEvent?.metadata?['timetable'] ?? false;

  List<FestivalDay> get _festivalDaysFromMetadata {
    List<FestivalDay> days = [];
    final metadata = _currentEvent?.metadata;
    if (metadata != null) {
      if (metadata.containsKey('festival_info')) {
        final info = metadata['festival_info'] as Map<String, dynamic>;
        if (info.containsKey('days')) {
          final daysJson = info['days'] as List<dynamic>;
          days = daysJson
              .map((json) => FestivalDay(
                    name: json['name'],
                    start: DateTime.parse(json['start']),
                    end: DateTime.parse(json['end']),
                  ))
              .toList();
        }
      } else if (metadata.containsKey('festival_days')) {
        final daysJson = metadata['festival_days'] as List<dynamic>;
        days = daysJson
            .map((json) => FestivalDay(
                  name: json['name'],
                  start: DateTime.parse(json['start']),
                  end: DateTime.parse(json['end']),
                ))
            .toList();
      }
    }
    return days;
  }

  List<String> get _availableStagesFromMetadata {
    final metadata = _currentEvent?.metadata;
    if (metadata != null) {
      if (metadata.containsKey('festival_info')) {
        final info = metadata['festival_info'] as Map<String, dynamic>;
        if (info.containsKey('stages')) {
          return List<String>.from(info['stages']);
        }
      } else if (metadata.containsKey('stages')) {
        return List<String>.from(metadata['stages']);
      }
    }
    return [];
  }

  Future<void> _fetchAssignments() async {
    setState(() => _isLoading = true);
    try {
      _assignments =
          await _eventArtistService.getArtistsByEventId(widget.eventId);
    } catch (e) {
      print('Error fetching artist assignments: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _editAssignment(Map<String, dynamic> assignment) async {
    if (!_canEdit || _currentEvent == null) return;
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ArtistAssignmentBottomSheet(
        eventId: widget.eventId,
        eventStart: _currentEvent!.eventDateTime,
        eventEnd: _currentEvent!.eventEndDateTime,
        assignment: assignment,
        canEdit: _canEdit,
        timetableActive: _timetableActive,
        festivalDays: _festivalDaysFromMetadata,
        availableStages: _availableStagesFromMetadata,
      ),
    );
    if (result == true) {
      await _fetchAssignments();
    }
  }

  void _showAddAssignmentSheet() async {
    if (!_canEdit || _currentEvent == null) return;
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ArtistAssignmentBottomSheet(
        eventId: widget.eventId,
        eventStart: _currentEvent!.eventDateTime,
        eventEnd: _currentEvent!.eventEndDateTime,
        canEdit: _canEdit,
        timetableActive: _timetableActive,
        festivalDays: _festivalDaysFromMetadata,
        availableStages: _availableStagesFromMetadata,
      ),
    );
    if (result == true) {
      await _fetchAssignments();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Group assignments by day (format: YYYY-MM-DD)
    Map<String, List<Map<String, dynamic>>> groupByDay = {};
    _assignments.sort((a, b) {
      DateTime? aTime = a['start_time'] is String
          ? DateTime.parse(a['start_time'] as String)
          : a['start_time'] as DateTime?;
      DateTime? bTime = b['start_time'] is String
          ? DateTime.parse(b['start_time'] as String)
          : b['start_time'] as DateTime?;

      // If both are null, treat as equal
      if (aTime == null && bTime == null) return 0;
      // Treat missing start times as later
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return aTime.compareTo(bTime);
    });

    for (var assignment in _assignments) {
      DateTime? start = assignment['start_time'] is String
          ? DateTime.parse(assignment['start_time'] as String)
          : assignment['start_time'] as DateTime?;

      // If start_time is null, use a special key (e.g., "No specific time")
      String dayKey = start != null
          ? start.toLocal().toString().substring(0, 10)
          : 'No specific time';

      groupByDay.putIfAbsent(dayKey, () => []).add(assignment);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Artist Assignments'),
        actions: [
          // Show the "+" button only if the user can edit
          if (_canEdit)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showAddAssignmentSheet,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : groupByDay.isEmpty
              ? const Center(child: Text('No assignments'))
              : ListView(
                  padding: const EdgeInsets.all(8),
                  children: groupByDay.entries.map((entry) {
                    final day = entry.key;
                    final assignments = entry.value;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            day == 'No specific time'
                                ? 'No specific time'
                                : formatEventDate(DateTime.parse(day)),
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...assignments.map((assignment) {
                          // Extraction des noms d'artistes
                          final List<dynamic> artists =
                              assignment['artists'] ?? [];
                          final String artistNames =
                              artists.map((a) => a.name).join(', ');

                          // Extraction des start/end times
                          final DateTime? parsedStart =
                              assignment['start_time'] is String
                                  ? DateTime.parse(
                                      assignment['start_time'] as String)
                                  : assignment['start_time'] as DateTime?;
                          final DateTime? parsedEnd = assignment['end_time']
                                  is String
                              ? DateTime.parse(assignment['end_time'] as String)
                              : assignment['end_time'] as DateTime?;

                          // Construction de l'affichage du créneau horaire
                          String timeDisplay;
                          if (_timetableActive) {
                            // Si timetable est activée, forcer les heures et afficher un message d'erreur si manquantes.
                            if (parsedStart != null && parsedEnd != null) {
                              final String startDate = parsedStart
                                  .toLocal()
                                  .toString()
                                  .substring(0, 10);
                              final String startHour = parsedStart
                                  .toLocal()
                                  .toString()
                                  .substring(11, 16);
                              final String endDate = parsedEnd
                                  .toLocal()
                                  .toString()
                                  .substring(0, 10);
                              final String endHour = parsedEnd
                                  .toLocal()
                                  .toString()
                                  .substring(11, 16);
                              timeDisplay =
                                  '$startDate $startHour → $endDate $endHour';
                            } else {
                              // Au lieu de "No specific time", afficher le message d'erreur en rouge
                              timeDisplay = 'Start/End time required!';
                            }
                          } else {
                            // Si timetable n'est pas active, le comportement habituel
                            if (parsedStart != null && parsedEnd != null) {
                              final String startDate = parsedStart
                                  .toLocal()
                                  .toString()
                                  .substring(0, 10);
                              final String startHour = parsedStart
                                  .toLocal()
                                  .toString()
                                  .substring(11, 16);
                              final String endDate = parsedEnd
                                  .toLocal()
                                  .toString()
                                  .substring(0, 10);
                              final String endHour = parsedEnd
                                  .toLocal()
                                  .toString()
                                  .substring(11, 16);
                              timeDisplay =
                                  '$startDate $startHour → $endDate $endHour';
                            } else if (parsedStart != null) {
                              final String startDate = parsedStart
                                  .toLocal()
                                  .toString()
                                  .substring(0, 10);
                              final String startHour = parsedStart
                                  .toLocal()
                                  .toString()
                                  .substring(11, 16);
                              timeDisplay = '$startDate $startHour';
                            } else {
                              timeDisplay = 'No specific time';
                            }
                          }

                          // Construction des lignes d'info
                          List<Widget> infoRows = [];
                          infoRows.add(Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 14),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  timeDisplay,
                                  style: _timetableActive &&
                                          (parsedStart == null ||
                                              parsedEnd == null)
                                      ? const TextStyle(
                                          fontSize: 14, color: Colors.red)
                                      : const TextStyle(fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ));

                          // Pour le champ stage, si timetable est active, afficher l'icône avec le message d'erreur à droite
                          if (_timetableActive) {
                            if (assignment['stage'] != null &&
                                (assignment['stage'] as String).isNotEmpty) {
                              infoRows.add(Row(
                                children: [
                                  const Icon(Icons.theater_comedy_sharp,
                                      size: 14),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      assignment['stage'],
                                      style: const TextStyle(fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ));
                            } else {
                              infoRows.add(Row(
                                children: [
                                  const Icon(Icons.theater_comedy_sharp,
                                      size: 14),
                                  const SizedBox(width: 4),
                                  const Expanded(
                                    child: Text(
                                      'Stage required!',
                                      style: TextStyle(
                                          fontSize: 14, color: Colors.red),
                                    ),
                                  ),
                                ],
                              ));
                            }
                          } else {
                            if (assignment['stage'] != null &&
                                (assignment['stage'] as String).isNotEmpty) {
                              infoRows.add(Row(
                                children: [
                                  const Icon(Icons.theater_comedy_sharp,
                                      size: 14),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      assignment['stage'],
                                      style: const TextStyle(fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ));
                            }
                          }

                          return Column(
                            children: [
                              Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                child: ListTile(
                                  title: Text(
                                    artistNames,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: infoRows,
                                  ),
                                  onTap: _canEdit
                                      ? () => _editAssignment(assignment)
                                      : null,
                                ),
                              ),
                              const Divider(thickness: 1),
                            ],
                          );
                        }).toList(),
                      ],
                    );
                  }).toList(),
                ),
    );
  }
}

/// Bottom sheet for adding or editing an artist assignment.
/// The eventStart and eventEnd represent the overall event's boundaries.
class ArtistAssignmentBottomSheet extends StatefulWidget {
  final int eventId;
  final DateTime eventStart;
  final DateTime? eventEnd;
  final Map<String, dynamic>? assignment;
  final bool canEdit;
  // Nouveaux paramètres pour la timetable :
  final bool timetableActive;
  final List<FestivalDay>? festivalDays;
  final List<String>? availableStages;

  const ArtistAssignmentBottomSheet({
    Key? key,
    required this.eventId,
    required this.eventStart,
    this.eventEnd,
    this.assignment,
    required this.canEdit,
    required this.timetableActive,
    this.festivalDays,
    this.availableStages,
  }) : super(key: key);

  @override
  _ArtistAssignmentBottomSheetState createState() =>
      _ArtistAssignmentBottomSheetState();
}

class _ArtistAssignmentBottomSheetState
    extends State<ArtistAssignmentBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _startTime;
  DateTime? _endTime;
  String? _customName;
  String? _stage;
  Set<int> _selectedArtistIds = {};
  bool _isLoading = true;
  List<Artist> _allArtists = [];
  final ArtistService _artistService = ArtistService();
  final EventArtistService _eventArtistService = EventArtistService();

  // For search filtering:
  List<Artist> _filteredArtists = [];
  String _searchQuery = '';
  int _maxArtistsToShow = 5;

  @override
  void initState() {
    super.initState();
    _fetchArtists();
    if (widget.assignment != null) {
      final startTimeVal = widget.assignment!['start_time'];
      if (startTimeVal != null) {
        _startTime = startTimeVal is String
            ? DateTime.parse(startTimeVal)
            : startTimeVal as DateTime;
      }
      final endTimeVal = widget.assignment!['end_time'];
      if (endTimeVal != null) {
        _endTime = endTimeVal is String
            ? DateTime.parse(endTimeVal)
            : endTimeVal as DateTime;
      }
      _customName = widget.assignment!['custom_name'];
      _stage = widget.assignment!['stage'];
      final List<dynamic> artists = widget.assignment!['artists'] ?? [];
      _selectedArtistIds = artists.map((a) => a.id as int).toSet();
    }
    _applyFilter();
  }

  Future<void> _fetchArtists() async {
    setState(() => _isLoading = true);
    try {
      _allArtists = await _artistService.getArtists();
      _applyFilter();
    } catch (e) {
      print('Error fetching artists: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredArtists = _allArtists;
      } else {
        _filteredArtists = _allArtists
            .where((artist) =>
                artist.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _pickStartTime() async {
    if (!widget.canEdit) return;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startTime ?? widget.eventStart,
      firstDate: widget.eventStart,
      lastDate:
          widget.eventEnd ?? widget.eventStart.add(const Duration(days: 365)),
    );
    if (pickedDate != null) {
      final initialTime = _startTime != null
          ? TimeOfDay.fromDateTime(_startTime!)
          : TimeOfDay.fromDateTime(widget.eventStart);
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
      );
      if (pickedTime != null) {
        setState(() {
          _startTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _pickEndTime() async {
    if (!widget.canEdit) return;
    if (_startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a start time first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _endTime ?? _startTime!,
      firstDate: _startTime!,
      lastDate: widget.eventEnd ?? _startTime!.add(const Duration(days: 365)),
    );
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: _endTime != null
            ? TimeOfDay.fromDateTime(_endTime!)
            : TimeOfDay.fromDateTime(_startTime!),
      );
      if (pickedTime != null) {
        setState(() {
          _endTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  // Vérifie que le créneau [_startTime, _endTime] se trouve dans l'un des jours de festival
  bool _isInValidRange() {
    if (widget.festivalDays == null || widget.festivalDays!.isEmpty) {
      return false;
    }
    for (var day in widget.festivalDays!) {
      if (_startTime != null && _endTime != null) {
        if (!_startTime!.isBefore(day.start) && !_endTime!.isAfter(day.end)) {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedArtistIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one artist'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    // Si timetable est activé, forcer start/end time et stage
    if (widget.timetableActive) {
      if (_startTime == null ||
          _endTime == null ||
          _stage == null ||
          _stage!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'When timetable is active, start time, end time and stage are required'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      if (!_isInValidRange()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'The selected times are not within any valid festival day range'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }
    try {
      if (widget.assignment == null) {
        await _eventArtistService.addArtistAssignment(
          eventId: widget.eventId,
          artistIds: _selectedArtistIds.toList(),
          startTime: _startTime,
          endTime: _endTime,
          customName: _customName,
          status: 'confirmed',
          stage: _stage,
        );
      } else {
        if (widget.assignment!['id'] == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Cannot update assignment: missing id'),
                behavior: SnackBarBehavior.floating),
          );
          return;
        }
        await _eventArtistService.updateArtistAssignment(
          eventId: widget.eventId,
          assignmentId: widget.assignment!['id'],
          artistIds: _selectedArtistIds.toList(),
          startTime: _startTime,
          endTime: _endTime,
          customName: _customName,
          status: 'confirmed',
          stage: _stage,
        );
      }
      Navigator.of(context).pop(true);
    } catch (e) {
      print('Error submitting assignment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _confirmDelete() async {
    if (widget.assignment == null || widget.assignment!['id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Cannot delete assignment: missing id'),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Deletion'),
            content:
                const Text('Are you sure you want to delete this assignment?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete',
                      style: TextStyle(color: Colors.red))),
            ],
          ),
        ) ??
        false;
    if (confirmed) {
      try {
        await _eventArtistService.deleteArtistAssignment(
          eventId: widget.eventId,
          assignmentId: widget.assignment!['id'],
        );
        Navigator.of(context).pop(true);
      } catch (e) {
        print('Error deleting assignment: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double sheetHeight =
        min(screenHeight * 1.0, screenHeight - statusBarHeight - 20);

    return Container(
      constraints: BoxConstraints(maxHeight: sheetHeight),
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(maxHeight: sheetHeight),
          padding: const EdgeInsets.all(16),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Barre supérieure
                      Container(
                        height: 5,
                        width: 50,
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(false),
                          ),
                          Row(
                            children: [
                              if (widget.assignment != null)
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed:
                                      widget.canEdit ? _confirmDelete : null,
                                ),
                              if (widget.canEdit)
                                IconButton(
                                  icon: widget.assignment == null
                                      ? const Icon(Icons.add)
                                      : const Icon(Icons.save),
                                  onPressed: _submit,
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: sectionTitleSpacing),
                      Text(
                        widget.assignment == null
                            ? 'Add Artist Assignment'
                            : 'Edit Artist Assignment',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: sectionTitleSpacing),
                      // Search bar & artist selection (inchangée)
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Search Artists',
                          suffixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          _searchQuery = value;
                          _applyFilter();
                        },
                      ),
                      const SizedBox(height: sectionTitleSpacing),
                      SizedBox(
                        height: 150,
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          itemCount: _filteredArtists.length > _maxArtistsToShow
                              ? _maxArtistsToShow + 1
                              : _filteredArtists.length,
                          itemBuilder: (context, index) {
                            if (index < _maxArtistsToShow) {
                              final artist = _filteredArtists[index];
                              return CheckboxListTile(
                                title: Text(artist.name,
                                    style: const TextStyle(fontSize: 16)),
                                value: _selectedArtistIds.contains(artist.id!),
                                onChanged: widget.canEdit
                                    ? (val) {
                                        setState(() {
                                          if (val == true) {
                                            _selectedArtistIds.add(artist.id!);
                                          } else {
                                            _selectedArtistIds
                                                .remove(artist.id!);
                                          }
                                        });
                                      }
                                    : null,
                              );
                            } else {
                              return TextButton(
                                onPressed: () {
                                  setState(() {
                                    _maxArtistsToShow = _filteredArtists.length;
                                  });
                                },
                                child: const Text('Show More'),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: sectionTitleSpacing),
                      const Divider(thickness: 1),
                      // Start time picker
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: widget.canEdit ? _pickStartTime : null,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _startTime == null
                                        ? 'Select start time'
                                        : 'Start: ${_startTime!.toLocal().toString().substring(0, 16)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (widget.timetableActive &&
                                      _startTime == null)
                                    const Text(
                                      'Please define a start time',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.red),
                                    )
                                  else if (!widget.timetableActive)
                                    const Text(
                                      'optional',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (!widget.timetableActive)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: widget.canEdit
                                  ? () {
                                      setState(() {
                                        _endTime = null;
                                      });
                                    }
                                  : null,
                            ),
                          IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: widget.canEdit ? _pickStartTime : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: sectionTitleSpacing),
                      // End time picker
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: widget.canEdit ? _pickEndTime : null,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _endTime == null
                                        ? 'Select end time'
                                        : 'End: ${_endTime!.toLocal().toString().substring(0, 16)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (widget.timetableActive &&
                                      _endTime == null)
                                    const Text(
                                      'Please define an end time',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.red),
                                    )
                                  else if (!widget.timetableActive)
                                    const Text(
                                      'optional',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (!widget.timetableActive)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: widget.canEdit
                                  ? () {
                                      setState(() {
                                        _endTime = null;
                                      });
                                    }
                                  : null,
                            ),
                          IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: widget.canEdit ? _pickEndTime : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: sectionTitleSpacing),
                      // Stage field
                      widget.timetableActive
                          ? DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Stage',
                                // Aucun helperText ici car le message d'erreur sera affiché si nécessaire
                              ),
                              value: _stage != null && _stage!.isNotEmpty
                                  ? _stage
                                  : null,
                              items: widget.availableStages != null
                                  ? widget.availableStages!
                                      .map((stage) => DropdownMenuItem<String>(
                                            value: stage,
                                            child: Text(stage),
                                          ))
                                      .toList()
                                  : [],
                              onChanged: widget.canEdit
                                  ? (val) => setState(() => _stage = val)
                                  : null,
                              validator: (val) {
                                if (widget.timetableActive &&
                                    (val == null || val.isEmpty)) {
                                  return 'Please define a stage';
                                }
                                return null;
                              },
                            )
                          : TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Stage',
                                helperText: 'optional',
                                helperStyle:
                                    TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              initialValue: _stage,
                              onChanged:
                                  widget.canEdit ? (val) => _stage = val : null,
                            ),
                      if (widget.timetableActive &&
                          (_stage == null || _stage!.isEmpty))
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: const Text(
                              'Please define a stage',
                              style: TextStyle(fontSize: 12, color: Colors.red),
                            ),
                          ),
                        ),

                      const SizedBox(height: sectionTitleSpacing),
                      // Custom Slot Name field (inchangé)
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Custom Slot Name',
                          helperText: 'optional',
                          helperStyle:
                              TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        initialValue: _customName,
                        onChanged:
                            widget.canEdit ? (val) => _customName = val : null,
                      ),
                      const SizedBox(height: sectionTitleSpacing),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
