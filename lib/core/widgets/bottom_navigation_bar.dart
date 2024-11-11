// lib/core/widgets/bottom_navigation_bar.dart

import 'package:flutter/material.dart';
import 'package:sway/core/routes.dart';

class ScaffoldWithNavBarWithoutAppBar extends StatefulWidget {
  const ScaffoldWithNavBarWithoutAppBar({super.key, required this.child});
  final Widget child;

  @override
  State<ScaffoldWithNavBarWithoutAppBar> createState() => _ScaffoldWithNavBarWithoutAppBarState();
}

class _ScaffoldWithNavBarWithoutAppBarState extends State<ScaffoldWithNavBarWithoutAppBar> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(debugLabel: 'navbar');

  @override
  void initState() {
    super.initState();
    int index = selectedIndex();
    // Assurer que l'index est valide
    if (index < 0 || index >= 4) { // 4 étant le nombre d'items
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
        label: "Discovery",
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
        label: "Settings", // Modifier le label
      ),
    ];

    // Calculer un index valide
    final int validIndex = (_currentIndex < 0 || _currentIndex >= items.length) ? 0 : _currentIndex;

    return Scaffold(
      key: _scaffoldKey,
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
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
      ),
    );
  }
}
