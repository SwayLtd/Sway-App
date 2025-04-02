// lib/features/claim/widgets/claim_widgets.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sway/features/user/services/user_service.dart';
import 'package:sway/features/user/widgets/snackbar_login.dart';
import 'package:sway/core/utils/connectivity_helper.dart';

/// A widget that displays a promotional claim tile at the bottom of entity pages
/// (e.g., promoters, artists, or venues).
class ClaimPageTile extends StatefulWidget {
  final String entityName; // e.g. "Promoter", "Artist", or "Venue"
  final String entityType; // used for navigation (e.g., 'promoter')
  final int? entityId; // Optional entity ID to be passed to the claim form
  final bool isVerified; // If true, the tile will not be displayed

  static const double sectionSpacing = 16.0;

  const ClaimPageTile({
    Key? key,
    required this.entityName,
    required this.entityType,
    this.entityId,
    this.isVerified = false,
  }) : super(key: key);

  @override
  _ClaimPageTileState createState() => _ClaimPageTileState();
}

class _ClaimPageTileState extends State<ClaimPageTile> {
  final UserService _userService = UserService();
  bool _isLoggedIn = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserStatus();
  }

  Future<void> _loadUserStatus() async {
    try {
      final currentUser = await _userService.getCurrentUser();
      if (!mounted) return;
      setState(() {
        _isLoggedIn = currentUser != null;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading user status: $e');
      if (!mounted) return;
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: ConnectivityHelper.connectivityStream,
      initialData: true,
      builder: (context, snapshot) {
        bool connected = snapshot.data ?? true;
        if (!connected) {
          debugPrint(
              "ClaimPageTile: No internet connection detected – widget hidden.");
          return const SizedBox.shrink();
        }
        // Also hide the widget if the entity is already verified or if user status is still loading.
        if (widget.isVerified || _isLoading) return const SizedBox.shrink();

        // Otherwise, build the ClaimPageTile.
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: ClaimPageTile.sectionSpacing * 2),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Leading emoji and headline.
                    Row(
                      children: [
                        const Text(
                          "👋",
                          style: TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Are you ${widget.entityName}? Connect with your fans like never before",
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Subheading text.
                    const Text(
                      "Customize your page and discover who your superfans are",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    // Full-width button.
                    ElevatedButton(
                      onPressed: !_isLoggedIn
                          ? () {
                              SnackbarLogin.showLoginSnackBar(context);
                            }
                          : () {
                              final route =
                                  '/claimForm/${widget.entityType}/${widget.entityId}';
                              context.push(route);
                            },
                      child: const Text('CLAIM THIS PAGE'),
                    )
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A widget that displays a verification badge for an entity.
/// If the entity is verified, a filled verified icon is shown.
/// When the icon is pressed, a snackbar with verification details and
/// an option to view the claim history is displayed.
/// If the entity is not verified, nothing is displayed.
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
    // If the entity is not verified, display nothing.
    if (!isVerified) {
      return const SizedBox.shrink();
    }

    return IconButton(
      icon: const Icon(Icons.verified_user),
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${capitalize(entityType)} "$entityName" has been verified and validated by a moderator.',
            ),
            action: SnackBarAction(
              label: 'History',
              onPressed: () {
                context.push('/claimHistory/$entityType/${entityId ?? 0}');
              },
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }
}
