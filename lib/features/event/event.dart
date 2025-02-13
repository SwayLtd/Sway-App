// lib/features/event/screens/event_screen.dart

import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:sway/core/constants/dimensions.dart'; // sectionSpacing & sectionTitleSpacing
import 'package:sway/core/utils/date_utils.dart'; // Utilise ici la fonction formatEventDateRange
import 'package:sway/core/utils/share_util.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/artist/artist.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/artist/widgets/artist_item_widget.dart';
import 'package:sway/features/artist/widgets/artist_modal_bottom_sheet.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/screens/edit_event_screen.dart';
import 'package:sway/features/event/services/event_artist_service.dart';
import 'package:sway/features/event/services/event_genre_service.dart';
import 'package:sway/features/event/services/event_promoter_service.dart';
import 'package:sway/features/event/services/event_venue_service.dart';
import 'package:sway/features/event/widgets/info_card.dart';
import 'package:sway/features/genre/genre.dart';
import 'package:sway/features/genre/widgets/genre_chip.dart';
import 'package:sway/features/genre/widgets/genre_modal_bottom_sheet.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/promoter/promoter.dart';
import 'package:sway/features/promoter/widgets/promoter_item_widget.dart';
import 'package:sway/features/promoter/widgets/promoter_modal_bottom_sheet.dart';
import 'package:sway/features/ticketing/models/ticket_model.dart';
import 'package:sway/features/ticketing/screens/ticket_detail_screen.dart';
import 'package:sway/features/ticketing/services/ticket_service.dart';
import 'package:sway/features/ticketing/ticketing.dart';
import 'package:sway/features/user/services/user_permission_service.dart';
import 'package:sway/features/user/widgets/follow_count_widget.dart';
import 'package:sway/features/venue/models/venue_model.dart';
import 'package:sway/features/venue/venue.dart';
import 'package:sway/features/user/widgets/interest_event_button_widget.dart';
import 'package:sway/features/event/widgets/event_location_map_widget.dart';

class EventScreen extends StatefulWidget {
  final Event event;

  const EventScreen({required this.event, Key? key}) : super(key: key);

