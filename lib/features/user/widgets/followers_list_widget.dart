import 'package:flutter/material.dart';
import 'package:sway_events/features/user/screens/followers_screen.dart';
import 'package:sway_events/features/user/services/user_follow_artist_service.dart';
import 'package:sway_events/features/user/services/user_follow_organizer_service.dart';
import 'package:sway_events/features/user/services/user_follow_venue_service.dart';
import 'package:sway_events/features/user/services/user_interest_event_service.dart'; // Change this according to the service

class FollowersListWidget extends StatelessWidget {
  final String entityId;
  final String entityType; // 'venue', 'organizer', 'event', 'artist'

  const FollowersListWidget({required this.entityId, required this.entityType});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _getFollowersCountForEntity(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          final int followersCount = snapshot.data ?? 0;
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FollowersScreen(
                      entityId: entityId, entityType: entityType),
                ),
              );
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                '$followersCount follower${followersCount == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // White text on blue background
                ),
              ),
            ),
          );
        }
      },
    );
  }

  Future<int> _getFollowersCountForEntity() {
    switch (entityType) {
      case 'artist':
        return UserFollowArtistService().getArtistFollowersCount(entityId);
      case 'venue':
        return UserFollowVenueService().getVenueFollowersCount(entityId);
      case 'organizer':
        return UserFollowOrganizerService()
            .getOrganizerFollowersCount(entityId);
      case 'event':
        return UserInterestEventService().getEventInterestCount(entityId);
      default:
        throw Exception('Unknown entity type');
    }
  }
}
