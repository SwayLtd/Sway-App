// lib/core/widgets/bottom_navigation_bar.dart

import 'package:flutter/material.dart';
import 'package:sway/core/routes.dart';
import 'package:flutter/services.dart';
// Ensure GoRouter is imported

class ScaffoldWithNavBarWithoutAppBar extends StatefulWidget {
  const ScaffoldWithNavBarWithoutAppBar({super.key, required this.child});
  final Widget child;

  @override
  State<ScaffoldWithNavBarWithoutAppBar> createState() =>
      _ScaffoldWithNavBarWithoutAppBarState();
}

class _ScaffoldWithNavBarWithoutAppBarState
    extends State<ScaffoldWithNavBarWithoutAppBar> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(debugLabel: 'navbar');

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    int index = selectedIndex();
    // Ensure the index is valid
    if (index < 0 || index >= 4) {
      // 4 being the number of items
      index = 0;
    }
    _currentIndex = index;
  }

  /// The widget to display in the body of the Scaffold.
  @override
  Widget build(BuildContext context) {
    final List<BottomNavigationBarItem> items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.local_library_outlined),
        label: "Explore",
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.search_outlined),
        label: "Search",
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.local_activity_outlined),
        label: "Tickets",
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.settings_outlined),
        label: "Settings",
      ),
    ];

    final List<NavigationDestination> destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.explore_outlined),
        selectedIcon: Icon(Icons.explore),
        label: "Explore",
      ),
      const NavigationDestination(
        icon: Icon(Icons.search_outlined),
        selectedIcon: Icon(Icons.search),
        label: "Search",
      ),
      const NavigationDestination(
        icon: Icon(Icons.local_activity_outlined),
        selectedIcon: Icon(Icons.local_activity),
        label: "Tickets",
      ),
      const NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: "Settings",
      ),
    ];

    // Calculate a valid index
    final int validIndex = (_currentIndex < 0 || _currentIndex >= items.length)
        ? 0
        : _currentIndex;

    // Get screen width to calculate indicator position
    /* final double screenWidth = MediaQuery.of(context).size.width;
    final int numberOfItems = items.length;
    final double itemWidth = screenWidth / numberOfItems;

    // Define indicator properties
    final double indicatorWidth = 48.0;
    final double indicatorHeight = 2.0;
    final Color indicatorColor = Theme.of(context).primaryColor; */

    return Scaffold(
      key: _scaffoldKey,
      body: widget.child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Divider line to separate BottomNavigationBar from content
          Divider(
            height: 1,
            thickness: 1,
            color: Color.fromRGBO(41, 36, 24, 1),
          ),
          // Stack to overlay the BottomNavigationBar and the indicator
          Stack(
            children: [
              /* BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                selectedItemColor: Theme.of(context).primaryColor,
                unselectedItemColor: Theme.of(context).disabledColor,
                items: items,
                onTap: (int index) {
                  onTap(context, index);
                  setState(() {
                    _currentIndex = index;
                  });
                },
                currentIndex: validIndex,
              ), */
              NavigationBar(
                selectedIndex: validIndex,
                onDestinationSelected: (int index) {
                  onTap(context, index);
                  setState(() {
                    _currentIndex = index;
                  });
                },
                destinations: destinations,
                // Optionally customize the NavigationBar appearance
                // You can adjust the height, background color, etc., here
              ),
              // Positioned indicator above the selected BottomNavigationBarItem
              /* AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                top:
                    0, // Position the indicator at the top of the BottomNavigationBar
                left:
                    (itemWidth * validIndex) + (itemWidth - indicatorWidth) / 2,
                child: Container(
                  width: indicatorWidth,
                  height: indicatorHeight,
                  decoration: BoxDecoration(
                    color: indicatorColor,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ), */
            ],
          ),
        ],
      ),
    );
  }
}
