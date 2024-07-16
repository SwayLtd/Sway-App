// event_tickets_screen.dart

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sway_events/core/widgets/image_with_error_handler.dart';
import 'package:sway_events/features/event/event.dart';
import 'package:sway_events/features/event/models/event_model.dart';

class EventTicketsScreen extends StatefulWidget {
  final Event event;

  const EventTicketsScreen({required this.event});

  @override
  _EventTicketsScreenState createState() => _EventTicketsScreenState();
}

class _EventTicketsScreenState extends State<EventTicketsScreen> {
  int _currentIndex = 0;

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final PageController pageController = PageController();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.event.title} Tickets'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) => buildDot(index, context)),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 475, // Adjusted height
            child: PageView.builder(
              controller: pageController,
              itemCount: 3, // Replace with actual ticket count
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                return Container(
                  width: 300,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      ImageWithErrorHandler(
                        imageUrl: widget.event.imageUrl,
                        width: 300,
                        height: 150,
                      ),
                      const SizedBox(height: 10),
                      const Text("Door", style: TextStyle(fontSize: 14)),
                      QrImageView(
                        data:
                            "567578676745687", // Replace with actual QR code data
                        size: 150,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "567578676745687 - €25",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ), // Smaller text for ticket ID and price
                      Text(
                        widget.event.dateTime,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ), // Smaller text for date
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          buildIconWithLabel(
                            icon: Icons.attach_money,
                            label: 'Sell',
                            onTap: () {
                              // Resell logic
                            },
                            context: context,
                          ),
                          buildIconWithLabel(
                            icon: Icons.reply,
                            label: 'Transfer',
                            onTap: () {
                              // Transfer logic
                            },
                            context: context,
                            isReversed: true,
                          ),
                          buildIconWithLabel(
                            icon: Icons.more_horiz,
                            label: 'More',
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                ),
                                builder: (context) {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        height: 5,
                                        width: 50,
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                      ),
                                      ListTile(
                                        leading:
                                            const Icon(Icons.remove_red_eye),
                                        title: const Text('See event'),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => EventScreen(
                                                event: widget.event,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      ListTile(
                                        leading:
                                            const Icon(Icons.calendar_today),
                                        title: const Text('Add to calendar'),
                                        onTap: () {
                                          // Add to calendar logic
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.directions),
                                        title: const Text('Get directions'),
                                        onTap: () {
                                          // Get directions logic
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.receipt),
                                        title: const Text('Order details'),
                                        onTap: () {
                                          // Order details logic
                                        },
                                      ),
                                      ListTile(
                                        leading:
                                            const Icon(Icons.file_download),
                                        title: const Text(
                                            'Download e-ticket (PDF)'),
                                        onTap: () {
                                          // Download e-ticket logic
                                        },
                                      ),
                                      ListTile(
                                        leading:
                                            const Icon(Icons.contact_support),
                                        title: const Text('Contact organizer'),
                                        onTap: () {
                                          // Contact organizer logic
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            context: context,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDot(int index, BuildContext context) {
    return Container(
      height: 10,
      width: 10,
      margin: const EdgeInsets.only(right: 5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _currentIndex == index
            ? Theme.of(context).primaryColor
            : Colors.grey,
      ),
    );
  }

  Widget buildIconWithLabel({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required BuildContext context,
    bool isReversed = false,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: CircleAvatar(
            backgroundColor: Colors.grey[300],
            child: Transform(
              alignment: Alignment.center,
              transform:
                  isReversed ? Matrix4.rotationY(3.14159) : Matrix4.identity(),
              child: Icon(
                icon,
                color: Colors.grey[700],
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
