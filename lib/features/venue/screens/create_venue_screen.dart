// lib/features/venue/screens/create_venue_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sway/features/security/services/storage_service.dart';
import 'package:sway/features/user/services/user_service.dart';
import 'package:sway/features/venue/models/venue_model.dart';
import 'package:sway/features/venue/services/venue_service.dart';

class CreateVenueScreen extends StatefulWidget {
  const CreateVenueScreen({Key? key}) : super(key: key);

  @override
  State<CreateVenueScreen> createState() => _CreateVenueScreenState();
}

class _CreateVenueScreenState extends State<CreateVenueScreen> {
  final _formKey = GlobalKey<FormState>();
  final VenueService _venueService = VenueService();
  final StorageService _storageService = StorageService();
  final UserService _userService = UserService();

  TextEditingController _nameController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _locationController = TextEditingController();

  File? _selectedImage;
  bool _isSubmitting = false;

  /// Sélectionne une image depuis la galerie.
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

  /// Uploade l'image sélectionnée et retourne l'URL publique.
  Future<String> _uploadImage(int venueId) async {
    if (_selectedImage == null) {
      throw Exception('No image selected.');
    }

    // Lire les octets du fichier
    final fileBytes = await _selectedImage!.readAsBytes();

    // Construire un nom de fichier unique
    final fileExtension = _selectedImage!.path.split('.').last;
    final fileName =
        "${DateTime.now().millisecondsSinceEpoch}.$fileExtension"; // Ex: "1627891234567.jpg"

    // Construire le chemin complet du fichier
    final filePath = "$venueId/$fileName"; // Exemple: "1/1627891234567.jpg"

    // Uploader dans le bucket "venue-images" (assurez-vous de créer ce bucket dans Supabase)
    final publicUrl = await _storageService.uploadFile(
      bucketName: "venue-images",
      fileName: filePath, // Utilisez le chemin complet ici
      fileData: fileBytes,
    );

    print('Image Uploaded: $publicUrl');

    return publicUrl;
  }

  /// Soumet le formulaire et crée une nouvelle venue.
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select an image for the venue.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Obtenir l'utilisateur actuel
      final currentUser = await _userService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not authenticated.');
      }
      print('Current User: ${currentUser.toJson()}');

      // Créer une nouvelle venue sans l'image pour obtenir l'ID
      final newVenue = Venue(
        name: _nameController.text.trim(),
        imageUrl: '',
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
      );

      // Ajouter la venue à la base de données et récupérer l'objet créé avec l'ID assigné
      final createdVenue = await _venueService.addVenue(newVenue);
      print('Created Venue: ${createdVenue.toJson()}');

      // Uploader l'image et obtenir l'URL
      final imageUrl = await _uploadImage(createdVenue.id!);
      print('Image Uploaded: $imageUrl');

      // Mettre à jour la venue avec l'URL de l'image
      final updatedVenue = createdVenue.copyWith(imageUrl: imageUrl);
      print('Updated Venue Data: ${updatedVenue.toJson()}');

      final resultVenue = await _venueService.updateVenue(updatedVenue);
      print('Result Venue: ${resultVenue.toJson()}');

      // Vérifier que la venue a été mise à jour correctement
      if (resultVenue.imageUrl.isEmpty) {
        throw Exception('Image URL was not updated.');
      }

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Venue created successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Naviguer vers une autre page ou fermer l'écran
      Navigator.pop(context);
    } catch (e) {
      print('Error creating venue: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating venue: $e'),
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
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  /// Construit le formulaire de création de venue.
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Venue'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Sélection et aperçu de l'image
              GestureDetector(
                onTap: _isSubmitting ? null : _pickImage,
                child: Container(
                  width: 150,
                  height: 150,
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
                            width: double.infinity,
                            height: 200,
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
              // Champ Nom
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
                    return 'Please enter a description.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Champ Adresse
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the address.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              // Bouton de soumission
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
                    : const Text('Create Venue'),
                style: ElevatedButton.styleFrom(
                  // Couleurs selon le thème
                  side: BorderSide(
                      color: isDark ? Colors.white : Colors.black, width: 1),
                  elevation: isDark ? 2 : 0,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
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
