// lib/features/user/widgets/following_button_widget.dart

import 'package:flutter/material.dart';
import 'package:sway/features/user/services/user_follow_artist_service.dart';
import 'package:sway/features/user/services/user_follow_genre_service.dart';
import 'package:sway/features/user/services/user_follow_promoter_service.dart';
import 'package:sway/features/user/services/user_follow_user_service.dart';
import 'package:sway/features/user/services/user_follow_venue_service.dart';

class FollowingButtonWidget extends StatefulWidget {
  final int entityId;
  final String entityType; // 'venue', 'promoter', 'artist', 'user', 'genre'

  const FollowingButtonWidget({
    required this.entityId,
    required this.entityType,
  });

  @override
  _FollowingButtonWidgetState createState() => _FollowingButtonWidgetState();
}

class _FollowingButtonWidgetState extends State<FollowingButtonWidget> {
  bool isFollowing = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFollowingStatus();
  }

  Future<void> _loadFollowingStatus() async {
    try {
      bool following = await _isFollowing();
      setState(() {
        isFollowing = following;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading following status: $e');
      setState(() {
        isFollowing = false;
        isLoading = false;
      });
    }
  }

  Future<bool> _isFollowing() {
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
      setState(() {
        isFollowing = updatedStatus;
        isLoading = false;
      });
    } catch (e) {
      print('Error toggling follow status: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else {
      return IconButton(
        icon: Icon(
          isFollowing ? Icons.star : Icons.star_border,
          // You can customize the color if needed
        ),
        onPressed: _toggleFollow,
      );
    }
  }
}
