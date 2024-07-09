import 'package:sway_events/core/constants/l10n.dart';
import 'package:sway_events/core/routes.dart';
import 'package:flutter/material.dart';

class ScaffoldWithNavBar extends StatefulWidget {
  const ScaffoldWithNavBar({super.key, required this.child});
  final Widget child;

  @override
  State<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends State<ScaffoldWithNavBar> {
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
      BottomNavigationBarItem(
        icon: const Icon(Icons.local_library_outlined),
        label: "Discovery",
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.search_outlined),
        label: context.loc.bottomnavbarDevices,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.local_activity_outlined),
        label: context.loc.bottomnavbarAutomations,
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outlined),
        label: "Profile",
      ),
    ];

    return Scaffold(
      key: _scaffoldKey,
      body: widget.child,
      appBar: AppBar(
        title: Text(routeName()),
        centerTitle: true, // Center the title in the AppBar
        actions: <Widget>[
          InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () {
              // Access user settings screen
              setState(() {
                onTap(context, 4);
              });
            },
            child: Container(
              margin: const EdgeInsets.only(
                left: 7.5,
                right: 7.5,
              ), // Add some margin to the edges of the avatar
              child: const CircleAvatar(
                backgroundImage: NetworkImage(
                  'https://avatars.githubusercontent.com/u/21986104', // TODO: Get user avatar
                ),
              ),
            ),
          ),
        ],
      ),
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
