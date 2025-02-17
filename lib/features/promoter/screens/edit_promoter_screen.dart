// lib/features/promoter/screens/edit_promoter_screen.dart

import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // pour listEquals
import 'package:image_picker/image_picker.dart';
import 'package:sway/core/utils/validators.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/genre/models/genre_model.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/promoter/services/promoter_service.dart';
import 'package:sway/features/user/screens/user_access_management_screen.dart';
import 'package:sway/features/user/services/user_permission_service.dart';
import 'package:sway/features/user/services/user_service.dart';
import 'package:sway/features/promoter/services/promoter_genre_service.dart';
import 'package:sway/features/promoter/services/promoter_resident_artists_service.dart';
import 'package:sway/features/genre/widgets/genre_chip.dart';
import 'package:sway/features/artist/widgets/artist_chip.dart';
import 'package:sway/features/genre/services/genre_service.dart';
import 'package:sway/features/artist/services/artist_service.dart';
import 'package:sway/features/security/services/storage_service.dart';
import 'package:sway/core/constants/dimensions.dart';

class EditPromoterScreen extends StatefulWidget {
  final Promoter promoter;

  const EditPromoterScreen({required this.promoter, Key? key})
      : super(key: key);

  @override
  _EditPromoterScreenState createState() => _EditPromoterScreenState();
}

