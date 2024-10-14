import 'package:flutter/material.dart';
import 'package:sway/features/user/models/user_model.dart';
import 'package:sway/features/user/services/user_follow_artist_service.dart';
import 'package:sway/features/user/services/user_follow_genre_service.dart';
import 'package:sway/features/user/services/user_follow_promoter_service.dart';
import 'package:sway/features/user/services/user_follow_user_service.dart';
import 'package:sway/features/user/services/user_follow_venue_service.dart';
import 'package:sway/features/user/services/user_interest_event_service.dart';
import 'package:sway/features/user/user.dart';

class FollowersScreen extends StatefulWidget {
  final int entityId;
  final String
      entityType; // 'venue', 'promoter', 'event', 'artist', 'user', 'genre'
  final int initialTabIndex;

  const FollowersScreen({
    required this.entityId,
    required this.entityType,
    this.initialTabIndex = 0,
  });

  @override
  _FollowersScreenState createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 2, vsync: this, initialIndex: widget.initialTabIndex,);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entityType == 'event') {
      return _buildEventFollowersTabs();
    } else if (widget.entityType == 'user') {
      return _buildUserFollowersTabs();
    } else {
      return Scaffold(
        appBar: AppBar(title: const Text('Followers')),
        body: _buildFollowersList(),
      );
    }
  }

  Widget _buildEventFollowersTabs() {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Event Followers'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Interested'),
              Tab(text: 'Going'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildFollowersList(followerType: 'interested'),
            _buildFollowersList(followerType: 'going'),
          ],
        ),
      ),
    );
  }

  Widget _buildUserFollowersTabs() {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('User Followers'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Followers'),
              Tab(text: 'Following'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildFollowersList(followerType: 'followers'),
            _buildFollowersList(followerType: 'following'),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowersList({String? followerType}) {
    return FutureBuilder<List<User>>(
      future: _getFollowersForEntity(followerType: followerType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No followers found'));
        } else {
          final followers = snapshot.data!;
          return ListView.separated(
            itemCount: followers.length,
            itemBuilder: (context, index) {
              final user = followers[index];
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(user.profilePictureUrl),
                ),
                title: Text(user.username),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserScreen(userId: user.id),
                    ),
                  );
                },
              );
            },
            separatorBuilder: (context, index) => const SizedBox(
              height: 10,
            ),
          );
        }
      },
    );
  }

  Future<List<User>> _getFollowersForEntity({String? followerType}) {
    switch (widget.entityType) {
      case 'artist':
        return UserFollowArtistService().getFollowersForArtist(widget.entityId);
      case 'venue':
        return UserFollowVenueService().getFollowersForVenue(widget.entityId);
      case 'promoter':
        return UserFollowPromoterService()
            .getFollowersForPromoter(widget.entityId);
      case 'event':
        if (followerType == 'interested') {
          return UserInterestEventService()
              .getInterestedUsersForEvent(widget.entityId);
        } else if (followerType == 'going') {
          return UserInterestEventService()
              .getGoingUsersForEvent(widget.entityId);
        } else {
          return Future.value([]);
        }
      case 'user':
        if (followerType == 'followers') {
          return UserFollowUserService().getFollowersForUser(widget.entityId);
        } else if (followerType == 'following') {
          return UserFollowUserService().getFollowingForUser(widget.entityId);
        } else {
          return Future.value([]);
        }
      case 'genre':
        return UserFollowGenreService().getUsersFollowingGenre(widget.entityId);
      default:
        throw Exception('Unknown entity type');
    }
  }
}
