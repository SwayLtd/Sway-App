// lib/core/routes.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/core/auth_state_manager.dart';
import 'package:sway/core/utils/error/error_not_found.dart';
import 'package:sway/core/widgets/bottom_navigation_bar.dart';
import 'package:sway/features/artist/artist.dart';
import 'package:sway/features/explore/explore.dart';
import 'package:sway/features/event/event.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/services/event_service.dart';
import 'package:sway/features/genre/genre.dart';
import 'package:sway/features/promoter/promoter.dart';
import 'package:sway/features/ticketing/screens/ticket_detail_screen.dart';
import 'package:sway/features/ticketing/services/ticket_service.dart';
import 'package:sway/features/user/user.dart';
import 'package:sway/features/search/search.dart';
import 'package:sway/features/settings/settings.dart';
import 'package:sway/features/ticketing/ticketing.dart';
import 'package:sway/features/user/profile.dart';
import 'package:sway/features/user/screens/reset_password_screen.dart';
import 'package:sway/features/venue/venue.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

List<Map<String, dynamic>> shellRoutes = [
  {
    'name': 'Explore',
    'path': '/',
    'index': 0,
    'screen': ExploreScreen(),
  },
  {
    'name': 'Search',
    'path': '/search',
    'index': 1,
    'screen': SearchScreen(),
  },
  {
    'name': 'Tickets',
    'path': '/tickets',
    'index': 2,
    'screen': TicketingScreen(),
  },
  {
    'name': 'Settings',
    'path': '/settings',
    'index': 3,
    'screen': const SettingsScreen(),
  },
];

List<Map<String, dynamic>> standaloneRoutes = [
  {
    'name': 'ResetPassword',
    'path': '/reset-password',
    'screen': const ResetPasswordScreen(),
  },
  // New standalone routes for artist and user
  {
    'name': 'ArtistDetail',
    'path': '/artist/:id',
    'screenBuilder': (BuildContext context, GoRouterState state) {
      final int artistId = int.parse(state.pathParameters['id']!);
      return ArtistScreen(artistId: artistId);
    },
  },
  {
    'name': 'PromoterDetail',
    'path': '/promoter/:id',
    'screenBuilder': (BuildContext context, GoRouterState state) {
      final int promoterId = int.parse(state.pathParameters['id']!);
      return PromoterScreen(promoterId: promoterId);
    },
  },
  {
    'name': 'VenueDetail',
    'path': '/venue/:id',
    'screenBuilder': (BuildContext context, GoRouterState state) {
      final int venueId = int.parse(state.pathParameters['id']!);
      return VenueScreen(venueId: venueId);
    },
  },
  {
    'name': 'GenreDetail',
    'path': '/genre/:id',
    'screenBuilder': (BuildContext context, GoRouterState state) {
      final int genreId = int.parse(state.pathParameters['id']!);
      return GenreScreen(genreId: genreId);
    },
  },
  {
    'name': 'UserDetail',
    'path': '/user/:id',
    'screenBuilder': (BuildContext context, GoRouterState state) {
      final int userId = int.parse(state.pathParameters['id']!);
      return UserScreen(userId: userId);
    },
  },
  {
    'name': 'EventDetail',
    'path': '/event/:id',
    'screenBuilder': (BuildContext context, GoRouterState state) {
      final int idParam = int.parse(state.pathParameters['id']!);
      final EventService _eventService = EventService();
      return FutureBuilder<Event?>(
        future: _eventService.getEventById(idParam),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              appBar: AppBar(title: const Text('Loading Event')),
              body: const Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: Center(child: Text('Error: ${snapshot.error}')),
            );
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Event Not Found')),
              body: const Center(child: Text('Event not found.')),
            );
          } else {
            final event = snapshot.data!;
            return EventScreen(event: event);
          }
        },
      );
    },
  },
  {
    'name': 'TicketDetail',
    'path': '/ticket/:id',
    'screenBuilder': (BuildContext context, GoRouterState state) {
      final String ticketIdParam = state.pathParameters['id']!;
      final int ticketId = int.tryParse(ticketIdParam) ?? -1;
      return FutureBuilder(
        future: TicketService().getTicketById(ticketId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              appBar: AppBar(title: const Text('Loading Ticket')),
              body: const Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Ticket Not Found')),
              body: const Center(child: Text('Ticket not found.')),
            );
          } else {
            final ticket = snapshot.data!;
            return TicketDetailScreen(
              tickets: [ticket],
              initialTicket: ticket,
            );
          }
        },
      );
    },
  },
];

final authStateManager = AuthStateManager();

