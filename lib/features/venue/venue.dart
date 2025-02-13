// lib/features/venue/venue.dart

import 'package:flutter/material.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:sway/core/constants/dimensions.dart';
import 'package:sway/core/utils/share_util.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/artist/artist.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/artist/widgets/artist_item_widget.dart'; // Contains ArtistTileItemWidget
import 'package:sway/features/artist/widgets/artist_modal_bottom_sheet.dart';
import 'package:sway/features/claim/widgets/verified_icon_widget.dart';
import 'package:sway/features/event/event.dart';
import 'package:sway/features/event/widgets/event_item_widget.dart';
import 'package:sway/features/event/widgets/event_modal_bottom_sheet.dart';
import 'package:sway/features/event/widgets/info_card.dart';
import 'package:sway/features/genre/genre.dart';
import 'package:sway/features/genre/widgets/genre_chip.dart';
import 'package:sway/features/genre/widgets/genre_modal_bottom_sheet.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/promoter/promoter.dart';
import 'package:sway/features/promoter/widgets/promoter_item_widget.dart';
import 'package:sway/features/promoter/widgets/promoter_modal_bottom_sheet.dart';
import 'package:sway/features/user/services/user_permission_service.dart';
import 'package:sway/features/user/widgets/follow_count_widget.dart';
import 'package:sway/features/user/widgets/following_button_widget.dart';
import 'package:sway/features/venue/models/venue_model.dart';
import 'package:sway/features/venue/screens/edit_venue_screen.dart';
import 'package:sway/features/venue/services/venue_genre_service.dart';
import 'package:sway/features/venue/services/venue_promoter_service.dart';
import 'package:sway/features/venue/services/venue_resident_artists_service.dart';
import 'package:sway/features/venue/services/venue_service.dart';
import 'package:maps_launcher/maps_launcher.dart';
// Import the map widget
import 'package:sway/features/event/widgets/event_location_map_widget.dart';
// Import EventService to get upcoming events via EventVenueService.
import 'package:sway/features/event/services/event_venue_service.dart';
// Import event screen and event card widget for navigation.
import 'package:sway/features/event/models/event_model.dart';

class VenueScreen extends StatefulWidget {
  final int venueId;

  const VenueScreen({required this.venueId, Key? key}) : super(key: key);

  @override
  _VenueScreenState createState() => _VenueScreenState();
}

