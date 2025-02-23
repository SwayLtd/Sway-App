// lib/features/event/screens/event_screen.dart

import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:sway/core/constants/dimensions.dart'; // sectionSpacing & sectionTitleSpacing
import 'package:sway/core/utils/date_utils.dart'; // for formatEventDateRange
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
import 'package:sway/features/event/services/event_service.dart';
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
import 'package:add_2_calendar/add_2_calendar.dart' as calendar;
import 'package:url_launcher/url_launcher.dart';

class EventScreen extends StatefulWidget {
  final Event event;

  const EventScreen({required this.event, Key? key}) : super(key: key);

  @override
  _EventScreenState createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  late Event _event;
  late Future<Event?> _eventFuture;
  late Future<List> _genresFuture;
  late Future<List<Map<String, dynamic>>> _artistsFuture;
  late Future<List<Promoter>> _promotersFuture;
  late Future<Venue?> _venueFuture;
  late Future<Map<String, dynamic>?> _metadataFuture;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _eventFuture = _fetchEventData();
    _fetchData();
    _metadataFuture = EventService().getEventMetadata(_event.id!);
  }

  /// Launches a URL if possible.
  Future<void> _launchURL(Uri url) async {
    if (!await launchUrl(url)) {
      throw 'Could not launch $url';
    }
  }

  Future<Event?> _fetchEventData() async {
    final updatedEvent = await EventService().getEventById(_event.id!);
    return updatedEvent;
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
      _eventFuture =
          _fetchEventData(); // Rafraîchissement des données de l'événement
      _fetchData(); // Rafraîchissement des autres données
    });
    await Future.wait([
      _eventFuture,
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
                .hasPermissionForCurrentUser(_event.id!, 'event', 2),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting ||
                  !snapshot.hasData ||
                  snapshot.data == false) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  // Naviguer vers l'écran d'édition et attendre le retour avec l'événement mis à jour
                  final updatedEvent = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditEventScreen(event: _event),
                    ),
                  );
                  if (updatedEvent != null) {
                    setState(() {
                      _event =
                          updatedEvent; // Mettre à jour l'événement avec les modifications
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
              // Event image.
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
              // Event title.
              Text(
                _event.title,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: sectionTitleSpacing),
              // Followers count.
              FollowersCountWidget(entityId: _event.id!, entityType: 'event'),
              const SizedBox(height: sectionSpacing),
              // InfoCard: Date.
              GestureDetector(
                onTap: () async {
                  final venue = await _venueFuture;
                  final location = venue?.location ?? '';
                  final calendarEvent = calendar.Event(
                    title: _event.title,
                    description: _event.description,
                    location: location,
                    startDate: _event.eventDateTime,
                    endDate: _event.eventEndDateTime ??
                        _event.eventDateTime.add(const Duration(hours: 1)),
                    iosParams: const calendar.IOSParams(
                      reminder: Duration(minutes: 60),
                      url: 'https://sway.events',
                    ),
                    androidParams: const calendar.AndroidParams(
                      emailInvites: [],
                    ),
                  );

                  try {
                    await calendar.Add2Calendar.addEvent2Cal(calendarEvent);
                  } catch (e) {
                    debugPrint("Error adding event to calendar: $e");
                  }
                },
                child: InfoCard(
                  title: "Date",
                  content: _event.eventEndDateTime != null
                      ? formatEventDateRange(
                          _event.eventDateTime, _event.eventEndDateTime!)
                      : "${formatEventDate(_event.eventDateTime)} ${formatEventTime(_event.eventDateTime)}",
                ),
              ),
              const SizedBox(height: sectionTitleSpacing),
              // InfoCard : Location avec précision ajoutée
              FutureBuilder<List<dynamic>>(
                future: Future.wait([_venueFuture, _metadataFuture]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const InfoCard(
                        title: "Location", content: 'Loading');
                  } else if (snapshot.hasError ||
                      snapshot.data == null ||
                      snapshot.data!.isEmpty ||
                      snapshot.data![0] == null) {
                    return const InfoCard(
                        title: "Location", content: 'Location not found');
                  } else {
                    final venue = snapshot.data![0] as Venue;
                    final metadata = snapshot.data![1] as Map<String, dynamic>?;
                    final locationPrecision =
                        metadata?['location_precision'] ?? '';
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
                      child: InfoCard(
                        title: "Location",
                        content:
                            '${venue.name} ${locationPrecision.isNotEmpty ? "- $locationPrecision" : ""}',
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: sectionTitleSpacing),
              // InfoCard : Tickets (rendre cliquable avec URL)
              FutureBuilder<Map<String, dynamic>?>(
                // Assurez-vous que le Map est non nul
                future: _metadataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  } else if (snapshot.hasError || !snapshot.hasData) {
                    return const SizedBox.shrink();
                  } else {
                    final metadata = snapshot.data;
                    final ticketLink = metadata?['ticket_link'] ??
                        ''; // Assurez-vous de fournir une chaîne vide si null
                    return ticketLink.isNotEmpty
                        ? GestureDetector(
                            onTap: () => _launchURL(Uri.parse(ticketLink)),
                            child: InfoCard(
                              title: "Tickets",
                              content: ticketLink, // Contenu propre
                            ),
                          )
                        : const SizedBox.shrink();
                  }
                },
              ),

              /* // InfoCard : Prices
              FutureBuilder<Map<String, dynamic>?>(
                future: _metadataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  } else if (snapshot.hasError || !snapshot.hasData) {
                    return const SizedBox.shrink();
                  } else {
                    final metadata = snapshot.data;
                    final ticketLink = metadata?['prices'];
                    return ticketLink != null
                        ? InfoCard(
                            title: "Prices",
                            content: ticketLink ?? "No prices available",
                          )
                        : const SizedBox.shrink();
                  }
                },
              ),*/

              const SizedBox(height: sectionSpacing),
              // ABOUT section.
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
              // MOOD section.
              FutureBuilder<List>(
                future: _genresFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator.adaptive());
                  } else if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    // return const Center(child: Text("You're offline."));
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
              // LINE UP section.
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
                    final Map<int, Artist> uniqueArtists = {};
                    final Map<int, DateTime?> performanceTimes = {};
                    final Map<int, DateTime?> performanceEndTimes = {};

                    for (final entry in artistEntries) {
                      DateTime? assignmentStartTime;
                      DateTime? assignmentEndTime;
                      if (entry['start_time'] != null) {
                        if (entry['start_time'] is String) {
                          assignmentStartTime =
                              DateTime.parse(entry['start_time'] as String);
                        } else if (entry['start_time'] is DateTime) {
                          assignmentStartTime = entry['start_time'] as DateTime;
                        }
                      }
                      if (entry['end_time'] != null) {
                        if (entry['end_time'] is String) {
                          assignmentEndTime =
                              DateTime.parse(entry['end_time'] as String);
                        } else if (entry['end_time'] is DateTime) {
                          assignmentEndTime = entry['end_time'] as DateTime;
                        }
                      }
                      final List<dynamic> artists =
                          entry['artists'] as List<dynamic>;
                      for (final artist in artists.cast<Artist>()) {
                        uniqueArtists[artist.id!] = artist;
                        if (!performanceTimes.containsKey(artist.id) &&
                            assignmentStartTime != null) {
                          performanceTimes[artist.id!] = assignmentStartTime;
                        }
                        if (!performanceEndTimes.containsKey(artist.id) &&
                            assignmentEndTime != null) {
                          performanceEndTimes[artist.id!] = assignmentEndTime;
                        }
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
                          // Passage du mapping performanceTimes et performanceEndTimes au modal.
                          showArtistModalBottomSheet(
                            context,
                            artistsList.take(10).toList(),
                            performanceTimes: performanceTimes,
                            performanceEndTimes: performanceEndTimes,
                          );
                        }),
                        const SizedBox(height: sectionTitleSpacing),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: displayArtists.map((artist) {
                              // Récupérer les heures de passage si disponibles
                              DateTime? performanceTime =
                                  performanceTimes[artist.id];
                              DateTime? performanceEndTime =
                                  performanceEndTimes[artist.id];

                              return Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: ArtistTileItemWidget(
                                  artist: artist,
                                  performanceTime: performanceTime,
                                  performanceEndTime: performanceEndTime,
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

              // ORGANIZED BY section.
              FutureBuilder<List<Promoter>>(
                future: _promotersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator.adaptive());
                  } else if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    // return const Center(child: Text("You're offline."));
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
              // MAP section.
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