final GoRouter router = GoRouter(
  navigatorKey: rootNavigatorKey,
  // initialLocation: '/',
  initialLocation: Uri.base.toString(),
  debugLogDiagnostics: false,
  redirect: (context, state) async {
    final user = Supabase.instance.client.auth.currentUser;
    final bool loggedIn = user != null;
    final bool isAuthPath = state.matchedLocation == '/auth';

    // Si la route commence par "content://", on force la route à "/"
    final location = state.uri.toString();
    if (location.startsWith('content://')) {
      // On ignore la tentative de route sur content://…
      // et on redirige vers la home page (ou '/tickets', selon tes besoins).
      return '/';
    }

    // Access the authChangeEvent from authStateManager
    final authChangeEvent = authStateManager.authChangeEvent;

    // Check if the user is recovering password
    final recoveringPassword =
        authChangeEvent == AuthChangeEvent.passwordRecovery;

    // Define protected paths that require authentication
    final List<String> protectedPaths = [
      '/settings/profile',
      // Add more protected paths if needed
    ];

    // Check if the current path is protected
    bool isProtected =
        protectedPaths.any((path) => state.uri.toString().startsWith(path));

    if (!loggedIn && isProtected) {
      return '/';
    }

    // If the user is recovering password, redirect to '/reset-password'
    if (recoveringPassword && state.uri.toString() != '/reset-password') {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      return '/reset-password';
    }

    // Handle deep links for 'artist', 'promoter', 'venue', 'genre' and 'user'
    // Extract the entity type from the path
    final uri = Uri.parse(state.uri.toString());
    final pathSegments = uri.pathSegments;

    if (pathSegments.isNotEmpty) {
      final entityType = pathSegments[0];

      switch (entityType) {
        case 'artist':
          print('Artist entity found');
          break;
        case 'promoter':
          print('Promoter entity found');
          break;
        case 'venue':
          print('Venue entity found');
          break;
        case 'genre':
          print('Genre entity found');
          break;
        case 'user':
          print('User entity found');
          break;
        case 'event':
          print('Event entity found');
          break;
        default:
          // No action needed for other paths
          break;
      }
      // No redirect needed for entity deep links
      return null;
    }

    // If already logged in and trying to access auth, redirect to home
    if (loggedIn && isAuthPath) {
      return '/';
    }

    print('Navigating to: ${state.uri.toString()}');
    print('Matched location: ${state.matchedLocation}');

    return null; // No redirect needed
  },
  refreshListenable: authStateManager,
  routes: [
    ShellRoute(
      navigatorKey: shellNavigatorKey,
      builder: (BuildContext context, GoRouterState state, Widget child) {
        return ResponsiveBreakpoints.builder(
          child: ScaffoldWithNavBarWithoutAppBar(child: child),
          breakpoints: const [
            Breakpoint(start: 0, end: 450, name: MOBILE),
            Breakpoint(start: 451, end: 800, name: TABLET),
            Breakpoint(start: 801, end: 1200, name: DESKTOP),
            Breakpoint(start: 1201, end: 2460, name: 'HD'),
            Breakpoint(start: 2461, end: double.infinity, name: 'UHD'),
          ],
        );
      },
      routes: [
        ...getShellRoutes(),
        ...getStandaloneRoutes(),
      ],
    ),
  ],
  errorBuilder: (context, state) => NotFoundError(state.error),
);

List<RouteBase> getShellRoutes() {
  final List<RouteBase> generatedRoutes = [];
  for (final route in shellRoutes) {
    generatedRoutes.add(
      GoRoute(
        path: route['path'] as String,
        name: route['name'] as String,
        pageBuilder: (context, state) {
          return fadeTransitionPage(context, state, route['screen'] as Widget);
        },
        routes: [
          // Define subroutes if needed, e.g., '/settings/profile'
          if (route['path'] == '/settings')
            GoRoute(
              path: 'profile',
              name: 'Profile',
              builder: (context, state) => const ProfileScreen(),
            ),
        ],
      ),
    );
  }

  return generatedRoutes;
}

List<RouteBase> getStandaloneRoutes() {
  final List<RouteBase> generatedRoutes = [];
  for (final route in standaloneRoutes) {
    if (route.containsKey('screen')) {
      generatedRoutes.add(
        GoRoute(
          path: route['path'] as String,
          name: route['name'] as String,
          pageBuilder: (context, state) {
            return fadeTransitionPage(
                context, state, route['screen'] as Widget);
          },
        ),
      );
    } else if (route.containsKey('screenBuilder')) {
      generatedRoutes.add(
        GoRoute(
          path: route['path'] as String,
          name: route['name'] as String,
          pageBuilder: (context, state) {
            final widget = (route['screenBuilder'] as Widget Function(
                BuildContext, GoRouterState))(context, state);
            return fadeTransitionPage(context, state, widget);
          },
        ),
      );
    }
  }
  return generatedRoutes;
}

/// Returns the name of the current route.
String routeName() {
  final route = shellRoutes.firstWhere(
    (route) =>
        route['path'] == router.routerDelegate.currentConfiguration.fullPath,
    orElse: () => shellRoutes.first,
  );
  return route['name'] as String;
}

/// Returns the index of the current screen.
int selectedIndex() {
  final route = shellRoutes.firstWhere(
    (route) =>
        route['path'] == router.routerDelegate.currentConfiguration.fullPath,
    orElse: () => shellRoutes.first,
  );
  return route['index'];
}

/// Navigates to the screen corresponding to the index.
void onTap(BuildContext context, int index) {
  final route = shellRoutes.firstWhere(
    (route) => route['index'] == index,
    orElse: () => shellRoutes.first,
  );

  // Use context.go to navigate without stacking
  // context.go(route['path'] as String);
  context.push(route['path'] as String);
  // context.pop(route['path'] as String);
  // context.pushReplacement(route['path'] as String);
}

/// Class to listen to authentication state changes.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

Page<void> fadeTransitionPage(
    BuildContext context, GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  );
}
