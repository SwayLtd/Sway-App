// lib/features/artist/widgets/artist_item_widget.dart

import 'package:flutter/material.dart';
import 'package:sway/core/constants/dimensions.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/event/services/event_artist_service.dart';
import 'package:sway/features/user/services/user_follow_artist_service.dart';
import 'package:sway/features/user/widgets/following_button_widget.dart';

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
  late Future<int> _upcomingEventsCountFuture;

  final UserFollowArtistService _userFollowArtistService =
      UserFollowArtistService();
  final EventArtistService _eventArtistService = EventArtistService();

  @override
  void initState() {
    super.initState();
    _followersCountFuture =
        _userFollowArtistService.getArtistFollowersCount(widget.artist.id);
    _upcomingEventsCountFuture = _eventArtistService
        .getEventsByArtistId(widget.artist.id)
        .then((events) => events.length);
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
                FutureBuilder<int>(
                  future: _followersCountFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text(
                        '0 followers',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      );
                    } else if (snapshot.hasError) {
                      return Text(
                        'Error: ${snapshot.error}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
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
                FutureBuilder<int>(
                  future: _upcomingEventsCountFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text(
                        '0 upcoming events', // 'Loading events...',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      );
                    } else if (snapshot.hasError) {
                      return Text(
                        'Error: ${snapshot.error}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      );
                    } else {
                      return Text(
                        '${snapshot.data} upcoming events',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      );
                    }
                  },
                ),
              ],
            ),
            trailing: FollowingButtonWidget(
              entityId: widget.artist.id,
              entityType: 'artist',
            ),
          ),
        ),
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
        ? '${artist.name.substring(0, maxNameLength)}...'
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
              maxLines: 1, // Permet jusqu'à 2 lignes
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
