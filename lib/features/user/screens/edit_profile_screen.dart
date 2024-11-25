// lib/features/user/screens/edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/user/models/user_model.dart';
import 'package:sway/features/user/services/auth_service.dart';
import 'package:sway/features/user/services/user_service.dart';
import 'package:sway/features/user/utils/auth_validator.dart'; // Import du validateur

class EditProfileScreen extends StatefulWidget {
  final User user;

  const EditProfileScreen({required this.user, Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;

  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

  bool _isUpdating = false;
  bool _isResettingPassword = false;
  String? _errorMessage;

  final _formKey = GlobalKey<FormState>(); // Clé du formulaire

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _emailController = TextEditingController(text: widget.user.email);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// Méthode pour mettre à jour le profil utilisateur
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      // Si la validation échoue, ne pas procéder
      return;
    }

    final newUsername = _usernameController.text.trim();
    final newEmail = _emailController.text.trim();

    final bool isUsernameChanged = newUsername != widget.user.username;
    final bool isEmailChanged = newEmail != widget.user.email;

    if (!isUsernameChanged && !isEmailChanged) {
      // Rien à mettre à jour
      Navigator.pop(context);
      return;
    }

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
          supabaseId: widget.user.supabaseId,
          newUsername: newUsername,
        );
      }

      if (isEmailChanged) {
        await _authService.updateEmail(newEmail);
        // Supabase envoie automatiquement un email de confirmation à la nouvelle adresse
      }

      // Récupérer l'utilisateur mis à jour
      final updatedUser = await _userService.getCurrentUser();
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
    } on AuthenticationException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.message}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: An unexpected error occurred.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
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
          backgroundColor: Colors.green,
        ),
      );
    } on AuthenticationException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.message}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: An unexpected error occurred.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isResettingPassword = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
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
                      // Avatar et bouton d'édition
                      Center(
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: ImageWithErrorHandler(
                                imageUrl: widget.user.profilePictureUrl,
                                width: 100,
                                height: 100,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // Logique pour éditer l'avatar sera ici
                              },
                              child: const Text('Edit avatar'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
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
                      const SizedBox(height: 10),
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
