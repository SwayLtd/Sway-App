import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sway/core/utils/date_utils.dart'; // formatEventDate, formatEventTime
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/artist/services/artist_service.dart';
import 'package:sway/features/event/services/event_artist_service.dart';

/// Screen dedicated to managing artist assignments for an event.
/// In EditEventScreen, only a button is shown to navigate here.
class EditEventArtistsScreen extends StatefulWidget {
  final int eventId;
  const EditEventArtistsScreen({Key? key, required this.eventId})
      : super(key: key);

  @override
  _EditEventArtistsScreenState createState() => _EditEventArtistsScreenState();
}

class _EditEventArtistsScreenState extends State<EditEventArtistsScreen> {
  final EventArtistService _eventArtistService = EventArtistService();
  List<Map<String, dynamic>> _assignments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAssignments();
  }

  void _showAddAssignmentSheet() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          ArtistAssignmentBottomSheet(eventId: widget.eventId),
    );
    if (result == true) {
      await _fetchAssignments();
    }
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
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ArtistAssignmentBottomSheet(
        eventId: widget.eventId,
        assignment: assignment,
      ),
    );
    if (result == true) {
      await _fetchAssignments();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Group assignments by day (classic format: YYYY-MM-DD)
    Map<String, List<Map<String, dynamic>>> groupByDay = {};
    _assignments.sort((a, b) {
      DateTime aTime = a['start_time'] is String
          ? DateTime.parse(a['start_time'])
          : a['start_time'];
      DateTime bTime = b['start_time'] is String
          ? DateTime.parse(b['start_time'])
          : b['start_time'];
      return aTime.compareTo(bTime);
    });
    for (var assignment in _assignments) {
      DateTime start = assignment['start_time'] is String
          ? DateTime.parse(assignment['start_time'])
          : assignment['start_time'];
      String dayKey = start.toLocal().toString().substring(0, 10);
      groupByDay.putIfAbsent(dayKey, () => []).add(assignment);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Artist Assignments'),
        actions: [
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
                            formatEventDate(DateTime.parse(day)),
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...assignments.map((assignment) {
                          // Bold artist names.
                          final List<dynamic> artists =
                              assignment['artists'] ?? [];
                          final String artistNames =
                              artists.map((a) => a.name).join(', ');

                          // Classic date format "YYYY-MM-DD HH:mm" for start and end.
                          final DateTime parsedStart =
                              assignment['start_time'] is String
                                  ? DateTime.parse(assignment['start_time'])
                                  : assignment['start_time'];
                          final DateTime parsedEnd =
                              assignment['end_time'] is String
                                  ? DateTime.parse(assignment['end_time'])
                                  : assignment['end_time'];
                          final String startDate =
                              parsedStart.toLocal().toString().substring(0, 10);
                          final String startHour = parsedStart
                              .toLocal()
                              .toString()
                              .substring(11, 16);
                          final String endDate =
                              parsedEnd.toLocal().toString().substring(0, 10);
                          final String endHour =
                              parsedEnd.toLocal().toString().substring(11, 16);

                          // Info rows with icons.
                          List<Widget> infoRows = [];
                          infoRows.add(Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 14),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '$startDate $startHour → $endDate $endHour',
                                  style: const TextStyle(fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ));
                          if (assignment['custom_name'] != null &&
                              (assignment['custom_name'] as String)
                                  .isNotEmpty) {
                            infoRows.add(Row(
                              children: [
                                const Icon(Icons.edit, size: 14),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    assignment['custom_name'],
                                    style: const TextStyle(fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ));
                          }
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
                                  onTap: () => _editAssignment(assignment),
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

/// Modal bottom sheet for adding or editing an artist assignment.
/// Ce fichier contient à la fois EditEventArtistScreen et ArtistAssignmentBottomSheet.
class ArtistAssignmentBottomSheet extends StatefulWidget {
  final int eventId;

  /// If provided, the assignment will be edited; otherwise, a new assignment is added.
  final Map<String, dynamic>? assignment;
  const ArtistAssignmentBottomSheet({
    Key? key,
    required this.eventId,
    this.assignment,
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

  // Dummy event times – remplacer par les vraies valeurs
  final DateTime _dummyEventStart = DateTime.parse("2025-02-14 19:29:00");
  final DateTime _dummyEventEnd = DateTime.parse("2025-02-15 19:29:00");

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
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startTime ?? _dummyEventStart,
      firstDate: _dummyEventStart,
      lastDate: DateTime(2030),
    );
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: _startTime != null
            ? TimeOfDay.fromDateTime(_startTime!)
            : TimeOfDay.fromDateTime(_dummyEventStart),
      );
      if (pickedTime != null) {
        setState(() {
          _startTime = DateTime(pickedDate.year, pickedDate.month,
              pickedDate.day, pickedTime.hour, pickedTime.minute);
        });
      }
    }
  }

  Future<void> _pickEndTime() async {
    if (_startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a start date first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    // Utiliser _startTime comme initialDate si _endTime est null
    final DateTime initialDate = _endTime ?? _startTime!;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: _startTime!, // L'heure de début devient la date minimum
      lastDate: DateTime(2030),
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

  /// Validate that assignment times are within event times.
  bool _validateAssignmentTimes(DateTime eventStart, DateTime eventEnd) {
    final assignmentStartUtc = _startTime!.toUtc();
    final assignmentEndUtc = _endTime!.toUtc();
    final eventStartUtc = eventStart.toUtc();
    final eventEndUtc = eventEnd.toUtc();
    return (assignmentStartUtc.isAtSameMomentAs(eventStartUtc) ||
            assignmentStartUtc.isAfter(eventStartUtc)) &&
        (assignmentEndUtc.isAtSameMomentAs(eventEndUtc) ||
            assignmentEndUtc.isBefore(eventEndUtc));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select start and end times'),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (_selectedArtistIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select at least one artist'),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }
    final DateTime eventStart = _dummyEventStart;
    final DateTime eventEnd = _dummyEventEnd;
    if (!_validateAssignmentTimes(eventStart, eventEnd)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Assignment times must be within the event times: Start: ${eventStart.toLocal().toString().substring(0, 16)} → End: ${eventEnd.toLocal().toString().substring(0, 16)}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    try {
      if (widget.assignment == null) {
        await _eventArtistService.addArtistAssignment(
          eventId: widget.eventId,
          artistIds: _selectedArtistIds.toList(),
          startTime: _startTime!,
          endTime: _endTime!,
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
          startTime: _startTime!,
          endTime: _endTime!,
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
        min(screenHeight * 0.8, screenHeight - statusBarHeight - 20);

    return Padding(
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
                      // Top bar: horizontal grey line above icons.
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
                                  onPressed: _confirmDelete,
                                ),
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
                      const SizedBox(height: 10),
                      Text(
                        widget.assignment == null
                            ? 'Add Artist Assignment'
                            : 'Edit Artist Assignment',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      // Search bar for artists
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
                      const SizedBox(height: 10),
                      // Multi-selection list for artists with "Show More"
                      Container(
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
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedArtistIds.add(artist.id!);
                                    } else {
                                      _selectedArtistIds.remove(artist.id!);
                                    }
                                  });
                                },
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
                      const SizedBox(height: 10),
                      // White horizontal space between artist list and time pickers.
                      const Divider(color: Colors.white, thickness: 1),
                      // Start time picker
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _pickStartTime,
                              child: Text(
                                _startTime == null
                                    ? 'Select start time'
                                    : 'Start: ${_startTime!.toLocal().toString().substring(0, 16)}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: _pickStartTime,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // End time picker
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _pickEndTime,
                              child: Text(
                                _endTime == null
                                    ? 'Select end time'
                                    : 'End: ${_endTime!.toLocal().toString().substring(0, 16)}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: _pickEndTime,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Custom Slot Name field
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Custom Slot Name',
                          helperText: 'optional',
                          helperStyle:
                              TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        initialValue: _customName,
                        onChanged: (val) => _customName = val,
                      ),
                      const SizedBox(height: 10),
                      // Stage field
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Stage',
                          helperText: 'optional',
                          helperStyle:
                              TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        initialValue: _stage,
                        onChanged: (val) => _stage = val,
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
