// lib/features/core/widgets/random_greeting_tile.dart

import 'dart:math';
import 'package:flutter/material.dart';

class RandomGreetingTile extends StatefulWidget {
  final String? username; // Optionally pass the username
  const RandomGreetingTile({Key? key, this.username}) : super(key: key);

  @override
  _RandomGreetingTileState createState() => _RandomGreetingTileState();
}

class _RandomGreetingTileState extends State<RandomGreetingTile> {
  late String greeting;

  @override
  void initState() {
    super.initState();
    greeting = _generateGreeting(widget.username);
  }

  // Generate a random greeting based on the username.
  String _generateGreeting(String? username) {
    final List<String> allGreetings = [
      "Hello Raver!",
      "Sleep is overrated!",
      "Hi @username, welcome back!",
      "Have a great party!",
      "See you this weekend!",
      "Let's get the party started!",
      "Keep dancing!",
      "Enjoy your night!",
      "Rock on!",
      "Stay awesome!",
      "Party hard, play smart!",
      "Good vibes only!",
      "Time to groove!",
      "Let's make some memories!",
      "Dance like nobody's watching!",
      "Keep the rhythm alive!",
      "Turn up the volume!",
      "Feel the beat!",
      "Live for the moment!",
      "Shine on, superstar!",
      "Cheers to a great night!"
    ];

    // If username is null or empty, filter out messages with the placeholder.
    final List<String> greetings = (username == null || username.isEmpty)
        ? allGreetings.where((msg) => !msg.contains('@username')).toList()
        : allGreetings;

    final random = Random();
    String selected = greetings[random.nextInt(greetings.length)];

    if (username != null &&
        username.isNotEmpty &&
        selected.contains('@username')) {
      selected = selected.replaceAll('@username', username);
    } else if (username != null && username.isNotEmpty && random.nextBool()) {
      selected = "Hi $username, " + selected.toLowerCase();
    }
    return selected;
  }

  @override
  void didUpdateWidget(covariant RandomGreetingTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the username changes, regenerate the greeting.
    if (widget.username != oldWidget.username) {
      setState(() {
        greeting = _generateGreeting(widget.username);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 12.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          alignment: Alignment.topLeft,
          child: Text(
            greeting,
            style: const TextStyle(
              fontSize: 18,
            ),
            textAlign: TextAlign.start,
          ),
        ),
      ),
    );
  }
}
