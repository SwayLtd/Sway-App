// lib/features/user/screens/edit_user_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sway/core/constants/dimensions.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/security/services/storage_service.dart';
import 'package:sway/features/user/models/user_model.dart';
import 'package:sway/features/user/services/auth_service.dart';
import 'package:sway/features/user/services/user_service.dart';
import 'package:sway/core/utils/validators.dart';

class EditUserScreen extends StatefulWidget {
  final User user;

  const EditUserScreen({required this.user, Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditUserScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _bioController;

  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  bool _isUpdating = false;
  bool _isResettingPassword = false;
  String? _errorMessage;

  final _formKey = GlobalKey<FormState>();

  late User _currentUser; // Variable d'état pour l'utilisateur

  // Instance of the global validator used for text fields.
  // It will be updated with the combined forbiddenWords (French + English).
  late FieldValidator defaultValidator;

  @override
  void initState() {
    super.initState();
    _currentUser =
        widget.user; // Initialiser avec l'utilisateur passé en paramètre
    _usernameController = TextEditingController(text: _currentUser.username);
    _emailController = TextEditingController(text: _currentUser.email);
    _bioController = TextEditingController(text: _currentUser.bio);

    // Initialize defaultValidator with base parameters and an empty forbiddenWords.
    defaultValidator = FieldValidator(
      isRequired: true,
      maxLength: 500,
      forbiddenWords: [],
    );

    // Load forbidden words for French and English, then update the validator.
    _loadDefaultForbiddenWords();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
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

  /// Méthode pour mettre à jour le profil utilisateur
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      // Si la validation échoue, ne pas procéder
      return;
    }

    final newUsername = _usernameController.text.trim();
    final newEmail = _emailController.text.trim();
    final newBio = _bioController.text.trim();

    final bool isUsernameChanged = newUsername != _currentUser.username;
    final bool isEmailChanged = newEmail != _currentUser.email;
    final bool isBioChanged = newBio != _currentUser.bio;

    if (!isUsernameChanged && !isEmailChanged && !isBioChanged) {
      // Rien à mettre à jour
      Navigator.pop(context);
      return;
    }

    if (!mounted) return;
    setState(() {
      _isUpdating = true;
      _errorMessage = null;
    });

    try {
      if (isUsernameChanged) {
        // Vérifier si le nouveau nom d'utilisateur existe déjà
        final bool usernameExists =
            await _authService.doesUsernameExist(newUsername);
        if (usernameExists) {
          throw AuthenticationException('Username already exists.', '');
        }

        await _userService.updateUsername(
          supabaseId: _currentUser.supabaseId,
          newUsername: newUsername,
        );
      }

      if (isEmailChanged) {
        await _authService.updateEmail(newEmail);
        // Supabase envoie automatiquement un email de confirmation à la nouvelle adresse
      }

      if (isBioChanged) {
        await _userService.updateUserBio(
          supabaseId: _currentUser.supabaseId,
          newBio: newBio,
        );
      }

      // Récupérer l'utilisateur mis à jour
      final updatedUser = await _userService.getCurrentUser();
      print('Updated User: ${updatedUser?.toJson()}');

      if (updatedUser != null) {
        setState(() {
          _currentUser = updatedUser; // Mettre à jour _currentUser
        });
        Navigator.pop(context, updatedUser);

        // Afficher une boîte de dialogue pour informer l'utilisateur de vérifier son email
        if (isEmailChanged) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(
                  'A confirmation email has been sent to your new email address.'),
            ),
          );
        }
      }
    } on AuthenticationException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.message}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('Update Profile Error: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An unexpected error occurred.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: An unexpected error occurred.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isUpdating = false;
      });
    }
  }

  /// Méthode pour réinitialiser le mot de passe
  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email to reset password.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _isResettingPassword = true;
      _errorMessage = null;
    });

    try {
      await _authService.sendPasswordResetEmail(email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email has been sent.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on AuthenticationException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.message}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('Reset Password Error: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An unexpected error occurred.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: An unexpected error occurred.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isResettingPassword = false;
      });
    }
  }

  /// Méthode pour sélectionner et uploader une nouvelle image de profil
  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final imageFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (imageFile == null) return; // Pas d'image choisie

    try {
      // Lire les octets du fichier
      final fileBytes = await File(imageFile.path).readAsBytes();

      // Construire un nom de fichier unique
      final fileExtension = imageFile.path.split('.').last;
      final fileName =
          "${DateTime.now().millisecondsSinceEpoch}.$fileExtension"; // Ex: "1627891234567.jpg"

      // Construire le chemin complet du fichier
      final filePath =
          "${_currentUser.supabaseId}/$fileName"; // Ex: "user-id/1627891234567.jpg"

      // Uploader dans le bucket "user-images"
      final publicUrl = await _storageService.uploadFile(
        bucketName: "user-images",
        fileName: filePath, // Utilisez le chemin complet ici
        fileData: fileBytes,
      );

      print('Image Uploaded: $publicUrl');

      // (Optionnel) Supprimer l'ancien avatar si nécessaire
      // Extraire le nom du fichier de l'URL actuelle
      final oldFileName =
          _currentUser.profilePictureUrl.split('/').last.split('?').first;
      if (oldFileName.isNotEmpty) {
        final oldFilePath = "${_currentUser.supabaseId}/$oldFileName";
        await _storageService.deleteFile(
          bucketName: "user-images",
          fileName: oldFilePath,
        );
        print('Old Image Deleted: $oldFilePath');
      }

      // Mettre à jour l'URL de l'utilisateur dans la table users
      await _userService.updateUserProfilePicture(
        supabaseId: _currentUser.supabaseId,
        profilePictureUrl: publicUrl,
      );

      print('User Picture Updated in Database');

      // Récupérer le user mis à jour
      final updatedUser = await _userService.getCurrentUser();
      print('Updated User after avatar upload: ${updatedUser?.toJson()}');

      if (updatedUser != null && mounted) {
        setState(() {
          _currentUser = updatedUser; // Mettre à jour _currentUser
        });
      }

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Avatar updated successfully!'),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      print('Pick and Upload Avatar Error: $e');
      // Gérer l'erreur
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Error: ${e.toString()}'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit User'),
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
            onPressed: _isUpdating ? null : _updateProfile,
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
                      // Avatar et bouton d'édition améliorés
                      Center(
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap: _isUpdating
                                  ? null
                                  : _pickAndUploadAvatar, // Rendre l'image cliquable
                              child: Container(
                                width: 150, // Taille de l'avatar
                                height: 150,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                        .withValues(
                                            alpha:
                                                0.5), // Couleur de la bordure
                                    width: 2.0, // Épaisseur de la bordure
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      15), // Coins arrondis
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
                                  borderRadius: BorderRadius.circular(
                                      12), // Assurer les coins arrondis
                                  child: ImageWithErrorHandler(
                                    imageUrl: _currentUser
                                        .profilePictureUrl, // Utiliser _currentUser
                                    width: 150,
                                    height: 150,
                                    fit: BoxFit
                                        .cover, // Assurer que l'image couvre le conteneur
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _isUpdating
                                    ? null
                                    : _pickAndUploadAvatar, // Rendre l'icône cliquable
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    shape: BoxShape
                                        .circle, // Forme circulaire pour l'icône
                                    /* border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary
                                          .withValues(
                                              alpha:
                                                  0.5), // Bordure blanche autour de l'icône
                                      width: 2.0,
                                    ) */
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.2),
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
                      const SizedBox(height: sectionSpacing),
                      // Champ Username avec validation
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            usernameValidator, // Intégration du validateur
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      const SizedBox(height: sectionTitleSpacing),
                      // Champ Email avec validation basique
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: emailValidator,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      const SizedBox(height: sectionTitleSpacing),
                      // Champ pour la bio
                      TextFormField(
                        controller: _bioController,
                        decoration: const InputDecoration(
                          labelText: 'About you',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 5,
                        validator: (value) => defaultValidator.validate(value),
                      ),
                      // Afficher un message d'erreur si nécessaire
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
          ),
          // Bouton Reset Password en bas
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: 225,
              child: TextButton(
                child: Text(
                  'Reset Password',
                  style: TextStyle(
                    color: Theme.of(context).disabledColor,
                  ),
                ),
                onPressed: _isResettingPassword ? null : _resetPassword,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
