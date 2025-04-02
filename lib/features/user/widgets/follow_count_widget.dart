// lib/features/user/widgets/followers_count_widget.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sway/core/utils/text_formatting.dart';
import 'package:sway/features/user/screens/followers_screen.dart';
import 'package:sway/features/user/services/user_follow_artist_service.dart';
import 'package:sway/features/user/services/user_follow_genre_service.dart';
import 'package:sway/features/user/services/user_follow_promoter_service.dart';
import 'package:sway/features/user/services/user_follow_user_service.dart';
import 'package:sway/features/user/services/user_follow_venue_service.dart';
import 'package:sway/features/user/services/user_interest_event_service.dart';
import 'package:sway/features/user/services/user_service.dart';
import 'package:sway/features/user/widgets/snackbar_login.dart';

class FollowersCountWidget extends StatefulWidget {
  final int entityId;
  final String
      entityType; // 'venue', 'promoter', 'event', 'artist', 'user', 'genre'

  const FollowersCountWidget(
      {required this.entityId, required this.entityType});

  @override
  _FollowersCountWidgetState createState() => _FollowersCountWidgetState();
}

class _FollowersCountWidgetState extends State<FollowersCountWidget> {
  bool isAuthenticated = false;
  bool isLoading = true;
  Map<String, int> counts = {};

  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      // Vérifie l'état d'authentification
      final user = await _userService.getCurrentUser();
      if (!mounted) return;
      setState(() {
        isAuthenticated = user != null;
      });

      // Récupère les counts en fonction du type d'entité
      if (widget.entityType == 'event') {
        counts = await _getEventFollowersCount();
      } else if (widget.entityType == 'user') {
        counts = await _getUserFollowersFollowingCount();
      } else {
        counts['followersCount'] = await _getFollowersCountForEntity();
      }

      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error initializing FollowersCountWidget: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<int> _getFollowersCountForEntity() {
    switch (widget.entityType) {
      case 'artist':
        return UserFollowArtistService()
            .getArtistFollowersCount(widget.entityId);
      case 'venue':
        return UserFollowVenueService().getVenueFollowersCount(widget.entityId);
      case 'promoter':
        return UserFollowPromoterService()
            .getPromoterFollowersCount(widget.entityId);
      case 'genre':
        return UserFollowGenreService().getGenreFollowersCount(widget.entityId);
      default:
        throw Exception('Unknown entity type');
    }
  }

  Future<Map<String, int>> _getEventFollowersCount() async {
    final interestedCount = await UserInterestEventService()
        .getEventInterestCount(widget.entityId, 'interested');
    final goingCount = await UserInterestEventService()
        .getEventInterestCount(widget.entityId, 'going');
    return {
      'interested': interestedCount,
      'going': goingCount,
    };
  }

  Future<Map<String, int>> _getUserFollowersFollowingCount() async {
    final followersCount =
        await UserFollowUserService().getFollowersCount(widget.entityId);
    final followingCount =
        await UserFollowUserService().getFollowingCount(widget.entityId);
    return {
      'followers': followersCount,
      'following': followingCount,
    };
  }

  void _navigateToFollowersScreen({int initialTabIndex = 0}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FollowersScreen(
          entityId: widget.entityId,
          entityType: widget.entityType,
          initialTabIndex: initialTabIndex,
        ),
      ),
    );
  }

  void _handleTap({int initialTabIndex = 0}) async {
    if (isAuthenticated) {
      _navigateToFollowersScreen(initialTabIndex: initialTabIndex);
    } else {
      SnackbarLogin.showLoginSnackBar(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      final baseColor = isDarkMode
          ? Colors.grey.shade700.withValues(alpha: 0.1)
          : Colors.grey.shade300;
      final highlightColor = isDarkMode
          ? Colors.grey.shade500.withValues(alpha: 0.1)
          : Colors.grey.shade100;
      final containerColor =
          isDarkMode ? Theme.of(context).scaffoldBackgroundColor : Colors.white;

      return Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: widget.entityType == 'event'
            ? Row(
                children: [
                  Container(
                    width: 120,
                    height: 42,
                    decoration: BoxDecoration(
                      color: containerColor,
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 120,
                    height: 42,
                    decoration: BoxDecoration(
                      color: containerColor,
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ],
              )
            : widget.entityType == 'user'
                ? Row(
                    children: [
                      Container(
                        width: 120,
                        height: 42,
                        decoration: BoxDecoration(
                          color: containerColor,
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 120,
                        height: 42,
                        decoration: BoxDecoration(
                          color: containerColor,
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ],
                  )
                : Container(
                    width: 120,
                    height: 42,
                    decoration: BoxDecoration(
                      color: containerColor,
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
      );
    }
    if (widget.entityType == 'event') {
      final int interestedCount = counts['interested'] ?? 0;
      final int goingCount = counts['going'] ?? 0;
      return Row(
        children: [
          GestureDetector(
            onTap: () => _handleTap(initialTabIndex: 0),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                '${formatNumber(interestedCount)} interested',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _handleTap(initialTabIndex: 1),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.greenAccent,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                '${formatNumber(goingCount)} going',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    } else if (widget.entityType == 'user') {
      final int followersCount = counts['followers'] ?? 0;
      final int followingCount = counts['following'] ?? 0;
      return Row(
        children: [
          GestureDetector(
            onTap: () => _handleTap(initialTabIndex: 0),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                '${formatNumber(followersCount)} followers',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _handleTap(initialTabIndex: 1),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.greenAccent,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                '${formatNumber(followingCount)} following',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      final int followersCount = counts['followersCount'] ?? 0;
      return GestureDetector(
        onTap: () => _handleTap(),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            '${formatNumber(followersCount)} follower${followersCount == 1 ? '' : 's'}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    }
  }
}
