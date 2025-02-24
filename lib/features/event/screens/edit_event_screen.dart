import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Importez vos services et modèles
import 'package:sway/core/constants/dimensions.dart';
import 'package:sway/core/utils/validators.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/screens/edit_event_artist_screen.dart';
import 'package:sway/features/event/services/event_genre_service.dart';
import 'package:sway/features/event/services/event_promoter_service.dart';
import 'package:sway/features/event/services/event_service.dart';
import 'package:sway/features/event/services/event_venue_service.dart';
import 'package:sway/features/genre/models/genre_model.dart';
import 'package:sway/features/genre/services/genre_service.dart';
import 'package:sway/features/genre/widgets/genre_chip.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/promoter/services/promoter_service.dart';
import 'package:sway/features/security/services/storage_service.dart';
import 'package:sway/features/user/screens/user_access_management_screen.dart';
import 'package:sway/features/user/services/user_permission_service.dart';
import 'package:sway/features/user/services/user_service.dart';
import 'package:sway/features/venue/models/venue_model.dart';
import 'package:sway/features/venue/services/venue_service.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/artist/services/artist_service.dart';

/// EditEventScreen: permet d'éditer un event existant.
/// On peut modifier l'image, le titre, le type, les dates, la description,
/// le promoter principal, la venue, les genres et les artistes.
class EditEventScreen extends StatefulWidget {
  final Event event;

  const EditEventScreen({Key? key, required this.event}) : super(key: key);

  @override
  _EditEventScreenState createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs pour le titre et la description
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _ticketLinkController;
  late TextEditingController _locationPrecisionController;

  // Types d'event (visuel vs stocké)
  final List<String> _eventTypeLabels = ['Festival', 'Rave', 'Party', 'Other'];
  late String _selectedTypeLabel; // ex: "Festival", stocké en minuscule

  // Dates
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  // Image
  File? _selectedImage;
  String _originalImageUrl = '';
  bool _isUpdating = false;

  // Promoter/venue/genres/artists
  Promoter? _selectedPromoterObj;
  Venue? _selectedVenueObj;
  List<int> _selectedGenres = [];

  // Services
  final EventService _eventService = EventService();
  final StorageService _storageService = StorageService();
  final UserPermissionService _permissionService = UserPermissionService();
  final UserService _userService = UserService();
  final PromoterService _promoterService = PromoterService();
  final VenueService _venueService = VenueService();
  final GenreService _genreService = GenreService();

  // Services pour join tables
  final EventPromoterService _eventPromoterService = EventPromoterService();
  final EventVenueService _eventVenueService = EventVenueService();
  final EventGenreService _eventGenreService = EventGenreService();

  // Liste des promoteurs où l'utilisateur est manager/admin
  List<Promoter> _permittedPromoters = [];

  // Variables de permissions
  bool isAdmin = false;
  bool isManager = false;
  bool isReadOnly = false;
  bool _permissionsLoaded = false;

  // Instance of the global validator used for text fields.
  // It will be updated with the combined forbiddenWords (French + English).
  late FieldValidator defaultValidator;

  // ignore: unused_field
  Map<String, dynamic> _eventMetadata = {};

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _descriptionController =
        TextEditingController(text: widget.event.description);
    // Initialisation des contrôleurs pour ticketLink et locationPrecision
    _ticketLinkController = TextEditingController();
    _locationPrecisionController = TextEditingController();

    _loadEventMetadata();

    // Convertir event.type (en minuscule) => label (ex: "festival" => "Festival")
    final capitalizedType =
        '${widget.event.type[0].toUpperCase()}${widget.event.type.substring(1).toLowerCase()}';
    _selectedTypeLabel =
        _eventTypeLabels.contains(capitalizedType) ? capitalizedType : 'Other';

    _selectedStartDate = widget.event.eventDateTime;
    _selectedEndDate = widget.event.eventEndDateTime;
    _originalImageUrl = widget.event.imageUrl;

    _loadUserPermissions();
    _fetchPermittedPromoters();
    _loadEventAssociations();

    // Initialize defaultValidator with base parameters and an empty forbiddenWords.
    defaultValidator = FieldValidator(
      isRequired: true,
      maxLength: 500,
      forbiddenWords: [],
    );

