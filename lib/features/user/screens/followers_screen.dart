import 'package:flutter/material.dart';
import 'package:sway_events/features/user/models/user_model.dart';
import 'package:sway_events/features/user/services/user_follow_artist_service.dart';
import 'package:sway_events/features/user/services/user_follow_organizer_service.dart';
import 'package:sway_events/features/user/services/user_follow_venue_service.dart';
import 'package:sway_events/features/user/services/user_interest_event_service.dart';
import 'package:sway_events/features/user/user.dart'; // Changer selon le service approprié
// Changer selon le service approprié

class FollowersScreen extends StatelessWidget {
  final String entityId;
  final String entityType; // 'venue', 'organizer', 'event', 'artist'

  const FollowersScreen({required this.entityId, required this.entityType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Followers')),
      body: FutureBuilder<List<User>>(
        future: _getFollowersForEntity(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No followers found'));
          } else {
            final followers = snapshot.data!;
            return ListView.separated(
              itemCount: followers.length,
              itemBuilder: (context, index) {
                final user = followers[index];
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(user.profilePictureUrl),
                  ),
                  title: Text(user.username),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserScreen(userId: user.id),
                      ),
                    );
                  },
                );
              },
              separatorBuilder: (context, index) => const SizedBox(
                  height: 10), // Ajouter un espace entre chaque élément
            );
          }
        },
      ),
    );
  }

  Future<List<User>> _getFollowersForEntity() {
    switch (entityType) {
      case 'artist':
        return UserFollowArtistService().getFollowersForArtist(entityId);
      case 'venue':
        return UserFollowVenueService().getFollowersForVenue(entityId);
      case 'organizer':
        return UserFollowOrganizerService().getFollowersForOrganizer(entityId);
      case 'event':
        return UserInterestEventService().getFollowersForEvent(entityId);
      default:
        throw Exception('Unknown entity type');
    }
  }
}
