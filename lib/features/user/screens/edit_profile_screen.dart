// lib/features/user/screens/edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/user/models/user_model.dart';
import 'package:sway/features/user/services/auth_service.dart';
import 'package:sway/features/user/services/user_service.dart';

class EditProfileScreen extends StatefulWidget {
  final User user;

  const EditProfileScreen({required this.user});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;

  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

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

  Future<void> _updateProfile() async {
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
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (isUsernameChanged) {
        await _userService.updateUsername(
          supabaseId: widget.user.supabaseId,
          newUsername: newUsername,
        );
      }

      if (isEmailChanged) {
        await _authService.updateEmail(newEmail);
        // Ne mettez pas à jour directement la table 'users' ici
      }

      // Récupérer l'utilisateur mis à jour
      final updatedUser = await _userService.getCurrentUser();
      Navigator.pop(context, updatedUser);

      // Afficher une boîte de dialogue pour informer l'utilisateur de vérifier son email
      if (isEmailChanged) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Vérification Email'),
            content: Text(
                'Un email de vérification a été envoyé à votre nouvelle adresse. Veuillez vérifier votre email pour confirmer les changements.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
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
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _updateProfile,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            if (_isLoading) CircularProgressIndicator.adaptive(),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}
