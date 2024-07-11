import 'package:flutter/material.dart';
import 'package:sway_events/features/user/services/user_follow_artist_service.dart';
import 'package:sway_events/features/user/services/user_follow_genre_service.dart';
import 'package:sway_events/features/user/services/user_follow_organizer_service.dart';
import 'package:sway_events/features/user/services/user_follow_user_service.dart';
import 'package:sway_events/features/user/services/user_follow_venue_service.dart';

class FollowingButtonWidget extends StatelessWidget {
  final String entityId;
  final String entityType; // 'venue', 'organizer', 'artist', 'user', 'genre'

  const FollowingButtonWidget({required this.entityId, required this.entityType});

  Future<bool> _isFollowing() {
    switch (entityType) {
      case 'artist':
        return UserFollowArtistService().isFollowingArtist(entityId);
      case 'venue':
        return UserFollowVenueService().isFollowingVenue(entityId);
      case 'organizer':
        return UserFollowOrganizerService().isFollowingOrganizer(entityId);
      case 'genre':
        return UserFollowGenreService().isFollowingGenre(entityId);
      case 'user':
        return UserFollowUserService().isFollowingUser(entityId);
      default:
        throw Exception('Unknown entity type');
    }
  }

  Future<void> _followEntity() {
    switch (entityType) {
      case 'artist':
        return UserFollowArtistService().followArtist(entityId);
      case 'venue':
        return UserFollowVenueService().followVenue(entityId);
      case 'organizer':
        return UserFollowOrganizerService().followOrganizer(entityId);
      case 'genre':
        return UserFollowGenreService().followGenre(entityId);
      case 'user':
        return UserFollowUserService().followUser(entityId);
      default:
        throw Exception('Unknown entity type');
    }
  }

  Future<void> _unfollowEntity() {
    switch (entityType) {
      case 'artist':
        return UserFollowArtistService().unfollowArtist(entityId);
      case 'venue':
        return UserFollowVenueService().unfollowVenue(entityId);
      case 'organizer':
        return UserFollowOrganizerService().unfollowOrganizer(entityId);
      case 'genre':
        return UserFollowGenreService().unfollowGenre(entityId);
      case 'user':
        return UserFollowUserService().unfollowUser(entityId);
      default:
        throw Exception('Unknown entity type');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isFollowing(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          final bool isFollowing = snapshot.data ?? false;
          return ElevatedButton(
            onPressed: () async {
              if (isFollowing) {
                await _unfollowEntity();
              } else {
                await _followEntity();
              }
              // Refresh UI after follow/unfollow
              (context as Element).markNeedsBuild();
            },
            child: Text(isFollowing ? "Following" : "Follow"),
          );
        }
      },
    );
  }
}