class _VenueScreenState extends State<VenueScreen> {
  late Future<Venue?> _venueFuture;
  late Future<List<Artist>> _residentArtistsFuture;
  late Future<List<Promoter>> _ownedByFuture;
  late Future<List<int>> _genresFuture;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    _venueFuture = VenueService().getVenueById(widget.venueId);
    _residentArtistsFuture =
        VenueResidentArtistsService().getArtistsByVenueId(widget.venueId);
    _ownedByFuture =
        VenuePromoterService().getPromotersByVenueId(widget.venueId);
    _genresFuture = VenueGenreService().getGenresByVenueId(widget.venueId);
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() {
      _fetchData();
    });
    await Future.wait([
      _venueFuture,
      _residentArtistsFuture,
      _ownedByFuture,
      _genresFuture,
    ]);
  }

  /// Builds a section title with an optional forward arrow.
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
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Venue?>(
          future: _venueFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Loading');
            } else if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data == null) {
              return const Text('Venue');
            } else {
              return Text('${snapshot.data!.name}');
            }
          },
        ),
        actions: [
          FutureBuilder<bool>(
            future: UserPermissionService()
                .hasPermissionForCurrentUser(widget.venueId, 'venue', 'edit'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting ||
                  !snapshot.hasData ||
                  snapshot.data == false) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final venue =
                      await VenueService().getVenueById(widget.venueId);
                  if (venue != null) {
                    final updatedVenue = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditVenueScreen(venue: venue),
                      ),
                    );
                    if (updatedVenue != null) {
                      _refresh();
                    }
                  }
                },
              );
            },
          ),
          FutureBuilder<bool>(
            future: UserPermissionService().hasPermissionForCurrentUser(
              widget.venueId,
              'venue',
              'insight',
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting ||
                  !snapshot.hasData ||
                  !snapshot.data!) {
                return const SizedBox.shrink();
              } else {
                return const SizedBox.shrink();
                // TODO: Implement insights for venues
              }
            },
          ),
          FutureBuilder<Venue?>(
            future: VenueService().getVenueById(widget.venueId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              } else if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data == null) {
                return const SizedBox.shrink();
              } else {
                final venue = snapshot.data!;
                return Transform.flip(
                  flipX: true,
                  child: IconButton(
                    icon: const Icon(Icons.reply),
                    onPressed: () {
                      shareEntity('venue', widget.venueId, venue.name);
                    },
                  ),
                );
              }
            },
          ),
          FollowingButtonWidget(
            entityId: widget.venueId,
            entityType: 'venue',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<Venue?>(
          future: _venueFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator.adaptive());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text('Venue not found'));
            } else {
              final venue = snapshot.data!;
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image section
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimary
                                  .withValues(alpha: 0.5),
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: ImageWithErrorHandler(
                              imageUrl: venue.imageUrl,
                              width: 200,
                              height: 200,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: sectionSpacing),
                      // Display venue name with VerifiedIconWidget for verification status
                      Container(
                        width: double.infinity,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              venue.name,
                              textAlign: TextAlign.left,
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            VerifiedIconWidget(
                              isVerified: venue
                                  .isVerified, // Make sure your Artist model has an "isVerified" property
                              entityType: 'venue',
                              entityName: venue.name,
                              entityId: venue.id,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: sectionTitleSpacing),
                      // Followers Count
                      FollowersCountWidget(
                        entityId: widget.venueId,
                        entityType: 'venue',
                      ),
                      SizedBox(height: sectionSpacing),
                      // Location InfoCard
                      FutureBuilder<Venue?>(
                        future: VenueService().getVenueById(widget.venueId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const InfoCard(
                              title: "Location",
                              content: 'Loading',
                            );
                          } else if (snapshot.hasError ||
                              !snapshot.hasData ||
                              snapshot.data == null) {
                            return const InfoCard(
                              title: "Location",
                              content: 'Location not found',
                            );
                          } else {
                            final venue = snapshot.data!;
                            return InkWell(
                              onTap: () {
                                // Use maps_launcher to open the external maps app with the venue address.
                                MapsLauncher.launchQuery(venue.location);
                              },
                              child: InfoCard(
                                title: "Location",
                                content: venue.location,
                              ),
                            );
                          }
                        },
                      ),
                      SizedBox(height: sectionSpacing),
                      // ABOUT Section
                      if (venue.description.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "ABOUT",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ExpandableText(
                              venue.description,
                              expandText: 'show more',
                              collapseText: 'show less',
                              maxLines: 3,
                              linkColor: Theme.of(context).primaryColor,
                            ),
                          ],
                        ),
                      SizedBox(height: sectionSpacing),
                      // MOOD Section
                      FutureBuilder<List<int>>(
                        future: _genresFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator.adaptive());
                          } else if (snapshot.hasError ||
                              !snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return const SizedBox.shrink();
                          } else {
                            final genres = snapshot.data!;
                            final bool hasMoreGenres = genres.length > 5;
                            final displayCount =
                                hasMoreGenres ? 5 : genres.length;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: hasMoreGenres
                                      ? MainAxisAlignment.spaceBetween
                                      : MainAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "MOOD",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (hasMoreGenres)
                                      IconButton(
                                        icon: const Icon(Icons.arrow_forward),
                                        onPressed: () {
                                          showGenreModalBottomSheet(
                                              context, genres);
                                        },
                                      ),
                                  ],
                                ),
                                const SizedBox(height: sectionTitleSpacing),
                                SizedBox(
                                  height: 60,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: displayCount,
                                    itemBuilder: (context, index) {
                                      final genreId = genres[index];
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8.0),
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    GenreScreen(
                                                        genreId: genreId),
                                              ),
                                            );
                                          },
                                          child: GenreChip(genreId: genreId),
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
                      // UPCOMING EVENTS Section
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: EventVenueService()
                            .getEventsByVenueId(widget.venueId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox();
                          } else if (snapshot.hasError ||
                              !snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return const SizedBox();
                          } else {
                            final eventsData = snapshot.data!;
                            final now = DateTime.now();
                            final upcomingEvents =
                                eventsData.where((eventData) {
                              final Event event = eventData['event'] as Event;
                              return event.dateTime.isAfter(now);
                            }).toList();
                            if (upcomingEvents.isEmpty) {
                              return const SizedBox();
                            }
                            final bool hasMore = upcomingEvents.length > 5;
                            final displayEvents = hasMore
                                ? upcomingEvents.sublist(0, 5)
                                : upcomingEvents;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header text: UPCOMING EVENTS
                                const Text(
                                  "UPCOMING EVENTS",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: sectionTitleSpacing),
                                SizedBox(
                                  height: 258, // Height for event cards
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: displayEvents.length,
                                    itemBuilder: (context, index) {
                                      final eventData = displayEvents[index];
                                      final Event event =
                                          eventData['event'] as Event;
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
                                if (hasMore)
                                  IconButton(
                                    icon: const Icon(Icons.arrow_forward),
                                    onPressed: () {
                                      // Show up to 10 events in a modal bottom sheet.
                                      showEventModalBottomSheet(
                                          context,
                                          upcomingEvents
                                              .take(10)
                                              .cast<Event>()
                                              .toList());
                                    },
                                  ),
                                const SizedBox(height: sectionSpacing),
                              ],
                            );
                          }
                        },
                      ),
                      // RESIDENT ARTISTS Section
                      FutureBuilder<List<Artist>>(
                        future: _residentArtistsFuture,
                        builder: (context, artistSnapshot) {
                          if (artistSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator.adaptive();
                          } else if (artistSnapshot.hasError ||
                              !artistSnapshot.hasData ||
                              artistSnapshot.data!.isEmpty) {
                            return const SizedBox.shrink();
                          } else {
                            final artists = artistSnapshot.data!;
                            final bool hasMoreArtists = artists.length > 5;
                            final displayedArtists = hasMoreArtists
                                ? artists.take(5).toList()
                                : artists;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: hasMoreArtists
                                      ? MainAxisAlignment.spaceBetween
                                      : MainAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "RESIDENT ARTISTS",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (hasMoreArtists)
                                      IconButton(
                                        icon: const Icon(Icons.arrow_forward),
                                        onPressed: () {
                                          showArtistModalBottomSheet(context,
                                              artists.take(10).toList());
                                        },
                                      ),
                                  ],
                                ),
                                const SizedBox(height: sectionTitleSpacing),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: displayedArtists.map((artist) {
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
                                                        artistId: artist.id!),
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
                      // OWNED BY Section
                      FutureBuilder<List<Promoter>>(
                        future: _ownedByFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator.adaptive());
                          } else if (snapshot.hasError ||
                              !snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return const SizedBox.shrink();
                          } else {
                            final promoters = snapshot.data!;
                            final bool hasMorePromoters = promoters.length > 3;
                            final displayCount =
                                hasMorePromoters ? 3 : promoters.length;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: hasMorePromoters
                                      ? MainAxisAlignment.spaceBetween
                                      : MainAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "OWNED BY",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (hasMorePromoters)
                                      IconButton(
                                        icon: const Icon(Icons.arrow_forward),
                                        onPressed: () {
                                          showPromoterModalBottomSheet(
                                              context, promoters);
                                        },
                                      ),
                                  ],
                                ),
                                const SizedBox(height: sectionTitleSpacing),
                                Column(
                                  children: promoters
                                      .take(displayCount)
                                      .map((promoter) {
                                    return PromoterListItemWidget(
                                      promoter: promoter,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                PromoterScreen(
                                                    promoterId: promoter.id!),
                                          ),
                                        );
                                      },
                                      maxNameLength: 20,
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: sectionSpacing),
                              ],
                            );
                          }
                        },
                      ),
                      // MAP Section
                      FutureBuilder<Venue?>(
                        future: _venueFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox();
                          } else if (snapshot.hasError ||
                              !snapshot.hasData ||
                              snapshot.data == null) {
                            return const SizedBox();
                          } else {
                            final venue = snapshot.data!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle("MAP", false, null),
                                const SizedBox(height: sectionTitleSpacing),
                                EventLocationMapWidget(
                                    location: venue.location),
                                const SizedBox(height: sectionSpacing),
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
