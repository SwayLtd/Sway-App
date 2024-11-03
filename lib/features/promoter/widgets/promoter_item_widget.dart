// lib/features/promoter/widgets/promoter_item_widget.dart

import 'package:flutter/material.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/promoter/models/promoter_model.dart'; // Assurez-vous d'avoir ce modèle
import 'package:sway/features/promoter/services/promoter_service.dart';
import 'package:sway/features/user/services/user_follow_promoter_service.dart';

/// Widget pour afficher un promoteur sous forme de liste avec image, nom, followers, événements à venir et bouton de suivi.
class PromoterListItemWidget extends StatefulWidget {
  final Promoter promoter;
  final VoidCallback onTap;
  final int maxNameLength;

  const PromoterListItemWidget({
    required this.promoter,
    required this.onTap,
    this.maxNameLength = 20, // Longueur maximale du nom par défaut
    Key? key,
  }) : super(key: key);

  @override
  _PromoterListItemWidgetState createState() => _PromoterListItemWidgetState();
}

class _PromoterListItemWidgetState extends State<PromoterListItemWidget> {
  late Future<int> _followersCountFuture;
  late Future<int> _upcomingEventsCountFuture;
  late Future<bool> _isFollowingFuture;

  @override
  void initState() {
    super.initState();
    _followersCountFuture = UserFollowPromoterService()
        .getPromoterFollowersCount(widget.promoter.id);
    _isFollowingFuture =
        UserFollowPromoterService().isFollowingPromoter(widget.promoter.id);
    _upcomingEventsCountFuture = PromoterService()
        .getPromoterByIdWithEvents(widget.promoter.id)
        .then((promoter) => promoter?.upcomingEvents.length ?? 0);
  }

  void _toggleFollow(bool isFollowing) async {
    if (isFollowing) {
      await UserFollowPromoterService().unfollowPromoter(widget.promoter.id);
    } else {
      await UserFollowPromoterService().followPromoter(widget.promoter.id);
    }
    setState(() {
      _isFollowingFuture =
          UserFollowPromoterService().isFollowingPromoter(widget.promoter.id);
      _followersCountFuture = UserFollowPromoterService()
          .getPromoterFollowersCount(widget.promoter.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Troncature du nom si nécessaire
    String truncatedName = widget.promoter.name.length > widget.maxNameLength
        ? '${widget.promoter.name.substring(0, widget.maxNameLength)}...'
        : widget.promoter.name;

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
            imageUrl: widget.promoter.imageUrl,
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
            FutureBuilder<int>(
              future: _upcomingEventsCountFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text(
                    'Loading events...',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  );
                } else if (snapshot.hasError) {
                  return Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  );
                } else {
                  return Text(
                    '${snapshot.data} upcoming events',
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
              return ElevatedButton(
                onPressed: () => _toggleFollow(isFollowing),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFollowing ? Colors.grey : Colors.blue,
                  minimumSize: const Size(80, 30),
                ),
                child: Text(
                  isFollowing ? 'Following' : 'Follow',
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

/// Widget pour afficher un promoteur sous forme de carte avec image, nom, followers, événements à venir et bouton de suivi.
class PromoterCardItemWidget extends StatefulWidget {
  final Promoter promoter;
  final VoidCallback onTap;
  final int maxNameLength;

  const PromoterCardItemWidget({
    required this.promoter,
    required this.onTap,
    this.maxNameLength = 20, // Longueur maximale du nom par défaut
    Key? key,
  }) : super(key: key);

  @override
  _PromoterCardItemWidgetState createState() => _PromoterCardItemWidgetState();
}

class _PromoterCardItemWidgetState extends State<PromoterCardItemWidget> {
  late Future<int> _followersCountFuture;
  late Future<int> _upcomingEventsCountFuture;
  late Future<bool> _isFollowingFuture;

  @override
  void initState() {
    super.initState();
    _followersCountFuture = UserFollowPromoterService()
        .getPromoterFollowersCount(widget.promoter.id);
    _isFollowingFuture =
        UserFollowPromoterService().isFollowingPromoter(widget.promoter.id);
    _upcomingEventsCountFuture = PromoterService()
        .getPromoterByIdWithEvents(widget.promoter.id)
        .then((promoter) => promoter?.upcomingEvents.length ?? 0);
  }

  void _toggleFollow(bool isFollowing) async {
    if (isFollowing) {
      await UserFollowPromoterService().unfollowPromoter(widget.promoter.id);
    } else {
      await UserFollowPromoterService().followPromoter(widget.promoter.id);
    }
    setState(() {
      _isFollowingFuture =
          UserFollowPromoterService().isFollowingPromoter(widget.promoter.id);
      _followersCountFuture = UserFollowPromoterService()
          .getPromoterFollowersCount(widget.promoter.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Troncature du nom si nécessaire
    String truncatedName = widget.promoter.name.length > widget.maxNameLength
        ? '${widget.promoter.name.substring(0, widget.maxNameLength)}...'
        : widget.promoter.name;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 3,
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image du promoteur
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
            child: ImageWithErrorHandler(
              imageUrl: widget.promoter.imageUrl,
              width: double.infinity,
              height: 150,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom du promoteur avec troncature
                Text(
                  truncatedName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Nombre de followers
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
                const SizedBox(height: 2),
                // Nombre d'événements à venir
                FutureBuilder<int>(
                  future: _upcomingEventsCountFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text(
                        'Loading events...',
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
                const SizedBox(height: 8),
                // Bouton "Follow" ou "Following"
                FutureBuilder<bool>(
                  future: _isFollowingFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        width: 80,
                        height: 30,
                        child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    } else if (snapshot.hasError) {
                      return const Icon(Icons.error, color: Colors.red);
                    } else {
                      bool isFollowing = snapshot.data ?? false;
                      return ElevatedButton(
                        onPressed: () => _toggleFollow(isFollowing),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isFollowing ? Colors.grey : Colors.blue,
                          minimumSize: const Size(80, 30),
                        ),
                        child: Text(
                          isFollowing ? 'Following' : 'Follow',
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
