// lib/features/venue/venue.dart

import 'package:flutter/material.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:sway/core/constants/dimensions.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/artist/artist.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/artist/widgets/artist_item_widget.dart';
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
// Correction de l'import
import 'package:sway/features/artist/widgets/artist_modal_bottom_sheet.dart'; // Import existant

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Venue?>(
          future: _venueFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Loading...');
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
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              } else if (snapshot.hasError ||
                  !snapshot.hasData ||
                  !snapshot.data!) {
                return const SizedBox.shrink();
              } else {
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
              }
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
              return const Center(child: CircularProgressIndicator());
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
                      // Image
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: ImageWithErrorHandler(
                            imageUrl: venue.imageUrl,
                            width: 200,
                            height: 200,
                          ),
                        ),
                      ),
                      SizedBox(height: sectionSpacing),
                      // Venue Name
                      Text(
                        venue.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
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
                              content: 'Loading...',
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
                            return InfoCard(
                                title: "Location", content: venue.location);
                          }
                        },
                      ),
                      SizedBox(height: sectionSpacing),
                      // ABOUT Section
                      if (venue.description.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Remplacer le Row par un simple Text
                            const Text(
                              "ABOUT",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: sectionTitleSpacing),
                            ExpandableText(
                              venue.description,
                              expandText: 'show more',
                              collapseText: 'show less',
                              maxLines: 3,
                              linkColor: Theme.of(context).primaryColor,
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: sectionSpacing),
                          ],
                        ),
                      // MOOD Section
                      FutureBuilder<List<int>>(
                        future: _genresFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(
                                child: Text('Error: ${snapshot.error}'));
                          } else if (!snapshot.hasData ||
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
                                  height:
                                      60, // Hauteur fixe adaptée à vos GenreChips
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
                      // RESIDENT ARTISTS Section
                      FutureBuilder<List<Artist>>(
                        future: _residentArtistsFuture,
                        builder: (context, artistSnapshot) {
                          if (artistSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          } else if (artistSnapshot.hasError) {
                            return Text('Error: ${artistSnapshot.error}');
                          } else if (!artistSnapshot.hasData ||
                              artistSnapshot.data!.isEmpty) {
                            return const SizedBox
                                .shrink(); // Ne rien afficher si vide
                          } else {
                            final artists = artistSnapshot.data!;
                            final bool hasMoreArtists = artists.length > 7;
                            final displayedArtists = hasMoreArtists
                                ? artists.take(7).toList()
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
                                          fontWeight: FontWeight.bold),
                                    ),
                                    if (hasMoreArtists)
                                      IconButton(
                                        icon: const Icon(Icons.arrow_forward),
                                        onPressed: () {
                                          showArtistModalBottomSheet(
                                              context, artists);
                                        },
                                      ),
                                  ],
                                ),
                                const SizedBox(height: sectionTitleSpacing),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      ...displayedArtists.map((artist) {
                                        return ArtistCardItemWidget(
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
                                        );
                                      }).toList(),
                                    ],
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
                                child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(
                                child: Text('Error: ${snapshot.error}'));
                          } else if (!snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return const SizedBox
                                .shrink(); // Ne rien afficher si vide
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
                                              promoterId: promoter.id,
                                            ),
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
