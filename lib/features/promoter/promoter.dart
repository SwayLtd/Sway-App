// lib/features/promoter/promoter.dart

import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:sway/core/constants/dimensions.dart'; // Import des constantes
import 'package:sway/core/utils/share_util.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/artist/widgets/artist_item_widget.dart';
import 'package:sway/features/artist/widgets/artist_modal_bottom_sheet.dart';
import 'package:sway/features/event/event.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/services/event_service.dart';
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
  final int maxEvents = 2;

  final UserPermissionService _permissionService = UserPermissionService();

  // Méthode pour récupérer les données du promoteur
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
          // Bouton d'édition conditionnel basé sur les permissions
          FutureBuilder<bool>(
            future: _permissionService.hasPermissionForCurrentUser(
              widget.promoterId,
              'promoter',
              'edit', // 'edit' correspond à 'manager' ou supérieur dans UserPermissionService
            ),
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
                    if (_promoter != null) {
                      final updatedPromoter = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditPromoterScreen(promoter: _promoter!),
                        ),
                      );
                      if (updatedPromoter != null) {
                        // Rafraîchir les données après modification
                        _fetchPromoterData();
                      }
                    }
                  },
                );
              }
            },
          ),
          // Bouton d'insight (vide pour l'instant)
          FutureBuilder<bool>(
            future: _permissionService.hasPermissionForCurrentUser(
              widget.promoterId,
              'promoter',
              'insight', // À implémenter si nécessaire
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              } else if (snapshot.hasError ||
                  !snapshot.hasData ||
                  !snapshot.data!) {
                return const SizedBox.shrink();
              } else {
                // Implémenter le bouton d'insight si nécessaire
                return IconButton(
                  icon: const Icon(Icons.insights),
                  onPressed: () {
                    // Action pour le bouton d'insight
                  },
                );
              }
            },
          ),
          // Bouton de Partage
          FutureBuilder<Promoter?>(
            future: PromoterService().getPromoterById(widget.promoterId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Afficher rien pendant le chargement
                return const SizedBox.shrink();
              } else if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data == null) {
                // Afficher rien en cas d'erreur ou si le lieu n'est pas trouvé
                return const SizedBox.shrink();
              } else {
                final promoter = snapshot.data!;
                return Transform.flip(
                  flipX: true,
                  child: IconButton(
                    icon: const Icon(Icons.reply),
                    onPressed: () {
                      // Appeler la fonction de partage avec les paramètres appropriés
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
                                    .withValues(
                                        alpha: 0.5), // Couleur de la bordure
                                width: 2.0, // Épaisseur de la bordure
                              ),
                              borderRadius: BorderRadius.circular(
                                  12), // Coins arrondis de la bordure
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
                        const SizedBox(
                            height:
                                sectionTitleSpacing), // Utilisation de la constante
                        // Nom du promoteur
                        Text(
                          _promoter!.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                            height:
                                sectionTitleSpacing), // Utilisation de la constante
                        // Compteur de followers
                        FollowersCountWidget(
                          entityId: widget.promoterId,
                          entityType: 'promoter',
                        ),
                        const SizedBox(
                            height:
                                sectionSpacing), // Utilisation de la constante
                        // Section "ABOUT" avec condition de visibilité
                        if (_promoter!.description.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "ABOUT",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(
                                  height:
                                      sectionTitleSpacing), // Utilisation de la constante
                              ExpandableText(
                                _promoter!.description,
                                expandText: 'show more',
                                collapseText: 'show less',
                                maxLines:
                                    3, // Nombre maximal de lignes avant "Show More"
                                linkColor: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(
                                  height:
                                      sectionSpacing), // Utilisation de la constante
                            ],
                          ),
                        // Section "ABOUT" cachée si description est vide ou null
                        if (_promoter!.description.isEmpty)
                          const SizedBox.shrink(),
                        // MOOD Section
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
                        // Section "UPCOMING EVENTS"
                        Row(
                          mainAxisAlignment:
                              _promoter!.upcomingEvents.length > maxEvents
                                  ? MainAxisAlignment.spaceBetween
                                  : MainAxisAlignment.start,
                          children: [
                            const Text(
                              "UPCOMING EVENTS",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            if (_promoter!.upcomingEvents.length > maxEvents)
                              IconButton(
                                icon: const Icon(Icons.arrow_forward),
                                onPressed: () async {
                                  // Convertir List<int> en List<Event>
                                  List<Event> events = await PromoterService()
                                      .getEventsByIds(
                                          _promoter!.upcomingEvents);
                                  showEventModalBottomSheet(context, events);
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: sectionTitleSpacing),
                        _promoter!.upcomingEvents.isEmpty
                            ? Row(
                                children: const [
                                  Icon(Icons.event_busy, color: Colors.grey),
                                  SizedBox(width: 8),
                                  Text(
                                    'No upcoming events',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              )
                            : SizedBox(
                                height:
                                    246, // Définissez une hauteur appropriée pour le ListView horizontal
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _promoter!.upcomingEvents.length >
                                          maxEvents
                                      ? maxEvents
                                      : _promoter!.upcomingEvents.length,
                                  itemBuilder: (context, index) {
                                    final eventId =
                                        _promoter!.upcomingEvents[index];
                                    return FutureBuilder<Event?>(
                                      future:
                                          EventService().getEventById(eventId),
                                      builder: (context, eventSnapshot) {
                                        if (eventSnapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 8.0, horizontal: 8.0),
                                            child: CircularProgressIndicator
                                                .adaptive(),
                                          );
                                        } else if (eventSnapshot.hasError ||
                                            !eventSnapshot.hasData ||
                                            eventSnapshot.data == null) {
                                          return const SizedBox
                                              .shrink(); // Ne rien afficher si erreur
                                        } else {
                                          final event = eventSnapshot.data!;
                                          return EventCardItemWidget(
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
                                          );
                                        }
                                      },
                                    );
                                  },
                                ),
                              ),
                        const SizedBox(height: sectionSpacing),
                        // Section "RESIDENT ARTISTS" avec ArtistItemWidget et icône "Show More" alignée à droite
                        FutureBuilder<List<Artist>>(
                          future: PromoterResidentArtistsService()
                              .getArtistsByPromoterId(widget.promoterId),
                          builder: (context, artistSnapshot) {
                            if (artistSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator.adaptive();
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
                      ],
                    ),
                  ),
      ),
    );
  }
}