    // Load forbidden words for French and English, then update the validator.
    _loadDefaultForbiddenWords();
  }

  Future<void> _loadDefaultForbiddenWords() async {
    try {
      final frWords = await loadForbiddenWords('fr');
      final enWords = await loadForbiddenWords('en');
      // Combine the two lists and remove duplicates.
      final combined = {...frWords, ...enWords}.toList();
      setState(() {
        defaultValidator = FieldValidator(
          isRequired: true,
          maxLength: 2000,
          forbiddenWords: combined,
        );
      });
      // Optionnel : Revalider le formulaire pour mettre à jour les erreurs si besoin.
      _formKey.currentState?.validate();
    } catch (e) {
      print('Error loading forbidden words: $e');
    }
  }

  // Dans _loadUserPermissions, à la fin de la méthode, indiquez que le chargement est terminé
  Future<void> _loadUserPermissions() async {
    final currentUser = await _userService.getCurrentUser();
    if (currentUser == null) {
      setState(() {
        isReadOnly = true;
        isManager = false;
        isAdmin = false;
        _permissionsLoaded = true;
      });
      return;
    }
    final admin = await _permissionService.hasPermissionForCurrentUser(
        widget.event.id!, 'event', 3);
    final manager = await _permissionService.hasPermissionForCurrentUser(
        widget.event.id!, 'event', 2);
    setState(() {
      isAdmin = admin;
      isManager = (!admin && manager);
      isReadOnly = (!admin && !manager);
      _permissionsLoaded = true;
    });
  }

  /// Charger la liste des promoteurs autorisés
  Future<void> _fetchPermittedPromoters() async {
    setState(() => _isUpdating = true);
    try {
      final currentUser = await _userService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not logged in');
      }
      final perms = await _permissionService.getPermissionsByUserIdAndType(
        currentUser.id,
        'promoter',
      );
      // Filtrer manager/admin
      final allowedPromoterIds = perms
          .where((p) => p.permissionLevel >= 2) // manager = 2 ou admin = 3
          .map((p) => p.entityId)
          .toList();
      if (allowedPromoterIds.isNotEmpty) {
        final promoters =
            await _promoterService.getPromotersByIds(allowedPromoterIds);
        setState(() {
          _permittedPromoters = promoters;
        });
      }
    } catch (e) {
      print('Error fetching permitted promoters: $e');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  /// Charger promoterObj / venueObj / genres depuis la DB
  Future<void> _loadEventAssociations() async {
    setState(() => _isUpdating = true);
    try {
      // Promoter (event_promoter) : en principe, un seul promoter
      final promoters = await _eventPromoterService.getPromotersByEventId(
        widget.event.id!,
      );
      if (promoters.isNotEmpty) {
        _selectedPromoterObj = promoters.first;
      }

      // Venue (event_venue)
      final venue =
          await _eventVenueService.getVenueByEventId(widget.event.id!);
      _selectedVenueObj = venue;

      // Genres (event_genre)
      final genreIds =
          await _eventGenreService.getGenresByEventId(widget.event.id!);
      _selectedGenres = genreIds;
    } catch (e) {
      print('Error loading event associations: $e');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _loadEventMetadata() async {
    try {
      // Charger les métadonnées depuis Supabase
      final metadata = await EventService().getEventMetadata(widget.event.id!);
      if (metadata != null) {
        setState(() {
          _eventMetadata = metadata;
          _ticketLinkController.text = metadata['ticket_link'] ?? '';
          _locationPrecisionController.text =
              metadata['location_precision'] ?? '';
        });
      } else {
        // Si aucune donnée n'est trouvée, laisser les champs vides ou avec des valeurs par défaut.
        setState(() {
          _eventMetadata = {};
          _ticketLinkController.text = '';
          _locationPrecisionController.text = '';
        });
      }
    } catch (e) {
      print("Error loading metadata: $e");
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

  Future<void> _pickImage() async {
    if (isReadOnly) return;
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
    if (isReadOnly) return;
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? now,
      firstDate: now.subtract(Duration(days: 365)),
      lastDate: DateTime(now.year + 5),
    );
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
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
    if (isReadOnly) return;
    if (_selectedStartDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a start date first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final pickedDate = await showDatePicker(
      context: context,
      initialDate:
          _selectedEndDate ?? _selectedStartDate!.add(Duration(hours: 1)),
      firstDate: _selectedStartDate!,
      lastDate: DateTime(_selectedStartDate!.year + 5),
    );
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
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

    final publicUrl = await _storageService.uploadFile(
      bucketName: "event-images",
      fileName: filePath,
      fileData: fileBytes,
    );
    return publicUrl;
  }

  Future<void> _updateEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedStartDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select the start date/time.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedPromoterObj == null || _selectedVenueObj == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a promoter and a venue.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isUpdating = true);
    try {
      // Vérifier que l'utilisateur a au moins le niveau manager pour éditer
      final hasPermission =
          await _permissionService.hasPermissionForCurrentUser(
        widget.event.id!,
        'event',
        2,
      );
      if (!hasPermission) {
        throw Exception('Permission denied on this event.');
      }

      final String typeToStore = _selectedTypeLabel.toLowerCase();

      // Fusionner l'ancienne metadata avec les nouvelles valeurs
      final Map<String, dynamic> oldMetadata = widget.event.metadata ?? {};
      final Map<String, dynamic> mergedMetadata =
          Map<String, dynamic>.from(oldMetadata);

      // Mettre à jour ticket_link
      final String ticketLink = _ticketLinkController.text.trim();
      if (ticketLink.isNotEmpty) {
        mergedMetadata['ticket_link'] = ticketLink;
      } else {
        mergedMetadata.remove('ticket_link');
      }

      // Mettre à jour location_precision
      final String locationPrecision = _locationPrecisionController.text.trim();
      if (locationPrecision.isNotEmpty) {
        mergedMetadata['location_precision'] = locationPrecision;
      } else {
        mergedMetadata.remove('location_precision');
      }

      // Créer l'événement mis à jour avec la metadata fusionnée
      Event updatedEvent = widget.event.copyWith(
        title: _titleController.text.trim(),
        type: typeToStore,
        eventDateTime: _selectedStartDate,
        eventEndDateTime: _selectedEndDate,
        description: _descriptionController.text.trim(),
        metadata: mergedMetadata,
      );

      String newImageUrl = widget.event.imageUrl;
      if (_selectedImage != null) {
        newImageUrl = await _uploadImage(widget.event.id!, _selectedImage!);
        if (_originalImageUrl.isNotEmpty) {
          final oldFileName =
              _originalImageUrl.split('/').last.split('?').first;
          if (oldFileName.isNotEmpty) {
            final oldFilePath = "${widget.event.id}/$oldFileName";
            await _storageService.deleteFile(
              bucketName: "event-images",
              fileName: oldFilePath,
            );
          }
        }
        updatedEvent = updatedEvent.copyWith(imageUrl: newImageUrl);
      }

      final finalEvent = await _eventService.updateEvent(updatedEvent);

      if (_selectedPromoterObj != null) {
        await _eventPromoterService.updateEventPromoters(
          finalEvent.id!,
          [_selectedPromoterObj!.id!],
        );
      }
      if (_selectedVenueObj != null) {
        await _eventVenueService.updateEventVenue(
          finalEvent.id!,
          _selectedVenueObj!.id!,
        );
      }
      await _eventGenreService.updateEventGenres(
          finalEvent.id!, _selectedGenres);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event updated successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, updatedEvent);
    } catch (e) {
      print('Error updating event: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating event: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final isAllowedToDelete =
        await _permissionService.hasPermissionForCurrentUser(
      widget.event.id!,
      'event',
      3,
    );
    if (!isAllowedToDelete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to delete this event.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this event?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(ctx, false),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      _deleteEvent();
    }
  }

  Future<void> _deleteEvent() async {
    setState(() => _isUpdating = true);
    try {
      await _eventService.deleteEvent(widget.event.id!);
      if (_originalImageUrl.isNotEmpty) {
        final oldFileName = _originalImageUrl.split('/').last.split('?').first;
        if (oldFileName.isNotEmpty) {
          final oldFilePath = "${widget.event.id}/$oldFileName";
          await _storageService.deleteFile(
            bucketName: "event-images",
            fileName: oldFilePath,
          );
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event deleted successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, null);
    } catch (e) {
      print('Error deleting event: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting event: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit "${widget.event.title}"'),
        actions: [
          // Bouton d'accès aux permissions (toujours actif si non en chargement)
          IconButton(
            icon: const Icon(Icons.add_moderator),
            onPressed: _isUpdating
                ? null
                : () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserAccessManagementScreen(
                          entityId: widget.event.id!,
                          entityType: 'event',
                        ),
                      ),
                    );
                    if (!mounted) return;
                    setState(() {});
                  },
          ),
          // Bouton delete
          if (isAdmin || isManager)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isUpdating
                  ? null
                  : isAdmin
                      ? () async {
                          await _showDeleteConfirmation();
                        }
                      : null, // Pour manager, le bouton est visible mais désactivé
            ),
          // Bouton save
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: (_isUpdating || isReadOnly || !_permissionsLoaded)
                ? null
                : _updateEvent,
            color: (_isUpdating || isReadOnly || !_permissionsLoaded)
                ? Colors.grey
                : null,
          ),
        ],
      ),
      body: _isUpdating
          ? const Center(child: CircularProgressIndicator.adaptive())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Section image avec overlay d'édition (affiché uniquement si l'utilisateur n'est pas read-only)
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: isReadOnly ? null : _pickImage,
                          child: Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey[200],
                            ),
                            child: _selectedImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : widget.event.imageUrl.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: ImageWithErrorHandler(
                                          imageUrl: widget.event.imageUrl,
                                          width: double.infinity,
                                          height: 200,
                                        ),
                                      )
                                    : const Center(
                                        child: Icon(
                                          Icons.camera_alt,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                      ),
                          ),
                        ),
                        // L'icône d'édition n'est affichée que si l'utilisateur n'est pas en mode read-only
                        if (!isReadOnly)
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: IconButton(
                              icon: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(8),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              onPressed: isReadOnly ? null : _pickImage,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: sectionSpacing),
                    // Titre
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => defaultValidator.validate(value),
                      readOnly: isReadOnly,
                    ),
                    const SizedBox(height: sectionSpacing),
                    // Event type (Dropdown)
                    DropdownButtonFormField<String>(
                      value: _selectedTypeLabel,
                      decoration: const InputDecoration(
                        labelText: 'Event Type',
                        border: OutlineInputBorder(),
                      ),
                      dropdownColor: isDark ? Colors.black : null,
                      items: _eventTypeLabels.map((e) {
                        return DropdownMenuItem<String>(
                          value: e,
                          child: Text(e),
                        );
                      }).toList(),
                      onChanged: isReadOnly
                          ? null
                          : (value) {
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
                      onTap: isReadOnly ? null : _pickStartDateTime,
                      decoration: InputDecoration(
                        labelText: 'Start Date & Time',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: isReadOnly ? null : _pickStartDateTime,
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
                          return 'Please select the start date/time.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: sectionSpacing),
                    // End date/time
                    TextFormField(
                      readOnly: true,
                      onTap: isReadOnly ? null : _pickEndDateTime,
                      decoration: InputDecoration(
                        labelText: 'End Date & Time',
                        border: const OutlineInputBorder(),
                        helperText: 'optional',
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: isReadOnly
                                  ? null
                                  : () {
                                      setState(() {
                                        _selectedEndDate = null;
                                      });
                                    },
                            ),
                            IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: isReadOnly ? null : _pickEndDateTime,
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
                      validator: (_) => null,
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
                      readOnly: isReadOnly,
                    ),
                    const SizedBox(height: sectionSpacing),
                    // Ticket link (URL format validation)
                    TextFormField(
                      controller: _ticketLinkController,
                      decoration: const InputDecoration(
                        labelText: 'Ticket Link',
                        hintText: 'e.g. https://www.ticketux.be/',
                        helperText: 'optional',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 1,
                      validator: ticketLinkValidator,
                      readOnly: isReadOnly,
                    ),
                    const SizedBox(height: sectionSpacing),
                    // Promoter section
                    _buildPromoterSection(isDark),
                    const SizedBox(height: sectionSpacing),
                    // Venue section
                    _buildVenueSection(isDark),
                    const SizedBox(height: sectionSpacing),
                    // Location precision (optional)
                    TextFormField(
                      controller: _locationPrecisionController,
                      decoration: const InputDecoration(
                        labelText: 'Location Precision',
                        hintText: 'e.g. "Room 10", "Hall 2"',
                        helperText: 'optional',
                      ),
                      maxLines: 1,
                      readOnly: isReadOnly,
                    ),
                    const SizedBox(height: sectionSpacing),
                    // Genres section
                    _buildGenresSection(),
                    const SizedBox(height: sectionSpacing),
                    // Artists section
                    _buildArtistsSection(),
                    const SizedBox(height: sectionSpacing),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPromoterSection(bool isDark) {
    return Row(
      children: [
        const Icon(Icons.person),
        const SizedBox(width: 8),
        if (_selectedPromoterObj == null)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : Colors.black,
                  ),
                  onPressed: (_permittedPromoters.isEmpty ||
                          _isUpdating ||
                          isReadOnly)
                      ? null
                      : () async {
                          final result = await showModalBottomSheet<Promoter>(
                            context: context,
                            isScrollControlled: true,
                            builder: (context) => EditEventPromoterBottomSheet(
                              permittedPromoters: _permittedPromoters,
                              selectedPromoter: _selectedPromoterObj,
                            ),
                          );
                          if (result != null && mounted) {
                            setState(() => _selectedPromoterObj = result);
                          }
                        },
                  child: const Text('Select Promoter'),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  color: isDark ? Colors.white : Colors.black,
                  onPressed: (_permittedPromoters.isEmpty ||
                          _isUpdating ||
                          isReadOnly)
                      ? null
                      : () async {
                          final result = await showModalBottomSheet<Promoter>(
                            context: context,
                            isScrollControlled: true,
                            builder: (context) => EditEventPromoterBottomSheet(
                              permittedPromoters: _permittedPromoters,
                              selectedPromoter: _selectedPromoterObj,
                            ),
                          );
                          if (result != null && mounted) {
                            setState(() => _selectedPromoterObj = result);
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
                  onDeleted: (_isUpdating || isReadOnly)
                      ? null
                      : () => setState(() => _selectedPromoterObj = null),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  color: isDark ? Colors.white : Colors.black,
                  onPressed: (_permittedPromoters.isEmpty ||
                          _isUpdating ||
                          isReadOnly)
                      ? null
                      : () async {
                          final result = await showModalBottomSheet<Promoter>(
                            context: context,
                            isScrollControlled: true,
                            builder: (context) => EditEventPromoterBottomSheet(
                              permittedPromoters: _permittedPromoters,
                              selectedPromoter: _selectedPromoterObj,
                            ),
                          );
                          if (result != null && mounted) {
                            setState(() => _selectedPromoterObj = result);
                          }
                        },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildVenueSection(bool isDark) {
    return Row(
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
                    foregroundColor: isDark ? Colors.white : Colors.black,
                  ),
                  onPressed: (_isUpdating || isReadOnly)
                      ? null
                      : () async {
                          final selectedVenue =
                              await showModalBottomSheet<Venue>(
                            context: context,
                            isScrollControlled: true,
                            builder: (context) => EditEventVenueBottomSheet(
                              venueService: _venueService,
                              selectedVenue: null,
                            ),
                          );
                          if (selectedVenue != null && mounted) {
                            setState(() => _selectedVenueObj = selectedVenue);
                          }
                        },
                  child: const Text('Select Venue'),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  color: isDark ? Colors.white : Colors.black,
                  onPressed: (_isUpdating || isReadOnly)
                      ? null
                      : () async {
                          final selectedVenue =
                              await showModalBottomSheet<Venue>(
                            context: context,
                            isScrollControlled: true,
                            builder: (context) => EditEventVenueBottomSheet(
                              venueService: _venueService,
                              selectedVenue: null,
                            ),
                          );
                          if (selectedVenue != null && mounted) {
                            setState(() => _selectedVenueObj = selectedVenue);
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
                  onDeleted: (_isUpdating || isReadOnly)
                      ? null
                      : () => setState(() => _selectedVenueObj = null),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  color: isDark ? Colors.white : Colors.black,
                  onPressed: (_isUpdating || isReadOnly)
                      ? null
                      : () async {
                          final selectedVenue =
                              await showModalBottomSheet<Venue>(
                            context: context,
                            isScrollControlled: true,
                            builder: (context) => EditEventVenueBottomSheet(
                              venueService: _venueService,
                              selectedVenue: _selectedVenueObj,
                            ),
                          );
                          if (selectedVenue != null && mounted) {
                            setState(() => _selectedVenueObj = selectedVenue);
                          }
                        },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildGenresSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.only(left: -32, right: 16),
          leading: const Icon(Icons.queue_music),
          title: Text(
            _selectedGenres.isEmpty
                ? 'Select Genres'
                : '${_selectedGenres.length} selected genres',
          ),
          trailing: Icon(
            Icons.edit,
            color: isReadOnly
                ? Colors.grey[700]
                : Theme.of(context).iconTheme.color,
          ),
          onTap: isReadOnly
              ? null
              : () async {
                  final selectedGenresSet = Set<int>.from(_selectedGenres);
                  final bool? saved = await showModalBottomSheet<bool>(
                    context: context,
                    isScrollControlled: true,
                    builder: (BuildContext context) =>
                        EditEventGenreBottomSheet(
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
      ],
    );
  }

  Widget _buildArtistsSection() {
    return Row(
      children: [
        const Icon(Icons.headset_mic),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Manage Artist Assignments',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
        IconButton(
          icon: isReadOnly
              ? const Icon(Icons.arrow_forward)
              : const Icon(Icons.edit),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    EditEventArtistsScreen(eventId: widget.event.id!),
              ),
            );
          },
        ),
      ],
    );
  }
}

// =================== Bottom sheets / classes pour l'édition ===================

/// Bottom sheet pour sélectionner/éditer le promoter
class EditEventPromoterBottomSheet extends StatefulWidget {
  final List<Promoter> permittedPromoters;
  final Promoter? selectedPromoter;

  const EditEventPromoterBottomSheet({
    Key? key,
    required this.permittedPromoters,
    this.selectedPromoter,
  }) : super(key: key);

  @override
  State<EditEventPromoterBottomSheet> createState() =>
      _EditEventPromoterBottomSheetState();
}

class _EditEventPromoterBottomSheetState
    extends State<EditEventPromoterBottomSheet> {
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
                onPressed: () => Navigator.of(context).pop(null),
              ),
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveSelection,
              ),
            ],
          ),
          const SizedBox(height: sectionTitleSpacing),
          const Text(
            'Edit Promoter',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: sectionTitleSpacing),

          TextField(
            decoration: const InputDecoration(
              labelText: 'Search Promoters',
              suffixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
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

                        // RadioListTile pour mono-sélection
                        return RadioListTile<int>(
                          title: Text(promoter.name),
                          value: promoter.id!,
                          groupValue: _tempSelected?.id,
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _tempSelected = promoter);
                            }
                          },
                        );
                      } else {
                        // Show More
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

/// Bottom sheet pour sélectionner/éditer la venue
class EditEventVenueBottomSheet extends StatefulWidget {
  final VenueService venueService;
  final Venue? selectedVenue;

  const EditEventVenueBottomSheet({
    Key? key,
    required this.venueService,
    this.selectedVenue,
  }) : super(key: key);

  @override
  State<EditEventVenueBottomSheet> createState() =>
      _EditEventVenueBottomSheetState();
}

class _EditEventVenueBottomSheetState extends State<EditEventVenueBottomSheet> {
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
                onPressed: () => Navigator.of(context).pop(null),
              ),
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveSelection,
              ),
            ],
          ),
          const SizedBox(height: sectionTitleSpacing),
          const Text(
            'Edit Venue',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: sectionTitleSpacing),

          TextField(
            decoration: const InputDecoration(
              labelText: 'Search Venues',
              suffixIcon: Icon(Icons.search),
            ),
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
                            // Show more
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

/// Bottom sheet for editing (selecting/unselecting) the genres of an event
class EditEventGenreBottomSheet extends StatefulWidget {
  final Set<int> selectedGenres;
  final GenreService genreService;

  const EditEventGenreBottomSheet({
    Key? key,
    required this.selectedGenres,
    required this.genreService,
  }) : super(key: key);

  @override
  _EditEventGenreBottomSheetState createState() =>
      _EditEventGenreBottomSheetState();
}

class _EditEventGenreBottomSheetState extends State<EditEventGenreBottomSheet> {
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

      // Show selected items first
      genres.sort((a, b) {
        final aSelected = widget.selectedGenres.contains(a.id);
        final bSelected = widget.selectedGenres.contains(b.id);
        if (aSelected && !bSelected) return -1;
        if (!aSelected && bSelected) return 1;
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
    Navigator.of(context).pop(true); // Indicates the user validated changes
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double sheetHeight =
        min(screenHeight * 0.5, screenHeight - statusBarHeight - 100);

    final displayedList =
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
                onPressed: () => Navigator.of(context).pop(false),
              ),
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveSelections,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Edit Event Genres',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          _isLoading
              ? const CircularProgressIndicator.adaptive()
              : Expanded(
                  child: displayedList.isEmpty
                      ? const Center(child: Text('No genres found.'))
                      : ListView.builder(
                          itemCount: displayedList.length +
                              (_genres.length > _maxGenresToShow && !_showAll
                                  ? 1
                                  : 0),
                          itemBuilder: (context, index) {
                            if (index < displayedList.length) {
                              final genre = displayedList[index];
                              final isSelected =
                                  widget.selectedGenres.contains(genre.id);

                              return CheckboxListTile(
                                value: isSelected,
                                title: Text(genre.name),
                                onChanged: (bool? checked) {
                                  if (!mounted) return;
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
                              // Show More
                              return TextButton(
                                onPressed: () =>
                                    setState(() => _showAll = true),
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

/// Bottom sheet for editing (selecting/unselecting) the artists of an event
class EditEventArtistBottomSheet extends StatefulWidget {
  final Set<int> selectedArtists;
  final ArtistService artistService;

  const EditEventArtistBottomSheet({
    Key? key,
    required this.selectedArtists,
    required this.artistService,
  }) : super(key: key);

  @override
  _EditEventArtistBottomSheetState createState() =>
      _EditEventArtistBottomSheetState();
}

class _EditEventArtistBottomSheetState
    extends State<EditEventArtistBottomSheet> {
  List<Artist> _artists = [];
  String _searchQuery = '';
  bool _isLoading = false;
  bool _showAll = false;

  static const int _maxArtistsToShow = 10;

  @override
  void initState() {
    super.initState();
    _searchArtists();
  }

  Future<void> _searchArtists() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      List<Artist> artists;
      if (_searchQuery.isEmpty) {
        artists = await widget.artistService.getArtists();
      } else {
        artists = await widget.artistService.searchArtists(_searchQuery);
      }

      // Sort: selected first
      artists.sort((a, b) {
        final aSel = widget.selectedArtists.contains(a.id);
        final bSel = widget.selectedArtists.contains(b.id);
        if (aSel && !bSel) return -1;
        if (!aSel && bSel) return 1;
        return a.name.compareTo(b.name);
      });

      if (!mounted) return;
      setState(() {
        _artists = artists;
      });
    } catch (e) {
      print('Error searching artists: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Error searching artists: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _saveSelections() {
    Navigator.of(context).pop(true); // user validated changes
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double sheetHeight =
        min(screenHeight * 0.5, screenHeight - statusBarHeight - 100);

    final displayedList =
        _showAll ? _artists : _artists.take(_maxArtistsToShow).toList();

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
                onPressed: () => Navigator.of(context).pop(false),
              ),
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveSelections,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Edit Event Artists',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Search Artists',
              suffixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
              _searchArtists();
            },
          ),
          const SizedBox(height: 16),
          _isLoading
              ? const CircularProgressIndicator.adaptive()
              : Expanded(
                  child: displayedList.isEmpty
                      ? const Center(child: Text('No artists found.'))
                      : ListView.builder(
                          itemCount: displayedList.length +
                              (_artists.length > _maxArtistsToShow && !_showAll
                                  ? 1
                                  : 0),
                          itemBuilder: (context, index) {
                            if (index < displayedList.length) {
                              final artist = displayedList[index];
                              final isSelected =
                                  widget.selectedArtists.contains(artist.id!);

                              return CheckboxListTile(
                                value: isSelected,
                                title: Text(artist.name),
                                onChanged: (bool? checked) {
                                  setState(() {
                                    if (checked == true) {
                                      widget.selectedArtists.add(artist.id!);
                                    } else {
                                      widget.selectedArtists.remove(artist.id!);
                                    }
                                  });
                                },
                              );
                            } else {
                              // Show more
                              return TextButton(
                                onPressed: () =>
                                    setState(() => _showAll = true),
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
