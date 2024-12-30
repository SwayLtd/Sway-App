import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/artist/models/artist_model.dart';

class ArtistImageRotator extends StatefulWidget {
  final List<Artist> artists;

  const ArtistImageRotator({required this.artists});

  @override
  _ArtistImageRotatorState createState() => _ArtistImageRotatorState();
}

class _ArtistImageRotatorState extends State<ArtistImageRotator> {
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startImageRotation();
  }

  void _startImageRotation() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) return;
      setState(() {
        _currentIndex = (_currentIndex + 1) % widget.artists.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .onPrimary
              .withValues(alpha: 0.5), // Couleur de la bordure
          width: 2.0, // Épaisseur de la bordure
        ),
        borderRadius: BorderRadius.circular(12), // Coins arrondis de la bordure
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: ImageWithErrorHandler(
          imageUrl: widget.artists[_currentIndex].imageUrl,
          width: 40,
          height: 40,
        ),
      ),
    );
  }
}
