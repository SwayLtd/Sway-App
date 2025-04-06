// lib/features/user/widgets/snackbar_login.dart

import 'package:flutter/material.dart';
import 'package:sway/core/services/database_service.dart';
import 'package:sway/features/user/widgets/auth_modal.dart';

class SnackbarLogin {
  /// Displays a snackbar asking the user to log in.
  /// [context] : BuildContext used to display the snackbar.
  /// [message] : Message to be displayed in the snackbar.
  static void showLoginSnackBar(BuildContext context,
      {String message = 'Please log in to continue.'}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            Expanded(child: Text(message)),
            GestureDetector(
              onTap: () async {
                AuthModal.showAuthModal(context);
              },
              child: Icon(
                Icons.login,
                color: Theme.of(context).snackBarTheme.actionTextColor,
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
