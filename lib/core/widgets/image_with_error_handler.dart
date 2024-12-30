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
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      /* placeholder: (context, url) => Container(
        width: width,
        height: height,
        child: const Center(
          child: CircularProgressIndicator.adaptive(),
        ),
      ),*/
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/404.png', // Votre image par défaut
              width: width * 0.66,
              height: height * 0.66,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 8),
            const Text(
              'Image not available',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 200),
    );
  }
}