  @override
  _EventScreenState createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  late Event _event;
  late Future<List> _genresFuture;
  late Future<List<Map<String, dynamic>>> _artistsFuture;
  late Future<List<Promoter>> _promotersFuture;
  late Future<Venue?> _venueFuture;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _fetchData();
  }

  // Initializes the futures for each section.
  void _fetchData() {
    _genresFuture = EventGenreService().getGenresByEventId(_event.id!);
    _artistsFuture = EventArtistService().getArtistsByEventId(_event.id!);
    _promotersFuture = EventPromoterService().getPromotersByEventId(_event.id!);
    _venueFuture = EventVenueService().getVenueByEventId(_event.id!);
  }

  Future<void> _refreshData() async {
    setState(() {
      _fetchData();
    });
    await Future.wait([
      _genresFuture,
      _artistsFuture,
      _promotersFuture,
      _venueFuture,
    ]);
  }

  /// Builds a section title with a forward arrow if needed.
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
        title: Text(_event.title),
        actions: [
          // Edit button (displayed if the user has permission)
          FutureBuilder<bool>(
            future: UserPermissionService()
                .hasPermissionForCurrentUser(_event.id!, 'event', 'edit'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting ||
                  !snapshot.hasData ||
                  snapshot.data == false) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final updatedEvent = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditEventScreen(event: _event),
                    ),
                  );
                  if (updatedEvent != null) {
                    setState(() {
                      _event = updatedEvent;
                    });
                  }
                },
              );
            },
          ),
          // Share button
          Transform.flip(
            flipX: true,
            child: IconButton(
              icon: const Icon(Icons.reply),
              onPressed: () {
                shareEntity('event', _event.id!, _event.title);
              },
            ),
          ),
          // Interest button (with dropdown menu)
          InterestEventButtonWidget(eventId: _event.id!),
          // Ticket count widget using TicketService
          FutureBuilder<List<Ticket>>(
            future: TicketService().getTicketsByEventId(_event.id!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              } else if (snapshot.hasError || !snapshot.hasData) {
                return const SizedBox();
              } else {
                final tickets = snapshot.data!;
                final int count = tickets.length;
                final String ticketText =
                    count <= 1 ? '$count ticket' : '$count tickets';

                return GestureDetector(
                  onTap: () {
                    if (count == 0) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => TicketingScreen()),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TicketDetailScreen(
                            tickets: tickets,
                            initialTicket: tickets.first,
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(
                        width: 1,
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withValues(alpha: 0.5),
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_activity_outlined,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ticketText,
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event image (kept with the same format)
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
                      imageUrl: _event.imageUrl,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: sectionSpacing),
              // Event title
              Text(
                _event.title,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: sectionTitleSpacing),
              // Followers count
              FollowersCountWidget(entityId: _event.id!, entityType: 'event'),
              const SizedBox(height: sectionSpacing),
              // InfoCard: Date (using formatEventDateRange from date_utils.dart)
              InfoCard(
                title: "Date",
                content:
                    "${formatEventDateRange(_event.dateTime, _event.endDateTime)}",
              ),
              const SizedBox(height: sectionTitleSpacing),
              // InfoCard: Location
              FutureBuilder<Venue?>(
                future: _venueFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const InfoCard(
                        title: "Location", content: 'Loading');
                  } else if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data == null) {
                    return const InfoCard(
                        title: "Location", content: 'Location not found');
                  } else {
                    final venue = snapshot.data!;
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                VenueScreen(venueId: venue.id!),
                          ),
                        );
                      },
                      child: InfoCard(title: "Location", content: venue.name),
                    );
                  }
                },
              ),
              const SizedBox(height: sectionSpacing),
              // ABOUT section (description)
              if (_event.description.isNotEmpty) ...[
                _buildSectionTitle("ABOUT", false, null),
                const SizedBox(height: sectionTitleSpacing),
                ExpandableText(
                  _event.description,
                  expandText: 'show more',
                  collapseText: 'show less',
                  maxLines: 3,
                  linkColor: Theme.of(context).primaryColor,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: sectionSpacing),
              ],
              // MOOD section (Genres)
              FutureBuilder<List>(
                future: _genresFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator.adaptive());
                  } else if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  } else {
                    final genres = snapshot.data!;
                    final bool hasMore = genres.length > 5;
                    final displayGenres =
                        hasMore ? genres.sublist(0, 5) : genres;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle("MOOD", hasMore, () {
                          // Show up to 10 genres in a modal.
                          showGenreModalBottomSheet(
                              context, genres.take(10).cast<int>().toList());
                        }),
                        const SizedBox(height: sectionTitleSpacing),
                        Wrap(
                          spacing: 8.0,
                          children: displayGenres.map<Widget>((genreId) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        GenreScreen(genreId: genreId),
                                  ),
                                );
                              },
                              child: GenreChip(genreId: genreId),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: sectionSpacing),
                      ],
                    );
                  }
                },
              ),
              // LINE UP section (Artists)
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _artistsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator.adaptive());
                  } else if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  } else {
                    final artistEntries = snapshot.data!;
                    // Flatten and deduplicate the list of artists.
                    final Map<int, Artist> uniqueArtists = {};
                    for (final entry in artistEntries) {
                      final List<dynamic> artists =
                          entry['artists'] as List<dynamic>;
                      for (final artist in artists.cast<Artist>()) {
                        uniqueArtists[artist.id!] = artist;
                      }
                    }
                    final artistsList = uniqueArtists.values.toList();
                    final bool hasMore = artistsList.length > 5;
                    final displayArtists =
                        hasMore ? artistsList.sublist(0, 5) : artistsList;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle("LINE UP", hasMore, () {
                          // Show up to 10 artists in a modal.
                          showArtistModalBottomSheet(
                              context, artistsList.take(10).toList());
                        }),
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
                                            ArtistScreen(artistId: artist.id!),
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
              // ORGANIZED BY section (Promoters)
              FutureBuilder<List<Promoter>>(
                future: _promotersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator.adaptive());
                  } else if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  } else {
                    final promoters = snapshot.data!;
                    final bool hasMore = promoters.length > 3;
                    final displayPromoters =
                        hasMore ? promoters.sublist(0, 3) : promoters;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle("ORGANIZED BY", hasMore, () {
                          // Show up to 10 promoters in a modal.
                          showPromoterModalBottomSheet(
                              context, promoters.take(10).toList());
                        }),
                        const SizedBox(height: sectionTitleSpacing),
                        Column(
                          children: displayPromoters.map((promoter) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: PromoterListItemWidget(
                                promoter: promoter,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PromoterScreen(
                                          promoterId: promoter.id!),
                                    ),
                                  );
                                },
                                maxNameLength: 20,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: sectionSpacing),
                      ],
                    );
                  }
                },
              ),
              // Map section: displays the event location on a map.
              FutureBuilder<Venue?>(
                future: _venueFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
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
                        EventLocationMapWidget(location: venue.location),
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
    );
  }
}
