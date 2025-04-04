import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

// Importations des services, modèles et widgets
import 'package:sway/core/constants/dimensions.dart';
import 'package:sway/core/utils/validators.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/genre/models/genre_model.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/venue/models/venue_model.dart';
import 'package:sway/features/venue/services/venue_service.dart';
import 'package:sway/features/venue/services/venue_genre_service.dart';
import 'package:sway/features/venue/services/venue_promoter_service.dart';
import 'package:sway/features/venue/services/venue_resident_artists_service.dart';
import 'package:sway/features/genre/widgets/genre_chip.dart';
import 'package:sway/features/promoter/widgets/promoter_chip.dart';
import 'package:sway/features/artist/widgets/artist_chip.dart';
import 'package:sway/features/genre/services/genre_service.dart';
import 'package:sway/features/promoter/services/promoter_service.dart';
import 'package:sway/features/artist/services/artist_service.dart';
import 'package:sway/features/security/services/storage_service.dart';
import 'package:sway/features/user/screens/user_access_management_screen.dart';
import 'package:sway/features/user/services/user_permission_service.dart';
import 'package:sway/features/user/services/user_service.dart';

class EditVenueScreen extends StatefulWidget {
  final Venue venue;

  const EditVenueScreen({required this.venue, Key? key}) : super(key: key);

  @override
  _EditVenueScreenState createState() => _EditVenueScreenState();
}

