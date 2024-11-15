import 'package:flutter/material.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/user/models/user_model.dart';
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
    final updatedUser = widget.user.copyWith(
      username: _usernameController.text,
      email: _emailController.text,
    );
    // await UserService().updateUser(updatedUser);
    Navigator.pop(context, updatedUser);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _updateProfile,
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
                      // Logic to edit avatar will be here
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
            ),
          ],
        ),
      ),
    );
  }
}
