// lib/core/routes.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/core/constants/l10n.dart';
import 'package:sway/core/utils/error/error_not_found.dart';
import 'package:sway/core/widgets/bottom_navigation_bar.dart';
import 'package:sway/features/discovery/discovery.dart';
import 'package:sway/features/search/search.dart';
import 'package:sway/features/settings/settings.dart';
import 'package:sway/features/ticketing/ticketing.dart';
import 'package:sway/features/user/screens/login_screen.dart'; // Importer le nouvel écran

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
    'screen': const SettingsScreen(), // Remplacer par le nouvel écran
  },
];

List<Map<String, dynamic>> standaloneRoutes = [
  {
    'name': 'Login',
    'path': '/login',
    'screen': const LoginScreen(),
  },
];

final GoRouter router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  redirect: (context, state) {
    final bool loggedIn = Supabase.instance.client.auth.currentUser != null;
    final bool loggingIn = state.matchedLocation == '/login';

    if (!loggedIn) {
      return loggingIn ? null : '/login';
    }

    if (loggingIn) {
      return '/';
    }

    return null;
  },
  refreshListenable:
      GoRouterRefreshStream(Supabase.instance.client.auth.onAuthStateChange),
  routes: [
    ShellRoute(
      navigatorKey: shellNavigatorKey,
      builder: (BuildContext context, GoRouterState state, Widget child) {
        // Localisation des noms de routes
        shellRoutes[0]['name'] = context.loc.routesNameHome;
        shellRoutes[1]['name'] = context.loc.routesNameTest;
        shellRoutes[2]['name'] = context.loc.routesNameTest;
        shellRoutes[3]['name'] = context.loc.routesNameSettings;

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
    // Routes hors de la ShellRoute (ex. Login)
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

// Retourner le nom de la route actuelle
String routeName() {
  final route = shellRoutes.firstWhere(
    (route) =>
        route['path'] == router.routerDelegate.currentConfiguration.fullPath,
    orElse: () => shellRoutes.first,
  );
  return route['name'] as String;
}

// Retourner l'index de l'écran actuel
int selectedIndex() {
  final route = shellRoutes.firstWhere(
    (route) =>
        route['path'] == router.routerDelegate.currentConfiguration.fullPath,
    orElse: () => shellRoutes.first,
  );
  return route['index'];
}

// Naviguer vers l'écran correspondant à l'index
void onTap(BuildContext context, int index) {
  final route = shellRoutes.firstWhere(
    (route) => route['index'] == index,
    orElse: () => shellRoutes.first,
  );

  // Utiliser context.go pour éviter les boucles de navigation
  context.go(route['path'] as String);
}

// Classe pour écouter les changements d'état d'authentification
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