class _EditVenueScreenState extends State<EditVenueScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late FocusNode _locationFocusNode; // FocusNode pour le champ Location

  final VenueService _venueService = VenueService();
  final VenueGenreService _venueGenreService = VenueGenreService();
  final VenuePromoterService _venuePromoterService = VenuePromoterService();
  final VenueResidentArtistsService _venueResidentArtistsService =
      VenueResidentArtistsService();
  final StorageService _storageService = StorageService();
  final GenreService _genreService = GenreService();
  final PromoterService _promoterService = PromoterService();
  final ArtistService _artistService = ArtistService();
  final UserPermissionService _permissionService = UserPermissionService();
  final UserService _userService = UserService();

  // Variables pour stocker les associations
  List<int> _selectedGenres = [];
  List<int> _selectedPromoters = [];
  List<int> _selectedArtists = [];

  List<int> _initialGenres = [];
  List<int> _initialPromoters = [];
  List<int> _initialArtists = [];

  bool _isUpdating = false;
  bool _isDeleting = false;
  String? _errorMessage;

  late Venue _currentVenue;
  File? _selectedImage;

  // Variables de permission
  bool isAdmin = false;
  bool isManager = false;
  bool isReadOnly = false;
  bool _permissionsLoaded = false;

  // Validator global pour les champs de texte.
  late FieldValidator defaultValidator;

  // Variables pour la géolocalisation
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _currentVenue = widget.venue;
    _nameController = TextEditingController(text: _currentVenue.name);
    _descriptionController =
        TextEditingController(text: _currentVenue.description);
    _locationController = TextEditingController(text: _currentVenue.location);
    // Initialisation du FocusNode pour le champ Location.
    _locationFocusNode = FocusNode();
    _locationFocusNode.addListener(() {
      if (!_locationFocusNode.hasFocus && _locationController.text.isNotEmpty) {
        _fetchLocation(_locationController.text.trim());
      }
    });
    _loadUserPermissions();
    _loadAssociatedData();

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
      debugPrint('Error loading forbidden words: $e');
    }
  }

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
        _currentVenue.id!, 'venue', 3);
    final manager = await _permissionService.hasPermissionForCurrentUser(
        _currentVenue.id!, 'venue', 2);
    setState(() {
      isAdmin = admin;
      isManager = (!admin && manager);
      isReadOnly = (!admin && !manager);
      _permissionsLoaded = true;
    });
  }

  Future<void> _loadAssociatedData() async {
    setState(() => _isUpdating = true);
    try {
      // Charger les genres associés à la venue
      final genres =
          await _venueGenreService.getGenresByVenueId(_currentVenue.id!);
      setState(() {
        _selectedGenres = genres;
        _initialGenres = List.from(genres);
      });
      // Charger les promoteurs associés à la venue
      final promoters =
          await _venuePromoterService.getPromotersByVenueId(_currentVenue.id!);
      setState(() {
        _selectedPromoters = promoters.map((promoter) => promoter.id!).toList();
        _initialPromoters = List.from(_selectedPromoters);
      });
      // Charger les artistes résidents associés à la venue
      final artists = await _venueResidentArtistsService
          .getArtistsByVenueId(_currentVenue.id!);
      setState(() {
        _selectedArtists = artists.map((artist) => artist.id!).toList();
        _initialArtists = List.from(_selectedArtists);
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des données associées: $e');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _locationFocusNode.dispose();
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

  Future<String> _uploadImage(int venueId, File imageFile) async {
    final fileBytes = await imageFile.readAsBytes();
    final fileExtension = imageFile.path.split('.').last;
    final fileName = "${DateTime.now().millisecondsSinceEpoch}.$fileExtension";
    final filePath = "$venueId/$fileName";

    final publicUrl = await _storageService.uploadFile(
      bucketName: "venue-images",
      fileName: filePath,
      fileData: fileBytes,
    );
    return publicUrl;
  }

  /// Interroge Nominatim directement pour géocoder l'adresse.
  Future<void> _fetchLocation(String address) async {
    final url =
        "https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(address)}";
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "User-Agent":
              "YourAppName/1.0 (your_email@example.com)" // Remplacez par vos informations
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          final firstResult = data[0];
          setState(() {
            _latitude = double.tryParse(firstResult['lat'].toString());
            _longitude = double.tryParse(firstResult['lon'].toString());
          });
        } else {
          debugPrint('No geocoding results found.');
        }
      } else {
        debugPrint('Error during geolocation: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error during geocoding: $e');
    }
  }

  Future<void> _updateVenue() async {
    if (!_formKey.currentState!.validate()) return;

    final newName = _nameController.text.trim();
    final newDescription = _descriptionController.text.trim();
    final newLocation = _locationController.text.trim();

    // Vérifier si des changements ont été effectués
    final bool isNameChanged = newName != _currentVenue.name;
    final bool isDescriptionChanged =
        newDescription != _currentVenue.description;
    final bool isLocationChanged = newLocation != _currentVenue.location;
    final bool isImageChanged = _selectedImage != null;
    final bool isGenresChanged = !listEquals(_selectedGenres, _initialGenres);
    final bool isPromotersChanged =
        !listEquals(_selectedPromoters, _initialPromoters);
    final bool isArtistsChanged =
        !listEquals(_selectedArtists, _initialArtists);

    if (!isNameChanged &&
        !isDescriptionChanged &&
        !isLocationChanged &&
        !isImageChanged &&
        !isGenresChanged &&
        !isPromotersChanged &&
        !isArtistsChanged) {
      Navigator.pop(context, _currentVenue);
      return;
    }

    setState(() {
      _isUpdating = true;
      _errorMessage = null;
    });

    try {
      String updatedImageUrl = _currentVenue.imageUrl;
      if (isImageChanged) {
        updatedImageUrl =
            await _uploadImage(_currentVenue.id!, _selectedImage!);
        if (_currentVenue.imageUrl.isNotEmpty) {
          final oldFileName =
              _currentVenue.imageUrl.split('/').last.split('?').first;
          if (oldFileName.isNotEmpty) {
            final oldFilePath = "${_currentVenue.id}/$oldFileName";
            await _storageService.deleteFile(
              bucketName: "venue-images",
              fileName: oldFilePath,
            );
          }
        }
      }
      // Si l'adresse a changé, on inclut la nouvelle localisation et les coordonnées géocodées.
      Venue updatedVenue = _currentVenue.copyWith(
        name: isNameChanged ? newName : null,
        description: isDescriptionChanged ? newDescription : null,
        location: isLocationChanged ? newLocation : null,
        imageUrl: isImageChanged ? updatedImageUrl : null,
        latitude: isLocationChanged ? _latitude : null,
        longitude: isLocationChanged ? _longitude : null,
      );

      if (isNameChanged ||
          isDescriptionChanged ||
          isLocationChanged ||
          isImageChanged) {
        updatedVenue = await _venueService.updateVenue(updatedVenue);
        setState(() {
          _currentVenue = updatedVenue;
          _selectedImage = null;
        });
      }
      if (isGenresChanged) {
        await _venueGenreService.updateVenueGenres(
            _currentVenue.id!, _selectedGenres);
        setState(() {
          _initialGenres = List.from(_selectedGenres);
        });
      }
      if (isPromotersChanged) {
        await _venuePromoterService.updateVenuePromoters(
            _currentVenue.id!, _selectedPromoters);
        setState(() {
          _initialPromoters = List.from(_selectedPromoters);
        });
      }
      if (isArtistsChanged) {
        await _venueResidentArtistsService.updateVenueArtists(
            _currentVenue.id!, _selectedArtists);
        setState(() {
          _initialArtists = List.from(_selectedArtists);
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Venue updated successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, _currentVenue);
    } catch (e) {
      debugPrint('Update Venue Error: $e');
      setState(() {
        _errorMessage = 'An unexpected error occurred.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating venue: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _showDeleteConfirmationDialog() async {
    final isAllowedToDelete =
        await _permissionService.hasPermissionForCurrentUser(
      _currentVenue.id!,
      'venue',
      3,
    );
    if (!isAllowedToDelete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to delete this venue.'),
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
          content: const Text('Are you sure you want to delete this venue?'),
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
      _deleteVenue();
    }
  }

  Future<void> _deleteVenue() async {
    setState(() => _isDeleting = true);
    try {
      await _venueService.deleteVenue(_currentVenue.id!);
      if (_currentVenue.imageUrl.isNotEmpty) {
        final oldFileName =
            _currentVenue.imageUrl.split('/').last.split('?').first;
        if (oldFileName.isNotEmpty) {
          final oldFilePath = "${_currentVenue.id}/$oldFileName";
          await _storageService.deleteFile(
            bucketName: "venue-images",
            fileName: oldFilePath,
          );
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Venue deleted successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, null);
    } catch (e) {
      debugPrint('Delete Venue Error: $e');
      setState(() {
        _errorMessage = 'Failed to delete venue.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting venue: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit "${_currentVenue.name}"'),
        actions: [
          // Bouton d'accès aux permissions
          IconButton(
            icon: const Icon(Icons.add_moderator),
            onPressed: _isUpdating || _isDeleting
                ? null
                : () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserAccessManagementScreen(
                          entityId: _currentVenue.id!,
                          entityType: 'venue',
                        ),
                      ),
                    );
                    if (!mounted) return;
                    setState(() {});
                  },
          ),
          // Bouton delete (visible pour admin et manager, actif uniquement pour admin)
          if (isAdmin || isManager)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isDeleting || _isUpdating
                  ? null
                  : isAdmin
                      ? () async {
                          await _showDeleteConfirmationDialog();
                        }
                      : null,
            ),
          // Bouton save (désactivé en read-only ou pendant le chargement/maj)
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: (_isUpdating || isReadOnly || !_permissionsLoaded)
                ? null
                : _updateVenue,
            color: (_isUpdating || isReadOnly || !_permissionsLoaded)
                ? Colors.grey
                : null,
          ),
        ],
      ),
      body: _isUpdating
          ? const Center(child: CircularProgressIndicator.adaptive())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section Image
                          Center(
                            child: GestureDetector(
                              onTap: isReadOnly ? null : _pickImage,
                              child: Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                        .withValues(alpha: 0.5),
                                    width: 2.0,
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: _selectedImage != null
                                      ? Image.file(
                                          _selectedImage!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: 150,
                                        )
                                      : _currentVenue.imageUrl.isNotEmpty
                                          ? ImageWithErrorHandler(
                                              imageUrl: _currentVenue.imageUrl,
                                              width: 150,
                                              height: 150,
                                              fit: BoxFit.cover,
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
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Champ Nom
                          TextFormField(
                            validator: (value) =>
                                defaultValidator.validate(value),
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Venue Name',
                              border: OutlineInputBorder(),
                            ),
                            readOnly: isReadOnly,
                          ),
                          const SizedBox(height: sectionTitleSpacing),
                          // Champ Description
                          TextFormField(
                            validator: (value) =>
                                defaultValidator.validate(value),
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 4,
                            readOnly: isReadOnly,
                          ),
                          const SizedBox(height: sectionTitleSpacing),
                          // Champ Localisation
                          TextFormField(
                            validator: (value) =>
                                defaultValidator.validate(value),
                            controller: _locationController,
                            focusNode: _locationFocusNode,
                            decoration: const InputDecoration(
                              labelText: 'Location',
                              border: OutlineInputBorder(),
                            ),
                            readOnly: isReadOnly,
                          ),
                          const SizedBox(height: 8),
                          if (_latitude != null && _longitude != null)
                            Text(
                                "Latitude: $_latitude, Longitude: $_longitude"),
                          const SizedBox(height: 20),
                          // Section Genres
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Genres',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: (!_permissionsLoaded || isReadOnly)
                                    ? null
                                    : () async {
                                        final selectedGenres =
                                            Set<int>.from(_selectedGenres);
                                        final bool? saved =
                                            await showModalBottomSheet<bool>(
                                          context: context,
                                          isScrollControlled: true,
                                          builder: (BuildContext context) =>
                                              GenreSelectionBottomSheet(
                                            selectedGenres: selectedGenres,
                                            genreService: _genreService,
                                          ),
                                        );
                                        if (saved == true && mounted) {
                                          setState(() {
                                            _selectedGenres =
                                                selectedGenres.toList();
                                          });
                                        }
                                      },
                              ),
                            ],
                          ),
                          const SizedBox(height: sectionTitleSpacing),
                          if (_selectedGenres.isNotEmpty)
                            Wrap(
                              spacing: 8.0,
                              children: _selectedGenres.map((genreId) {
                                return GenreChip(genreId: genreId);
                              }).toList(),
                            ),
                          const SizedBox(height: 20),
                          // Section Promoteurs
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Promoters',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: isReadOnly
                                    ? null
                                    : () async {
                                        final selectedPromoters =
                                            Set<int>.from(_selectedPromoters);
                                        final bool? saved =
                                            await showModalBottomSheet<bool>(
                                          context: context,
                                          isScrollControlled: true,
                                          builder: (BuildContext context) =>
                                              PromoterSelectionBottomSheet(
                                            selectedPromoters:
                                                selectedPromoters,
                                            promoterService: _promoterService,
                                          ),
                                        );
                                        if (saved == true && mounted) {
                                          setState(() {
                                            _selectedPromoters =
                                                selectedPromoters.toList();
                                          });
                                        }
                                      },
                              ),
                            ],
                          ),
                          const SizedBox(height: sectionTitleSpacing),
                          if (_selectedPromoters.isNotEmpty)
                            Wrap(
                              spacing: 8.0,
                              children: _selectedPromoters.map((promoterId) {
                                return PromoterChip(promoterId: promoterId);
                              }).toList(),
                            ),
                          const SizedBox(height: 20),
                          // Section Artistes Résidents
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Resident Artists',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: isReadOnly
                                    ? null
                                    : () async {
                                        final selectedArtists =
                                            Set<int>.from(_selectedArtists);
                                        final bool? saved =
                                            await showModalBottomSheet<bool>(
                                          context: context,
                                          isScrollControlled: true,
                                          builder: (BuildContext context) =>
                                              ArtistSelectionBottomSheet(
                                            selectedArtists: selectedArtists,
                                            artistService: _artistService,
                                          ),
                                        );
                                        if (saved == true && mounted) {
                                          setState(() {
                                            _selectedArtists =
                                                selectedArtists.toList();
                                          });
                                        }
                                      },
                              ),
                            ],
                          ),
                          const SizedBox(height: sectionTitleSpacing),
                          if (_selectedArtists.isNotEmpty)
                            Wrap(
                              spacing: 8.0,
                              children: _selectedArtists.map((artistId) {
                                return ArtistChip(artistId: artistId);
                              }).toList(),
                            ),
                          const SizedBox(height: 20),
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Bottom sheet for selecting genres
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

      // Trier les genres pour afficher les sélectionnés en premier
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
            content: Text(
                'Erreur lors de la recherche des genres : ${e.toString()}')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
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

    List<Genre> genresToDisplay =
        _showAll ? _genres : _genres.take(_maxGenresToShow).toList();

    return Container(
      height: sheetHeight,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveSelections,
              ),
            ],
          ),
          const SizedBox(height: sectionSpacing),
          const Text(
            'Select Genres',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: sectionSpacing),
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
          const SizedBox(height: sectionSpacing),
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

