// lib/features/promoter/widgets/promoter_item_widget.dart

import 'package:flutter/material.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/promoter/services/promoter_service.dart';
import 'package:sway/features/user/services/user_follow_promoter_service.dart';
import 'package:sway/features/user/widgets/following_button_widget.dart';

/// Widget to display a promoter as a list item with image, name, followers, upcoming events, and follow button.
class PromoterListItemWidget extends StatefulWidget {
  final Promoter promoter;
  final VoidCallback onTap;
  final int maxNameLength;

  const PromoterListItemWidget({
    required this.promoter,
    required this.onTap,
    this.maxNameLength = 16, // Default maximum name length
    Key? key,
  }) : super(key: key);

  @override
  _PromoterListItemWidgetState createState() => _PromoterListItemWidgetState();
}

class _PromoterListItemWidgetState extends State<PromoterListItemWidget> {
  late Future<int> _followersCountFuture;
  late Future<int> _upcomingEventsCountFuture;

  final UserFollowPromoterService _userFollowPromoterService =
      UserFollowPromoterService();
  final PromoterService _promoterService = PromoterService();

  @override
  void initState() {
    super.initState();
    _followersCountFuture = _userFollowPromoterService
        .getPromoterFollowersCount(widget.promoter.id);
    _upcomingEventsCountFuture = _promoterService
        .getPromoterByIdWithEvents(widget.promoter.id)
        .then((promoter) => promoter?.upcomingEvents.length ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    // Truncate name if necessary
    String truncatedName = widget.promoter.name.length > widget.maxNameLength
        ? '${widget.promoter.name.substring(0, widget.maxNameLength)}...'
        : widget.promoter.name;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Card(
        color:
            Theme.of(context).cardColor, // Appliquez la couleur personnalisée
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 3,
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
                    imageUrl: widget.promoter.imageUrl,
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
                        '',
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
              ],
            ),
            trailing: FollowingButtonWidget(
              entityId: widget.promoter.id,
              entityType: 'promoter',
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget to display a promoter as a card with image, name, followers, upcoming events, and follow button.
class PromoterCardItemWidget extends StatefulWidget {
  final Promoter promoter;
  final VoidCallback onTap;
  final int maxNameLength;

  const PromoterCardItemWidget({
    required this.promoter,
    required this.onTap,
    this.maxNameLength = 20, // Default maximum name length
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
    if (!mounted) return;
    setState(() {
      _isFollowingFuture =
          UserFollowPromoterService().isFollowingPromoter(widget.promoter.id);
      _followersCountFuture = UserFollowPromoterService()
          .getPromoterFollowersCount(widget.promoter.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Truncate name if necessary
    String truncatedName = widget.promoter.name.length > widget.maxNameLength
        ? '${widget.promoter.name.substring(0, widget.maxNameLength)}...'
        : widget.promoter.name;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Promoter Image
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor, // Apply cardColor from theme
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
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
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Promoter Name
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
                // Followers Count
                FutureBuilder<int>(
                  future: _followersCountFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text(
                        '',
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
                // Upcoming Events Count
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
                // Follow Button
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
                      return IconButton(
                        icon: isFollowing
                            ? Icon(Icons.favorite)
                            : Icon(Icons.favorite_border),
                        onPressed: () => _toggleFollow(isFollowing),
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
