import 'package:flutter/material.dart';
import 'package:sway_events/features/user/screens/followers_screen.dart';
import 'package:sway_events/features/user/services/user_follow_artist_service.dart';
import 'package:sway_events/features/user/services/user_follow_organizer_service.dart';
import 'package:sway_events/features/user/services/user_follow_venue_service.dart';
import 'package:sway_events/features/user/services/user_interest_event_service.dart';
import 'package:sway_events/features/user/services/user_follow_user_service.dart';

class FollowersListWidget extends StatelessWidget {
  final String entityId;
  final String entityType; // 'venue', 'organizer', 'event', 'artist', 'user'

  const FollowersListWidget({required this.entityId, required this.entityType});

  @override
  Widget build(BuildContext context) {
    if (entityType == 'event') {
      return FutureBuilder<Map<String, int>>(
        future: _getEventFollowersCount(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            final int interestedCount = snapshot.data?['interested'] ?? 0;
            final int goingCount = snapshot.data?['going'] ?? 0;
            return Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FollowersScreen(
                          entityId: entityId,
                          entityType: entityType,
                          initialTabIndex: 0, // Interested tab
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      '$interestedCount interested',
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FollowersScreen(
                          entityId: entityId,
                          entityType: entityType,
                          initialTabIndex: 1, // Going tab
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      '$goingCount going',
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
          }
        },
      );
    } else if (entityType == 'user') {
      return FutureBuilder<Map<String, int>>(
        future: _getUserFollowersFollowingCount(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            final int followersCount = snapshot.data?['followers'] ?? 0;
            final int followingCount = snapshot.data?['following'] ?? 0;
            return Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FollowersScreen(
                          entityId: entityId,
                          entityType: 'user',
                          initialTabIndex: 0, // Followers tab
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      '$followersCount followers',
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FollowersScreen(
                          entityId: entityId,
                          entityType: 'user',
                          initialTabIndex: 1, // Following tab
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      '$followingCount following',
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
          }
        },
      );
    } else {
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
                      entityId: entityId,
                      entityType: entityType,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  '$followersCount follower${followersCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          }
        },
      );
    }
  }

  Future<int> _getFollowersCountForEntity() {
    switch (entityType) {
      case 'artist':
        return UserFollowArtistService().getArtistFollowersCount(entityId);
      case 'venue':
        return UserFollowVenueService().getVenueFollowersCount(entityId);
      case 'organizer':
        return UserFollowOrganizerService().getOrganizerFollowersCount(entityId);
      default:
        throw Exception('Unknown entity type');
    }
  }

  Future<Map<String, int>> _getEventFollowersCount() async {
    final interestedCount = await UserInterestEventService().getEventInterestCount(entityId, 'interested');
    final goingCount = await UserInterestEventService().getEventInterestCount(entityId, 'going');
    return {
      'interested': interestedCount,
      'going': goingCount,
    };
  }

  Future<Map<String, int>> _getUserFollowersFollowingCount() async {
    final followersCount = await UserFollowUserService().getFollowersCount(entityId);
    final followingCount = await UserFollowUserService().getFollowingCount(entityId);
    return {
      'followers': followersCount,
      'following': followingCount,
    };
  }
}
