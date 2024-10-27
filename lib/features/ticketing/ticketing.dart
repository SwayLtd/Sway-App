// lib/features/ticketing/ticketing.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/services/event_service.dart';
import 'package:sway/features/ticketing/models/ticket_model.dart';
import 'package:sway/features/ticketing/screens/ticket_detail_screen.dart';
import 'package:sway/features/ticketing/services/ticket_service.dart';
import 'package:sway/core/utils/date_utils.dart'; // Assurez-vous que ce chemin est correct

class TicketingScreen extends StatefulWidget {
  @override
  _TicketingScreenState createState() => _TicketingScreenState();
}

class _TicketingScreenState extends State<TicketingScreen>
    with SingleTickerProviderStateMixin {
  final TicketService _ticketService = TicketService();
  final EventService _eventService = EventService();

  List<Ticket> _upcomingTickets = [];
  List<Ticket> _pastTickets = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _loadTickets();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _loadTickets() async {
    List<Ticket> upcoming = await _ticketService.getUpcomingTickets();
    List<Ticket> past = await _ticketService.getPastTickets();
    setState(() {
      _upcomingTickets = upcoming;
      _pastTickets = past;
    });
  }

  Future<void> _importTicket() async {
    await _ticketService.importTicket();
    await _loadTickets();
  }

  Widget _buildTicketList(List<Ticket> tickets, {required bool isUpcoming}) {
    // Grouper les tickets catégorisés par eventId
    final categorizedGrouped = <int, List<Ticket>>{};
    tickets.where((t) => t.eventId != null).forEach((ticket) {
      categorizedGrouped.putIfAbsent(ticket.eventId!, () => []).add(ticket);
    });

    // Tickets non catégorisés
    final uncategorized =
        isUpcoming ? tickets.where((t) => t.eventId == null).toList() : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tickets Catégorisés
        if (categorizedGrouped.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Categorized',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ...categorizedGrouped.entries.map((entry) {
          final eventId = entry.key;
          final eventTickets = entry.value;
          return _buildCategorizedTile(eventId, eventTickets);
        }).toList(),

        // Tickets Non Catégorisés (Uniquement dans Upcoming)
        if (isUpcoming && uncategorized.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Uncategorized',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        if (isUpcoming)
          ...uncategorized.map((ticket) {
            return _buildListTile(ticket, isCategorized: false);
          }).toList(),

        // Message lorsqu'il n'y a aucun ticket
        if (categorizedGrouped.isEmpty &&
            (isUpcoming ? uncategorized.isEmpty : true))
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'No tickets imported',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategorizedTile(int eventId, List<Ticket> eventTickets) {
    return FutureBuilder<Event?>(
      future: _eventService.getEventById(eventId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListTile(
            leading: CircularProgressIndicator(),
            title: Text('Loading...'),
          );
        } else if (snapshot.hasError || !snapshot.hasData) {
          return ListTile(
            leading: Icon(Icons.error, color: Colors.red),
            title: Text('Event not found'),
          );
        } else {
          final event = snapshot.data!;
          final venueName = eventTickets.first.eventLocation ?? 'Venue not found';
          return ListTile(
            leading: event.imageUrl.isNotEmpty
                ? ImageWithErrorHandler(
                    imageUrl: event.imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  )
                : Icon(
                    Icons.calendar_today,
                    color: Colors.red,
                    size: 40,
                  ),
            title: Text(
              event.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  venueName,
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Colors.red,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      formatEventDate(event.dateTime),
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  '${eventTickets.length} ticket${eventTickets.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            onTap: () {
              // Naviguer vers TicketDetailScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TicketDetailScreen(
                    tickets:
                        eventTickets, // Liste complète des tickets associés
                    initialTicket: eventTickets[0], // Ticket initial
                  ),
                ),
              ).then((_) => _loadTickets());
            },
          );
        }
      },
    );
  }

  Widget _buildListTile(Ticket ticket, {bool isCategorized = true}) {
    return ListTile(
      leading: _buildLeadingImage(ticket),
      title: Text(
        isCategorized
            ? (ticket.eventName ?? 'Unnamed Event')
            : _getFileName(ticket.filePath),
        style: TextStyle(
          fontSize: isCategorized ? 16 : 14,
          fontWeight: isCategorized ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isCategorized
                ? (ticket.eventLocation ?? 'Unknown event details')
                : 'Unknown event details',
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: Colors.red,
                size: 16,
              ),
              SizedBox(width: 4),
              Text(
                isCategorized
                    ? formatEventDate(ticket.eventDate ?? ticket.importedDate)
                    : 'Unknown date',
                style: TextStyle(
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            '1 ticket',
            style: TextStyle(
              fontSize: 12,
            ),
          ),
        ],
      ),
      trailing: null, // Supprimer le compteur à droite
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TicketDetailScreen(
              tickets: [ticket],
              initialTicket: ticket,
            ),
          ),
        );
        await _loadTickets();
      },
    );
  }

  Widget _buildLeadingImage(Ticket ticket) {
    if (ticket.eventId != null) {
      // Afficher l'image de l'événement avec gestion des erreurs
      return FutureBuilder<Event?>(
        future: _eventService.getEventById(ticket.eventId!),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.imageUrl.isNotEmpty) {
            return ImageWithErrorHandler(
              imageUrl: snapshot.data!.imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            );
          } else {
            // Afficher une icône de calendrier par défaut
            return Icon(
              Icons.calendar_today,
              color: Colors.red,
              size: 40,
            );
          }
        },
      );
    } else {
      // Afficher l'icône du fichier ou une icône par défaut
      final fileExtension = _getFileExtension(ticket.filePath).toLowerCase();
      if (fileExtension == 'pdf') {
        return Icon(
          Icons.picture_as_pdf,
          color: Colors.red,
          size: 40,
        );
      } else if (['png', 'jpg', 'jpeg'].contains(fileExtension)) {
        return Image.file(
          File(ticket.filePath),
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        );
      } else {
        return Icon(
          Icons.insert_drive_file,
          color: Colors.red,
          size: 40,
        );
      }
    }
  }

  String _getFileName(String path) {
    return path.split('/').last;
  }

  String _getFileExtension(String path) {
    return path.split('.').last;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Deux onglets : Upcoming et Past
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tickets'),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.upload_file),
              onPressed: _importTicket,
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Onglet Upcoming
            _upcomingTickets.isEmpty
                ? Center(
                    child: Text(
                      'No tickets imported',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : SingleChildScrollView(
                    child: _buildTicketList(_upcomingTickets, isUpcoming: true),
                  ),
            // Onglet Past
            _pastTickets.isEmpty
                ? Center(
                    child: Text(
                      'No tickets imported',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : SingleChildScrollView(
                    child: _buildTicketList(_pastTickets, isUpcoming: false),
                  ),
          ],
        ),
      ),
    );
  }
}