/// Bottom sheet for selecting promoters
class PromoterSelectionBottomSheet extends StatefulWidget {
  final Set<int> selectedPromoters;
  final PromoterService promoterService;

  const PromoterSelectionBottomSheet({
    required this.selectedPromoters,
    required this.promoterService,
    Key? key,
  }) : super(key: key);

  @override
  _PromoterSelectionBottomSheetState createState() =>
      _PromoterSelectionBottomSheetState();
}

class _PromoterSelectionBottomSheetState
    extends State<PromoterSelectionBottomSheet> {
  List<Promoter> _promoters = [];
  String _searchQuery = '';
  bool _isLoading = false;
  bool _showAll = false;

  static const int _maxPromotersToShow = 10;

  @override
  void initState() {
    super.initState();
    _searchPromoters();
  }

  Future<void> _searchPromoters() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      List<Promoter> promoters;
      if (_searchQuery.isEmpty) {
        promoters = await widget.promoterService.getPromoters();
      } else {
        promoters = await widget.promoterService.searchPromoters(_searchQuery);
      }

      promoters.sort((a, b) {
        bool aSelected = widget.selectedPromoters.contains(a.id);
        bool bSelected = widget.selectedPromoters.contains(b.id);
        if (aSelected && !bSelected) return -1;
        if (!aSelected && bSelected) return 1;
        return a.name.compareTo(b.name);
      });

      if (!mounted) return;
      setState(() {
        _promoters = promoters;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
                'Erreur lors de la recherche des promoteurs : ${e.toString()}')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
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

    List<Promoter> promotersToDisplay =
        _showAll ? _promoters : _promoters.take(_maxPromotersToShow).toList();

    return Container(
      height: sheetHeight,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveSelections,
              ),
            ],
          ),
          const SizedBox(height: sectionSpacing),
          const Text(
            'Select Promoters',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: sectionSpacing),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Search Promoters',
              suffixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              _searchQuery = value;
              _searchPromoters();
            },
          ),
          const SizedBox(height: sectionSpacing),
          _isLoading
              ? const CircularProgressIndicator.adaptive()
              : Expanded(
                  child: _promoters.isEmpty
                      ? const Center(child: Text('No promoters found.'))
                      : ListView.builder(
                          itemCount: promotersToDisplay.length +
                              (_promoters.length > _maxPromotersToShow &&
                                      !_showAll
                                  ? 1
                                  : 0),
                          itemBuilder: (context, index) {
                            if (index < promotersToDisplay.length) {
                              final promoter = promotersToDisplay[index];
                              final isSelected = widget.selectedPromoters
                                  .contains(promoter.id);
                              return CheckboxListTile(
                                value: isSelected,
                                title: Text(promoter.name),
                                onChanged: (bool? value) {
                                  if (!mounted) return;
                                  setState(() {
                                    if (value == true) {
                                      widget.selectedPromoters
                                          .add(promoter.id!);
                                    } else {
                                      widget.selectedPromoters
                                          .remove(promoter.id);
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

/// Bottom sheet for selecting resident artists
class ArtistSelectionBottomSheet extends StatefulWidget {
  final Set<int> selectedArtists;
  final ArtistService artistService;

  const ArtistSelectionBottomSheet({
    required this.selectedArtists,
    required this.artistService,
    Key? key,
  }) : super(key: key);

  @override
  _ArtistSelectionBottomSheetState createState() =>
      _ArtistSelectionBottomSheetState();
}

class _ArtistSelectionBottomSheetState
    extends State<ArtistSelectionBottomSheet> {
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
    setState(() {
      _isLoading = true;
    });

    try {
      List<Artist> artists;
      if (_searchQuery.isEmpty) {
        artists = await widget.artistService.getArtists();
      } else {
        artists = await widget.artistService.searchArtists(_searchQuery);
      }

      artists.sort((a, b) {
        bool aSelected = widget.selectedArtists.contains(a.id);
        bool bSelected = widget.selectedArtists.contains(b.id);
        if (aSelected && !bSelected) return -1;
        if (!aSelected && bSelected) return 1;
        return a.name.compareTo(b.name);
      });

      if (!mounted) return;
      setState(() {
        _artists = artists;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
                'Erreur lors de la recherche des artistes : ${e.toString()}')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
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

    List<Artist> artistsToDisplay =
        _showAll ? _artists : _artists.take(_maxArtistsToShow).toList();

    return Container(
      height: sheetHeight,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveSelections,
              ),
            ],
          ),
          const SizedBox(height: sectionSpacing),
          const Text(
            'Select Resident Artists',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: sectionSpacing),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Search Artists',
              suffixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              _searchQuery = value;
              _searchArtists();
            },
          ),
          const SizedBox(height: sectionSpacing),
          _isLoading
              ? const CircularProgressIndicator.adaptive()
              : Expanded(
                  child: _artists.isEmpty
                      ? const Center(child: Text('No artists found.'))
                      : ListView.builder(
                          itemCount: artistsToDisplay.length +
                              (_artists.length > _maxArtistsToShow && !_showAll
                                  ? 1
                                  : 0),
                          itemBuilder: (context, index) {
                            if (index < artistsToDisplay.length) {
                              final artist = artistsToDisplay[index];
                              final isSelected =
                                  widget.selectedArtists.contains(artist.id!);
                              return CheckboxListTile(
                                value: isSelected,
                                title: Text(artist.name),
                                onChanged: (bool? value) {
                                  if (!mounted) return;
                                  setState(() {
                                    if (value == true) {
                                      widget.selectedArtists.add(artist.id!);
                                    } else {
                                      widget.selectedArtists.remove(artist.id!);
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
