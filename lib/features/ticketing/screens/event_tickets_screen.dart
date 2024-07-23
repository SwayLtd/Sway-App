import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sway_events/core/widgets/image_with_error_handler.dart';
import 'package:sway_events/features/event/event.dart';
import 'package:sway_events/features/event/models/event_model.dart';
import 'package:sway_events/features/ticketing/models/ticket_model.dart';
import 'package:sway_events/features/ticketing/services/ticket_service.dart';
import 'package:sway_events/features/user/models/user_event_ticket_model.dart';
import 'package:sway_events/features/user/services/user_event_ticket_service.dart';

class EventTicketsScreen extends StatefulWidget {
  final Event event;

  const EventTicketsScreen({required this.event});

  @override
  _EventTicketsScreenState createState() => _EventTicketsScreenState();
}

class _EventTicketsScreenState extends State<EventTicketsScreen> {
  int _currentIndex = 0;
  List<Ticket> tickets = [];
  String userId = "3"; // Assuming user ID is 3 for demonstration

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    final UserEventTicketService userTicketService = UserEventTicketService();
    final TicketService ticketService = TicketService();

    final List<UserEventTicket> userTickets =
        await userTicketService.getTicketsByEventId(widget.event.id);

    final List<Ticket> loadedTickets = [];
    for (var userTicket in userTickets) {
      final ticket = await ticketService.getTicketById(userTicket.ticketId);
      loadedTickets.add(ticket);
    }

    setState(() {
      tickets = loadedTickets;
    });
  }

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
      body: tickets.isEmpty
          ? Center(child: Text('No tickets found for this event'))
          : Column(
              children: [
                if (tickets.length > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      tickets.length,
                      (index) => buildDot(index, context),
                    ),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 475, // Adjusted height
                  width: double.infinity, // Full width
                  child: PageView.builder(
                    controller: pageController,
                    itemCount: tickets.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, index) {
                      final Ticket ticket = tickets[index];
                      final String qrCode =
                          ticket.generateQRCode(userId, DateTime.now());

                      return Container(
                        width: 300, // Fixed width for each ticket
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Theme.of(context).cardColor,
                        ),
                        child: Column(
                          children: [
                            ImageWithErrorHandler(
                              imageUrl: widget.event.imageUrl,
                              width: 300,
                              height: 150,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              ticket.ticketType,
                              style: const TextStyle(fontSize: 14),
                            ),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: QrImageView(
                                data: qrCode, // Use generated QR code data
                                size: 150,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "${ticket.id} - ${ticket.price}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .color,
                              ),
                            ), // Smaller text for ticket ID and price
                            Text(
                              widget.event.dateTime,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
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
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                vertical: 10,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[300],
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                            ),
                                            ListTile(
                                              leading: const Icon(
                                                Icons.remove_red_eye,
                                              ),
                                              title: const Text('See event'),
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        EventScreen(
                                                      event: widget.event,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            ListTile(
                                              leading: const Icon(
                                                Icons.calendar_today,
                                              ),
                                              title:
                                                  const Text('Add to calendar'),
                                              onTap: () {
                                                // Add to calendar logic
                                              },
                                            ),
                                            ListTile(
                                              leading:
                                                  const Icon(Icons.directions),
                                              title:
                                                  const Text('Get directions'),
                                              onTap: () {
                                                // Get directions logic
                                              },
                                            ),
                                            ListTile(
                                              leading:
                                                  const Icon(Icons.receipt),
                                              title:
                                                  const Text('Order details'),
                                              onTap: () {
                                                // Order details logic
                                              },
                                            ),
                                            ListTile(
                                              leading: const Icon(
                                                Icons.file_download,
                                              ),
                                              title: const Text(
                                                'Download e-ticket (PDF)',
                                              ),
                                              onTap: () {
                                                // Download e-ticket logic
                                              },
                                            ),
                                            ListTile(
                                              leading: const Icon(
                                                Icons.contact_support,
                                              ),
                                              title: const Text(
                                                'Contact organizer',
                                              ),
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
      margin: const EdgeInsets.only(
        right: 5,
        top: 20,
      ),
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
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodyMedium!.color,
          ),
        ),
      ],
    );
  }
}
