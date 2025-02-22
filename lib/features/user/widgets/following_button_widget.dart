// lib/features/user/widgets/following_button_widget.dart

import 'package:flutter/material.dart';
import 'package:sway/features/user/services/user_follow_artist_service.dart';
import 'package:sway/features/user/services/user_follow_genre_service.dart';
import 'package:sway/features/user/services/user_follow_promoter_service.dart';
import 'package:sway/features/user/services/user_follow_user_service.dart';
import 'package:sway/features/user/services/user_follow_venue_service.dart';
import 'package:sway/features/user/services/user_service.dart';
import 'package:sway/features/user/widgets/snackbar_login.dart';

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
        // L'utilisateur est anonyme
        if (!mounted) return;
        setState(() {
          isAnonymous = true;
          isLoading = false;
        });
      } else {
        // L'utilisateur est authentifié, vérifier s'il suit l'entité
        bool following = await _isFollowing();
        if (!mounted) return;
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
      if (isFollowing) {
        await _unfollowEntity();
      } else {
        await _followEntity();
      }
      bool updatedStatus = await _isFollowing();
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
          content: Text('Error updating follow.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      /* return Padding(
        padding: EdgeInsets.all(8.0),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ); */
      return IconButton(
        icon: Icon(Icons.favorite_border, color: Colors.grey),
        onPressed: () => SnackbarLogin.showLoginSnackBar(context),
      );
    } else {
      IconData iconData;
      Color iconColor;
      VoidCallback? onPressed;

      if (isAnonymous) {
        // Utilisateur anonyme
        iconData = Icons.favorite_border;
        iconColor = Colors.grey;
        onPressed = () => SnackbarLogin.showLoginSnackBar(context);
      } else {
        // Utilisateur authentifié
        if (isFollowing) {
          iconData = Icons.favorite;
          iconColor = Theme.of(context).primaryColor;
        } else {
          iconData = Icons.favorite_border;
          // Utiliser une valeur par défaut si color est null
          iconColor = Theme.of(context).iconTheme.color ?? Colors.grey;
        }
        onPressed = _toggleFollow;
      }

      return IconButton(
        icon: Icon(iconData, color: iconColor),
        onPressed: onPressed,
      );
    }
  }
}
