// lib/features/artist/widgets/artist_item_widget.dart

import 'dart:async'; // Importer pour Timer
import 'package:flutter/material.dart';
import 'package:sway/core/constants/dimensions.dart';
import 'package:sway/core/utils/date_utils.dart'; // Importer les utilitaires de date
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/services/event_artist_service.dart';
import 'package:sway/features/user/services/user_follow_artist_service.dart';
import 'package:sway/features/user/widgets/following_button_widget.dart';
import 'package:go_router/go_router.dart'; // Importer GoRouter pour la navigation

/// Widget pour afficher un artiste sous forme de liste avec une image, un titre limité,
/// un bouton "follow", le nombre de followers et les événements à venir.
class ArtistListItemWidget extends StatefulWidget {
  final Artist artist;
  final VoidCallback onTap;
  final int maxTitleLength;

  const ArtistListItemWidget({
    required this.artist,
    required this.onTap,
    this.maxTitleLength = 20, // Longueur maximale du titre par défaut
    Key? key,
  }) : super(key: key);

  @override
  _ArtistListItemWidgetState createState() => _ArtistListItemWidgetState();
}

class _ArtistListItemWidgetState extends State<ArtistListItemWidget> {
  late Future<int> _followersCountFuture;
  late Future<List<Event>> _upcomingEventsFuture;

  final UserFollowArtistService _userFollowArtistService =
      UserFollowArtistService();
  final EventArtistService _eventArtistService = EventArtistService();

  bool _showUpcomingEventsCount = true; // État pour l'alternance
  Timer? _timer; // Timer pour l'alternance
  bool _hasTimer =
      false; // Indicateur pour éviter de configurer plusieurs timers

  @override
  void initState() {
    super.initState();
    _followersCountFuture =
        _userFollowArtistService.getArtistFollowersCount(widget.artist.id!);
    _upcomingEventsFuture =
        _fetchUpcomingEvents(); // Récupérer la liste des événements à venir
  }

  /// Méthode pour récupérer la liste des événements à venir en utilisant getEventsByArtistId
  Future<List<Event>> _fetchUpcomingEvents() async {
    try {
      final List<Map<String, dynamic>> eventsData =
          await _eventArtistService.getEventsByArtistId(widget.artist.id!);

      if (eventsData.isEmpty) {
        print(
            'Aucun événement trouvé pour l\'artiste ID: ${widget.artist.id!}');
        return [];
      }

      // Extraire les objets Event à partir des maps retournées
      List<Event> events = eventsData
          .map((data) {
            final event =
                data['event'] as Event?; // Traiter 'event' comme un objet Event
            if (event == null) {
              print(
                  'Données de l\'événement manquantes pour un événement associé à l\'artiste ID: ${widget.artist.id!}');
              return null;
            }
            return event;
          })
          .where((event) => event != null)
          .cast<Event>()
          .toList();

      // Filtrer les événements à venir
      DateTime now = DateTime.now();
      List<Event> upcomingEvents =
          events.where((event) => event.eventDateTime.isAfter(now)).toList();

      if (upcomingEvents.isEmpty) {
        return [];
      }

      // Trier les événements par date ascendante
      upcomingEvents.sort((a, b) => a.eventDateTime.compareTo(b.eventDateTime));

      print(
          'Upcoming event:${upcomingEvents.first.title} le ${upcomingEvents.first.eventDateTime}');

      // Configurer le timer pour l'alternance si non déjà configuré
      if (!_hasTimer) {
        _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
          setState(() {
            _showUpcomingEventsCount = !_showUpcomingEventsCount;
          });
        });
        _hasTimer = true;
      }