class _EditPromoterScreenState extends State<EditPromoterScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  final PromoterService _promoterService = PromoterService();
  final PromoterGenreService _promoterGenreService = PromoterGenreService();
  final PromoterResidentArtistsService _promoterArtistService =
      PromoterResidentArtistsService();
  final UserPermissionService _permissionService = UserPermissionService();
  final UserService _userService = UserService();
  final GenreService _genreService = GenreService();
  final ArtistService _artistService = ArtistService();
  final StorageService _storageService = StorageService();

  // Listes des associations
  List<int> _selectedGenres = [];
  List<int> _selectedArtists = [];
  List<int> _initialGenres = [];
  List<int> _initialArtists = [];

  bool _isLoading = false;
  bool _isDeleting = false;
  String? _errorMessage;
  File? _selectedImage;

  late Promoter _currentPromoter;
  final _formKey = GlobalKey<FormState>();

  // Variables de permission
  bool isAdmin = false;
  bool isManager = false;
  bool isReadOnly = false;
  bool _permissionsLoaded = false;

  // Instance of the global validator used for text fields.
  // It will be updated with the combined forbiddenWords (French + English).
  late FieldValidator defaultValidator;

  @override
  void initState() {
    super.initState();
    _currentPromoter = widget.promoter;
    _nameController = TextEditingController(text: _currentPromoter.name);
    _descriptionController =
        TextEditingController(text: _currentPromoter.description);
    _loadUserPermissions();
    _loadAssociatedData();

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
    // Vérifier les permissions pour un promoter
    final admin = await _permissionService.hasPermissionForCurrentUser(
      _currentPromoter.id!,
      'promoter',
      3,
    );
    final manager = await _permissionService.hasPermissionForCurrentUser(
      _currentPromoter.id!,
      'promoter',
      2,
    );
    setState(() {
      isAdmin = admin;
      isManager = (!admin && manager);
      isReadOnly = (!admin && !manager);
      _permissionsLoaded = true;
    });
  }

  Future<void> _loadAssociatedData() async {
    setState(() => _isLoading = true);
    try {
      // Charger les genres associés au promoter
      final genres = await _promoterGenreService
          .getGenresByPromoterId(_currentPromoter.id!);
      setState(() {
        _selectedGenres = List.from(genres);
        _initialGenres = List.from(genres);
      });
      // Charger les resident artists associés au promoter
      final artists = await _promoterArtistService
          .getArtistsByPromoterId(_currentPromoter.id!);
      setState(() {
        _selectedArtists = artists.map((artist) => artist.id!).toList();
        _initialArtists = List.from(_selectedArtists);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des données: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
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

  Future<String> _uploadImage(int promoterId, File imageFile) async {
    final fileBytes = await imageFile.readAsBytes();
    final fileExtension = imageFile.path.split('.').last;
    final fileName = "${DateTime.now().millisecondsSinceEpoch}.$fileExtension";
    final filePath = "$promoterId/$fileName";

    final publicUrl = await _storageService.uploadFile(
      bucketName: "promoter-images",
      fileName: filePath,
      fileData: fileBytes,
    );
    return publicUrl;
  }

  Future<void> _updatePromoter() async {
    if (!_formKey.currentState!.validate()) return;

    final newName = _nameController.text.trim();
    final newDescription = _descriptionController.text.trim();

    final bool isNameChanged = newName != _currentPromoter.name;
    final bool isDescriptionChanged =
        newDescription != _currentPromoter.description;
    final bool isImageChanged = _selectedImage != null;
    final bool isGenresChanged = !listEquals(_selectedGenres, _initialGenres);
    final bool isArtistsChanged =
        !listEquals(_selectedArtists, _initialArtists);

    if (!isNameChanged &&
        !isDescriptionChanged &&
        !isImageChanged &&
        !isGenresChanged &&
        !isArtistsChanged) {
      Navigator.pop(context, _currentPromoter);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String updatedImageUrl = _currentPromoter.imageUrl;
      if (isImageChanged) {
        updatedImageUrl =
            await _uploadImage(_currentPromoter.id!, _selectedImage!);
        if (_currentPromoter.imageUrl.isNotEmpty) {
          final oldFileName =
              _currentPromoter.imageUrl.split('/').last.split('?').first;
          if (oldFileName.isNotEmpty) {
            final oldFilePath = "${_currentPromoter.id}/$oldFileName";
            await _storageService.deleteFile(
              bucketName: "promoter-images",
              fileName: oldFilePath,
            );
          }
        }
      }

      Promoter updatedPromoter = _currentPromoter.copyWith(
        name: isNameChanged ? newName : null,
        description: isDescriptionChanged ? newDescription : null,
        imageUrl: isImageChanged ? updatedImageUrl : null,
      );

      if (isNameChanged || isDescriptionChanged || isImageChanged) {
        updatedPromoter =
            await _promoterService.updatePromoter(updatedPromoter);
        setState(() {
          _currentPromoter = updatedPromoter;
          _selectedImage = null;
        });
      }

      if (isGenresChanged) {
        await _promoterGenreService.updatePromoterGenres(
            _currentPromoter.id!, _selectedGenres);
        setState(() {
          _initialGenres = List.from(_selectedGenres);
        });
      }
      if (isArtistsChanged) {
        await _promoterArtistService.updatePromoterArtists(
            _currentPromoter.id!, _selectedArtists);
        setState(() {
          _initialArtists = List.from(_selectedArtists);
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Promoter updated successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, updatedPromoter);
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating promoter: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showDeleteConfirmationDialog() async {
    // Seul l'admin peut supprimer le promoter
    final isAllowedToDelete =
        await _permissionService.hasPermissionForCurrentUser(
      _currentPromoter.id!,
      'promoter',
      3,
    );
    if (!isAllowedToDelete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to delete this promoter.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this promoter?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await _deletePromoter();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePromoter() async {
    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });
    try {
      // Suppression optionnelle de l'image associée
      final oldFileName =
          _currentPromoter.imageUrl.split('/').last.split('?').first;
      if (oldFileName.isNotEmpty) {
        final oldFilePath = "${_currentPromoter.id}/$oldFileName";
        await _storageService.deleteFile(
          bucketName: "promoter-images",
          fileName: oldFilePath,
        );
      }
      await _promoterService.deletePromoter(_currentPromoter.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Promoter deleted successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, null);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to delete promoter.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
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
        title: Text('Edit "${_currentPromoter.name}"'),
        actions: [
          // Bouton d'accès à la gestion des permissions
          IconButton(
            icon: const Icon(Icons.add_moderator),
            onPressed: _isLoading || _isDeleting
                ? null
                : () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserAccessManagementScreen(
                          entityId: _currentPromoter.id!,
                          entityType: 'promoter',
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
              onPressed: _isDeleting || _isLoading
                  ? null
                  : isAdmin
                      ? () async {
                          await _showDeleteConfirmationDialog();
                        }
                      : null,
            ),
          // Bouton save
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: (_isLoading || isReadOnly || !_permissionsLoaded)
                ? null
                : _updatePromoter,
            color: (_isLoading || isReadOnly || !_permissionsLoaded)
                ? Colors.grey
                : null,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Image : L'image est cliquable pour changer, mais si l'utilisateur est read-only, l'icône d'édition n'est pas affichée
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
                                  color: Colors.black.withValues(alpha: 0.1),
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
                                  : _currentPromoter.imageUrl.isNotEmpty
                                      ? ImageWithErrorHandler(
                                          imageUrl: _currentPromoter.imageUrl,
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
                        validator: (value) => defaultValidator.validate(value),
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                        ),
                        readOnly: isReadOnly,
                      ),
                      const SizedBox(height: sectionTitleSpacing),
                      // Champ Description
                      TextFormField(
                        validator: (value) => defaultValidator.validate(value),
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        readOnly: isReadOnly,
                      ),
                      const SizedBox(height: 20),
                      // Section Genres avec IconButton uniformisé
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
                      // Section Promoteurs avec IconButton uniformisé
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

      // Sort genres to show selected first
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
    Navigator.of(context).pop(true); // Return true to indicate save
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the height: just below the status bar
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double sheetHeight = min(screenHeight * 0.5,
        screenHeight - statusBarHeight - 100); // Adjust accordingly

    // Determine genres to display based on _showAll
    List<Genre> genresToDisplay =
        _showAll ? _genres : _genres.take(_maxGenresToShow).toList();

    return Container(
      height: sheetHeight,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Header with cancel and save icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop(false); // Cancel and close
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
                              // Show "Show More" button
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

/// Bottom sheet for selecting artists
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

  static const int _maxArtistsToShow = 5;

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

      // Sort artists to show selected first
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
            content: Text('Error searching artists: ${e.toString()}')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _saveSelections() {
    Navigator.of(context).pop(true); // Return true to indicate save
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the height: just below the status bar
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double sheetHeight = min(screenHeight * 0.5,
        screenHeight - statusBarHeight - 100); // Adjust accordingly

    // Determine artists to display based on _showAll
    List<Artist> artistsToDisplay =
        _showAll ? _artists : _artists.take(_maxArtistsToShow).toList();

    return Container(
      height: sheetHeight,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Header with cancel and save icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop(false); // Cancel and close
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
            'Select Resident Artists',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: sectionTitleSpacing),
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
          const SizedBox(height: sectionTitleSpacing),
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
                              // Show "Show More" button
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
