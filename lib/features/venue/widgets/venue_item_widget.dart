// lib/features/venue/widgets/venue_item_widget.dart

import 'package:flutter/material.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/venue/models/venue_model.dart'; // Assurez-vous d'avoir ce modèle
import 'package:sway/features/user/services/user_follow_venue_service.dart';

/// Widget pour afficher un lieu sous forme de liste avec image, nom, followers, événements à venir et bouton de suivi.
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
  late Future<bool> _isFollowingFuture;

  @override
  void initState() {
    super.initState();
    _followersCountFuture =
        UserFollowVenueService().getVenueFollowersCount(widget.venue.id);
    _isFollowingFuture =
        UserFollowVenueService().isFollowingVenue(widget.venue.id);
  }

  void _toggleFollow(bool isFollowing) async {
    if (isFollowing) {
      await UserFollowVenueService().unfollowVenue(widget.venue.id);
    } else {
      await UserFollowVenueService().followVenue(widget.venue.id);
    }
    setState(() {
      _isFollowingFuture =
          UserFollowVenueService().isFollowingVenue(widget.venue.id);
      _followersCountFuture =
          UserFollowVenueService().getVenueFollowersCount(widget.venue.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Troncature du nom si nécessaire
    String truncatedName = widget.venue.name.length > widget.maxNameLength
        ? '${widget.venue.name.substring(0, widget.maxNameLength)}...'
        : widget.venue.name;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        onTap: widget.onTap,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: ImageWithErrorHandler(
            imageUrl: widget.venue.imageUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          truncatedName,
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
                    'Loading followers...',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  );
                } else if (snapshot.hasError) {
                  return Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  );
                } else {
                  return Text(
                    '${snapshot.data} followers',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  );
                }
              },
            ),
          ],
        ),
        trailing: FutureBuilder<bool>(
          future: _isFollowingFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            } else if (snapshot.hasError) {
              return const Icon(Icons.error, color: Colors.red);
            } else {
              bool isFollowing = snapshot.data ?? false;
              return IconButton(
                icon: isFollowing
                    ? Icon(Icons.favorite)
                    : Icon(Icons.favorite_border),
                onPressed: () => _toggleFollow(isFollowing),
              );
            }
          },
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
        ? '${venue.name.substring(0, maxNameLength)}...'
        : venue.name;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Image du lieu
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ImageWithErrorHandler(
                imageUrl: venue.imageUrl,
                width: 100,
                height: 100,
              ),
            ),
            const SizedBox(height: 5),
            // Nom du lieu avec troncature et retour à la ligne
            Text(
              truncatedName,
              style: const TextStyle(fontSize: 14),
              maxLines: 2, // Permet jusqu'à 2 lignes
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
