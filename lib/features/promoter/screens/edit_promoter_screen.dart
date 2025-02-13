// lib/features/promoter/screens/edit_promoter_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Import pour listEquals
import 'package:image_picker/image_picker.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/genre/models/genre_model.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/promoter/services/promoter_service.dart';
import 'package:sway/features/user/models/user_permission_model.dart';
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
import 'package:sway/core/constants/dimensions.dart'; // Import spacing constants
import 'dart:math'; // For min

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
  final UserService _userService = UserService(); // Added UserService
  final GenreService _genreService = GenreService();
  final ArtistService _artistService = ArtistService();
  final StorageService _storageService =
      StorageService(); // Added StorageService

  List<int> _selectedGenres = [];
  List<int> _selectedArtists = [];
  List<int> _initialGenres = [];
  List<int> _initialArtists = [];

  bool _isLoading = false;
  bool _isDeleting = false; // To manage deletion state
  String? _errorMessage;

  final _formKey = GlobalKey<FormState>();

  late Promoter _currentPromoter; // State variable for the promoter

  File? _selectedImage; // Image sélectionnée pour mise à jour

  @override
  void initState() {
    super.initState();
    _currentPromoter = widget.promoter; // Initialize the state variable
    _nameController = TextEditingController(text: _currentPromoter.name);
    _descriptionController =
        TextEditingController(text: _currentPromoter.description);
    _loadAssociatedData();
  }

  Future<void> _loadAssociatedData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      // Load associated genres
      final genres = await _promoterGenreService
          .getGenresByPromoterId(_currentPromoter.id!);
      if (!mounted) return;
      setState(() {
        _selectedGenres = genres;
        _initialGenres = List.from(genres);
      });

      // Load associated resident artists
      final artists = await _promoterArtistService
          .getArtistsByPromoterId(_currentPromoter.id!);
      if (!mounted) return;
      setState(() {
        _selectedArtists = artists.map((artist) => artist.id!).toList();
        _initialArtists = List.from(_selectedArtists);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Error loading data: ${e.toString()}')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Method to select a new promoter image
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path); // Update selected image
      });
    }
  }

  /// Method to upload the selected image and get the public URL
  Future<String> _uploadImage(int promoterId, File imageFile) async {
    // Read the file bytes
    final fileBytes = await imageFile.readAsBytes();

    // Generate a unique file name
    final fileExtension = imageFile.path.split('.').last;
    final fileName =
        "${DateTime.now().millisecondsSinceEpoch}.$fileExtension"; // Ex: "1627891234567.jpg"

    // Build the complete file path
    final filePath = "$promoterId/$fileName"; // Ex: "17/1627891234567.jpg"

    // Upload to the "promoter-images" bucket
    final publicUrl = await _storageService.uploadFile(
      bucketName: "promoter-images",
      fileName: filePath, // Use the complete path here
      fileData: fileBytes,
    );

    print('Image Uploaded: $publicUrl');
    return publicUrl;
  }

  /// Method to update promoter details, including the image
  Future<void> _updatePromoter() async {
    if (!_formKey.currentState!.validate()) {
      // If validation fails, do not proceed
      return;
    }

    final newName = _nameController.text.trim();
    final newDescription = _descriptionController.text.trim();

    // Check if any changes have been made
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
      // Nothing to update
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
        // Upload the new image and get the URL
        updatedImageUrl =
            await _uploadImage(_currentPromoter.id!, _selectedImage!);

        // (Optional) Delete the old image if necessary
        final oldFileName =
            _currentPromoter.imageUrl.split('/').last.split('?').first;
        if (oldFileName.isNotEmpty) {
          final oldFilePath = "${_currentPromoter.id}/$oldFileName";
          await _storageService.deleteFile(
            bucketName: "promoter-images",
            fileName: oldFilePath,
          );
          print('Old Image Deleted: $oldFilePath');
        }
      }

      // Create the updated Promoter object
      Promoter updatedPromoter = _currentPromoter.copyWith(
        name: isNameChanged ? newName : null,
        description: isDescriptionChanged ? newDescription : null,
        imageUrl: isImageChanged ? updatedImageUrl : null,
      );

      // Update the promoter via PromoterService if necessary
      if (isNameChanged || isDescriptionChanged || isImageChanged) {
        updatedPromoter =
            await _promoterService.updatePromoter(updatedPromoter);
        setState(() {
          _currentPromoter = updatedPromoter; // Update local state
          _selectedImage = null; // Reset selected image
        });
      }

      // Update associated genres if necessary
      if (isGenresChanged) {
        await _promoterGenreService.updatePromoterGenres(
            _currentPromoter.id!, _selectedGenres);
        setState(() {
          _initialGenres = List.from(_selectedGenres);
        });
      }

      // Update associated resident artists if necessary
      if (isArtistsChanged) {
        await _promoterArtistService.updatePromoterArtists(
            _currentPromoter.id!, _selectedArtists);
        setState(() {
          _initialArtists = List.from(_selectedArtists);
        });
      }

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Promoter updated successfully!'),
        behavior: SnackBarBehavior.floating,
      ));

      Navigator.pop(context, updatedPromoter);
    } catch (e) {
      print('Update Promoter Error: $e');
      setState(() {
        _errorMessage = 'An unexpected error occurred.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Retrieves the current user's permission for the promoter
  Future<UserPermission?> _getCurrentUserPermission() async {
    final currentUser = await _userService.getCurrentUser(); // Use UserService
    if (currentUser == null) return null;

    final permissions = await _permissionService.getPermissionsByUserIdAndType(
        currentUser.id, 'promoter');

    for (var permission in permissions) {
      if (permission.entityId == _currentPromoter.id!) {
        return permission;
      }
    }

    return null;
  }

  /// Method to display the genre selection bottom sheet
  Future<void> _showSelectGenresBottomSheet() async {
    try {
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
        ),
      );

      if (saved == true) {
        if (!mounted) return;
        setState(() {
          _selectedGenres = selectedGenres.toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Error loading genres: ${e.toString()}')),
      );
    }
  }

  /// Method to display the artist selection bottom sheet
  Future<void> _showSelectArtistsBottomSheet() async {
    try {
      final selectedArtists = Set<int>.from(_selectedArtists);
      final bool? saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return ArtistSelectionBottomSheet(
            selectedArtists: selectedArtists,
            artistService: _artistService,
          );
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
        ),
      );

      if (saved == true) {
        if (!mounted) return;
        setState(() {
          _selectedArtists = selectedArtists.toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Error loading artists: ${e.toString()}')),
      );
    }
  }

  /// Build the promoter editing form.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Supprimer le bouton "Manage Permissions" en bas
      appBar: AppBar(
        title: Text('Edit "${_currentPromoter.name}"'), // Use state variable
        actions: [
          IconButton(
            icon: const Icon(
                Icons.add_moderator), // Conserver l'icône "add_moderator"
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
          IconButton(
            icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.save),
            onPressed: _isLoading || _isDeleting ? null : _updatePromoter,
          ),
          IconButton(
            icon: _isDeleting
                ? const SizedBox.shrink()
                : const Icon(Icons.delete),
            onPressed: _isDeleting || _isLoading
                ? null
                : () async {
                    final permission = await _getCurrentUserPermission();
                    if (permission != null &&
                        permission.permission == 'admin') {
                      await _showDeleteConfirmationDialog();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'You do not have permission to delete this promoter.'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey, // Added Form
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Picker and Preview (Forme carrée)
                      Center(
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap:
                                  _isLoading || _isDeleting ? null : _pickImage,
                              child: Container(
                                width: 150, // Taille carrée
                                height: 150,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                        .withValues(alpha: 0.5), // Border color
                                    width: 2.0, // Border thickness
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      15), // Rounded corners
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
                                      : ImageWithErrorHandler(
                                          imageUrl: _currentPromoter.imageUrl,
                                          width: 150,
                                          height: 150,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _isLoading || _isDeleting
                                    ? null
                                    : _pickImage,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: sectionSpacing),
                      // Champ Nom du Promoteur avec validation
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the promoter name.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: sectionSpacing),
                      // Champ Description du Promoteur avec validation
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a description.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: sectionSpacing),
                      // Genres Section
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
                          ElevatedButton(
                            onPressed: _showSelectGenresBottomSheet,
                            child: const Icon(Icons.edit),
                          ),
                        ],
                      ),
                      const SizedBox(height: sectionTitleSpacing),
                      if (_selectedGenres.isNotEmpty) // Hide if no genres
                        Wrap(
                          spacing: 8.0,
                          children: _selectedGenres.map((genreId) {
                            return GenreChip(
                              genreId: genreId,
                              // Removed onTap to prevent direct editing
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: sectionSpacing),
                      // Resident Artists Section
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
                          ElevatedButton(
                            onPressed: _showSelectArtistsBottomSheet,
                            child: const Icon(Icons.edit),
                          ),
                        ],
                      ),
                      const SizedBox(height: sectionTitleSpacing),
                      if (_selectedArtists.isNotEmpty) // Hide if no artists
                        Wrap(
                          spacing: 8.0,
                          children: _selectedArtists.map((artistId) {
                            return ArtistChip(
                              artistId: artistId,
                              // Removed onTap to prevent direct editing and hide delete icon
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: sectionSpacing),
                      // Display an error message if necessary
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      // Supprimer le bouton "Manage Permissions" ici
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  /// Method to display the deletion confirmation dialog
  Future<void> _showDeleteConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible:
          false, // The user must tap a button to dismiss the dialog
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
                Navigator.of(context).pop(); // Close the dialog first
                await _deletePromoter();
              },
            ),
          ],
        );
      },
    );
  }

  /// Method to delete the promoter
  Future<void> _deletePromoter() async {
    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      // (Optional) Delete the associated image first
      final oldFileName =
          _currentPromoter.imageUrl.split('/').last.split('?').first;
      if (oldFileName.isNotEmpty) {
        final oldFilePath = "${_currentPromoter.id}/$oldFileName";
        await _storageService.deleteFile(
          bucketName: "promoter-images",
          fileName: oldFilePath,
        );
        print('Promoter ${_currentPromoter.id} Image Deleted: $oldFilePath');
      }

      // Delete the promoter
      await _promoterService.deletePromoter(_currentPromoter.id!);

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Promoter deleted successfully!'),
        behavior: SnackBarBehavior.floating,
      ));

      Navigator.pop(context, null); // Return null to indicate deletion
    } catch (e) {
      print('Delete Promoter Error: $e');
      setState(() {
        _errorMessage = 'Failed to delete promoter.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
      });
    }
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
