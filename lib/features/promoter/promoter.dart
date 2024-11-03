// lib/features/promoter/promoter.dart

import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:sway/core/constants/dimensions.dart'; // Import des constantes
import 'package:sway/core/utils/date_utils.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/artist/widgets/artist_item_widget.dart';
import 'package:sway/features/artist/widgets/artist_modal_bottom_sheet.dart';
import 'package:sway/features/event/event.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/services/event_service.dart';
import 'package:sway/features/event/widgets/event_item_widget.dart';
import 'package:sway/features/event/widgets/event_modal_bottom_sheet.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/promoter/screens/edit_promoter_screen.dart';
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
        title: Text(_promoter != null
            ? '${_promoter!.name}'
            : 'Promoter'), // Suppression de "Details"
        actions: [
          // Bouton d'édition
          FutureBuilder<bool>(
            future: UserPermissionService().hasPermissionForCurrentUser(
              widget.promoterId,
              'promoter',
              'edit',
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
            future: UserPermissionService().hasPermissionForCurrentUser(
              widget.promoterId,
              'promoter',
              'insight',
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
                return const SizedBox.shrink();
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
            ? const Center(child: CircularProgressIndicator())
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
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: ImageWithErrorHandler(
                              imageUrl: _promoter!.imageUrl,
                              width: 200,
                              height: 200,
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
                            : // EventCardItemWidget view
                            /*Column(
                                children:
                                    _promoter!.upcomingEvents.take(maxEvents).map((eventId) {
                                  return FutureBuilder<Event?>(
                                    future:
                                        EventService().getEventById(eventId),
                                    builder: (context, eventSnapshot) {
                                      if (eventSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Padding(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 8.0, horizontal: 8.0),
                                          child: CircularProgressIndicator(),
                                        );
                                      } else if (eventSnapshot.hasError ||
                                          !eventSnapshot.hasData ||
                                          eventSnapshot.data == null) {
                                        return const SizedBox
                                            .shrink(); // Ne rien afficher si erreur
                                      } else {
                                        final event = eventSnapshot.data!;
                                        return EventListItemWidget(
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
                                }).toList(),
                              ),*/
                            SizedBox(
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
                                            child: CircularProgressIndicator(),
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
                        // const SizedBox(height: sectionSpacing),
                        // Section "RESIDENT ARTISTS" avec ArtistItemWidget et icône "Show More" alignée à droite
                        FutureBuilder<List<Artist>>(
                          future: PromoterResidentArtistsService()
                              .getArtistsByPromoterId(widget.promoterId),
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
                                        // Supprimer le GestureDetector "Show More" à la fin de la liste
                                        // Si nécessaire, vous pouvez le conserver, mais selon vos instructions, il doit être supprimé
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
