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

// Clés de navigation
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

// Définition des routes avec barre de navigation
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

// Définition des routes standalone sans barre de navigation
List<Map<String, dynamic>> standaloneRoutes = [
  {
    'name': 'ResetPassword',
    'path': '/reset-password',
    'screen': const ResetPasswordScreen(),
  },
  // Routes des artistes
  {
    'name': 'ArtistDetail',
    'path': '/artist/:id',
    'screenBuilder': (BuildContext context, GoRouterState state) {
      final int artistId = int.parse(state.pathParameters['id']!);
      return ArtistScreen(artistId: artistId);
    },
  },
  // Routes des promoteurs
  {
    'name': 'PromoterDetail',
    'path': '/promoter/:id',
    'screenBuilder': (BuildContext context, GoRouterState state) {
      final int promoterId = int.parse(state.pathParameters['id']!);
      return PromoterScreen(promoterId: promoterId);
    },
  },
  // Routes des lieux
  {
    'name': 'VenueDetail',
    'path': '/venue/:id',
    'screenBuilder': (BuildContext context, GoRouterState state) {
      final int venueId = int.parse(state.pathParameters['id']!);
      return VenueScreen(venueId: venueId);
    },
  },
  // Routes des genres
  {
    'name': 'GenreDetail',
    'path': '/genre/:id',
    'screenBuilder': (BuildContext context, GoRouterState state) {
      final int genreId = int.parse(state.pathParameters['id']!);
      return GenreScreen(genreId: genreId);
    },
  },
  // Routes des utilisateurs
  {
    'name': 'UserDetail',
    'path': '/user/:id',
    'screenBuilder': (BuildContext context, GoRouterState state) {
      final int userId = int.parse(state.pathParameters['id']!);
      return UserScreen(userId: userId);
    },
  },
  // Routes des événements
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
  // Routes des tickets
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

// Gestionnaire d'état d'authentification
final authStateManager = AuthStateManager();

// Configuration de GoRouter
final GoRouter router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: Uri.base.toString(),
  debugLogDiagnostics: false,
  redirect: (context, state) async {
    final user = Supabase.instance.client.auth.currentUser;
    final bool loggedIn = user != null;
    final bool isAuthPath = state.matchedLocation == '/auth';

    // Accès à l'événement de changement d'authentification
    final authChangeEvent = authStateManager.authChangeEvent;

    // Vérifier si l'utilisateur est en train de récupérer son mot de passe
    final recoveringPassword =
        authChangeEvent == AuthChangeEvent.passwordRecovery;

    // Définir les chemins protégés nécessitant une authentification
    final List<String> protectedPaths = [
      '/settings/profile',
      // Ajoutez d'autres chemins protégés si nécessaire
    ];

    // Vérifier si le chemin actuel est protégé
    bool isProtected =
        protectedPaths.any((path) => state.uri.toString().startsWith(path));

    if (!loggedIn && isProtected) {
      return '/';
    }

    // Si l'utilisateur est en train de récupérer son mot de passe, rediriger vers '/reset-password'
    if (recoveringPassword && state.uri.toString() != '/reset-password') {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      return '/reset-password';
    }

    // Gérer les liens profonds pour 'artist', 'promoter', 'venue', 'genre' et 'user'
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
          // Pas d'action nécessaire pour d'autres chemins
          break;
      }
      // Aucune redirection nécessaire pour les liens profonds d'entités
      return null;
    }

    // Si déjà connecté et que l'utilisateur essaie d'accéder à l'authentification, rediriger vers l'accueil
    if (loggedIn && isAuthPath) {
      return '/';
    }

    print('Navigating to: ${state.uri.toString()}');
    print('Matched location: ${state.matchedLocation}');

    return null; // Aucune redirection nécessaire
  },
  refreshListenable: authStateManager,
  routes: [
    // Définir le ShellRoute pour les routes avec barre de navigation
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
        ...getShellRoutes(), // Routes avec barre de navigation
      ],
    ),
    // Définir les routes standalone en dehors du ShellRoute
    ...getStandaloneRoutes(),
  ],
  errorBuilder: (context, state) => NotFoundError(state.error),
);

// Fonction pour générer les routes du ShellRoute
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
          // Définir des sous-routes si nécessaire, par exemple '/settings/profile'
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

// Fonction pour générer les routes standalone
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

/// Retourne le nom de la route actuelle.
String routeName() {
  final route = shellRoutes.firstWhere(
    (route) =>
        route['path'] == router.routerDelegate.currentConfiguration.fullPath,
    orElse: () => shellRoutes.first,
  );
  return route['name'] as String;
}

/// Retourne l'index de l'écran actuel.
int selectedIndex() {
  final route = shellRoutes.firstWhere(
    (route) =>
        route['path'] == router.routerDelegate.currentConfiguration.fullPath,
    orElse: () => shellRoutes.first,
  );
  return route['index'];
}

/// Navigue vers l'écran correspondant à l'index.
void onTap(BuildContext context, int index) {
  final route = shellRoutes.firstWhere(
    (route) => route['index'] == index,
    orElse: () => shellRoutes.first,
  );

  // Utiliser context.go pour naviguer sans empiler
  // context.go(route['path'] as String);
  context.push(route['path'] as String);
}

/// Classe pour écouter les changements d'état d'authentification.
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

/// Fonction pour créer une page avec une transition de fondu.
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
