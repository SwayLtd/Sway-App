// lib/core/routes.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/core/utils/error/error_not_found.dart';
import 'package:sway/core/widgets/bottom_navigation_bar.dart';
import 'package:sway/features/discovery/discovery.dart';
import 'package:sway/features/search/search.dart';
import 'package:sway/features/settings/settings.dart';
import 'package:sway/features/ticketing/ticketing.dart';
import 'package:sway/features/user/screens/login_screen.dart'; // Import LoginScreen
import 'package:sway/features/user/profile.dart';
import 'package:sway/features/user/screens/sign_up_screen.dart'; // Import ProfileScreen

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

List<Map<String, dynamic>> shellRoutes = [
  {
    'name': 'Discovery',
    'path': '/',
    'index': 0,
    'screen': DiscoveryScreen(),
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
    'name': 'Login',
    'path': '/login',
    'screen': const LoginScreen(),
  },
  {
    'name': 'SignUp',
    'path': '/signup',
    'screen': const SignUpScreen(),
  },
];

final GoRouter router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  redirect: (context, state) {
    final user = Supabase.instance.client.auth.currentUser;
    final bool loggedIn = user != null;
    final bool loggingIn = state.matchedLocation == '/login';
    final bool signingUp = state.matchedLocation == '/signup';

    // Define protected paths that require authentication
    final List<String> protectedPaths = [
      '/settings/profile',
      // Add more protected paths if needed
    ];

    // Check if the current path is protected
    bool isProtected =
        protectedPaths.any((path) => state.uri.toString().startsWith(path));

    if (!loggedIn && isProtected) {
      return '/login';
    }

    // If already logged in and trying to access login or signup, redirect to home
    if (loggedIn && (loggingIn || signingUp)) {
      return '/';
    }

    return null; // No redirect needed
  },
  refreshListenable:
      GoRouterRefreshStream(Supabase.instance.client.auth.onAuthStateChange),
  routes: [
    ShellRoute(
      navigatorKey: shellNavigatorKey,
      builder: (BuildContext context, GoRouterState state, Widget child) {
        // Optionally, localize route names here if needed

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
      routes: getShellRoutes(),
    ),
    // Add standalone routes (e.g., Login, SignUp)
    ...getStandaloneRoutes(),
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
          return NoTransitionPage(
            key: state.pageKey,
            child: route['screen'] as Widget,
          );
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
    generatedRoutes.add(
      GoRoute(
        path: route['path'] as String,
        name: route['name'] as String,
        builder: (context, state) => route['screen'] as Widget,
      ),
    );
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
  context.go(route['path'] as String);
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
