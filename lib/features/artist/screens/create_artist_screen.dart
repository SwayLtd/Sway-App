// lib/features/artist/screens/create_artist_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sway/core/constants/dimensions.dart';
import 'package:sway/core/utils/validators.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/artist/services/artist_service.dart';
import 'package:sway/features/security/services/storage_service.dart';
import 'package:sway/features/user/services/user_service.dart';

class CreateArtistScreen extends StatefulWidget {
  const CreateArtistScreen({Key? key}) : super(key: key);

  @override
  State<CreateArtistScreen> createState() => _CreateArtistScreenState();
}

class _CreateArtistScreenState extends State<CreateArtistScreen> {
  final _formKey = GlobalKey<FormState>();
  final ArtistService _artistService = ArtistService();
  final StorageService _storageService = StorageService();
  final UserService _userService = UserService();

  TextEditingController _nameController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  // Remove links controller if not needed initially
  // TextEditingController _linksController = TextEditingController(); // For simplicity

  File? _selectedImage;
  bool _isSubmitting = false;

  // Instance of the global validator used for text fields.
  // It will be updated with the combined forbiddenWords (French + English).
  late FieldValidator defaultValidator;

  @override
  void initState() {
    super.initState();
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

  /// Select an image from the gallery.
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

  /// Upload the selected image and return the public URL.
  Future<String> _uploadImage(int artistId) async {
    if (_selectedImage == null) {
      throw Exception('No image selected.');
    }

    // Read file bytes
    final fileBytes = await _selectedImage!.readAsBytes();

    // Generate a unique file name
    final fileExtension = _selectedImage!.path.split('.').last;
    final fileName =
        "${DateTime.now().millisecondsSinceEpoch}.$fileExtension"; // e.g., "1627891234567.jpg"

    // Full file path
    final filePath = "$artistId/$fileName"; // e.g., "1/1627891234567.jpg"

    // Upload to the "artist-images" bucket (ensure this bucket exists in Supabase)
    final publicUrl = await _storageService.uploadFile(
      bucketName: "artist-images",
      fileName: filePath, // Use the full path here
      fileData: fileBytes,
    );

    print('Image Uploaded: $publicUrl');

    return publicUrl;
  }

  /// Submit the form and create a new artist.
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select an image for the artist.'),
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
      // Get the current user
      final currentUser = await _userService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not authenticated.');
      }
      print('Current User: ${currentUser.toJson()}');

      final newArtist = Artist(
        name: _nameController.text.trim(),
        imageUrl: '',
        description: _descriptionController.text.trim(),
        genres: [],
        similarArtists: [],
        links: {},
        upcomingEvents: [],
      );

      // Add the artist to the database and get the created object with the assigned ID
      final createdArtist = await _artistService.addArtist(newArtist);
      print('Created Artist: ${createdArtist?.toJson()}');

      // Upload the image and get the URL
      final imageUrl = await _uploadImage(createdArtist!.id!);
      print('Image Uploaded: $imageUrl');

      // Update the artist with the image URL
      final updatedArtist = createdArtist.copyWith(imageUrl: imageUrl);
      print('Updated Artist Data: ${updatedArtist.toJson()}');

      final resultArtist = await _artistService.updateArtist(updatedArtist);
      print('Result Artist: ${resultArtist.toJson()}');

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Artist created successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate to another page or close the screen
      Navigator.pop(context);
    } catch (e) {
      print('Error creating artist: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating artist: $e'),
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
    // _linksController.dispose(); // If not used
    super.dispose();
  }

  /// Build the artist creation form.
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Artist'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Image selection and preview
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
              const SizedBox(height: sectionSpacing),
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Artist Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => defaultValidator.validate(value),
              ),
              const SizedBox(height: sectionSpacing),
              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) => defaultValidator.validate(value),
              ),
              // Remove links field for now
              /*
              const SizedBox(height: sectionSpacing),
              // Links field (simple example)
              TextFormField(
                controller: _linksController,
                decoration: const InputDecoration(
                  labelText: 'Links (e.g., Spotify, Instagram)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              */
              const SizedBox(height: 30),
              // Submit button
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
                    : const Text('Create Artist'),
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
