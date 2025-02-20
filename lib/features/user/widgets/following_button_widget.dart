// lib/features/user/widgets/following_button_widget.dart

import 'package:flutter/material.dart';
import 'package:sway/core/utils/connectivity_helper.dart';
import 'package:sway/features/user/services/user_follow_artist_service.dart';
import 'package:sway/features/user/services/user_follow_genre_service.dart';
import 'package:sway/features/user/services/user_follow_promoter_service.dart';
import 'package:sway/features/user/services/user_follow_user_service.dart';
import 'package:sway/features/user/services/user_follow_venue_service.dart';
import 'package:sway/features/user/services/user_service.dart';
import 'package:sway/features/user/widgets/snackbar_login.dart';
import 'package:sway/core/widgets/snackbar_offline.dart';

class FollowingButtonWidget extends StatefulWidget {
  final int entityId;
  final String entityType; // 'venue', 'promoter', 'artist', 'user', 'genre'

  const FollowingButtonWidget({
    required this.entityId,
    required this.entityType,
    Key? key,
  }) : super(key: key);

  @override
  _FollowingButtonWidgetState createState() => _FollowingButtonWidgetState();
}

class _FollowingButtonWidgetState extends State<FollowingButtonWidget> {
  bool isFollowing = false;
  bool isLoading = true;
  bool isAnonymous = false;

  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadUserStatus();
  }

  Future<void> _loadUserStatus() async {
    try {
      final currentUser = await _userService.getCurrentUser();
      if (currentUser == null) {
        // User is anonymous
        if (!mounted) return;
        // print("User is anonymous.");
        setState(() {
          isAnonymous = true;
          isLoading = false;
        });
      } else {
        // Authenticated user: check if following the entity.
        bool following = await _isFollowing();
        if (!mounted) return;
        // print("User is authenticated. Following status: $following");
        setState(() {
          isFollowing = following;
          isAnonymous = false;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user status: $e');
      if (!mounted) return;
      setState(() {
        isAnonymous = false;
        isFollowing = false;
        isLoading = false;
      });
    }
  }

  Future<bool> _isFollowing() async {
    switch (widget.entityType) {
      case 'artist':
        return UserFollowArtistService().isFollowingArtist(widget.entityId);
      case 'venue':
        return UserFollowVenueService().isFollowingVenue(widget.entityId);
      case 'promoter':
        return UserFollowPromoterService().isFollowingPromoter(widget.entityId);
      case 'genre':
        return UserFollowGenreService().isFollowingGenre(widget.entityId);
      case 'user':
        return UserFollowUserService().isFollowingUser(widget.entityId);
      default:
        throw Exception('Unknown entity type');
    }
  }

  Future<void> _followEntity() async {
    // print("Attempting to follow ${widget.entityType} with ID ${widget.entityId}");
    switch (widget.entityType) {
      case 'artist':
        await UserFollowArtistService().followArtist(widget.entityId);
        break;
      case 'venue':
        await UserFollowVenueService().followVenue(widget.entityId);
        break;
      case 'promoter':
        await UserFollowPromoterService().followPromoter(widget.entityId);
        break;
      case 'genre':
        await UserFollowGenreService().followGenre(widget.entityId);
        break;
      case 'user':
        await UserFollowUserService().followUser(widget.entityId);
        break;
      default:
        throw Exception('Unknown entity type');
    }
  }

  Future<void> _unfollowEntity() async {
    // print("Attempting to unfollow ${widget.entityType} with ID ${widget.entityId}");
    switch (widget.entityType) {
      case 'artist':
        await UserFollowArtistService().unfollowArtist(widget.entityId);
        break;
      case 'venue':
        await UserFollowVenueService().unfollowVenue(widget.entityId);
        break;
      case 'promoter':
        await UserFollowPromoterService().unfollowPromoter(widget.entityId);
        break;
      case 'genre':
        await UserFollowGenreService().unfollowGenre(widget.entityId);
        break;
      case 'user':
        await UserFollowUserService().unfollowUser(widget.entityId);
        break;
      default:
        throw Exception('Unknown entity type');
    }
  }

  Future<void> _toggleFollow() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });
    try {
      if (!await ConnectivityHelper.getCurrentConnectivity()) {
        // print("Connectivity check: offline in _toggleFollow");
        SnackbarOffline.showOfflineSnackBar(context);
        setState(() {
          isLoading = false;
        });
        return;
      }
      if (isFollowing) {
        await _unfollowEntity();
      } else {
        await _followEntity();
      }
      bool updatedStatus = await _isFollowing();
      // print("Updated follow status: $updatedStatus");
      if (!mounted) return;
      setState(() {
        isFollowing = updatedStatus;
        isLoading = false;
      });
    } catch (e) {
      print('Error toggling follow status: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: const Text('Error updating follow.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: ConnectivityHelper.connectivityStream,
      initialData: true,
      builder: (context, snapshot) {
        bool connected = snapshot.data ?? true;
        // // print("Connectivity status in build: ${connected ? "online" : "offline"}");
        IconData iconData;
        Color iconColor;
        VoidCallback? onPressed;

        if (isLoading) {
          iconData = Icons.favorite_border;
          iconColor = Colors.grey;
          onPressed = () {
            // print("Loading in progress. Showing login snackbar.");
            SnackbarLogin.showLoginSnackBar(context);
          };
        } else if (isAnonymous) {
          iconData = Icons.favorite_border;
          iconColor = Colors.grey;
          onPressed = () {
            // print("User is anonymous. Showing login snackbar.");
            SnackbarLogin.showLoginSnackBar(context);
          };
        } else {
          if (isFollowing) {
            iconData = Icons.favorite;
            iconColor = Theme.of(context).primaryColor;
          } else {
            iconData = Icons.favorite_border;
            iconColor = Theme.of(context).iconTheme.color ?? Colors.grey;
          }
          if (!connected) {
            // print("Device is offline. Graying out the icon and setting offline action.");
            iconColor = Colors.grey;
            onPressed = () {
              // print("User tapped button while offline. Showing offline snackbar.");
              SnackbarOffline.showOfflineSnackBar(context);
            };
          } else {
            onPressed = _toggleFollow;
          }
        }

        return IconButton(
          icon: Icon(
            iconData,
            color: iconColor,
          ),
          onPressed: onPressed,
        );
      },
    );
  }
}
