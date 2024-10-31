// lib/features/ticketing/screens/ticket_detail_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sway/features/event/event.dart';
import 'package:sway/features/event/services/event_service.dart';
import 'package:sway/features/event/services/event_venue_service.dart';
import 'package:sway/features/ticketing/models/ticket_model.dart';
import 'package:sway/features/ticketing/screens/add_event_details_screen.dart';
import 'package:screen_brightness/screen_brightness.dart'; // Assurez-vous d'avoir ce package
import 'package:sway/features/ticketing/services/ticket_service.dart';
import 'package:sway/features/venue/models/venue_model.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
// Importez le service VenueService

class TicketDetailScreen extends StatefulWidget {
  final List<Ticket> tickets;
  final Ticket initialTicket;

  const TicketDetailScreen({
    required this.tickets,
    required this.initialTicket,
  });

  @override
  _TicketDetailScreenState createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final EventService _eventService = EventService();
  final TicketService _ticketService = TicketService();
  final EventVenueService _eventVenueService =
      EventVenueService(); // Ajout du service

  late List<Ticket> _ticketsForEvent;
  late int _currentIndex;
  Venue? _venue; // Variable pour stocker la venue
  PdfViewerController _pdfViewerController = PdfViewerController();

  @override
  void initState() {
    super.initState();
    _loadTicketsForEvent();
    _currentIndex = _ticketsForEvent.indexOf(widget.initialTicket);
    if (_currentIndex == -1) _currentIndex = 0;
    _increaseBrightness();

    // Charger la venue associée à l'événement initial
    _loadVenue();
  }

  Future<void> _loadTicketsForEvent() async {
    // Si tous les tickets sont passés via widget.tickets, vous pouvez les assigner directement
    _ticketsForEvent = widget.tickets;
    // Sinon, récupérez-les via TicketService si nécessaire
    // _ticketsForEvent = await _ticketService.getTicketsByEventId(widget.initialTicket.eventId ?? -1);
  }

  Future<void> _loadVenue() async {
    final currentTicket = widget.initialTicket;
    if (currentTicket.eventId != null) {
      Venue? venue =
          await _eventVenueService.getVenueByEventId(currentTicket.eventId!);
      setState(() {
        _venue = venue;
      });
    }
  }

  Future<void> _increaseBrightness() async {
    try {
      await ScreenBrightness.instance.setApplicationScreenBrightness(
          1.0); // Ajustement local à l'application
    } catch (e) {
      print('Error setting brightness: $e');
    }
  }

  Future<void> _resetBrightness() async {
    try {
      await ScreenBrightness.instance.resetApplicationScreenBrightness();
    } catch (e) {
      print('Error resetting brightness: $e');
    }
  }

  @override
  void dispose() {
    _resetBrightness();
    _pdfViewerController.dispose();
    super.dispose();
  }

  Future<void> _showOptions() async {
    final Ticket currentTicket = _ticketsForEvent[_currentIndex];
    final List<PopupMenuEntry<String>> menuItems = [
      const PopupMenuItem<String>(
        value: 'download',
        child: Text('Download'),
      ),
      if (currentTicket.eventId != null)
        const PopupMenuItem<String>(
          value: 'go_to_event',
          child: Text('Go to event page'),
        ),
      const PopupMenuItem<String>(
        value: 'transfer',
        child: Text('Transfer', style: TextStyle(color: Colors.grey)),
      ),
      const PopupMenuItem<String>(
        value: 'add_to_calendar',
        child: Text('Add to calendar', style: TextStyle(color: Colors.grey)),
      ),
      if (currentTicket.eventId != null)
        const PopupMenuItem<String>(
          value: 'contact_promoter',
          child: Text('Contact promoter', style: TextStyle(color: Colors.grey)),
        ),
      // New PopupMenuItem for dissociating from group
      if (currentTicket.groupId != null)
        PopupMenuItem<String>(
          value: 'dissociate_group',
          child: Text('Dissociate tickets'),
        ),
      const PopupMenuItem<String>(
        value: 'delete_ticket',
        child: Text('Delete ticket', style: TextStyle(color: Colors.red)),
      ),
    ];

    final String? selected = await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(100, 100, 0, 0),
      items: menuItems,
    );

