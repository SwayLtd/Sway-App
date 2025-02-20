// lib/core/widgets/snackbar_offline.dart

import 'package:flutter/material.dart';

class SnackbarOffline {
  /// Displays a snackbar indicating the device is offline.
  static void showOfflineSnackBar(BuildContext context,
      {String message = "You're offline."}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(message),
      ),
    );
  }
}
