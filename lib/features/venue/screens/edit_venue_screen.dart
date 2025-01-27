// lib/features/venue/screens/edit_venue_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/security/services/storage_service.dart';
import 'package:sway/features/user/models/user_permission_model.dart';
import 'package:sway/features/user/screens/user_access_management_screen.dart';
import 'package:sway/features/user/services/user_permission_service.dart';
import 'package:sway/features/venue/models/venue_model.dart';
import 'package:sway/features/venue/services/venue_service.dart';

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
  final StorageService _storageService = StorageService();
  final UserPermissionService _permissionService = UserPermissionService();

  bool _isUpdating = false;
  bool _isDeleting = false;
  String? _errorMessage;

  final _formKey = GlobalKey<FormState>();

  late Venue _currentVenue; // Variable d'état pour la venue

  File? _selectedImage; // Image sélectionnée pour mise à jour

  @override
  void initState() {
    super.initState();
    _currentVenue = widget.venue;
    _nameController = TextEditingController(text: _currentVenue.name);
    _descriptionController =
        TextEditingController(text: _currentVenue.description);
    _locationController = TextEditingController(text: _currentVenue.location);
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
        _selectedImage = File(pickedFile.path);
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

    if (!isNameChanged &&
        !isDescriptionChanged &&
        !isLocationChanged &&
        !isImageChanged) {
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

      // Mettre à jour la venue via VenueService
      updatedVenue = await _venueService.updateVenue(updatedVenue);

      setState(() {
        _currentVenue = updatedVenue; // Mettre à jour l'état local
        _selectedImage = null; // Réinitialiser l'image sélectionnée
      });

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
          false, // The user must tap a button to dismiss the dialog
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
                Navigator.of(context).pop();
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
          return const CircularProgressIndicator.adaptive();
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

  /// Build the venue editing form.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Venue'),
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
                      const SizedBox(height: 10),
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
