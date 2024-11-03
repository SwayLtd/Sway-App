// lib/features/artist/widgets/artist_item_widget.dart

import 'package:flutter/material.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/artist/models/artist_model.dart';

/// Widget pour afficher un artiste sous forme de liste avec une image et un titre limité.
class ArtistListItemWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Troncature du titre si nécessaire
    String truncatedTitle = artist.name.length > maxTitleLength
        ? '${artist.name.substring(0, maxTitleLength)}...'
        : artist.name;

    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ImageWithErrorHandler(
          imageUrl: artist.imageUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        ),
      ),
      title: Text(
        truncatedTitle,
        maxLines: 2, // Permet jusqu'à 2 lignes
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onTap,
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
            // Image de l'artiste
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ImageWithErrorHandler(
                imageUrl: artist.imageUrl,
                width: 100,
                height: 100,
              ),
            ),
            const SizedBox(height: 5),
            // Nom de l'artiste avec troncature et retour à la ligne
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
