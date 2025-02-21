// lib/features/promoter/promoter.dart

import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:sway/core/constants/dimensions.dart'; // sectionSpacing, sectionTitleSpacing
import 'package:sway/core/utils/share_util.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/artist/widgets/artist_item_widget.dart';
import 'package:sway/features/artist/widgets/artist_modal_bottom_sheet.dart';
import 'package:sway/features/claim/widgets/claim_widgets.dart';
import 'package:sway/features/event/event.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/services/event_promoter_service.dart';
import 'package:sway/features/event/widgets/event_item_widget.dart';
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
  String? _error; // Variable pour stocker le message d'erreur
  List<Event> _upcomingEvents = [];

  final UserPermissionService _permissionService = UserPermissionService();

  // Récupération des données du promoteur
  Future<void> _fetchPromoterData() async {
    try {
      final promoter =
          await PromoterService().getPromoterById(widget.promoterId);
      if (promoter == null) {
        setState(() {
          _error = 'Promoter not found';
          _isLoading = false;
        });
      } else {
        setState(() {
          _promoter = promoter;
          _isLoading = false;
          _error = null;
        });

        // Récupérer les événements à partir de EventPromoterService
        _upcomingEvents = await EventPromoterService()
            .getEventsByPromoterId(widget.promoterId);

        // Utiliser setState ici pour forcer la mise à jour de l'interface utilisateur
        setState(() {});
      }
    } catch (e) {
      final errorMessage = e.toString();
      if (errorMessage.contains('No internet connection') ||
          errorMessage.contains('SocketException')) {
        setState(() {
          _error = 'You are offline';
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'An unexpected error occurred: $errorMessage';
          _isLoading = false;
        });
      }
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
        title: Text(_promoter != null ? _promoter!.name : 'Promoter'),
        actions: [
          FutureBuilder<bool>(
            future: _permissionService.hasPermissionForCurrentUser(
              widget.promoterId,
              'promoter',
              2,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting ||
                  snapshot.hasError ||
                  !snapshot.hasData ||
                  !snapshot.data!) {
                return const SizedBox.shrink();
              }
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
            },
          ),
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
                ? Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(fontSize: 16, color: Colors.red),
                    ),
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Promoter image
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
                        // Promoter name and verification icon
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _promoter!.name,
                                style: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ),
                            VerifiedIconWidget(
                              isVerified: _promoter!.isVerified,
                              entityType: 'promoter',
                              entityName: _promoter!.name,
                              entityId: _promoter!.id,
                            ),
                          ],
                        ),
                        const SizedBox(height: sectionTitleSpacing),
                        FollowersCountWidget(
                          entityId: widget.promoterId,
                          entityType: 'promoter',
                        ),
                        const SizedBox(height: sectionSpacing),
                        // About section
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
                                child: const SizedBox
                                    .shrink(), // Text('Error: ${snapshot.error}'),
                              );
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
                        if (_upcomingEvents.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "UPCOMING EVENTS",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: sectionTitleSpacing),
                              SizedBox(
                                height: 258,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _upcomingEvents.length,
                                  itemBuilder: (context, index) {
                                    final event = _upcomingEvents[index];
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
                            ],
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
                        ClaimPageTile(
                          isVerified: _promoter!.isVerified,
                          entityName: _promoter!
                              .name, // ou "Artist", "Venue" selon le contexte
                          entityType:
                              "promoter", // correspond à l'URL de navigation (ex: '/claimForm/promoter')
                          entityId: _promoter!.id,
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
