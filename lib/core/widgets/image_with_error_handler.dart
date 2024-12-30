// lib/core/widgets/image_with_error_handler.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ImageWithErrorHandler extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final BoxFit fit;

  const ImageWithErrorHandler({
    required this.imageUrl,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        // Optionnel : Afficher un indicateur de chargement
        /*
        child: const Center(
          child: CircularProgressIndicator.adaptive(),
        ),
        */
      ),
      errorWidget: (context, url, error) => LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;

          // Définir le style du texte
          final textStyle = TextStyle(
            color: Colors.grey,
            fontSize: 14,
          );

          // Créer un TextPainter pour mesurer la taille du texte
          final textSpan = TextSpan(
            text: 'Image not available',
            style: textStyle,
          );
          final textPainter = TextPainter(
            text: textSpan,
            maxLines: 1,
            textDirection: TextDirection.ltr,
          )..layout(
              maxWidth:
                  availableWidth - 40); // Réduction pour le padding et l'image

          // Décider d'afficher le texte ou non
          final canShowText = !textPainter.didExceedMaxLines;

          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: canShowText
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/404.png', // Votre image par défaut
                          width: width * 0.66,
                          height: height * 0.66,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Image not available',
                          style: textStyle,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  : Image.asset(
                      'assets/images/404.png', // Votre image par défaut
                      width: width * 0.66,
                      height: height * 0.66,
                      fit: BoxFit.contain,
                    ),
            ),
          );
        },
      ),
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 200),
    );
  }
}
