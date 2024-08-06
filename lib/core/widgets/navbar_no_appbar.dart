import 'package:flutter/material.dart';
import 'package:sway_events/core/routes.dart';

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
    _currentIndex = selectedIndex();
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
        icon: Icon(Icons.person_outlined),
        label: "Profile",
      ),
    ];

    return Scaffold(
      key: _scaffoldKey,
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: selectedIndex() >= items.length
            ? Theme.of(context).disabledColor
            : Theme.of(context)
                .primaryColor, // Faking a disabled color if the index is out of range
        items: items,
        onTap: (int index) {
          onTap(context, index);
          _currentIndex = index;
        },
        currentIndex: (int index) {
          return _currentIndex = index >= items.length
              ? 0
              : index; // Faking the bottom navigation bar index if the index is out of range
        }(_currentIndex),
      ),
    );
  }
}
