// lib/features/user/profile.dart

import 'package:flutter/material.dart';
import 'package:sway/core/constants/dimensions.dart';
import 'package:sway/core/utils/date_utils.dart';
import 'package:sway/core/utils/share_util.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/artist/artist.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/artist/widgets/artist_item_widget.dart';
import 'package:sway/features/artist/widgets/artist_modal_bottom_sheet.dart';
import 'package:sway/features/event/event.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/widgets/event_item_widget.dart';
import 'package:sway/features/event/widgets/event_modal_bottom_sheet.dart';
import 'package:sway/features/genre/genre.dart';
import 'package:sway/features/genre/models/genre_model.dart';
import 'package:sway/features/genre/widgets/genre_chip.dart';
import 'package:sway/features/genre/widgets/genre_modal_bottom_sheet.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/promoter/promoter.dart';
import 'package:sway/features/promoter/widgets/promoter_item_widget.dart';
import 'package:sway/features/promoter/widgets/promoter_modal_bottom_sheet.dart';
import 'package:sway/features/user/models/user_model.dart';
import 'package:sway/features/user/screens/edit_profile_screen.dart';
import 'package:sway/features/user/services/user_follow_artist_service.dart';
import 'package:sway/features/user/services/user_follow_genre_service.dart';
import 'package:sway/features/user/services/user_follow_promoter_service.dart';
import 'package:sway/features/user/services/user_follow_venue_service.dart';
import 'package:sway/features/user/services/user_interest_event_service.dart';
import 'package:sway/features/user/services/user_service.dart';
import 'package:sway/features/user/widgets/follow_count_widget.dart';
import 'package:sway/features/venue/venue.dart';
import 'package:sway/features/venue/models/venue_model.dart';
import 'package:sway/features/venue/widgets/venue_item_widget.dart';
import 'package:sway/features/venue/widgets/venue_modal_bottom_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();

  late Future<User?> _userFuture;
  late Future<List<Genre>> _followedGenresFuture;
  late Future<List<Artist>> _followedArtistsFuture;
  late Future<List<Venue>> _followedVenuesFuture;
  late Future<List<Promoter>> _followedPromotersFuture;
  late Future<List<Event>> _interestedEventsFuture;
  late Future<List<Event>> _upcomingEventsFuture;
  late Future<List<Event>> _attendedEventsFuture;

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  /// Loads the current user and related data.
  void _fetchAllData() {
    _userFuture = _userService.getCurrentUser();
    _userFuture.then((user) {
      if (user != null) {
        setState(() {
          _followedGenresFuture =
              UserFollowGenreService().getFollowedGenresByUserId(user.id);
          _followedArtistsFuture =
              UserFollowArtistService().getFollowedArtistsByUserId(user.id);
          _followedVenuesFuture =
              UserFollowVenueService().getFollowedVenuesByUserId(user.id);
          _followedPromotersFuture =
              UserFollowPromoterService().getFollowedPromotersByUserId(user.id);
          // Use the same future for interested and upcoming events.
          _interestedEventsFuture = _upcomingEventsFuture =
              UserInterestEventService().getInterestedEventsByUserId(user.id);
          _attendedEventsFuture =
              UserInterestEventService().getGoingEventsByUserId(user.id);
        });
      }
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _fetchAllData();
    });
    await Future.wait([
      _userFuture,
      _followedGenresFuture,
      _followedArtistsFuture,
      _followedVenuesFuture,
      _followedPromotersFuture,
      _interestedEventsFuture,
      _attendedEventsFuture,
    ]);
  }

  /// Builds a section title with an arrow button if more items are available.
  Widget _buildSectionTitle(String title, bool hasMore, VoidCallback? onMore) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment:
            hasMore ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (hasMore)
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: onMore,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('User Profile')),
            body: const Center(child: CircularProgressIndicator.adaptive()),
          );
        } else if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('User Profile')),
            body: const Center(child: Text('User not found')),
          );
        } else {
          final user = snapshot.data!;
          return Scaffold(
            appBar: AppBar(
              title: Text(user.username),
              actions: [
                // Edit button
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final updatedUser = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfileScreen(user: user),
                      ),
                    );
                    if (updatedUser != null) {
                      setState(() {});
                    }
                  },
                ),
                // Share button
                Transform.flip(
                  flipX: true,
                  child: IconButton(
                    icon: const Icon(Icons.reply),
                    onPressed: () {
                      shareEntity('user', user.id, user.username);
                    },
                  ),
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                // Constrain the width to avoid infinite width errors.
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      minWidth: MediaQuery.of(context).size.width),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Picture
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimary
                                  .withAlpha(128),
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: ImageWithErrorHandler(
                              imageUrl: user.profilePictureUrl,
                              width: 150,
                              height: 150,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: sectionTitleSpacing),
                      // Username
                      Text(
                        user.username,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      // Registration Date
                      Text(
                        formatEventDate(user.createdAt.toLocal()),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: sectionSpacing),
                      // FOLLOWERS & FOLLOWING Section
                      FollowersCountWidget(
                        entityId: user.id,
                        entityType: 'user',
                      ),
                      const SizedBox(height: sectionSpacing),
                      // GENRES Section
                      FutureBuilder<List<Genre>>(
                        future: _followedGenresFuture,
                        builder: (context, genreSnapshot) {
                          if (genreSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator.adaptive());
                          } else if (genreSnapshot.hasError ||
                              !genreSnapshot.hasData ||
                              genreSnapshot.data!.isEmpty) {
                            return const SizedBox.shrink();
                          } else {
                            final genres = genreSnapshot.data!;
                            final bool hasMore = genres.length > 5;
                            final displayGenres =
                                hasMore ? genres.sublist(0, 5) : genres;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle(
                                  "MOODS",
                                  hasMore,
                                  () => showGenreModalBottomSheet(
                                    context,
                                    genres.map((g) => g.id).toList(),
                                  ),
                                ),
                                const SizedBox(height: sectionTitleSpacing),
                                Wrap(
                                  spacing: 8.0,
                                  children: displayGenres.map((genre) {
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                GenreScreen(genreId: genre.id),
                                          ),
                                        );
                                      },
                                      child: GenreChip(genreId: genre.id),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: sectionSpacing),
                              ],
                            );
                          }
                        },
                      ),

                      // ARTISTS Section
                      FutureBuilder<List<Artist>>(
                        future: _followedArtistsFuture,
                        builder: (context, artistSnapshot) {
                          if (artistSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator.adaptive());
                          } else if (artistSnapshot.hasError ||
                              !artistSnapshot.hasData ||
                              artistSnapshot.data!.isEmpty) {
                            return const SizedBox.shrink();
                          } else {
                            final artists = artistSnapshot.data!;
                            final bool hasMore = artists.length > 5;
                            final displayArtists =
                                hasMore ? artists.sublist(0, 5) : artists;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle(
                                  "ARTISTS",
                                  hasMore,
                                  () => showArtistModalBottomSheet(
                                      context, artists),
                                ),
                                const SizedBox(height: sectionTitleSpacing),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: displayArtists.map((artist) {
                                      return Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: ArtistTileItemWidget(
                                          artist: artist,
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ArtistScreen(
                                                        artistId: artist.id),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                const SizedBox(height: sectionSpacing),
                              ],
                            );
                          }
                        },
                      ),

                      // VENUES Section
                      FutureBuilder<List<Venue>>(
                        future: _followedVenuesFuture,
                        builder: (context, venueSnapshot) {
                          if (venueSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator.adaptive());
                          } else if (venueSnapshot.hasError ||
                              !venueSnapshot.hasData ||
                              venueSnapshot.data!.isEmpty) {
                            return const SizedBox.shrink();
                          } else {
                            final venues = venueSnapshot.data!;
                            final bool hasMore = venues.length > 3;
                            final displayVenues =
                                hasMore ? venues.sublist(0, 3) : venues;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle(
                                  "VENUES",
                                  hasMore,
                                  () => showVenueModalBottomSheet(
                                      context, venues),
                                ),
                                const SizedBox(height: sectionTitleSpacing),
                                Container(
                                  width: MediaQuery.of(context).size.width,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: displayVenues.map((venue) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8.0),
                                        child: VenueListItemWidget(
                                          venue: venue,
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    VenueScreen(
                                                        venueId: venue.id!),
                                              ),
                                            );
                                          },
                                          maxNameLength: 20,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                const SizedBox(height: sectionSpacing),
                              ],
                            );
                          }
                        },
                      ),

