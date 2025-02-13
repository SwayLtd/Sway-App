// lib/features/promoter/promoter.dart

import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:sway/core/constants/dimensions.dart'; // Import des constantes
import 'package:sway/core/utils/share_util.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/artist/widgets/artist_item_widget.dart'; // Contient ArtistTileItemWidget
import 'package:sway/features/artist/widgets/artist_modal_bottom_sheet.dart';
import 'package:sway/features/claim/widgets/verified_icon_widget.dart';
import 'package:sway/features/event/event.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/widgets/event_item_widget.dart';
import 'package:sway/features/event/widgets/event_modal_bottom_sheet.dart';
import 'package:sway/features/genre/genre.dart';
import 'package:sway/features/genre/widgets/genre_chip.dart';
import 'package:sway/features/genre/widgets/genre_modal_bottom_sheet.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/promoter/screens/edit_promoter_screen.dart';
import 'package:sway/features/promoter/services/promoter_genre_service.dart';
import 'package:sway/features/promoter/services/promoter_service.dart';
import 'package:sway/features/user/services/user_permission_service.dart';
import 'package:sway/features/user/widgets/follow_count_widget.dart';
import 'package:sway/features/user/widgets/following_button_widget.dart';
import 'package:sway/features/promoter/services/promoter_resident_artists_service.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/artist/artist.dart';

class PromoterScreen extends StatefulWidget {
  final int promoterId;

  const PromoterScreen({required this.promoterId, Key? key}) : super(key: key);

  @override
  _PromoterScreenState createState() => _PromoterScreenState();
}

class _PromoterScreenState extends State<PromoterScreen> {
  Promoter? _promoter;
  bool _isLoading = true;
  String? _error;
  // maxEvents peut rester à 2 pour la navigation rapide (dans le header) si nécessaire
  final int maxEvents = 2;

  final UserPermissionService _permissionService = UserPermissionService();

  // Récupération des données du promoteur
  Future<void> _fetchPromoterData() async {
    try {
      final promoter =
          await PromoterService().getPromoterByIdWithEvents(widget.promoterId);
      if (promoter == null) {
        setState(() {
          _error = 'Promoter not found';
          _isLoading = false;
        });
      } else {
        setState(() {
          _promoter = promoter;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchPromoterData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_promoter != null ? '${_promoter!.name}' : 'Promoter'),
        actions: [
          // Bouton d'édition (affiché selon les permissions)
          FutureBuilder<bool>(
            future: _permissionService.hasPermissionForCurrentUser(
              widget.promoterId,
              'promoter',
              2, // manager ou supérieur
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting ||
                  snapshot.hasError ||
                  !snapshot.hasData ||
                  !snapshot.data!) {
                return const SizedBox.shrink();
              } else {
                return IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    if (_promoter != null) {
                      final updatedPromoter = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditPromoterScreen(promoter: _promoter!),
                        ),
                      );
                      if (updatedPromoter != null) {
                        _fetchPromoterData();
                      }
                    }
                  },
                );
              }
            },
          ),
          // Bouton de partage
          FutureBuilder<Promoter?>(
            future: PromoterService().getPromoterById(widget.promoterId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting ||
                  snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data == null) {
                return const SizedBox.shrink();
              } else {
                final promoter = snapshot.data!;
                return Transform.flip(
                  flipX: true,
                  child: IconButton(
                    icon: const Icon(Icons.reply),
                    onPressed: () {
                      shareEntity('promoter', widget.promoterId, promoter.name);
                    },
                  ),
                );
              }
            },
          ),
          // Bouton de suivi
          FollowingButtonWidget(
            entityId: widget.promoterId,
            entityType: 'promoter',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchPromoterData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator.adaptive())
            : _error != null
                ? Center(child: Text('Error: $_error'))
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image du promoteur
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
                                imageUrl: _promoter!.imageUrl,
                                width: 200,
                                height: 200,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: sectionTitleSpacing),
                        // Display promoter name with VerifiedIconWidget for verification status
                        Container(
                          width: double.infinity,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                _promoter!.name,
                                textAlign: TextAlign.left,
                                style: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              VerifiedIconWidget(
                                isVerified: _promoter!
                                    .isVerified, // Make sure your Artist model has an "isVerified" property
                                entityType: 'promoter',
                                entityName: _promoter!.name,
                                entityId: _promoter!.id,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: sectionTitleSpacing),
                        // Compteur de followers
                        FollowersCountWidget(
                          entityId: widget.promoterId,
                          entityType: 'promoter',
                        ),
                        const SizedBox(height: sectionSpacing),
                        // Section "ABOUT"
                        if (_promoter!.description.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "ABOUT",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: sectionTitleSpacing),
                              ExpandableText(
                                _promoter!.description,
                                expandText: 'show more',
                                collapseText: 'show less',
                                maxLines: 3,
                                linkColor: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(height: sectionSpacing),
                            ],
                          )
                        else
                          const SizedBox.shrink(),
                        // Section "MOOD" (Genres affichés dans un Wrap)
                        FutureBuilder<List<int>>(
                          future: PromoterGenreService()
                              .getGenresByPromoterId(widget.promoterId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator.adaptive());
                            } else if (snapshot.hasError) {
                              return Center(
                                  child: Text('Error: ${snapshot.error}'));
                            } else if (!snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return const SizedBox.shrink();
                            } else {
                              final genres = snapshot.data!;
                              final bool hasMoreGenres = genres.length > 5;
                              final displayGenres =
                                  hasMoreGenres ? genres.sublist(0, 5) : genres;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "MOOD",
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
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
                                  Wrap(
                                    spacing: 8.0,
                                    runSpacing: 8.0,
                                    children: displayGenres
                                        .map((genreId) => GestureDetector(
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
                                              child:
                                                  GenreChip(genreId: genreId),
                                            ))
                                        .toList(),
                                  ),
                                  const SizedBox(height: sectionSpacing),
                                ],
                              );
                            }
                          },
                        ),
                        // Section "UPCOMING EVENTS" inspirée de VenueScreen
                        FutureBuilder<List<Event>>(
                          future: PromoterService()
                              .getEventsByIds(_promoter!.upcomingEvents),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const SizedBox();
                            } else if (snapshot.hasError ||
                                !snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return const SizedBox();
                            } else {
                              final events = snapshot.data!;
                              final bool hasMore = events.length > 5;
                              final displayEvents =
                                  hasMore ? events.sublist(0, 5) : events;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                                    height: 258,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: displayEvents.length,
                                      itemBuilder: (context, index) {
                                        final event = displayEvents[index];
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                              right: 16.0),
                                          child: SizedBox(
                                            width: 320,
                                            child: EventCardItemWidget(
                                              event: event,
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        EventScreen(
                                                            event: event),
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
                                        showEventModalBottomSheet(
                                            context, events.take(10).toList());
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
                          future: PromoterResidentArtistsService()
                              .getArtistsByPromoterId(widget.promoterId),
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
                      ],
                    ),
                  ),
      ),
    );
  }
}