    switch (selected) {
      case 'download':
        // TODO: Implement download functionality
        break;
      case 'go_to_event':
        if (currentTicket.eventId != null) {
          final event =
              await _eventService.getEventById(currentTicket.eventId!);
          if (event != null) {
            // Optional: Load associated venue
            final venue = await _eventVenueService.getVenueByEventId(event.id);
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => EventScreen(event: event)),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Event not found')),
            );
          }
        }
        break;
      case 'transfer':
        // TODO: Implement transfer functionality
        break;
      case 'add_to_calendar':
        // TODO: Implement add to calendar functionality
        break;
      case 'contact_promoter':
        // TODO: Implement contact promoter functionality
        break;
      case 'dissociate_group':
        await _ticketService.dissociateGroupFromTicket(currentTicket.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ticket dissociated from group')),
        );
        // Refresh the UI to reflect changes
        setState(() {});
        break;
      case 'delete_ticket':
        _confirmDeleteTicket(currentTicket);
        break;
      default:
        break;
    }
  }

  Future<void> _confirmDeleteTicket(Ticket ticket) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this ticket?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _ticketService.deleteTicket(ticket.id);
      _ticketsForEvent.remove(ticket);
      if (_ticketsForEvent.isEmpty) {
        Navigator.pop(context);
      } else {
        setState(() {
          _currentIndex = _currentIndex > 0 ? _currentIndex - 1 : 0;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ticket deleted successfully')),
      );
    }
  }

  Widget _buildFileDisplay(Ticket ticket) {
    final fileExtension = _getFileExtension(ticket.filePath).toLowerCase();

    if (['png', 'jpg', 'jpeg'].contains(fileExtension)) {
      // Afficher l'image avec superposition "Imported"
      return Stack(
        children: [
          InteractiveViewer(
            panEnabled: true, // Activer le déplacement
            scaleEnabled: true, // Activer le zoom
            minScale: 1.0, // Échelle minimale de zoom (taille normale)
            maxScale: 5.0, // Échelle maximale de zoom
            child: Image.file(
              File(ticket.filePath),
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              color: Colors.green.withOpacity(0.5),
              padding: const EdgeInsets.all(4.0),
              child: const Text(
                'Imported',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          if (_venue != null)
            Positioned(
              bottom: 10,
              left: 10,
              child: Container(
                color: Colors.black.withOpacity(0.5),
                padding: const EdgeInsets.all(4.0),
                child: Text(
                  _venue!.name,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      );
    } else if (fileExtension == 'pdf') {
      // Afficher le PDF avec superposition "Imported"
      return Stack(
        children: [
          SfPdfViewer.file(
            File(ticket.filePath),
            controller: _pdfViewerController,
            enableDoubleTapZooming: true,
            initialZoomLevel: 1.0,
            //minZoomLevel: 1.0,
            maxZoomLevel: 5.0,
            onDocumentLoaded: (PdfDocumentLoadedDetails details) {
              // Vous pouvez ajouter des actions après le chargement du document si nécessaire
            },
            onPageChanged: (PdfPageChangedDetails details) {
              // Vous pouvez ajouter des actions lors du changement de page si nécessaire
            },
          ),
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              color: Colors.green.withOpacity(0.5),
              padding: const EdgeInsets.all(4.0),
              child: const Text(
                'Imported',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 10,
            child: Container(
              color: Colors.black.withOpacity(0.5),
              padding: const EdgeInsets.all(4.0),
              child: Text(
                ticket.eventLocation ?? 'Unknown location',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      );
    } else {
      // Afficher une icône par défaut si le type de fichier n'est pas supporté
      return Center(
        child: Icon(
          Icons.insert_drive_file,
          color: Colors.grey,
          size: 100,
        ),
      );
    }
  }

  String _getFileExtension(String path) {
    return path.split('.').last;
  }

  String _getFileName(String path) {
    return path.split('/').last;
  }

  @override
  Widget build(BuildContext context) {
    final Ticket currentTicket = _ticketsForEvent[_currentIndex];
    final fileExtension =
        _getFileExtension(currentTicket.filePath).toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: Text(
            currentTicket.eventName ?? _getFileName(currentTicket.filePath)),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Afficher le fichier (Image ou PDF)
          Expanded(
            child: _buildFileDisplay(currentTicket),
          ),
          // Type de ticket
          if (currentTicket.ticketType != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                currentTicket.ticketType!,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          // Flèches de navigation, compteur et bouton d'édition
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                // Flèche gauche
                IconButton(
                  icon: Icon(Icons.arrow_left, size: 30),
                  onPressed: _currentIndex > 0
                      ? () {
                          setState(() {
                            _currentIndex--;
                            // Charger la venue pour le ticket précédent
                            _loadVenue();
                          });
                        }
                      : null,
                ),
                // Compteur centré
                Expanded(
                  child: Center(
                    child: Text(
                      '${_currentIndex + 1} / ${_ticketsForEvent.length} tickets',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                ),
                // Flèche droite
                IconButton(
                  icon: Icon(Icons.arrow_right, size: 30),
                  onPressed: _currentIndex < _ticketsForEvent.length - 1
                      ? () {
                          setState(() {
                            _currentIndex++;
                            // Charger la venue pour le ticket suivant
                            _loadVenue();
                          });
                        }
                      : null,
                ),
                // Bouton d'édition aligné à droite
                IconButton(
                  icon: Icon(Icons.edit,
                      color: Theme.of(context).colorScheme.secondary),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddEventDetailsScreen(ticket: currentTicket),
                      ),
                    );
                    await _loadTicketsForEvent();
                    // Recharger la venue après la mise à jour
                    _loadVenue();
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          // Supprimer le texte "ADD DETAILS"
        ],
      ),
    );
  }
}
