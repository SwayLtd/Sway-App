// lib/features/ticketing/ticketing.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/services/event_service.dart';
import 'package:sway/features/ticketing/models/ticket_model.dart';
import 'package:sway/features/ticketing/screens/ticket_detail_screen.dart';
import 'package:sway/features/ticketing/services/ticket_service.dart';
import 'package:sway/core/utils/date_utils.dart';

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
    // Séparer les tickets en catégorisés et non catégorisés
    final categorizedTickets = tickets.where((t) => t.eventId != null).toList();
    final uncategorizedTickets =
        isUpcoming ? tickets.where((t) => t.eventId == null).toList() : [];

    // Grouper les tickets catégorisés par eventName
    final Map<String, List<Ticket>> categorizedByEvent = {};
    for (var ticket in categorizedTickets) {
      String key = ticket.eventName ?? 'Unnamed Event';
      categorizedByEvent.putIfAbsent(key, () => []).add(ticket);
    }

    // Grouper les tickets non catégorisés par groupId ou les traiter individuellement
    final Map<String, List<Ticket>> groupedUncategorized = {};
    for (var ticket in uncategorizedTickets) {
      String key =
          ticket.groupId ?? ticket.eventName ?? _getFileName(ticket.filePath);
      groupedUncategorized.putIfAbsent(key, () => []).add(ticket);
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16.0,
        right: 16.0,
        top: 16.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section des Tickets Non Catégorisés
          if (groupedUncategorized.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Uncategorized',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          if (isUpcoming)
            ...groupedUncategorized.entries.map((entry) {
              final groupKey = entry.key;
              final groupTickets = entry.value;
              final ticketCount = groupTickets.length;

              // Déterminer le titre à afficher
              String displayTitle;
              if (groupTickets.first.groupId != null) {
                // Si le ticket appartient à un groupe (multi-pages PDF), afficher le nom de base sans le suffixe
                displayTitle = groupTickets.first.eventName != null
                    ? groupTickets.first.eventName!.split('_ticket')[0]
                    : 'Unnamed Event';
              } else {
                // Si le ticket est importé individuellement, utiliser le nom de l'événement ou le nom du fichier
                displayTitle =
                    groupTickets.first.eventName ?? _getFileName(groupKey);
              }

              return ListTile(
                leading: _buildLeadingImage(groupTickets.first),
                title: Text(
                  displayTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      groupTickets.first.eventLocation ??
                          'Unknown event details',
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
                          formatEventDate(groupTickets.first.eventDate ??
                              groupTickets.first.importedDate),
                          style: TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      '$ticketCount ticket${ticketCount > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Naviguer vers TicketDetailScreen avec tous les tickets du groupe
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TicketDetailScreen(
                        tickets: groupTickets,
                        initialTicket: groupTickets.first,
                      ),
                    ),
                  ).then((_) => _loadTickets());
                },
              );
            }).toList(),

          // Section des Tickets Catégorisés
          if (categorizedByEvent.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Categorized',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          // ListTiles regroupés par eventName
          ...categorizedByEvent.entries.map((entry) {
            final eventName = entry.key;
            final eventTickets = entry.value;
            final ticketCount = eventTickets.length;

            return ListTile(
              leading: _buildLeadingImage(eventTickets.first),
              title: Text(
                eventName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eventTickets.first.eventLocation ?? 'Venue not found',
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
                        formatEventDate(eventTickets.first.eventDate ??
                            eventTickets.first.importedDate),
                        style: TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    '$ticketCount ticket${ticketCount > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Naviguer vers TicketDetailScreen avec tous les tickets de cet eventName
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TicketDetailScreen(
                      tickets: eventTickets,
                      initialTicket: eventTickets.first,
                    ),
                  ),
                ).then((_) => _loadTickets());
              },
            );
          }).toList(),

          // Message lorsqu'il n'y a aucun ticket
          if (categorizedByEvent.isEmpty &&
              (isUpcoming ? uncategorizedTickets.isEmpty : true))
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
      ),
    );
  }

  Widget _buildLeadingImage(Ticket ticket) {
    if (ticket.eventId != null) {
      // Afficher l'image de l'événement avec gestion des erreurs
      return FutureBuilder<Event?>(
        future: _eventService.getEventById(ticket.eventId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError || !snapshot.hasData) {
            return Icon(
              Icons.error,
              color: Colors.red,
              size: 40,
            );
          } else {
            final event = snapshot.data!;
            if (event.imageUrl.isNotEmpty) {
              return ImageWithErrorHandler(
                imageUrl: event.imageUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              );
            } else {
              return Icon(
                Icons.calendar_today,
                color: Colors.red,
                size: 40,
              );
            }
          }
        },
      );
    } else {
      // Afficher l'icône du fichier ou une miniature si c'est une image
      final fileExtension = _getFileExtension(ticket.filePath).toLowerCase();
      if (['png', 'jpg', 'jpeg'].contains(fileExtension)) {
        return Image.file(
          File(ticket.filePath),
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        );
      } else if (fileExtension == 'pdf') {
        return Icon(
          Icons.picture_as_pdf,
          color: Colors.red,
          size: 40,
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

  Widget _buildGroupedTicketTile(String groupId, List<Ticket> groupTickets) {
    // Utiliser le premier ticket du groupe pour obtenir les informations de l'événement
    final Ticket firstTicket = groupTickets.first;

    // Déterminer si le groupe est catégorisé (a un eventId)
    bool isCategorized = firstTicket.eventId != null;

    if (isCategorized) {
      return FutureBuilder<Event?>(
        future: _eventService.getEventById(firstTicket.eventId!),
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
            final venueName = firstTicket.eventLocation ?? 'Venue not found';
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
                    '${groupTickets.length} ticket${groupTickets.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              onTap: () {
                // Naviguer vers TicketDetailScreen avec tous les tickets du groupe
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TicketDetailScreen(
                      tickets: groupTickets,
                      initialTicket: groupTickets[0],
                    ),
                  ),
                ).then((_) => _loadTickets());
              },
            );
          }
        },
      );
    } else {
      // Groupe Non Catégorisé
      return ListTile(
        leading: _buildLeadingImage(groupTickets.first),
        title: Text(
          firstTicket.eventName ?? _getFileName(firstTicket.filePath),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unknown event details',
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
                  'Unknown date',
                  style: TextStyle(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              '${groupTickets.length} ticket${groupTickets.length > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ],
        ),
        onTap: () {
          // Naviguer vers TicketDetailScreen avec tous les tickets du groupe
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TicketDetailScreen(
                tickets: groupTickets,
                initialTicket: groupTickets[0],
              ),
            ),
          ).then((_) => _loadTickets());
        },
      );
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
