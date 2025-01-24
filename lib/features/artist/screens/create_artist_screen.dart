// lib/features/artist/screens/create_artist_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

      // Create a new artist without the image to get the ID
      final newArtist = Artist(
        id: 0, // Temporary ID, will be replaced by the actual ID from the database
        name: _nameController.text.trim(),
        imageUrl: '',
        description: _descriptionController.text.trim(),
        genres: [], // Populate as needed
        similarArtists: [], // Populate as needed
        links: {}, // Populate as needed
        followers: null, // Remove followers
        isFollowing: null, // Remove isFollowing
        upcomingEvents: [],
      );

      // Add the artist to the database and get the created object with the assigned ID
      final createdArtist = await _artistService.addArtist(newArtist);
      print('Created Artist: ${createdArtist.toJson()}');

      // Upload the image and get the URL
      final imageUrl = await _uploadImage(createdArtist.id);
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
    // _linksController.dispose(); // If not used
    super.dispose();
  }

  /// Build the artist creation form.
  @override
  Widget build(BuildContext context) {
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
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
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
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Artist Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the artist name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Description field
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
              // Remove links field for now
              /*
              const SizedBox(height: 20),
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
