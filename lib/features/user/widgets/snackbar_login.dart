// lib/features/user/widgets/snackbar_login.dart

import 'package:flutter/material.dart';
import 'package:sway/features/user/widgets/auth_modal.dart';

class SnackbarLogin {
  /// Displays a snackbar asking the user to connect with an action containing an icon.
  /// [context] : BuildContext to display the snackbar.
  /// [message] : Message to be displayed in the snackbar.
  static void showLoginSnackBar(BuildContext context,
      {String message = 'Please log in to follow.'}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            Expanded(child: Text(message)),
            GestureDetector(
              onTap: () {
                AuthModal.showAuthModal(context);
              },
              child: Row(
                children: [
                  Icon(
                    Icons.login,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
