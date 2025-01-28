// lib/features/promoter/screens/create_promoter_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/promoter/services/promoter_service.dart';
import 'package:sway/features/security/services/storage_service.dart';
import 'package:sway/features/user/services/user_service.dart';

class CreatePromoterScreen extends StatefulWidget {
  const CreatePromoterScreen({Key? key}) : super(key: key);

  @override
  State<CreatePromoterScreen> createState() => _CreatePromoterScreenState();
}

class _CreatePromoterScreenState extends State<CreatePromoterScreen> {
  final _formKey = GlobalKey<FormState>();
  final PromoterService _promoterService = PromoterService();
  final StorageService _storageService = StorageService();
  final UserService _userService = UserService();

  TextEditingController _nameController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();

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
  Future<String> _uploadImage(int promoterId) async {
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
    final filePath = "$promoterId/$fileName"; // Exemple: "1/1627891234567.jpg"

    // Uploader dans le bucket "promoter-images" (assurez-vous de créer ce bucket dans Supabase)
    final publicUrl = await _storageService.uploadFile(
      bucketName: "promoter-images",
      fileName: filePath, // Utilisez le chemin complet ici
      fileData: fileBytes,
    );

    print('Image Uploaded: $publicUrl');

    return publicUrl;
  }

  /// Soumet le formulaire et crée un nouveau promoter.
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select an image for the promoter.'),
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

      // Créer un nouveau promoter sans l'image pour obtenir l'ID
      final newPromoter = Promoter(
        name: _nameController.text.trim(),
        imageUrl: '',
        description: _descriptionController.text.trim(),
      );

      // Ajouter le promoter à la base de données et récupérer l'objet créé avec l'ID assigné
      final createdPromoter = await _promoterService.addPromoter(newPromoter);
      print('Created Promoter: ${createdPromoter.toJson()}');

      // Vérifier que le promoter a été créé
      if (createdPromoter.id == null) {
        throw Exception('Promoter ID is null.');
      }

      // Uploader l'image et obtenir l'URL
      final imageUrl = await _uploadImage(createdPromoter.id!);
      print('Image Uploaded: $imageUrl');

      // Mettre à jour le promoter avec l'URL de l'image
      final updatedPromoter = createdPromoter.copyWith(imageUrl: imageUrl);
      print('Updated Promoter Data: ${updatedPromoter.toJson()}');

      final resultPromoter =
          await _promoterService.updatePromoter(updatedPromoter);
      print('Result Promoter: ${resultPromoter.toJson()}');

      // Vérifier que le promoter a été mis à jour correctement
      if (resultPromoter.imageUrl.isEmpty) {
        throw Exception('Image URL was not updated.');
      }

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Promoter created successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Naviguer vers une autre page ou fermer l'écran
      Navigator.pop(context);
    } catch (e) {
      print('Error creating promoter: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating promoter: $e'),
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
    super.dispose();
  }

  /// Construit le formulaire de création de promoter.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Promoter'),
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
              // Champ Nom
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Promoter Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the promoter name.';
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
                    : const Text('Create Promoter'),
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
