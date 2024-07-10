import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway_events/features/artist/models/artist_model.dart';
import 'package:sway_events/features/artist/services/artist_service.dart';
import 'package:sway_events/features/event/models/event_model.dart';
import 'package:sway_events/features/event/services/event_service.dart';
import 'package:sway_events/features/organizer/models/organizer_model.dart';
import 'package:sway_events/features/organizer/services/organizer_service.dart';
import 'package:sway_events/features/user/models/user_model.dart';
import 'package:sway_events/features/user/models/user_permission_model.dart';
import 'package:sway_events/features/venue/models/venue_model.dart';
import 'package:sway_events/features/venue/services/venue_service.dart';

class UserService {
  Future<List<User>> getUsers() async {
    final String response = await rootBundle.loadString('assets/databases/users.json');
    final List<dynamic> userJson = json.decode(response) as List<dynamic>;
    return userJson.map((json) => User.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<User?> getUserById(String userId) async {
    final List<User> users = await getUsers();
    try {
      return users.firstWhere((user) => user.id == userId);
    } catch (e) {
      return null;
    }
  }

  Future<List<Artist>> getFollowedArtists(String userId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_artist.json');
    final List<dynamic> userFollowArtistJson = json.decode(response) as List<dynamic>;
    final artistIds = userFollowArtistJson
        .where((entry) => entry['userId'] == userId)
        .map((entry) => entry['artistId'] as String)
        .toList();

    final artists = await ArtistService().getArtists();
    return artists.where((artist) => artistIds.contains(artist.id)).toList();
  }

  Future<List<Venue>> getFollowedVenues(String userId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_venue.json');
    final List<dynamic> userFollowVenueJson = json.decode(response) as List<dynamic>;
    final venueIds = userFollowVenueJson
        .where((entry) => entry['userId'] == userId)
        .map((entry) => entry['venueId'] as String)
        .toList();

    final venues = await VenueService().getVenues();
    return venues.where((venue) => venueIds.contains(venue.id)).toList();
  }

  Future<List<Organizer>> getFollowedOrganizers(String userId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_organizer.json');
    final List<dynamic> userFollowOrganizerJson = json.decode(response) as List<dynamic>;
    final organizerIds = userFollowOrganizerJson
        .where((entry) => entry['userId'] == userId)
        .map((entry) => entry['organizerId'] as String)
        .toList();

    final organizers = await OrganizerService().getOrganizers();
    return organizers.where((organizer) => organizerIds.contains(organizer.id)).toList();
  }

  Future<List<Event>> getInterestedEvents(String userId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_interest_event.json');
    final List<dynamic> userInterestEventJson = json.decode(response) as List<dynamic>;
    final eventIds = userInterestEventJson
        .where((entry) => entry['userId'] == userId)
        .map((entry) => entry['eventId'] as String)
        .toList();

    final events = await EventService().getEvents();
    return events.where((event) => eventIds.contains(event.id)).toList();
  }

  Future<List<UserPermission>> getUserPermissions(String userId) async {
    final String response = await rootBundle.loadString('assets/databases/user_permissions.json');
    final List<dynamic> userPermissionJson = json.decode(response) as List<dynamic>;
    return userPermissionJson
        .where((entry) => entry['userId'] == userId)
        .map((json) => UserPermission.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
