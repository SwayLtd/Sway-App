import 'dart:io';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:sway/core/constants/dimensions.dart';
import 'package:sway/core/utils/url_launcher.dart';
import 'package:sway/core/utils/validators.dart';
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

  // Controllers for text fields
  TextEditingController _nameController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _locationController = TextEditingController();

  // Variables to store the retrieved latitude and longitude
  double? _latitude;
  double? _longitude;

  // FocusNode for the address field to trigger geocoding on focus loss
  late FocusNode _locationFocusNode;

  File? _selectedImage;
  bool _isSubmitting = false;

  // Global validator for text fields.
  late FieldValidator defaultValidator;

  @override
  void initState() {
    super.initState();
    _locationFocusNode = FocusNode();
    _locationFocusNode.addListener(() {
      if (!_locationFocusNode.hasFocus && _locationController.text.isNotEmpty) {
        _fetchLocation(_locationController.text.trim());
      }
    });
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

  /// Selects an image from the gallery.
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

  /// Uploads the selected image and returns the public URL.
  Future<String> _uploadImage(int venueId) async {
    if (_selectedImage == null) {
      throw Exception('No image selected.');
    }
    final fileBytes = await _selectedImage!.readAsBytes();
    final fileExtension = _selectedImage!.path.split('.').last;
    final fileName = "${DateTime.now().millisecondsSinceEpoch}.$fileExtension";
    final filePath = "$venueId/$fileName";
    final publicUrl = await _storageService.uploadFile(
      bucketName: "venue-images",
      fileName: filePath,
      fileData: fileBytes,
    );
    debugPrint('Image Uploaded: $publicUrl');
    return publicUrl;
  }

  /// Calls Nominatim directly to geocode the address.
  Future<void> _fetchLocation(String address) async {
    final url =
        "https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(address)}";
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "User-Agent":
              "YourAppName/1.0 (your_email@example.com)" // Replace with your app details
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

  /// Submits the form and creates a new venue.
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
      final currentUser = await _userService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not authenticated.');
      }
      debugPrint('Current User: ${currentUser.toJson()}');

      // Create a new venue without the image to get the ID.
      // Uses retrieved latitude and longitude if available.
      final newVenue = Venue(
        name: _nameController.text.trim(),
        imageUrl: '',
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
      );
      final createdVenue = await _venueService.addVenue(newVenue);
      debugPrint('Created Venue: ${createdVenue.toJson()}');

      // Upload the image and get the public URL.
      final imageUrl = await _uploadImage(createdVenue.id!);
      debugPrint('Image Uploaded: $imageUrl');

      // Update the venue with the image URL.
      final updatedVenue = createdVenue.copyWith(imageUrl: imageUrl);
      debugPrint('Updated Venue Data: ${updatedVenue.toJson()}');

      final resultVenue = await _venueService.updateVenue(updatedVenue);
      debugPrint('Result Venue: ${resultVenue.toJson()}');

      if (resultVenue.imageUrl.isEmpty) {
        throw Exception('Image URL was not updated.');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Venue created successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error creating venue: $e');
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
    _locationFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Venue'),
        actions: [
          GestureDetector(
            onTap: () {
              launchURL("https://sway.events/docs/create/venues");
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(
                  width: 1,
                  color: Theme.of(context).colorScheme.onPrimary.withAlpha(128),
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    "How it works?",
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
              // Venue Name field
              TextFormField(
                validator: (value) => defaultValidator.validate(value),
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Venue Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: sectionSpacing),
              // Address field with FocusNode to trigger geocoding on focus loss
              TextFormField(
                validator: (value) => defaultValidator.validate(value),
                controller: _locationController,
                focusNode: _locationFocusNode,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              if (_latitude != null && _longitude != null)
                Text("Latitude: $_latitude, Longitude: $_longitude"),
              const SizedBox(height: sectionSpacing),
              // Description field
              TextFormField(
                validator: (value) => defaultValidator.validate(value),
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
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
                    : const Text('CREATE VENUE'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
