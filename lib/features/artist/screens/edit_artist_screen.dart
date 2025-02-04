// lib/features/artist/screens/edit_artist_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // pour listEquals
import 'package:image_picker/image_picker.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/artist/services/artist_service.dart';
import 'package:sway/features/artist/services/artist_genre_service.dart';
import 'package:sway/features/genre/widgets/genre_chip.dart';
import 'package:sway/features/security/services/storage_service.dart';
import 'package:sway/features/genre/models/genre_model.dart';
import 'package:sway/features/genre/services/genre_service.dart';

class EditArtistScreen extends StatefulWidget {
  final Artist artist;

  const EditArtistScreen({required this.artist, Key? key}) : super(key: key);

  @override
  _EditArtistScreenState createState() => _EditArtistScreenState();
}

class _EditArtistScreenState extends State<EditArtistScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  final ArtistService _artistService = ArtistService();
  final ArtistGenreService _artistGenreService = ArtistGenreService();
  final StorageService _storageService = StorageService();
  final GenreService _genreService = GenreService();

  // On stocke ici les genres associés (sous forme d'IDs)
  List<int> _selectedGenres = [];
  List<int> _initialGenres = [];

  bool _isLoading = false;
  bool _isDeleting = false;
  String? _errorMessage;
  File? _selectedImage;

  late Artist _currentArtist;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _currentArtist = widget.artist;
    _nameController = TextEditingController(text: _currentArtist.name);
    _descriptionController =
        TextEditingController(text: _currentArtist.description);
    _loadAssociatedData();
  }

  Future<void> _loadAssociatedData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Chargement des genres associés à l'artiste via le service dédié.
      final genres =
          await _artistGenreService.getGenresByArtistId(_currentArtist.id);
      setState(() {
        _selectedGenres = List<int>.from(genres);
        _initialGenres = List<int>.from(genres);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des genres : $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Sélection d'une nouvelle image depuis la galerie.
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  /// Téléchargement de l'image sélectionnée dans le bucket "artist-images"
  /// et récupération de son URL publique.
  Future<String> _uploadImage(int artistId, File imageFile) async {
    final fileBytes = await imageFile.readAsBytes();
    final fileExtension = imageFile.path.split('.').last;
    final fileName = "${DateTime.now().millisecondsSinceEpoch}.$fileExtension";
    final filePath = "$artistId/$fileName";

    final publicUrl = await _storageService.uploadFile(
      bucketName: "artist-images",
      fileName: filePath,
      fileData: fileBytes,
    );

    return publicUrl;
  }

  /// Mise à jour de l'artiste (nom, description, image et genres) si une modification est détectée.
  Future<void> _updateArtist() async {
    if (!_formKey.currentState!.validate()) return;

    final newName = _nameController.text.trim();
    final newDescription = _descriptionController.text.trim();

    final bool isNameChanged = newName != _currentArtist.name;
    final bool isDescriptionChanged =
        newDescription != _currentArtist.description;
    final bool isImageChanged = _selectedImage != null;
    final bool isGenresChanged = !listEquals(_selectedGenres, _initialGenres);

    if (!isNameChanged &&
        !isDescriptionChanged &&
        !isImageChanged &&
        !isGenresChanged) {
      Navigator.pop(context, _currentArtist);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String updatedImageUrl = _currentArtist.imageUrl;
      if (isImageChanged) {
        updatedImageUrl =
            await _uploadImage(_currentArtist.id, _selectedImage!);
        final oldFileName =
            _currentArtist.imageUrl.split('/').last.split('?').first;
        if (oldFileName.isNotEmpty) {
          final oldFilePath = "${_currentArtist.id}/$oldFileName";
          await _storageService.deleteFile(
            bucketName: "artist-images",
            fileName: oldFilePath,
          );
        }
      }

      Artist updatedArtist = _currentArtist.copyWith(
        name: isNameChanged ? newName : null,
        description: isDescriptionChanged ? newDescription : null,
        imageUrl: isImageChanged ? updatedImageUrl : null,
      );

      if (isNameChanged || isDescriptionChanged || isImageChanged) {
        updatedArtist = await _artistService.updateArtist(updatedArtist);
        setState(() {
          _currentArtist = updatedArtist;
          _selectedImage = null;
        });
      }

      if (isGenresChanged) {
        await _artistGenreService.updateArtistGenres(
            _currentArtist.id, _selectedGenres);
        setState(() {
          _initialGenres = List.from(_selectedGenres);
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Artist updated successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, updatedArtist);
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error has occurred.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Affichage d'un dialogue de confirmation pour la suppression de l'artiste.
  Future<void> _showDeleteConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // L'utilisateur doit confirmer
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: const Text('Voulez-vous vraiment supprimer cet artiste ?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Supprimer',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteArtist();
              },
            ),
          ],
        );
      },
    );
  }

  /// Suppression de l'artiste (et de son image associée) via le service.
  Future<void> _deleteArtist() async {
    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      // (Optionnel) Suppression de l'image associée.
      final oldFileName =
          _currentArtist.imageUrl.split('/').last.split('?').first;
      if (oldFileName.isNotEmpty) {
        final oldFilePath = "${_currentArtist.id}/$oldFileName";
        await _storageService.deleteFile(
          bucketName: "artist-images",
          fileName: oldFilePath,
        );
      }

      await _artistService.deleteArtist(_currentArtist.id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Artist deleted successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, null);
    } catch (e) {
      setState(() {
        _errorMessage = 'Échec de la suppression de l\'artist.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit "${_currentArtist.name}"'),
        actions: [
          IconButton(
            icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.save),
            onPressed: _isLoading || _isDeleting ? null : _updateArtist,
          ),
          IconButton(
            icon: _isDeleting
                ? const SizedBox.shrink()
                : const Icon(Icons.delete),
            onPressed: _isDeleting || _isLoading
                ? null
                : _showDeleteConfirmationDialog,
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
                      // Sélection et aperçu de l'image
                      Center(
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap:
                                  _isLoading || _isDeleting ? null : _pickImage,
                              child: Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                        .withOpacity(0.5),
                                    width: 2.0,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: _selectedImage != null
                                      ? Image.file(
                                          _selectedImage!,
                                          fit: BoxFit.cover,
                                          width: 150,
                                          height: 150,
                                        )
                                      : ImageWithErrorHandler(
                                          imageUrl: _currentArtist.imageUrl,
                                          width: 150,
                                          height: 150,
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
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(20),
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
                      // Champ Nom
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Artist Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez saisir le nom de l\'artist.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Champ Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez saisir une description.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Section Genres avec bouton d'édition via bottom sheet
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Genres',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final selectedGenres =
                                  Set<int>.from(_selectedGenres);
                              final bool? saved =
                                  await showModalBottomSheet<bool>(
                                context: context,
                                isScrollControlled: true,
                                builder: (BuildContext context) {
                                  return GenreSelectionBottomSheet(
                                    selectedGenres: selectedGenres,
                                    genreService: _genreService,
                                  );
                                },
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(16.0)),
                                ),
                              );
                              if (saved == true) {
                                setState(() {
                                  _selectedGenres = selectedGenres.toList();
                                });
                              }
                            },
                            child: const Icon(Icons.edit),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _selectedGenres.isNotEmpty
                          ? Wrap(
                              spacing: 8.0,
                              children: _selectedGenres.map((genreId) {
                                // Display the genre name using the GenreChip widget.
                                return GenreChip(genreId: genreId);
                              }).toList(),
                            )
                          : const SizedBox.shrink(),

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

/// Bottom sheet générique pour la sélection des genres.
/// Cette classe s’inspire des implémentations vues dans les écrans d’édition de promoteurs ou de venues.
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

      // Trier pour afficher en premier les genres déjà sélectionnés
      genres.sort((a, b) {
        bool aSelected = widget.selectedGenres.contains(a.id);
        bool bSelected = widget.selectedGenres.contains(b.id);
        if (aSelected && !bSelected) return -1;
        if (!aSelected && bSelected) return 1;
        return a.name.compareTo(b.name);
      });

      setState(() {
        _genres = genres;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la recherche des genres : $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
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
        (screenHeight * 0.5).clamp(0, screenHeight - statusBarHeight - 100);

    final List<Genre> genresToDisplay =
        _showAll ? _genres : _genres.take(_maxGenresToShow).toList();

    return Container(
      height: sheetHeight,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // En-tête avec les boutons annuler et sauvegarder
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
                              ((_genres.length > _maxGenresToShow && !_showAll)
                                  ? 1
                                  : 0),
                          itemBuilder: (context, index) {
                            if (index < genresToDisplay.length) {
                              final genre = genresToDisplay[index];
                              final bool isSelected =
                                  widget.selectedGenres.contains(genre.id);
                              return CheckboxListTile(
                                value: isSelected,
                                title: Text(genre.name),
                                onChanged: (bool? value) {
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
