// lib/core/widgets/verified_icon_widget.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A widget that displays a verification icon based on the verification status of an entity.
/// If the entity is verified, a filled verified icon is shown; if not, an outlined icon is displayed.
/// If the user is not logged in and the entity is not verified, the widget is not displayed.
class VerifiedIconWidget extends StatelessWidget {
  final bool isVerified;
  final String entityType;
  final String entityName;
  final int? entityId;

  const VerifiedIconWidget({
    Key? key,
    required this.isVerified,
    required this.entityType,
    required this.entityName,
    this.entityId,
  }) : super(key: key);

  /// Capitalizes the first letter of the given string.
  String capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    // Check if the user is logged in
    final currentUser = Supabase.instance.client.auth.currentUser;

    // If the entity is not verified and the user is not logged in, do not display the icon
    if (!isVerified && currentUser == null) {
      return SizedBox.shrink();
    }

    return IconButton(
      icon: Icon(
        isVerified ? Icons.verified_user : Icons.verified_user_outlined,
      ),
      onPressed: () {
        if (isVerified) {
          // Show snackbar for verified entity with option to view claim history
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${capitalize(entityType)} "$entityName" has been verified and validated by a moderator.',
              ),
              action: SnackBarAction(
                label: 'History',
                onPressed: () {
                  // Navigate to claim history screen
                  Navigator.pushNamed(context, '/claimHistory', arguments: {
                    'entityType': entityType,
                    'entityName': entityName,
                    'entityId': entityId,
                  });
                },
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          // Show snackbar for non-verified entity with option to claim
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${capitalize(entityType)} "$entityName" is not verified yet.',
              ),
              action: SnackBarAction(
                label: 'Claim',
                onPressed: () {
                  // Navigate to claim form screen
                  Navigator.pushNamed(context, '/claimForm', arguments: {
                    'entityType': entityType,
                    'entityId': entityId,
                  });
                },
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }
}
