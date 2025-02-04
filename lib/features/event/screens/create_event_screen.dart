// lib/features/event/screens/create_event_screen.dart

import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/core/constants/dimensions.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/services/event_service.dart';
import 'package:sway/features/genre/models/genre_model.dart';
import 'package:sway/features/genre/services/genre_service.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/promoter/services/promoter_service.dart';
import 'package:sway/features/venue/models/venue_model.dart';
import 'package:sway/features/venue/services/venue_service.dart';
import 'package:sway/features/genre/widgets/genre_chip.dart';
import 'package:sway/features/security/services/storage_service.dart';
import 'package:sway/features/user/services/user_service.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({Key? key}) : super(key: key);

  @override
  _CreateEventScreenState createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields.
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Event type selection (Dropdown).
  final List<String> _eventTypes = ['Festival', 'Rave', 'Party', 'Other'];
  String _selectedType = 'Festival';

  // Date and time selection.
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  // Image file for event image.
  File? _selectedImage;
  bool _isSubmitting = false;

  // Selected promoter, venue and genres (IDs).
  int? _selectedPromoter; // Single promoter.
  int? _selectedVenue; // Single venue.
  List<int> _selectedGenres = []; // Initialized to an empty list.

  final EventService _eventService = EventService();
  final StorageService _storageService = StorageService();
  final PromoterService _promoterService = PromoterService();
  final VenueService _venueService = VenueService();
  final GenreService _genreService = GenreService();
  final UserService _userService = UserService();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Picks an image from the gallery.
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  /// Uploads the selected image to the "event-images" bucket and returns the public URL.
  Future<String> _uploadImage(int eventId, File imageFile) async {
    final fileBytes = await imageFile.readAsBytes();
    final fileExtension = imageFile.path.split('.').last;
    final fileName = "${DateTime.now().millisecondsSinceEpoch}.$fileExtension";
    final filePath = "$eventId/$fileName";

    final publicUrl = await _storageService.uploadFile(
      bucketName: "event-images",
      fileName: filePath,
      fileData: fileBytes,
    );
    return publicUrl;
  }

  /// Selects a start date/time using a date picker.
  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      // Optionally, pick a time as well.
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedStartDate = DateTime(picked.year, picked.month, picked.day,
              pickedTime.hour, pickedTime.minute);
        });
      }
    }
  }

  /// Selects an end date/time using a date picker.
  Future<void> _pickEndDate() async {
    if (_selectedStartDate == null) {
      // Must select start date first.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a start date first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedEndDate ?? _selectedStartDate!.add(const Duration(hours: 1)),
      firstDate: _selectedStartDate!,
      lastDate: DateTime(_selectedStartDate!.year + 5),
    );
    if (picked != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedEndDate = DateTime(picked.year, picked.month, picked.day,
              pickedTime.hour, pickedTime.minute);
        });
      }
    }
  }

  /// Submits the form to create a new event.
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() ||
        _selectedStartDate == null ||
        _selectedEndDate == null ||
        _selectedImage == null ||
        _selectedPromoter == null ||
        _selectedVenue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Create event object with temporary empty fields for image and associations.
      final newEvent = Event(
        title: _titleController.text.trim(),
        type: _selectedType,
        dateTime: _selectedStartDate!,
        endDateTime: _selectedEndDate!,
        venue: _selectedVenue,
        description: _descriptionController.text.trim(),
        imageUrl: '', // Will be updated after image upload.
        price: '', // Default empty string.
        promoters: [_selectedPromoter!],
        genres: _selectedGenres,
        artists: [], // Not implemented.
        interestedUsersCount: 0,
      );

      // Add the event.
      await _eventService.addEvent(newEvent);

      // For simplicity, we query the event by title and start date (assuming uniqueness).
      final createdEvents = await _eventService.searchEvents(
        _titleController.text.trim(),
        {'date': _selectedStartDate!},
      );
      if (createdEvents.isEmpty) {
        throw Exception('Failed to retrieve the newly created event.');
      }
      final createdEvent = createdEvents.first;

      // Upload the event image to "event-images" bucket using the new event's ID.
      final imageUrl = await _uploadImage(createdEvent.id!, _selectedImage!);

      // Update the event with the image URL.
      final updatedEvent = createdEvent.copyWith(imageUrl: imageUrl);
      await _eventService.updateEvent(updatedEvent);

      // Insert join table entries.
      // Insert into event_promoter.
      await _supabase.from('event_promoter').insert({
        'event_id': updatedEvent.id,
        'promoter_id': _selectedPromoter,
      });

      // Insert into event_genre (for each selected genre).
      final genreEntries = _selectedGenres
          .map((genreId) => {
                'event_id': updatedEvent.id,
                'genre_id': genreId,
              })
          .toList();
      if (genreEntries.isNotEmpty) {
        await _supabase.from('event_genre').insert(genreEntries);
      }

      // Insert into event_venue.
      await _supabase.from('event_venue').insert({
        'event_id': updatedEvent.id,
        'venue_id': _selectedVenue,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event created successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      print('Error creating event: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating event: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Event'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Title field.
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the event title.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Event type dropdown.
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Event Type',
                  border: OutlineInputBorder(),
                ),
                items: _eventTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              const SizedBox(height: 20),
              // Start date field.
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Start Date & Time',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _pickStartDate,
                  ),
                ),
                controller: TextEditingController(
                  text: _selectedStartDate == null
                      ? ''
                      : _selectedStartDate!
                          .toLocal()
                          .toString()
                          .substring(0, 16),
                ),
                validator: (value) {
                  if (_selectedStartDate == null) {
                    return 'Please select the start date and time.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // End date field.
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'End Date & Time',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _pickEndDate,
                  ),
                ),
                controller: TextEditingController(
                  text: _selectedEndDate == null
                      ? ''
                      : _selectedEndDate!.toLocal().toString().substring(0, 16),
                ),
                validator: (value) {
                  if (_selectedEndDate == null) {
                    return 'Please select the end date and time.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Description field.
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Event image selection and preview.
              GestureDetector(
                onTap: _isSubmitting ? null : _pickImage,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[200],
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 150,
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.grey,
                            size: 50,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              // Promoter selection (using a bottom sheet).
              ListTile(
                leading: const Icon(Icons.person),
                title: Text(_selectedPromoter == null
                    ? 'Select Promoter'
                    : 'Promoter ID: $_selectedPromoter'),
                trailing: const Icon(Icons.edit),
                onTap: () async {
                  final selected = await showModalBottomSheet<int>(
                    context: context,
                    builder: (context) => SelectPromoterBottomSheet(
                      promoterService: _promoterService,
                    ),
                  );
                  if (selected != null) {
                    setState(() {
                      _selectedPromoter = selected;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              // Venue selection (using a bottom sheet).
              ListTile(
                leading: const Icon(Icons.location_on),
                title: Text(_selectedVenue == null
                    ? 'Select Venue'
                    : 'Venue ID: $_selectedVenue'),
                trailing: const Icon(Icons.edit),
                onTap: () async {
                  final selected = await showModalBottomSheet<int>(
                    context: context,
                    builder: (context) => SelectVenueBottomSheet(
                      venueService: _venueService,
                    ),
                  );
                  if (selected != null) {
                    setState(() {
                      _selectedVenue = selected;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              // Genres selection (using GenreSelectionBottomSheet).
              ListTile(
                leading: const Icon(Icons.library_music),
                title: Text(_selectedGenres.isEmpty
                    ? 'Select Genres'
                    : 'Selected Genres: ${_selectedGenres.length}'),
                trailing: const Icon(Icons.edit),
                onTap: () async {
                  final selectedGenres = Set<int>.from(_selectedGenres);
                  final bool? saved = await showModalBottomSheet<bool>(
                    context: context,
                    isScrollControlled: true,
                    builder: (BuildContext context) {
                      return GenreSelectionBottomSheet(
                        selectedGenres: selectedGenres,
                        genreService: _genreService,
                      );
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16.0)),
                    ),
                  );
                  if (saved == true) {
                    setState(() {
                      _selectedGenres = selectedGenres.toList();
                    });
                  }
                },
              ),
              // Display selected genres with GenreChip widgets.
              _selectedGenres.isNotEmpty
                  ? Wrap(
                      spacing: 8.0,
                      children: _selectedGenres.map((genreId) {
                        return GenreChip(genreId: genreId);
                      }).toList(),
                    )
                  : const SizedBox.shrink(),
              const SizedBox(height: 30),
              // Submit button.
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Create Event'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Bottom sheet for selecting a promoter.
class SelectPromoterBottomSheet extends StatefulWidget {
  final PromoterService promoterService;

  const SelectPromoterBottomSheet({required this.promoterService, Key? key})
      : super(key: key);

  @override
  _SelectPromoterBottomSheetState createState() =>
      _SelectPromoterBottomSheetState();
}

class _SelectPromoterBottomSheetState extends State<SelectPromoterBottomSheet> {
  List<Promoter> _promoters = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchPromoters();
  }

  Future<void> _fetchPromoters() async {
    setState(() {
      _isLoading = true;
    });
    try {
      _promoters = await widget.promoterService.getPromoters();
    } catch (e) {
      // Handle error if needed.
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectPromoter(Promoter promoter) {
    Navigator.of(context).pop(promoter.id);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      child: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _promoters.length,
              itemBuilder: (context, index) {
                final promoter = _promoters[index];
                return ListTile(
                  title: Text(promoter.name),
                  onTap: () => _selectPromoter(promoter),
                );
              },
            ),
    );
  }
}

// Bottom sheet for selecting a venue.
class SelectVenueBottomSheet extends StatefulWidget {
  final VenueService venueService;

  const SelectVenueBottomSheet({required this.venueService, Key? key})
      : super(key: key);

  @override
  _SelectVenueBottomSheetState createState() => _SelectVenueBottomSheetState();
}

class _SelectVenueBottomSheetState extends State<SelectVenueBottomSheet> {
  List<Venue> _venues = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchVenues();
  }

  Future<void> _fetchVenues() async {
    setState(() {
      _isLoading = true;
    });
    try {
      _venues = await widget.venueService.getVenues();
    } catch (e) {
      // Handle error if needed.
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectVenue(Venue venue) {
    Navigator.of(context).pop(venue.id);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      child: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _venues.length,
              itemBuilder: (context, index) {
                final venue = _venues[index];
                return ListTile(
                  title: Text(venue.name),
                  onTap: () => _selectVenue(venue),
                );
              },
            ),
    );
  }
}

// Bottom sheet for selecting genres.
class GenreSelectionBottomSheet extends StatefulWidget {
  final Set<int> selectedGenres;
  final GenreService genreService;

  const GenreSelectionBottomSheet({
    required this.selectedGenres,
    required this.genreService,
    Key? key,
  }) : super(key: key);

  @override
  _GenreSelectionBottomSheetState createState() =>
      _GenreSelectionBottomSheetState();
}

class _GenreSelectionBottomSheetState extends State<GenreSelectionBottomSheet> {
  List<Genre> _genres = [];
  String _searchQuery = '';
  bool _isLoading = false;
  bool _showAll = false;

  static const int _maxGenresToShow = 10;

  @override
  void initState() {
    super.initState();
    _searchGenres();
  }

  Future<void> _searchGenres() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      List<Genre> genres;
      if (_searchQuery.isEmpty) {
        genres = await widget.genreService.getGenres();
      } else {
        genres = await widget.genreService.searchGenres(_searchQuery);
      }

      // Sort genres to show selected first.
      genres.sort((a, b) {
        bool aSelected = widget.selectedGenres.contains(a.id);
        bool bSelected = widget.selectedGenres.contains(b.id);
        if (aSelected && !bSelected) return -1;
        if (!aSelected && bSelected) return 1;
        return a.name.compareTo(b.name);
      });

      if (!mounted) return;
      setState(() {
        _genres = genres;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Error searching genres: ${e.toString()}')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _saveSelections() {
    Navigator.of(context).pop(true); // Return true to indicate save.
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double sheetHeight =
        min(screenHeight * 0.5, screenHeight - statusBarHeight - 100);

    final List<Genre> genresToDisplay =
        _showAll ? _genres : _genres.take(_maxGenresToShow).toList();

    return Container(
      height: sheetHeight,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Header with cancel and save icons.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop(false); // Cancel and close.
                },
              ),
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveSelections,
              ),
            ],
          ),
          const SizedBox(height: sectionTitleSpacing),
          const Text(
            'Select Genres',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: sectionTitleSpacing),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Search Genres',
              suffixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              _searchQuery = value;
              _searchGenres();
            },
          ),
          const SizedBox(height: sectionTitleSpacing),
          _isLoading
              ? const CircularProgressIndicator.adaptive()
              : Expanded(
                  child: _genres.isEmpty
                      ? const Center(child: Text('No genres found.'))
                      : ListView.builder(
                          itemCount: genresToDisplay.length +
                              (_genres.length > _maxGenresToShow && !_showAll
                                  ? 1
                                  : 0),
                          itemBuilder: (context, index) {
                            if (index < genresToDisplay.length) {
                              final genre = genresToDisplay[index];
                              final isSelected =
                                  widget.selectedGenres.contains(genre.id);
                              return CheckboxListTile(
                                value: isSelected,
                                title: Text(genre.name),
                                onChanged: (bool? value) {
                                  if (!mounted) return;
                                  setState(() {
                                    if (value == true) {
                                      widget.selectedGenres.add(genre.id);
                                    } else {
                                      widget.selectedGenres.remove(genre.id);
                                    }
                                  });
                                },
                              );
                            } else {
                              return TextButton(
                                onPressed: () {
                                  if (!mounted) return;
                                  setState(() {
                                    _showAll = true;
                                  });
                                },
                                child: const Text('Show More'),
                              );
                            }
                          },
                        ),
                ),
        ],
      ),
    );
  }
}
