import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Importez vos services et modèles
import 'package:sway/core/constants/dimensions.dart';
import 'package:sway/core/utils/validators.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/services/event_service.dart';
import 'package:sway/features/event/services/event_genre_service.dart';
import 'package:sway/features/event/services/event_promoter_service.dart';
import 'package:sway/features/event/services/event_venue_service.dart';
import 'package:sway/features/genre/models/genre_model.dart';
import 'package:sway/features/genre/services/genre_service.dart';
import 'package:sway/features/genre/widgets/genre_chip.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/promoter/services/promoter_service.dart';
import 'package:sway/features/security/services/storage_service.dart';
import 'package:sway/features/user/services/user_permission_service.dart';
import 'package:sway/features/user/services/user_service.dart';
import 'package:sway/features/venue/models/venue_model.dart';
import 'package:sway/features/venue/services/venue_service.dart';

/// Modèle pour représenter une journée de festival
class FestivalDay {
  String name;
  DateTime start;
  DateTime end;

  FestivalDay({
    required this.name,
    required this.start,
    required this.end,
  });
}

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({Key? key}) : super(key: key);

  @override
  _CreateEventScreenState createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationPrecisionController =
      TextEditingController();
  final TextEditingController _ticketLinkController = TextEditingController();

  // Types d'event (affiché vs stocké)
  final List<String> _eventTypeLabels = [
    'Festival',
    'Rave',
    'Party',
    'Concert',
    'Other'
  ];
  late String _selectedTypeLabel;

  // Dates
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate; // Obligatoire si timetable activé

  // Image
  File? _selectedImage;
  bool _isSubmitting = false;

  // Promoter : on stocke l'objet
  Promoter? _selectedPromoterObj;
  // Venue
  Venue? _selectedVenueObj;
  // Genres
  List<int> _selectedGenres = [];

  // Liste des promoteurs pour lesquels on a la permission manager/admin
  List<Promoter> _permittedPromoters = [];

  // Services
  final EventService _eventService = EventService();
  final UserService _userService = UserService();
  final PromoterService _promoterService = PromoterService();
  final VenueService _venueService = VenueService();
  final GenreService _genreService = GenreService();
  final UserPermissionService _permissionService = UserPermissionService();
  final EventPromoterService _eventPromoterService = EventPromoterService();
  final EventGenreService _eventGenreService = EventGenreService();
  final EventVenueService _eventVenueService = EventVenueService();

  // Instance of the global validator.
  late FieldValidator defaultValidator;

  // ----- Nouvelle fonctionnalité "timetable" -----
  bool _isTimetableEnabled = false;
  List<FestivalDay> _festivalDays = [];
  List<String> _stages = [];

  @override
  void initState() {
    super.initState();
    _selectedTypeLabel = _eventTypeLabels.first; // par défaut "Festival"
    _fetchPermittedPromoters(); // Charger les promoteurs autorisés

    // Initialise le validateur global
    defaultValidator = FieldValidator(
      isRequired: true,
      maxLength: 500,
      forbiddenWords: [],
    );
    _loadDefaultForbiddenWords();
  }

  Future<void> _loadDefaultForbiddenWords() async {
    try {
      final frWords = await loadForbiddenWords('fr');
      final enWords = await loadForbiddenWords('en');
      final combined = {...frWords, ...enWords}.toList();
      setState(() {
        defaultValidator = FieldValidator(
          isRequired: true,
          maxLength: 2000,
          forbiddenWords: combined,
        );
      });
      _formKey.currentState?.validate();
    } catch (e) {
      print('Error loading forbidden words: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationPrecisionController.dispose();
    _ticketLinkController.dispose();
    super.dispose();
  }

  Future<void> _fetchPermittedPromoters() async {
    setState(() => _isSubmitting = true);
    try {
      final currentUser = await _userService.getCurrentUser();
      if (currentUser == null) throw Exception('User not logged in');

      final userPermissions =
          await _permissionService.getPermissionsByUserIdAndType(
        currentUser.id,
        'promoter',
      );

      final allowedPromoterIds = <int>[];
      for (final perm in userPermissions) {
        if (perm.permissionLevel >= 2) {
          allowedPromoterIds.add(perm.entityId);
        }
      }

      if (allowedPromoterIds.isNotEmpty) {
        final promoters =
            await _promoterService.getPromotersByIds(allowedPromoterIds);
        setState(() {
          _permittedPromoters = promoters;
        });
      } else {
        setState(() {
          _permittedPromoters = [];
        });
      }
    } catch (e) {
      print('Error fetching permitted promoters: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

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

  Future<void> _pickStartDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: DateTime(now.year + 5),
    );
    if (pickedDate != null) {
      final pickedTime =
          await showTimePicker(context: context, initialTime: TimeOfDay.now());
      if (pickedTime != null) {
        setState(() {
          _selectedStartDate = DateTime(
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

  Future<void> _pickEndDateTime() async {
    if (_selectedStartDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a start date first.'),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }
    final pickedDate = await showDatePicker(
      context: context,
      initialDate:
          _selectedEndDate ?? _selectedStartDate!.add(const Duration(hours: 1)),
      firstDate: _selectedStartDate!,
      lastDate: DateTime(_selectedStartDate!.year + 5),
    );
    if (pickedDate != null) {
      final pickedTime =
          await showTimePicker(context: context, initialTime: TimeOfDay.now());
      if (pickedTime != null) {
        setState(() {
          _selectedEndDate = DateTime(
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

  Future<String> _uploadImage(int eventId, File imageFile) async {
    final fileBytes = await imageFile.readAsBytes();
    final fileExtension = imageFile.path.split('.').last;
    final fileName = "${DateTime.now().millisecondsSinceEpoch}.$fileExtension";
    final filePath = "$eventId/$fileName";
    return await StorageService().uploadFile(
      bucketName: "event-images",
      fileName: filePath,
      fileData: fileBytes,
    );
  }

  Future<void> _submitForm() async {
    // Vérifications de base
    if (!_formKey.currentState!.validate() ||
        _selectedStartDate == null ||
        _selectedImage == null ||
        _selectedPromoterObj == null ||
        _selectedVenueObj == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all required fields.'),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }

    // Si timetable est activé, vérifier que endDateTime, days et stages sont renseignés
    if (_isTimetableEnabled) {
      if (_selectedEndDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Please select an end date & time when timetable is enabled.'),
              behavior: SnackBarBehavior.floating),
        );
        return;
      }
      if (_festivalDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please add at least one festival day.'),
              behavior: SnackBarBehavior.floating),
        );
        return;
      }
      if (_stages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please add at least one stage.'),
              behavior: SnackBarBehavior.floating),
        );
        return;
      }
    }

    // Vérification de permission sur le promoter
    final promoterId = _selectedPromoterObj!.id!;
    final canManage = await _permissionService.hasPermissionForCurrentUser(
        promoterId, 'promoter', 2);
    if (!canManage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You must manage a promoter to create an event.'),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final typeToStore = _selectedTypeLabel.toLowerCase();

      // Construction du metadata en conservant ticket_link et location_precision
      Map<String, dynamic> metadata = {};
      if (_ticketLinkController.text.trim().isNotEmpty) {
        metadata['ticket_link'] = _ticketLinkController.text.trim();
      }
      if (_locationPrecisionController.text.trim().isNotEmpty) {
        metadata['location_precision'] =
            _locationPrecisionController.text.trim();
      }
      // Ajout de la timetable
      metadata['timetable'] = _isTimetableEnabled;
      if (_isTimetableEnabled) {
        List<Map<String, String>> days = _festivalDays.map((day) {
          return {
            'name': day.name,
            'start': day.start.toUtc().toIso8601String(),
            'end': day.end.toUtc().toIso8601String(),
          };
        }).toList();
        metadata['festival_info'] = {
          'days': days,
          'stages': _stages,
        };
      }

      final newEvent = Event(
        title: _titleController.text.trim(),
        type: typeToStore,
        eventDateTime: _selectedStartDate!,
        eventEndDateTime:
            _selectedEndDate, // Doit être non-null si timetable activé
        description: _descriptionController.text.trim(),
        imageUrl: '',
        promoters: [promoterId],
        metadata: metadata.isEmpty ? null : metadata,
      );

      final createdEvent = await _eventService.addEvent(newEvent);

      // Upload de l'image
      final imageUrl = await _uploadImage(createdEvent!.id!, _selectedImage!);
      final updatedEvent = await _eventService.updateEvent(
        createdEvent.copyWith(imageUrl: imageUrl),
      );

      // Jointures
      await _eventPromoterService.addPromoterToEvent(
          updatedEvent.id!, promoterId);
      await _eventVenueService.addVenueToEvent(
          updatedEvent.id!, _selectedVenueObj!.id!);
      if (_selectedGenres.isNotEmpty) {
        for (final genreId in _selectedGenres) {
          await _eventGenreService.addGenreToEvent(updatedEvent.id!, genreId);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Event created successfully!'),
            behavior: SnackBarBehavior.floating),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error creating event: $e'),
            behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Event'),
      ),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Image
                  GestureDetector(
                    onTap: _isSubmitting ? null : _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: isDark ? Colors.white : Colors.black),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[200],
                      ),
                      child: _selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(_selectedImage!,
                                  fit: BoxFit.cover),
                            )
                          : const Center(
                              child: Icon(Icons.camera_alt,
                                  size: 50, color: Colors.grey),
                            ),
                    ),
                  ),
                  const SizedBox(height: sectionSpacing),

                  // Title
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => defaultValidator.validate(value),
                  ),
                  const SizedBox(height: sectionSpacing),

                  // Event type
                  DropdownButtonFormField<String>(
                    value: _selectedTypeLabel,
                    decoration: const InputDecoration(
                      labelText: 'Event Type',
                      border: OutlineInputBorder(),
                    ),
                    dropdownColor:
                        isDark ? Theme.of(context).popupMenuTheme.color : null,
                    items: _eventTypeLabels
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedTypeLabel = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: sectionSpacing),

                  // Start date/time
                  TextFormField(
                    readOnly: true,
                    onTap: _pickStartDateTime,
                    decoration: InputDecoration(
                      labelText: 'Start Date & Time',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: _pickStartDateTime),
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
                      if (_selectedStartDate == null)
                        return 'Please select a start date and time.';
                      return null;
                    },
                  ),
                  const SizedBox(height: sectionSpacing),

                  // End date/time
                  TextFormField(
                    readOnly: true,
                    onTap: _pickEndDateTime,
                    decoration: InputDecoration(
                      labelText: 'End Date & Time',
                      border: const OutlineInputBorder(),
                      helperText: _isTimetableEnabled
                          ? 'mandatory with timetable'
                          : 'optional',
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!_isTimetableEnabled)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _selectedEndDate = null;
                                });
                              },
                            ),
                          IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: _pickEndDateTime,
                          ),
                        ],
                      ),
                    ),
                    controller: TextEditingController(
                      text: _selectedEndDate == null
                          ? ''
                          : _selectedEndDate!
                              .toLocal()
                              .toString()
                              .substring(0, 16),
                    ),
                    validator: (value) {
                      if (_isTimetableEnabled && _selectedEndDate == null)
                        return 'End date is required when timetable is enabled.';
                      return null;
                    },
                  ),
                  const SizedBox(height: sectionSpacing),

                  // Switch pour activer la timetable
                  SwitchListTile.adaptive(
                    title: const Text('Enable Timetable'),
                    value: _isTimetableEnabled,
                    onChanged: (value) {
                      setState(() {
                        _isTimetableEnabled = value;
                        if (!value) {
                          // Réinitialiser les données timetable si désactivé
                          _festivalDays.clear();
                          _stages.clear();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: sectionSpacing),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) => defaultValidator.validate(value),
                  ),
                  const SizedBox(height: sectionSpacing),

                  // Ticket link
                  TextFormField(
                    controller: _ticketLinkController,
                    decoration: const InputDecoration(
                      labelText: 'Tickets Link',
                      border: OutlineInputBorder(),
                      hintText: 'e.g. https://www.ticketux.be/',
                      helperText: 'optional',
                    ),
                    maxLines: 1,
                    validator: ticketLinkValidator,
                  ),
                  const SizedBox(height: sectionSpacing),

                  // Promoter
                  Row(
                    children: [
                      const Icon(Icons.person),
                      const SizedBox(width: 8),
                      if (_isSubmitting)
                        const Text('Loading...')
                      else if (_selectedPromoterObj == null)
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor:
                                      isDark ? Colors.white : Colors.black,
                                ),
                                onPressed: _permittedPromoters.isEmpty
                                    ? null
                                    : () async {
                                        final result =
                                            await showModalBottomSheet<
                                                Promoter>(
                                          context: context,
                                          isScrollControlled: true,
                                          builder: (context) =>
                                              PromoterSelectionBottomSheet(
                                            permittedPromoters:
                                                _permittedPromoters,
                                            selectedPromoter:
                                                _selectedPromoterObj,
                                          ),
                                        );
                                        if (result != null && mounted) {
                                          setState(() {
                                            _selectedPromoterObj = result;
                                          });
                                        }
                                      },
                                child: const Text('Select Promoter'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                color: isDark ? Colors.white : Colors.black,
                                onPressed: _permittedPromoters.isEmpty
                                    ? null
                                    : () async {
                                        final result =
                                            await showModalBottomSheet<
                                                Promoter>(
                                          context: context,
                                          isScrollControlled: true,
                                          builder: (context) =>
                                              PromoterSelectionBottomSheet(
                                            permittedPromoters:
                                                _permittedPromoters,
                                            selectedPromoter:
                                                _selectedPromoterObj,
                                          ),
                                        );
                                        if (result != null && mounted) {
                                          setState(() {
                                            _selectedPromoterObj = result;
                                          });
                                        }
                                      },
                              ),
                            ],
                          ),
                        )
                      else
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Chip(
                                label: Text(_selectedPromoterObj!.name),
                                onDeleted: !_isSubmitting
                                    ? () => setState(
                                        () => _selectedPromoterObj = null)
                                    : null,
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                color: isDark ? Colors.white : Colors.black,
                                onPressed:
                                    _permittedPromoters.isEmpty || _isSubmitting
                                        ? null
                                        : () async {
                                            final result =
                                                await showModalBottomSheet<
                                                    Promoter>(
                                              context: context,
                                              isScrollControlled: true,
                                              builder: (context) =>
                                                  PromoterSelectionBottomSheet(
                                                permittedPromoters:
                                                    _permittedPromoters,
                                                selectedPromoter:
                                                    _selectedPromoterObj,
                                              ),
                                            );
                                            if (result != null && mounted) {
                                              setState(() {
                                                _selectedPromoterObj = result;
                                              });
                                            }
                                          },
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: sectionSpacing),

                  // Venue
                  Row(
                    children: [
                      const Icon(Icons.location_on),
                      const SizedBox(width: 8),
                      if (_selectedVenueObj == null)
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor:
                                      isDark ? Colors.white : Colors.black,
                                ),
                                onPressed: _isSubmitting
                                    ? null
                                    : () async {
                                        final selectedVenue =
                                            await showModalBottomSheet<Venue>(
                                          context: context,
                                          isScrollControlled: true,
                                          builder: (context) =>
                                              VenueSelectionBottomSheet(
                                            venueService: _venueService,
                                            selectedVenue: _selectedVenueObj,
                                          ),
                                        );
                                        if (selectedVenue != null && mounted) {
                                          setState(() {
                                            _selectedVenueObj = selectedVenue;
                                          });
                                        }
                                      },
                                child: const Text('Select Venue'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                color: isDark ? Colors.white : Colors.black,
                                onPressed: _isSubmitting
                                    ? null
                                    : () async {
                                        final selectedVenue =
                                            await showModalBottomSheet<Venue>(
                                          context: context,
                                          isScrollControlled: true,
                                          builder: (context) =>
                                              VenueSelectionBottomSheet(
                                            venueService: _venueService,
                                            selectedVenue: _selectedVenueObj,
                                          ),
                                        );
                                        if (selectedVenue != null && mounted) {
                                          setState(() {
                                            _selectedVenueObj = selectedVenue;
                                          });
                                        }
                                      },
                              ),
                            ],
                          ),
                        )
                      else
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Chip(
                                label: Text(_selectedVenueObj!.name),
                                onDeleted: !_isSubmitting
                                    ? () =>
                                        setState(() => _selectedVenueObj = null)
                                    : null,
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                color: isDark ? Colors.white : Colors.black,
                                onPressed: _isSubmitting
                                    ? null
                                    : () async {
                                        final selectedVenue =
                                            await showModalBottomSheet<Venue>(
                                          context: context,
                                          isScrollControlled: true,
                                          builder: (context) =>
                                              VenueSelectionBottomSheet(
                                            venueService: _venueService,
                                            selectedVenue: _selectedVenueObj,
                                          ),
                                        );
                                        if (selectedVenue != null && mounted) {
                                          setState(() {
                                            _selectedVenueObj = selectedVenue;
                                          });
                                        }
                                      },
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  // Location precision
                  TextFormField(
                    controller: _locationPrecisionController,
                    decoration: const InputDecoration(
                      labelText: 'Location Precision',
                      hintText: 'e.g. "Area 3", "Hall 2"',
                      helperText: 'optional',
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: sectionSpacing),

                  // Genres
                  ListTile(
                    contentPadding: const EdgeInsets.only(left: -32, right: 16),
                    leading: const Icon(Icons.queue_music),
                    title: Text(
                      _selectedGenres.isEmpty
                          ? 'Select Genres'
                          : '${_selectedGenres.length} selected genres',
                    ),
                    trailing: const Icon(Icons.edit),
                    onTap: () async {
                      final selectedGenresSet = Set<int>.from(_selectedGenres);
                      final bool? saved = await showModalBottomSheet<bool>(
                        context: context,
                        isScrollControlled: true,
                        builder: (BuildContext context) =>
                            GenreSelectionBottomSheet(
                          selectedGenres: selectedGenresSet,
                          genreService: _genreService,
                        ),
                      );
                      if (saved == true && mounted) {
                        setState(() {
                          _selectedGenres = selectedGenresSet.toList();
                        });
                      }
                    },
                  ),
                  if (_selectedGenres.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Wrap(
                        alignment: WrapAlignment.start,
                        spacing: 8.0,
                        children: _selectedGenres.map((genreId) {
                          return GenreChip(genreId: genreId);
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: sectionSpacing),

                  // Si timetable activé, afficher les boutons pour gérer Days et Stages
                  if (_isTimetableEnabled)
                    Container(
                      width: MediaQuery.of(context).size.width,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final result = await showModalBottomSheet<
                                    List<FestivalDay>>(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (context) => ManageDaysBottomSheet(
                                      existingDays: _festivalDays),
                                );
                                if (result != null) {
                                  setState(() {
                                    _festivalDays = result;
                                  });
                                }
                              },
                              child: const Text('MANAGE DAYS'),
                            ),
                          ),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final result =
                                    await showModalBottomSheet<List<String>>(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (context) => ManageStagesBottomSheet(
                                      existingStages: _stages),
                                );
                                if (result != null) {
                                  setState(() {
                                    _stages = result;
                                  });
                                }
                              },
                              child: const Text('MANAGE STAGES'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: sectionSpacing),

                  // Bouton de création
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('CREATE EVENT'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =================== Bottom Sheet: Promoter Selection ===================
class PromoterSelectionBottomSheet extends StatefulWidget {
  final List<Promoter> permittedPromoters;
  final Promoter? selectedPromoter;

  const PromoterSelectionBottomSheet({
    Key? key,
    required this.permittedPromoters,
    this.selectedPromoter,
  }) : super(key: key);

  @override
  State<PromoterSelectionBottomSheet> createState() =>
      _PromoterSelectionBottomSheetState();
}

class _PromoterSelectionBottomSheetState
    extends State<PromoterSelectionBottomSheet> {
  String _searchQuery = '';
  Promoter? _tempSelected;
  bool _showAll = false;
  static const _maxToShow = 10;

  @override
  void initState() {
    super.initState();
    _tempSelected = widget.selectedPromoter;
  }

  List<Promoter> get _filteredPromoters {
    if (_searchQuery.isEmpty) return widget.permittedPromoters;
    return widget.permittedPromoters
        .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _saveSelection() {
    Navigator.of(context).pop(_tempSelected);
  }

  @override
  Widget build(BuildContext context) {
    final displayList = _filteredPromoters;
    final limitedList =
        _showAll ? displayList : displayList.take(_maxToShow).toList();
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double sheetHeight =
        min(screenHeight * 0.5, screenHeight - statusBarHeight - 100);

    return Container(
      height: sheetHeight,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(null)),
              IconButton(
                  icon: const Icon(Icons.save), onPressed: _saveSelection),
            ],
          ),
          const SizedBox(height: sectionTitleSpacing),
          const Text('Search Promoters',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: sectionTitleSpacing),
          TextField(
            decoration: const InputDecoration(
                labelText: 'Search Promoters', suffixIcon: Icon(Icons.search)),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: sectionTitleSpacing),
          Expanded(
            child: limitedList.isEmpty
                ? const Center(child: Text('No promoters found.'))
                : ListView.builder(
                    itemCount: limitedList.length +
                        (displayList.length > _maxToShow && !_showAll ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < limitedList.length) {
                        final promoter = limitedList[index];
                        return RadioListTile<int>(
                          title: Text(promoter.name),
                          value: promoter.id!,
                          groupValue: _tempSelected?.id,
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _tempSelected = promoter;
                              });
                            }
                          },
                        );
                      } else {
                        return TextButton(
                          onPressed: () => setState(() => _showAll = true),
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

// =================== Bottom Sheet: Venue Selection ===================
class VenueSelectionBottomSheet extends StatefulWidget {
  final VenueService venueService;
  final Venue? selectedVenue;

  const VenueSelectionBottomSheet({
    Key? key,
    required this.venueService,
    this.selectedVenue,
  }) : super(key: key);

  @override
  State<VenueSelectionBottomSheet> createState() =>
      _VenueSelectionBottomSheetState();
}

class _VenueSelectionBottomSheetState extends State<VenueSelectionBottomSheet> {
  List<Venue> _venues = [];
  bool _isLoading = false;
  String _searchQuery = '';
  bool _showAll = false;
  static const _maxToShow = 10;
  Venue? _tempSelectedVenue;

  @override
  void initState() {
    super.initState();
    _tempSelectedVenue = widget.selectedVenue;
    _fetchVenues();
  }

  Future<void> _fetchVenues() async {
    setState(() => _isLoading = true);
    try {
      _venues = await widget.venueService.getVenues();
    } catch (e) {
      print('Error fetching venues: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _searchVenues() async {
    setState(() => _isLoading = true);
    try {
      final results = await widget.venueService.searchVenues(_searchQuery);
      setState(() {
        _venues = results;
      });
    } catch (e) {
      print('Error searching venues: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _saveSelection() {
    Navigator.of(context).pop(_tempSelectedVenue);
  }

  @override
  Widget build(BuildContext context) {
    final displayedList =
        _showAll ? _venues : _venues.take(_maxToShow).toList();
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double sheetHeight =
        min(screenHeight * 0.5, screenHeight - statusBarHeight - 100);

    return Container(
      height: sheetHeight,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(null)),
              IconButton(
                  icon: const Icon(Icons.save), onPressed: _saveSelection),
            ],
          ),
          const SizedBox(height: sectionTitleSpacing),
          const Text('Search Venues',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: sectionTitleSpacing),
          TextField(
            decoration: const InputDecoration(
                labelText: 'Search Venues', suffixIcon: Icon(Icons.search)),
            onChanged: (value) {
              _searchQuery = value;
              _searchVenues();
            },
          ),
          const SizedBox(height: sectionTitleSpacing),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayedList.isEmpty
                    ? const Center(child: Text('No venues found.'))
                    : ListView.builder(
                        itemCount: displayedList.length +
                            (_venues.length > _maxToShow && !_showAll ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index < displayedList.length) {
                            final venue = displayedList[index];
                            return RadioListTile<int>(
                              title: Text(venue.name),
                              value: venue.id!,
                              groupValue: _tempSelectedVenue?.id,
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _tempSelectedVenue = venue;
                                  });
                                }
                              },
                            );
                          } else {
                            return TextButton(
                              onPressed: () => setState(() => _showAll = true),
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

// =================== Bottom Sheet: Genre Selection ===================
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
    setState(() => _isLoading = true);
    try {
      List<Genre> genres;
      if (_searchQuery.isEmpty) {
        genres = await widget.genreService.getGenres();
      } else {
        genres = await widget.genreService.searchGenres(_searchQuery);
      }
      genres.sort((a, b) {
        final aSel = widget.selectedGenres.contains(a.id);
        final bSel = widget.selectedGenres.contains(b.id);
        if (aSel && !bSel) return -1;
        if (!aSel && bSel) return 1;
        return a.name.compareTo(b.name);
      });
      if (!mounted) return;
      setState(() {
        _genres = genres;
      });
    } catch (e) {
      print('Error searching genres: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Error searching genres: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _saveSelections() {
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double sheetHeight =
        min(screenHeight * 0.5, screenHeight - statusBarHeight - 100);
    final displayList =
        _showAll ? _genres : _genres.take(_maxGenresToShow).toList();

    return Container(
      height: sheetHeight,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(false)),
              IconButton(
                  icon: const Icon(Icons.save), onPressed: _saveSelections),
            ],
          ),
          const SizedBox(height: sectionTitleSpacing),
          const Text('Search Genres',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: sectionTitleSpacing),
          TextField(
            decoration: const InputDecoration(
                labelText: 'Search Genres', suffixIcon: Icon(Icons.search)),
            onChanged: (value) {
              _searchQuery = value;
              _searchGenres();
            },
          ),
          const SizedBox(height: sectionTitleSpacing),
          _isLoading
              ? const CircularProgressIndicator.adaptive()
              : Expanded(
                  child: displayList.isEmpty
                      ? const Center(child: Text('No genres found.'))
                      : ListView.builder(
                          itemCount: displayList.length +
                              (_genres.length > _maxGenresToShow && !_showAll
                                  ? 1
                                  : 0),
                          itemBuilder: (context, index) {
                            if (index < displayList.length) {
                              final genre = displayList[index];
                              final isSelected =
                                  widget.selectedGenres.contains(genre.id);
                              return CheckboxListTile(
                                value: isSelected,
                                title: Text(genre.name),
                                onChanged: (bool? checked) {
                                  setState(() {
                                    if (checked == true) {
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
                                  setState(() => _showAll = true);
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

// =================== Bottom Sheet: Manage Days ===================

class ManageDaysBottomSheet extends StatefulWidget {
  final List<FestivalDay> existingDays;

  const ManageDaysBottomSheet({Key? key, required this.existingDays})
      : super(key: key);

  @override
  _ManageDaysBottomSheetState createState() => _ManageDaysBottomSheetState();
}

class _ManageDaysBottomSheetState extends State<ManageDaysBottomSheet> {
  late List<FestivalDay> _days;

  @override
  void initState() {
    super.initState();
    // Clone des jours existants
    _days = List.from(widget.existingDays);
  }

  void _addDay() {
    // Ajoute une journée par défaut avec des valeurs temporaires
    final now = DateTime.now();
    setState(() {
      _days.add(FestivalDay(
          name: 'Day ${_days.length + 1}',
          start: now,
          end: now.add(const Duration(hours: 12))));
    });
  }

  void _removeDay(int index) {
    setState(() {
      _days.removeAt(index);
    });
  }

  Future<void> _pickDayStart(int index) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _days[index].start,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: DateTime(now.year + 5),
    );
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(_days[index].start));
      if (pickedTime != null) {
        setState(() {
          _days[index].start = DateTime(pickedDate.year, pickedDate.month,
              pickedDate.day, pickedTime.hour, pickedTime.minute);
        });
      }
    }
  }

  Future<void> _pickDayEnd(int index) async {
    final startDate = _days[index].start;
    final currentEnd = _days[index].end;
    final initialDate = currentEnd.isBefore(startDate) ? startDate : currentEnd;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: startDate,
      lastDate: DateTime(startDate.year + 5),
    );
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );
      if (pickedTime != null) {
        setState(() {
          _days[index].end = DateTime(
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

  void _saveDays() {
    if (_days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please add at least one day.'),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }
    Navigator.of(context).pop(_days);
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double sheetHeight =
        min(screenHeight * 0.6, screenHeight - statusBarHeight - 100);

    return Container(
      height: sheetHeight,
      padding: const EdgeInsets.all(16.0),
      child: Column(
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () =>
                      Navigator.of(context).pop(widget.existingDays)),
              IconButton(icon: const Icon(Icons.save), onPressed: _saveDays),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Manage Days',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: _days.isEmpty
                ? const Center(child: Text('No days added yet.'))
                : ReorderableListView(
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final item = _days.removeAt(oldIndex);
                        _days.insert(newIndex, item);
                      });
                    },
                    children: [
                      for (int index = 0; index < _days.length; index++)
                        Card(
                          key: ValueKey('day_$index'),
                          child: ListTile(
                            leading: ReorderableDragStartListener(
                              index: index,
                              child: const Icon(Icons.drag_handle),
                            ),
                            title: TextFormField(
                              initialValue: _days[index].name,
                              decoration:
                                  const InputDecoration(labelText: 'Day Name'),
                              onChanged: (val) {
                                setState(() {
                                  _days[index].name = val;
                                });
                              },
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                          'Start: ${_days[index].start.toLocal().toString().substring(0, 16)}'),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.calendar_today),
                                      onPressed: () => _pickDayStart(index),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                          'End: ${_days[index].end.toLocal().toString().substring(0, 16)}'),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.calendar_today),
                                      onPressed: () => _pickDayEnd(index),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _removeDay(index),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),

          ElevatedButton(
            onPressed: _addDay,
            child: const Text('ADD DAY'),
          ),
        ],
      ),
    );
  }
}

// =================== Bottom Sheet: Manage Stages ===================

class ManageStagesBottomSheet extends StatefulWidget {
  final List<String> existingStages;

  const ManageStagesBottomSheet({Key? key, required this.existingStages})
      : super(key: key);

  @override
  _ManageStagesBottomSheetState createState() =>
      _ManageStagesBottomSheetState();
}

class _ManageStagesBottomSheetState extends State<ManageStagesBottomSheet> {
  late List<String> _stages;
  final TextEditingController _stageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _stages = List.from(widget.existingStages);
  }

  void _addStage() {
    final stage = _stageController.text.trim();
    if (stage.isNotEmpty) {
      setState(() {
        _stages.add(stage);
        _stageController.clear();
      });
    }
  }

  void _removeStage(int index) {
    setState(() {
      _stages.removeAt(index);
    });
  }

  void _saveStages() {
    if (_stages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please add at least one stage.'),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }
    Navigator.of(context).pop(_stages);
  }

  @override
  void dispose() {
    _stageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double sheetHeight =
        min(screenHeight * 0.5, screenHeight - statusBarHeight - 100);

    return Container(
      height: sheetHeight,
      padding: const EdgeInsets.all(16.0),
      child: Column(
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () =>
                      Navigator.of(context).pop(widget.existingStages)),
              IconButton(icon: const Icon(Icons.save), onPressed: _saveStages),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Manage Stages',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _stageController,
                  decoration: const InputDecoration(labelText: 'Stage Name'),
                ),
              ),
              IconButton(icon: const Icon(Icons.add), onPressed: _addStage),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _stages.isEmpty
                ? const Center(child: Text('No stages added yet.'))
                : ReorderableListView(
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final item = _stages.removeAt(oldIndex);
                        _stages.insert(newIndex, item);
                      });
                    },
                    children: [
                      for (int index = 0; index < _stages.length; index++)
                        ListTile(
                          key: ValueKey('stage_$index'),
                          leading: ReorderableDragStartListener(
                            index: index,
                            child: const Icon(Icons.drag_handle),
                          ),
                          title: Text(_stages[index]),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _removeStage(index),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
