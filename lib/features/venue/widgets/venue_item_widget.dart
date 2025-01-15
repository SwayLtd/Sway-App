// lib/features/venue/widgets/venue_item_widget.dart

import 'package:flutter/material.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/event/services/event_venue_service.dart';
import 'package:sway/features/user/widgets/following_button_widget.dart';
import 'package:sway/features/venue/models/venue_model.dart'; // Assurez-vous d'avoir ce modèle
import 'package:sway/features/user/services/user_follow_venue_service.dart';

/// Widget pour afficher un lieu sous forme de liste avec image, nom, followers,
/// événements à venir et bouton de suivi.
class VenueListItemWidget extends StatefulWidget {
  final Venue venue;
  final VoidCallback onTap;
  final int maxNameLength;

  const VenueListItemWidget({
    required this.venue,
    required this.onTap,
    this.maxNameLength = 20, // Longueur maximale du nom par défaut
    Key? key,
  }) : super(key: key);

  @override
  _VenueListItemWidgetState createState() => _VenueListItemWidgetState();
}

class _VenueListItemWidgetState extends State<VenueListItemWidget> {
  late Future<int> _followersCountFuture;
  late Future<int> _upcomingEventsCountFuture;

  final UserFollowVenueService _userFollowVenueService =
      UserFollowVenueService();
  final EventVenueService _eventVenueService = EventVenueService();

  @override
  void initState() {
    super.initState();
    _followersCountFuture =
        _userFollowVenueService.getVenueFollowersCount(widget.venue.id);
    _upcomingEventsCountFuture = _eventVenueService
        .getEventsByVenueId(widget.venue.id)
        .then((events) => events.length);
  }

  @override
  Widget build(BuildContext context) {
    // Troncature du nom si nécessaire
    String truncatedName = widget.venue.name.length > widget.maxNameLength
        ? '${widget.venue.name.substring(0, widget.maxNameLength)}'
        : widget.venue.name;

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
                    imageUrl: widget.venue.imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            title: Text(
              truncatedName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<int>(
                  future: _followersCountFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink();
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
                      return const SizedBox.shrink();
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
              entityId: widget.venue.id,
              entityType: 'venue',
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget pour afficher un lieu sous forme de carte avec une image et un titre limité.
class VenueCardItemWidget extends StatelessWidget {
  final Venue venue;
  final VoidCallback onTap;
  final int
      maxNameLength; // Ajout d'un paramètre pour la longueur maximale du nom

  const VenueCardItemWidget({
    required this.venue,
    required this.onTap,
    this.maxNameLength = 12, // Valeur par défaut, ajustable selon vos besoins
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Troncature du nom si nécessaire
    String truncatedName = venue.name.length > maxNameLength
        ? '${venue.name.substring(0, maxNameLength)}'
        : venue.name;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Image du lieu
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
                  imageUrl: venue.imageUrl,
                  width: 100,
                  height: 100,
                ),
              ),
            ),
            const SizedBox(height: 5),
            // Nom du lieu avec troncature et retour à la ligne
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
