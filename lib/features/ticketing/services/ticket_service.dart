// lib/features/ticketing/services/ticket_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sway/features/ticketing/models/ticket_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class TicketService {
  static final TicketService _instance = TicketService._internal();
  factory TicketService() => _instance;
  TicketService._internal();

  static const String _ticketsKey = 'tickets';

  /// Importe un ticket (PDF ou Image) depuis l'appareil de l'utilisateur.
  Future<void> importTicket() async {
    try {
      // Ouvre le sélecteur de fichiers permettant les PDFs et les images
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final String filePath = result.files.single.path!;
        final String fileName = result.files.single.name;

        // Enregistre le fichier dans le répertoire des documents de l'application
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final String savedPath = '${appDocDir.path}/$fileName';
        final File file = File(filePath);
        await file.copy(savedPath);

        // Crée une nouvelle entrée de ticket
        final Ticket ticket = Ticket(
          id: Uuid().v4().hashCode,
          filePath: savedPath,
          importedDate: DateTime.now(),
        );

        // Récupère la liste actuelle des tickets
        List<Ticket> currentTickets = await getTickets();

        // Ajoute le nouveau ticket
        currentTickets.add(ticket);

        // Enregistre la liste mise à jour
        await _saveTickets(currentTickets);
      }
    } catch (e) {
      // Gérer les erreurs de manière appropriée
      print('Error importing ticket: $e');
    }
  }

  /// Récupère tous les tickets.
  Future<List<Ticket>> getTickets() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? ticketsJson = prefs.getString(_ticketsKey);
    if (ticketsJson != null) {
      List<dynamic> decoded = json.decode(ticketsJson);
      return decoded.map((item) => Ticket.fromMap(item)).toList();
    }
    return [];
  }

  /// Sauvegarde la liste des tickets dans SharedPreferences.
  Future<void> _saveTickets(List<Ticket> tickets) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> ticketsMap =
        tickets.map((t) => t.toMap()).toList();
    String encoded = json.encode(ticketsMap);
    await prefs.setString(_ticketsKey, encoded);
  }

  /// Met à jour un ticket existant.

  Future<void> updateTicket(Ticket updatedTicket) async {
    List<Ticket> currentTickets = await getTickets();
    int index = currentTickets.indexWhere((t) => t.id == updatedTicket.id);
    if (index != -1) {
      currentTickets[index] = updatedTicket;
      await _saveTickets(currentTickets);
    }
  }

  /// Récupère les tickets liés à un événement spécifique.
  Future<List<Ticket>> getTicketsByEventId(int eventId) async {
    List<Ticket> allTickets = await getTickets();
    return allTickets.where((t) => t.eventId == eventId).toList();
  }

  /// Récupère les tickets à venir en fonction de la date de l'événement.
  Future<List<Ticket>> getUpcomingTickets() async {
    final now = DateTime.now();
    List<Ticket> allTickets = await getTickets();
    return allTickets.where((t) {
      final eventDate = t.eventDate ?? t.importedDate;
      return isTodayOrAfter(eventDate, now);
    }).toList();
  }

  /// Récupère les tickets passés en fonction de la date de l'événement.
  Future<List<Ticket>> getPastTickets() async {
    final now = DateTime.now();
    List<Ticket> allTickets = await getTickets();
    return allTickets.where((t) {
      final eventDate = t.eventDate ?? t.importedDate;
      return isBeforeToday(eventDate, now);
    }).toList();
  }

  /// Helper method to check if date is today or after today
  bool isTodayOrAfter(DateTime date, DateTime reference) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final refOnly = DateTime(reference.year, reference.month, reference.day);
    return dateOnly.isAfter(refOnly) || dateOnly.isAtSameMomentAs(refOnly);
  }

  /// Helper method to check if date is before today
  bool isBeforeToday(DateTime date, DateTime reference) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final refOnly = DateTime(reference.year, reference.month, reference.day);
    return dateOnly.isBefore(refOnly);
  }

  /// Supprime un ticket de la liste en fonction de son ID.
  Future<void> deleteTicket(int ticketId) async {
    // Récupère la liste actuelle des tickets
    List<Ticket> currentTickets = await getTickets();

    // Filtre pour conserver uniquement les tickets qui ne correspondent pas à l'ID à supprimer
    currentTickets = currentTickets.where((t) => t.id != ticketId).toList();

    // Enregistre la liste mise à jour sans le ticket supprimé
    await _saveTickets(currentTickets);
  }
}
