// scrolling_text_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ScrollingTextScreen extends StatefulWidget {
  final String text;

  const ScrollingTextScreen({required this.text});

  @override
  _ScrollingTextScreenState createState() => _ScrollingTextScreenState();
}

class _ScrollingTextScreenState extends State<ScrollingTextScreen>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);

    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration:
          const Duration(seconds: 10), // Adjust duration for desired speed
    )..repeat();
    _animationController.addListener(_scroll);
  }

  void _scroll() {
    if (_scrollController.hasClients) {
      _scrollController
          .jumpTo(_scrollController.offset + 3); // Adjust for desired speed
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              return Center(
                child: SizedBox(
                  height: MediaQuery.of(context).size.width,
                  child: Text(
                    '${widget.text.toUpperCase()}. ',
                    style: const TextStyle(
                      fontSize: 175,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      wordSpacing: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