      return upcomingEvents;
    } catch (e) {
      // Gérer les erreurs ici ou les laisser remonter
      print('Erreur lors de la récupération des événements: $e');
      return [];
    }
  }

  @override
  void dispose() {
    // Annuler le timer si actif
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Troncature du titre si nécessaire
    String truncatedTitle = widget.artist.name.length > widget.maxTitleLength
        ? '${widget.artist.name.substring(0, widget.maxTitleLength)}...'
        : widget.artist.name;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Card(
        color:
            Theme.of(context).cardColor, // Appliquez la couleur personnalisée
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .onPrimary
                  .withValues(alpha: 0.5), // Couleur de la bordure avec opacité
              width: 2.0, // Épaisseur de la bordure
            ),
            borderRadius:
                BorderRadius.circular(12), // Coins arrondis de la bordure
          ),
          child: ListTile(
            onTap: widget.onTap,
            leading: Container(
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .cardColor, // Appliquer cardColor from theme
                borderRadius: BorderRadius.circular(10),
              ),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimary
                        .withValues(alpha: 0.5), // Couleur de la bordure
                    width: 2.0, // Épaisseur de la bordure
                  ),
                  borderRadius:
                      BorderRadius.circular(12), // Coins arrondis de la bordure
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ImageWithErrorHandler(
                    imageUrl: widget.artist.imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            title: Text(
              truncatedTitle,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Affichage du nombre de followers
                FutureBuilder<int>(
                  future: _followersCountFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text(
                        'Loading followers',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      );
                    } else if (snapshot.hasError) {
                      return Text(
                        'Error: ${snapshot.error}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      );
                    } else if (!snapshot.hasData) {
                      return const Text(
                        '0 followers',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      );
                    } else {
                      return Text(
                        '${snapshot.data} followers',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      );
                    }
                  },
                ),
                const SizedBox(height: 4), // Espacement entre les sections
                // Affichage des événements à venir
                FutureBuilder<List<Event>>(
                  future: _upcomingEventsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text(
                        'Loading upcoming events',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      );
                    } else if (snapshot.hasError) {
                      return Text(
                        'Error: ${snapshot.error}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      // Si aucun événement à venir, afficher "No upcoming events"
                      // Annuler le timer si actif
                      if (_hasTimer) {
                        _timer?.cancel();
                        _timer = null;
                        _hasTimer = false;
                      }
                      return const Text(
                        'No upcoming events',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      );
                    } else {
                      final upcomingEvents = snapshot.data!;
                      print(
                          'Upcoming Events List: $upcomingEvents'); // Log pour débogage
                      // Vérifier que la liste n'est pas vide
                      if (upcomingEvents.isEmpty) {
                        // Si la liste est vide, afficher "No upcoming events"
                        if (_hasTimer) {
                          _timer?.cancel();
                          _timer = null;
                          _hasTimer = false;
                        }
                        return const Text(
                          'No upcoming events',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Affichage conditionnel alterné entre "X upcoming events" et "Next Event"
                          _showUpcomingEventsCount
                              ? Text(
                                  '${upcomingEvents.length} upcoming event${upcomingEvents.length > 1 ? 's' : ''}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                )
                              : GestureDetector(
                                  onTap: () {
                                    // Naviguer vers la page de détails de l'événement
                                    context.push(
                                        '/event/${upcomingEvents.first.id}');
                                  },
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.navigate_next,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      Expanded(
                                        child: Text(
                                          '${upcomingEvents.first.title} on ${formatEventDate(upcomingEvents.first.eventDateTime)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey, // Texte neutre
                                            // Pas de soulignement
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                          // Ajouter un espace entre les deux éléments si nécessaire
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
            trailing: FollowingButtonWidget(
              entityId: widget.artist.id!,
              entityType: 'artist',
            ),
          ),
        ),
      ),
    );
  }
}

/// A square tile displaying an artist's image and name.
class ArtistTileItemWidget extends StatelessWidget {
  final Artist artist;
  final VoidCallback onTap;

  const ArtistTileItemWidget({
    required this.artist,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          // Image avec bordure grise uniquement autour de l'image
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ImageWithErrorHandler(
                imageUrl: artist.imageUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Nom de l'artiste centré
          Container(
            width: 100,
            child: Text(
              artist.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget pour afficher un artiste sous forme de carte avec une image et un titre limité.
class ArtistCardItemWidget extends StatelessWidget {
  final Artist artist;
  final VoidCallback onTap;
  final int
      maxNameLength; // Ajout d'un paramètre pour la longueur maximale du nom

  const ArtistCardItemWidget({
    required this.artist,
    required this.onTap,
    this.maxNameLength = 12, // Valeur par défaut, ajustable selon vos besoins
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Troncature du nom si nécessaire
    String truncatedName = artist.name.length > maxNameLength
        ? '${artist.name.substring(0, maxNameLength)}'
        : artist.name;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Container avec bordure autour de l'image de l'artiste
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimary
                      .withValues(alpha: 0.5), // Couleur de la bordure
                  width: 2.0, // Épaisseur de la bordure
                ),
                borderRadius:
                    BorderRadius.circular(12), // Coins arrondis de la bordure
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ImageWithErrorHandler(
                  imageUrl: artist.imageUrl,
                  width: 100,
                  height: 100,
                ),
              ),
            ),
            const SizedBox(height: sectionTitleSpacing),
            // Nom de l'artiste avec troncature et retour à la ligne
            Text(
              truncatedName,
              style: const TextStyle(fontSize: 14),
              maxLines: 1, // Permet jusqu'à 1 ligne
              overflow:
                  TextOverflow.ellipsis, // Ajoute des ellipses si nécessaire
              textAlign: TextAlign.center, // Optionnel : centre le texte
            ),
          ],
        ),
      ),
    );
  }
}
