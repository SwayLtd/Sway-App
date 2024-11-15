// lib/features/promoter/screens/edit_promoter_screen.dart

import 'package:flutter/material.dart';
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
  late TextEditingController _imageUrlController; // Controller for image URL

  final PromoterService _promoterService = PromoterService();
  final PromoterGenreService _promoterGenreService = PromoterGenreService();
  final PromoterResidentArtistsService _promoterArtistService =
      PromoterResidentArtistsService();
  final UserPermissionService _permissionService = UserPermissionService();
  final UserService _userService = UserService(); // Added UserService
  final GenreService _genreService = GenreService();
  final ArtistService _artistService = ArtistService();

  List<int> _selectedGenres = [];
  List<int> _selectedArtists = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.promoter.name);
    _descriptionController =
        TextEditingController(text: widget.promoter.description);
    _imageUrlController =
        TextEditingController(text: widget.promoter.imageUrl ?? '');
    _loadAssociatedData();
  }

  Future<void> _loadAssociatedData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load associated genres
      final genres =
          await _promoterGenreService.getGenresByPromoterId(widget.promoter.id);
      setState(() {
        _selectedGenres = genres;
      });

      // Load associated resident artists
      final artists = await _promoterArtistService
          .getArtistsByPromoterId(widget.promoter.id);
      setState(() {
        _selectedArtists = artists.map((artist) => artist.id).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose(); // Dispose the image URL controller
    super.dispose();
  }

  Future<void> _updatePromoter() async {
    final updatedPromoter = Promoter(
      id: widget.promoter.id,
      name: _nameController.text,
      description: _descriptionController.text,
      imageUrl: _imageUrlController.text, // Update image URL
      upcomingEvents: widget.promoter.upcomingEvents,
    );

    setState(() {
      _isLoading = true;
    });

    try {
      await _promoterService.updatePromoter(updatedPromoter);

      // Update associated genres
      await _promoterGenreService.updatePromoterGenres(
          widget.promoter.id, _selectedGenres);

      // Update associated resident artists
      await _promoterArtistService.updatePromoterArtists(
          widget.promoter.id, _selectedArtists);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Promoter updated successfully!')),
      );

      Navigator.pop(context, updatedPromoter);
    } catch (e) {
      String errorMessage = 'An error occurred while updating the promoter.';
      if (e.toString().contains('Permission denied')) {
        errorMessage = 'You do not have permission to update this promoter.';
      } else if (e.toString().contains('Failed to update promoter')) {
        errorMessage = 'Failed to update promoter. Please try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showDeleteConfirmationDialog(
      BuildContext context, UserPermission permission) async {
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
              child: const Text('Delete'),
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog first
                try {
                  await _promoterService.deletePromoter(permission.entityId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Promoter deleted successfully.')),
                  );
                  Navigator.of(context).pop(); // Return to previous screen
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

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
        setState(() {
          _selectedGenres = selectedGenres.toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading genres: ${e.toString()}')),
      );
    }
  }

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
        setState(() {
          _selectedArtists = selectedArtists.toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading artists: ${e.toString()}')),
      );
    }
  }

  Future<UserPermission?> _getCurrentUserPermission() async {
    final currentUser = await _userService.getCurrentUser(); // Use UserService
    if (currentUser == null) return null;

    final permissions = await _permissionService.getPermissionsByUserIdAndType(
        currentUser.id, 'promoter');

    for (var permission in permissions) {
      if (permission.entityId == widget.promoter.id) {
        return permission;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('Edit "${widget.promoter.name}"'), // Updated title with quotes
        actions: [
          IconButton(
            icon: const Icon(Icons.verified_user), // Changed icon
            onPressed: _isLoading
                ? null
                : () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserAccessManagementScreen(
                          entityId: widget.promoter.id,
                          entityType: 'promoter',
                        ),
                      ),
                    );
                    setState(() {});
                  },
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _updatePromoter,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Image Preview
                    if (_imageUrlController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Image.network(
                          _imageUrlController.text,
                          height: 200,
                          errorBuilder: (context, error, stackTrace) {
                            return const Text('Invalid image URL');
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const CircularProgressIndicator();
                          },
                        ),
                      ),
                    const SizedBox(height: sectionTitleSpacing),
                    // Image URL Field
                    TextField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(labelText: 'Image URL'),
                      onChanged: (value) {
                        setState(() {
                          // Update to trigger image preview
                        });
                      },
                    ),
                    const SizedBox(height: sectionSpacing),
                    // Name Field
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: sectionSpacing),
                    // Description Field with larger text area
                    TextField(
                      controller: _descriptionController,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                      maxLines: 3, // Set maxLines to 3
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
                    // Delete Button
                    FutureBuilder<UserPermission?>(
                      future: _getCurrentUserPermission(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasError ||
                            !snapshot.hasData ||
                            snapshot.data == null) {
                          return const SizedBox.shrink();
                        } else {
                          final permission = snapshot.data!;
                          // Check if user has 'admin' role
                          if (permission.permission != 'admin') {
                            return const SizedBox.shrink();
                          }
                          return Align(
                            alignment: Alignment.center,
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      _showDeleteConfirmationDialog(
                                          context, permission);
                                    },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.red,
                                minimumSize: const Size.fromHeight(50),
                              ),
                              child: const Text('Delete Promoter'),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

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

      // Sort genres to show selected first
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
        SnackBar(content: Text('Error searching genres: ${e.toString()}')),
      );
    } finally {
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
              ? const CircularProgressIndicator()
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

      setState(() {
        _artists = artists;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching artists: ${e.toString()}')),
      );
    } finally {
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
              ? const CircularProgressIndicator()
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
                              // Show "Show More" button
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
