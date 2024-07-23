import 'package:flutter/material.dart';

class EventAppBarItem extends StatelessWidget {
  final String title;
  final int index;
  final ValueChanged<int> onTap;
  final int selectedIndex;

  const EventAppBarItem({
    Key? key,
    required this.title,
    required this.index,
    required this.onTap,
    required this.selectedIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedIndex == index;

    return Theme(
      data: Theme.of(context).copyWith(
        buttonTheme: const ButtonThemeData(
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.transparent, width: 0),
          ),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 2,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.transparent,
            ),
          ),
          TextButton(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).textTheme.bodyLarge!.color,
              ),
            ),
            onPressed: () {
              if (selectedIndex != index) {
                onTap(index);
              }
            },
          ),
        ],
      ),
    );
  }
}
