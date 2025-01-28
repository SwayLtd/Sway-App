// lib/features/venue/screens/edit_venue_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Import pour listEquals
import 'package:image_picker/image_picker.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/genre/models/genre_model.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/security/services/storage_service.dart';
import 'package:sway/features/user/screens/user_access_management_screen.dart';
import 'package:sway/features/user/services/user_permission_service.dart';
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
import 'dart:math';

class EditVenueScreen extends StatefulWidget {
  final Venue venue;

  const EditVenueScreen({required this.venue, Key? key}) : super(key: key);

  @override
  _EditVenueScreenState createState() => _EditVenueScreenState();
}

class _EditVenueScreenState extends State<EditVenueScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;

  final VenueService _venueService = VenueService();
  final VenueGenreService _venueGenreService = VenueGenreService();
  final VenuePromoterService _venuePromoterService = VenuePromoterService();
  final VenueResidentArtistsService _venueResidentArtistsService =
      VenueResidentArtistsService();
  final StorageService _storageService = StorageService();
  final UserPermissionService _permissionService = UserPermissionService();
  final GenreService _genreService = GenreService();
  final PromoterService _promoterService = PromoterService();
  final ArtistService _artistService = ArtistService();

  List<int> _selectedGenres = [];
  List<int> _selectedPromoters = [];
  List<int> _selectedArtists = [];

  List<int> _initialGenres = [];
  List<int> _initialPromoters = [];
  List<int> _initialArtists = [];

  bool _isUpdating = false;
  bool _isDeleting = false; // To manage deletion state
  String? _errorMessage;

  final _formKey = GlobalKey<FormState>();

  late Venue _currentVenue; // Variable d'état pour la venue

  File? _selectedImage; // Image sélectionnée pour mise à jour

  @override
  void initState() {
    super.initState();
    _currentVenue = widget.venue; // Initialize the state variable
    _nameController = TextEditingController(text: _currentVenue.name);
    _descriptionController =
        TextEditingController(text: _currentVenue.description);
    _locationController = TextEditingController(text: _currentVenue.location);
    _loadAssociatedData(); // Charger les données associées
  }

  Future<void> _loadAssociatedData() async {
    if (!mounted) return;
    setState(() {
      _isUpdating = true;
    });

    try {
      // Charger les genres associés
      final genres =
          await _venueGenreService.getGenresByVenueId(_currentVenue.id!);
      if (!mounted) return;
      setState(() {
        _selectedGenres = genres;
        _initialGenres = List.from(genres);
      });

      // Charger les promoteurs associés
      final promoters =
          await _venuePromoterService.getPromotersByVenueId(_currentVenue.id!);
      if (!mounted) return;
      setState(() {
        _selectedPromoters = promoters.map((promoter) => promoter.id!).toList();
        _initialPromoters = List.from(_selectedPromoters);
      });

      // Charger les artistes résidents associés
      final artists = await _venueResidentArtistsService
          .getArtistsByVenueId(_currentVenue.id!);
      if (!mounted) return;
      setState(() {
        _selectedArtists = artists.map((artist) => artist.id).toList();
        _initialArtists = List.from(_selectedArtists);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
                'Erreur lors du chargement des données : ${e.toString()}')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  /// Méthode pour sélectionner une nouvelle image de venue
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

  /// Méthode pour télécharger l'image sélectionnée et obtenir l'URL publique
  Future<String> _uploadImage(int venueId, File imageFile) async {
    // Lire les octets du fichier
    final fileBytes = await imageFile.readAsBytes();

    // Générer un nom de fichier unique
    final fileExtension = imageFile.path.split('.').last;
    final fileName =
        "${DateTime.now().millisecondsSinceEpoch}.$fileExtension"; // Ex: "1627891234567.jpg"

    // Construire le chemin complet du fichier
    final filePath = "$venueId/$fileName"; // Ex: "venue-id/1627891234567.jpg"

    // Uploader dans le bucket "venue-images"
    final publicUrl = await _storageService.uploadFile(
      bucketName: "venue-images",
      fileName: filePath, // Utilisez le chemin complet ici
      fileData: fileBytes,
    );

    print('Image Uploaded: $publicUrl');
    return publicUrl;
  }

  /// Méthode pour mettre à jour les détails de la venue, y compris l'image
  Future<void> _updateVenue() async {
    if (!_formKey.currentState!.validate()) {
      // Si la validation échoue, ne pas procéder
      return;
    }

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
      // Rien à mettre à jour
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
        // Télécharger la nouvelle image et obtenir l'URL
        updatedImageUrl =
            await _uploadImage(_currentVenue.id!, _selectedImage!);

        // (Optionnel) Supprimer l'ancienne image si nécessaire
        final oldFileName =
            _currentVenue.imageUrl.split('/').last.split('?').first;
        if (oldFileName.isNotEmpty) {
          final oldFilePath = "${_currentVenue.id}/$oldFileName";
          await _storageService.deleteFile(
            bucketName: "venue-images",
            fileName: oldFilePath,
          );
          print('Old Image Deleted: $oldFilePath');
        }
      }

      // Créer l'objet Venue mis à jour
      Venue updatedVenue = _currentVenue.copyWith(
        name: isNameChanged ? newName : null,
        description: isDescriptionChanged ? newDescription : null,
        location: isLocationChanged ? newLocation : null,
        imageUrl: isImageChanged ? updatedImageUrl : null,
      );

      // Mettre à jour la venue via VenueService si nécessaire
      if (isNameChanged ||
          isDescriptionChanged ||
          isLocationChanged ||
          isImageChanged) {
        updatedVenue = await _venueService.updateVenue(updatedVenue);
        setState(() {
          _currentVenue = updatedVenue; // Mettre à jour l'état local
          _selectedImage = null; // Réinitialiser l'image sélectionnée
        });
      }

      // Mettre à jour les genres associés si nécessaire
      if (isGenresChanged) {
        await _venueGenreService.updateVenueGenres(
            _currentVenue.id!, _selectedGenres);
        setState(() {
          _initialGenres = List.from(_selectedGenres);
        });
      }

      // Mettre à jour les promoteurs associés si nécessaire
      if (isPromotersChanged) {
        await _venuePromoterService.updateVenuePromoters(
            _currentVenue.id!, _selectedPromoters);
        setState(() {
          _initialPromoters = List.from(_selectedPromoters);
        });
      }

      // Mettre à jour les artistes résidents associés si nécessaire
      if (isArtistsChanged) {
        await _venueResidentArtistsService.updateVenueArtists(
            _currentVenue.id!, _selectedArtists);
        setState(() {
          _initialArtists = List.from(_selectedArtists);
        });
      }

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Venue updated successfully!'),
        behavior: SnackBarBehavior.floating,
      ));

      Navigator.pop(context, updatedVenue);
    } catch (e) {
      print('Update Venue Error: $e');
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
        _isUpdating = false;
      });
    }
  }

  /// Method to display the deletion confirmation dialog
  Future<void> _showDeleteConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible:
          false, // L'utilisateur doit appuyer sur un bouton pour fermer
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this venue?'),
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
                Navigator.of(context).pop(); // Fermer le dialog d'abord
                await _deleteVenue();
              },
            ),
          ],
        );
      },
    );
  }

  /// Méthode pour supprimer la venue
  Future<void> _deleteVenue() async {
    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      await _venueService.deleteVenue(_currentVenue.id!);

      // (Optionnel) Supprimer l'image associée
      final oldFileName =
          _currentVenue.imageUrl.split('/').last.split('?').first;
      if (oldFileName.isNotEmpty) {
        final oldFilePath = "${_currentVenue.id}/$oldFileName";
        await _storageService.deleteFile(
          bucketName: "venue-images",
          fileName: oldFilePath,
        );
        print('Venue ${_currentVenue.id} Image Deleted: $oldFilePath');
      }

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Venue deleted successfully!'),
        behavior: SnackBarBehavior.floating,
      ));

      Navigator.pop(
          context, null); // Retourner null pour indiquer la suppression
    } catch (e) {
      print('Delete Venue Error: $e');
      setState(() {
        _errorMessage = 'Failed to delete venue.';
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

  /// Méthode pour gérer la mise à jour des permissions via un autre écran
  Future<void> _managePermissions() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserAccessManagementScreen(
          entityId: _currentVenue.id!,
          entityType: 'venue',
        ),
      ),
    );
    // Rafraîchir l'état après retour
    if (mounted) {
      setState(() {});
    }
  }

  /// Méthode pour afficher et gérer les permissions (bouton)
  Widget _buildPermissionButton() {
    return FutureBuilder<bool>(
      future: _permissionService.hasPermissionForCurrentUser(
        _currentVenue.id!,
        'venue',
        'admin',
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        } else if (snapshot.hasError || !snapshot.hasData || !snapshot.data!) {
          return const SizedBox.shrink();
        } else {
          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: ElevatedButton.icon(
              onPressed: _isUpdating || _isDeleting ? null : _managePermissions,
              icon: const Icon(Icons.group),
              label: const Text('Manage Permissions'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          );
        }
      },
    );
  }

  /// Méthode pour afficher le bottom sheet de sélection des genres
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

  /// Méthode pour afficher le bottom sheet de sélection des promoteurs
  Future<void> _showSelectPromotersBottomSheet() async {
    try {
      final selectedPromoters = Set<int>.from(_selectedPromoters);
      final bool? saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return PromoterSelectionBottomSheet(
            selectedPromoters: selectedPromoters,
            promoterService: _promoterService,
          );
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
        ),
      );

      if (saved == true) {
        if (!mounted) return;
        setState(() {
          _selectedPromoters = selectedPromoters.toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Error loading promoters: ${e.toString()}')),
      );
    }
  }

  /// Méthode pour afficher le bottom sheet de sélection des artistes
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

  /// Build the venue editing form.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit "${_currentVenue.name}"'),
        actions: [
          IconButton(
            icon: _isUpdating
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save),
            onPressed: _isUpdating || _isDeleting ? null : _updateVenue,
          ),
          IconButton(
            icon: _isDeleting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.delete),
            onPressed: _isDeleting ? null : _showDeleteConfirmationDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Contenu défilable
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  // Enveloppement du contenu dans un Form
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image et bouton d'édition
                      Center(
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap: _isUpdating || _isDeleting
                                  ? null
                                  : _pickImage,
                              child: Container(
                                width: 150, // Taille de l'image
                                height: 150,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                        .withOpacity(
                                            0.5), // Couleur de la bordure
                                    width: 2.0, // Épaisseur de la bordure
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      15), // Coins arrondis
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                      12), // Assurer les coins arrondis
                                  child: _selectedImage != null
                                      ? Image.file(
                                          _selectedImage!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: 150,
                                        )
                                      : ImageWithErrorHandler(
                                          imageUrl: _currentVenue.imageUrl,
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
                                onTap: _isUpdating || _isDeleting
                                    ? null
                                    : _pickImage,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.blue, // Couleur de l'icône
                                    shape: BoxShape
                                        .circle, // Forme circulaire pour l'icône
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 5,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
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
                      const SizedBox(height: 20),
                      // Champ Nom de la Venue avec validation
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Venue Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the venue name.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      // Champ Description de la Venue avec validation
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
                      const SizedBox(height: 10),
                      // Champ Localisation de la Venue avec validation
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the location.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

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
                      const SizedBox(height: 10),
                      if (_selectedGenres.isNotEmpty)
                        Wrap(
                          spacing: 8.0,
                          children: _selectedGenres.map((genreId) {
                            return GenreChip(
                              genreId: genreId,
                              // Vous pouvez ajouter des fonctionnalités supplémentaires si nécessaire
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 20),

                      // Promoteurs Section
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
                          ElevatedButton(
                            onPressed: _showSelectPromotersBottomSheet,
                            child: const Icon(Icons.edit),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_selectedPromoters.isNotEmpty)
                        Wrap(
                          spacing: 8.0,
                          children: _selectedPromoters.map((promoterId) {
                            return PromoterChip(
                              promoterId: promoterId,
                              // Vous pouvez ajouter des fonctionnalités supplémentaires si nécessaire
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 20),

                      // Artistes Résidents Section
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
                      const SizedBox(height: 10),
                      if (_selectedArtists.isNotEmpty)
                        Wrap(
                          spacing: 8.0,
                          children: _selectedArtists.map((artistId) {
                            return ArtistChip(
                              artistId: artistId,
                              // Vous pouvez ajouter des fonctionnalités supplémentaires si nécessaire
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 20),

                      // Afficher un message d'erreur si nécessaire
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      // Bouton pour gérer les permissions
                      _buildPermissionButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Bouton de suppression en bas
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isDeleting || _isUpdating
                    ? null
                    : _showDeleteConfirmationDialog,
                icon: _isDeleting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.delete, color: Colors.white),
                label: const Text('Delete Venue'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // Couleur du bouton
                  minimumSize: const Size.fromHeight(50),
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
    Navigator.of(context)
        .pop(true); // Retourner true pour indiquer la sauvegarde
  }

  @override
  Widget build(BuildContext context) {
    // Calculer la hauteur
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double sheetHeight = min(screenHeight * 0.5,
        screenHeight - statusBarHeight - 100); // Ajuster selon besoin

    // Déterminer les genres à afficher en fonction de _showAll
    List<Genre> genresToDisplay =
        _showAll ? _genres : _genres.take(_maxGenresToShow).toList();

    return Container(
      height: sheetHeight,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // En-tête avec les icônes annuler et sauvegarder
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop(false); // Annuler et fermer
                },
              ),
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveSelections,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Select Genres',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
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
          const SizedBox(height: 20),
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
                              // Bouton "Show More"
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

      // Trier les promoteurs pour afficher les sélectionnés en premier
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
    Navigator.of(context)
        .pop(true); // Retourner true pour indiquer la sauvegarde
  }

  @override
  Widget build(BuildContext context) {
    // Calculer la hauteur
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double sheetHeight = min(screenHeight * 0.5,
        screenHeight - statusBarHeight - 100); // Ajuster selon besoin

    // Déterminer les promoteurs à afficher en fonction de _showAll
    List<Promoter> promotersToDisplay =
        _showAll ? _promoters : _promoters.take(_maxPromotersToShow).toList();

    return Container(
      height: sheetHeight,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // En-tête avec les icônes annuler et sauvegarder
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop(false); // Annuler et fermer
                },
              ),
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveSelections,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Select Promoters',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
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
          const SizedBox(height: 20),
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
                              // Bouton "Show More"
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

      // Trier les artistes pour afficher les sélectionnés en premier
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
    Navigator.of(context)
        .pop(true); // Retourner true pour indiquer la sauvegarde
  }

  @override
  Widget build(BuildContext context) {
    // Calculer la hauteur
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double sheetHeight = min(screenHeight * 0.5,
        screenHeight - statusBarHeight - 100); // Ajuster selon besoin

    // Déterminer les artistes à afficher en fonction de _showAll
    List<Artist> artistsToDisplay =
        _showAll ? _artists : _artists.take(_maxArtistsToShow).toList();

    return Container(
      height: sheetHeight,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // En-tête avec les icônes annuler et sauvegarder
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop(false); // Annuler et fermer
                },
              ),
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveSelections,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Select Resident Artists',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
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
          const SizedBox(height: 20),
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
                                  widget.selectedArtists.contains(artist.id);
                              return CheckboxListTile(
                                value: isSelected,
                                title: Text(artist.name),
                                onChanged: (bool? value) {
                                  if (!mounted) return;
                                  setState(() {
                                    if (value == true) {
                                      widget.selectedArtists.add(artist.id);
                                    } else {
                                      widget.selectedArtists.remove(artist.id);
                                    }
                                  });
                                },
                              );
                            } else {
                              // Bouton "Show More"
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
