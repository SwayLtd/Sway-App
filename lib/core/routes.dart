// https://github.com/flutter/packages/blob/main/packages/go_router/example/lib/shell_route.dart
// https://blog.codemagic.io/flutter-go-router-guide/

// ignore_for_file: avoid_dynamic_calls

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:sway_events/core/constants/l10n.dart';
import 'package:sway_events/core/utils/error/error_not_found.dart';
import 'package:sway_events/core/widgets/navbar_no_appbar.dart';
import 'package:sway_events/features/discovery/discovery.dart';
import 'package:sway_events/features/search/search.dart';
import 'package:sway_events/features/user/profile.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

List routes = [
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
    'screen': SearchScreen(),
  },
  {
    'name': 'Profile',
    'path': '/profile/:id',
    'index': 3,
    'screen': const ProfileScreen(userId: '3',),
  },
];

final GoRouter router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  // routerNeglect: false, // Stop the router from adding the pages to the browser history > Setting for user privacy
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (BuildContext context, GoRouterState state, Widget child) {
        // Localizing road names
        routes[0]['name'] = context.loc.routesNameHome;
        routes[1]['name'] = context.loc.routesNameTest;
        routes[2]['name'] = context.loc.routesNameHome;
        routes[3]['name'] = context.loc.routesNameTest;

        return ResponsiveBreakpoints.builder(
          child: /*Stack(
            children: <Widget>[
              ResponsiveVisibility(
                key: GlobalKey(debugLabel: 'navBar'),
                // Show bottom navigation bar only on mobiles (smaller than TABLET)
                hiddenConditions: const [
                  Condition.largerThan(name: MOBILE),
                ],
                child: ScaffoldWithNavBar(child: child),
              ),
              ResponsiveVisibility(
                key: GlobalKey(debugLabel: 'appBar'),
                // Show app bar only on tablet (between MOBILE and DESKTOP)
                hiddenConditions: const [
                  Condition.smallerThan(name: TABLET),
                  Condition.largerThan(name: TABLET),
                ],
                child: ScaffoldWithAppBar(child: child),
              ),
              ResponsiveVisibility(
                key: GlobalKey(debugLabel: 'sideBar'),
                // Show side menu only on desktop (larger than TABLET)
                hiddenConditions: const [
                  Condition.smallerThan(name: DESKTOP),
                ],
                child: ScaffoldWithSideBar(child: child),
              ),
            ],
          ),*/
          ScaffoldWithNavBarWithoutAppBar(child: child),
          breakpoints: const [
            Breakpoint(start: 0, end: 450, name: MOBILE),
            Breakpoint(start: 451, end: 800, name: TABLET),
            Breakpoint(start: 801, end: 1200, name: DESKTOP),
            Breakpoint(start: 1201, end: 2460, name: 'HD'),
            Breakpoint(start: 2461, end: double.infinity, name: 'UHD'),
          ],
        );
      },
      routes: getRoutes(),
    ),
  ],
  errorBuilder: (context, state) => NotFoundError(state.error),
);

List<RouteBase> getRoutes() {
  final List<RouteBase> generatedRoutes = [];
  for (final route in routes) {
    generatedRoutes.add(
      GoRoute(
        path: route['path'] as String,
        name: route['name'] as String,
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          // NoTransitionPage is a custom widget that disables the default page transition animation
          child: route['screen'] as Widget,
        ),
      ),
    );
  }

  return generatedRoutes;
}

// Return the current route name
String routeName() {
  final route = routes.firstWhere(
    (route) => route['path'] == router.routerDelegate.currentConfiguration.fullPath,
    orElse: () => routes.first,
  );
  return route['name'] as String;
}

// Return the index of the current screen
int selectedIndex() {
  final route = routes.firstWhere(
    (route) => route['path'] == router.routerDelegate.currentConfiguration.fullPath,
    orElse: () => routes.first,
  );
  return route['index'] as int;
}

// Navigate to the screen corresponding to the index
void onTap(BuildContext context, int index) {
  final route = routes.firstWhere(
    (route) => route['index'] == index,
    orElse: () => routes.first,
  );

  // context.push has been used instead of context.go because it works better with the back button
  // Need to check if this is not creating a loop when we are faking the index for the bottom navigation bar
  context.push(route['path'] as String);
  Navigator.maybePop(context); // Close the drawer
}