// PROMOTERS Section
                      FutureBuilder<List<Promoter>>(
                        future: _followedPromotersFuture,
                        builder: (context, promoterSnapshot) {
                          if (promoterSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator.adaptive());
                          } else if (promoterSnapshot.hasError ||
                              !promoterSnapshot.hasData ||
                              promoterSnapshot.data!.isEmpty) {
                            return const SizedBox.shrink();
                          } else {
                            final promoters = promoterSnapshot.data!;
                            final bool hasMore = promoters.length > 3;
                            final displayPromoters =
                                hasMore ? promoters.sublist(0, 3) : promoters;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle(
                                  "PROMOTERS",
                                  hasMore,
                                  () => showPromoterModalBottomSheet(
                                      context, promoters),
                                ),
                                const SizedBox(height: sectionTitleSpacing),
                                Container(
                                  width: MediaQuery.of(context).size.width,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: displayPromoters.map((promoter) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8.0),
                                        child: PromoterListItemWidget(
                                          promoter: promoter,
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    PromoterScreen(
                                                        promoterId:
                                                            promoter.id!),
                                              ),
                                            );
                                          },
                                          maxNameLength: 20,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                const SizedBox(height: sectionSpacing),
                              ],
                            );
                          }
                        },
                      ),
                      // UPCOMING EVENTS Section (Interested events)
                      FutureBuilder<List<Event>>(
                        future: _upcomingEventsFuture,
                        builder: (context, eventSnapshot) {
                          if (eventSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator.adaptive());
                          } else if (eventSnapshot.hasError ||
                              !eventSnapshot.hasData ||
                              eventSnapshot.data!.isEmpty) {
                            return const SizedBox.shrink();
                          } else {
                            final events = eventSnapshot.data!;
                            const int displayCount = 5;
                            final bool hasMore = events.length > displayCount;
                            final displayEvents = hasMore
                                ? events.sublist(0, displayCount)
                                : events;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle(
                                  "UPCOMING EVENTS",
                                  hasMore,
                                  () => showEventModalBottomSheet(
                                      context, events),
                                ),
                                const SizedBox(height: sectionTitleSpacing),
                                SizedBox(
                                  height: 258,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    scrollDirection: Axis.horizontal,
                                    itemCount: displayEvents.length,
                                    itemBuilder: (context, index) {
                                      final event = displayEvents[index];
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(right: 16.0),
                                        child: SizedBox(
                                          width: 320,
                                          child: EventCardItemWidget(
                                            event: event,
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      EventScreen(event: event),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: sectionSpacing),
                              ],
                            );
                          }
                        },
                      ),
                      // ATTENDED EVENTS Section (Past events)
                      FutureBuilder<List<Event>>(
                        future: _attendedEventsFuture,
                        builder: (context, eventSnapshot) {
                          if (eventSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator.adaptive());
                          } else if (eventSnapshot.hasError ||
                              !eventSnapshot.hasData ||
                              eventSnapshot.data!.isEmpty) {
                            return const SizedBox.shrink();
                          } else {
                            final events = eventSnapshot.data!;
                            const int displayCount = 5;
                            final bool hasMore = events.length > displayCount;
                            final List<Event> displayEvents = hasMore
                                ? events.sublist(0, displayCount)
                                : events;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle(
                                  "ATTENDED EVENTS",
                                  hasMore,
                                  () => showEventModalBottomSheet(
                                      context, events),
                                ),
                                const SizedBox(height: sectionTitleSpacing),
                                SizedBox(
                                  height: 258,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    scrollDirection: Axis.horizontal,
                                    itemCount: displayEvents.length,
                                    itemBuilder: (context, index) {
                                      final event = displayEvents[index];
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(right: 16.0),
                                        child: SizedBox(
                                          width: 320,
                                          child: EventCardItemWidget(
                                            event: event,
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      EventScreen(event: event),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: sectionSpacing),
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
