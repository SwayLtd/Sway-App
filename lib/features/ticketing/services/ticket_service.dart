// lib/features/ticketing/services/ticket_service.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sway/features/ticketing/models/ticket_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class TicketService {
  static final TicketService _instance = TicketService._internal();
  factory TicketService() => _instance;
  TicketService._internal();

  static const String _ticketsKey = 'tickets';

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
        final String savedDirPath = '${appDocDir.path}/tickets';
        final Directory savedDir = Directory(savedDirPath);

        if (!await savedDir.exists()) {
          await savedDir.create(recursive: true);
        }

        final String fileExtension = _getFileExtension(fileName).toLowerCase();

        List<Ticket> newTickets = [];

        if (fileExtension == 'pdf') {
          // Traiter les PDF avec syncfusion_flutter_pdf
          final File file = File(filePath);
          final List<Ticket> tickets =
              await _splitPdfAndSaveSyncfusion(file, fileName, savedDirPath);
          newTickets.addAll(tickets);
        } else if (['png', 'jpg', 'jpeg'].contains(fileExtension)) {
          // Traiter les images
          final String savedPath = '$savedDirPath/$fileName';
          final File file = File(filePath);
          await file.copy(savedPath);

          // Ne pas assigner de groupId pour les images
          // Crée une nouvelle entrée de ticket sans groupId
          final Ticket ticket = Ticket(
            id: Uuid().v4().hashCode,
            filePath: savedPath,
            importedDate: DateTime.now(),
            eventName: _removeFileExtension(fileName),
            groupId: null, // Aucun groupId assigné
          );

          newTickets.add(ticket);
        }

        // Récupère la liste actuelle des tickets
        List<Ticket> currentTickets = await getTickets();

        // Ajoute les nouveaux tickets
        currentTickets.addAll(newTickets);

        // Enregistre la liste mise à jour
        await _saveTickets(currentTickets);
      }
    } catch (e) {
      // Gérer les erreurs de manière appropriée
      print('Error importing ticket: $e');
    }
  }

  Future<List<Ticket>> _splitPdfAndSaveSyncfusion(
      File originalFile, String originalFileName, String savedDirPath) async {
    List<Ticket> tickets = [];
    try {
      // Load the original PDF document
      final Uint8List bytes = await originalFile.readAsBytes();
      final PdfDocument originalPdf = PdfDocument(inputBytes: bytes);
      final int pageCount = originalPdf.pages.count;

      // Determine if the PDF has multiple pages
      String? groupId;
      if (pageCount > 1) {
        groupId = Uuid()
            .v4()
            .toString(); // Assign a unique groupId for multi-page PDFs
      }

      for (int pageNumber = 0; pageNumber < pageCount; pageNumber++) {
        // Generate a unique file name for each ticket
        final String newFileName =
            '${_removeFileExtension(originalFileName)}_ticket${pageNumber + 1}.pdf';
        final String savedPath = '$savedDirPath/$newFileName';

        // Create a new PDF document
        final PdfDocument newPdf = PdfDocument();

        // Get the size of the original page
        final PdfPage originalPage = originalPdf.pages[pageNumber];
        final Size originalSize = originalPage.size;

        // Remove white margins on page
        newPdf.pageSettings.margins.all = 0;

        // Add a new page with the same size as the original page
        final PdfPage newPage = newPdf.pages.add();

        // Import the page from the original document
        newPage.graphics.drawPdfTemplate(
          originalPage.createTemplate(),
          Offset.zero,
          Size(originalSize.width, originalSize.height),
        );

        // Save the new PDF document
        final List<int> newBytes = await newPdf.save();
        final File newPdfFile = File(savedPath);
        await newPdfFile.writeAsBytes(newBytes);

        // Dispose the new document
        newPdf.dispose();

        // Create a new ticket
        final Ticket ticket = Ticket(
          id: Uuid().v4().hashCode,
          filePath: savedPath,
          importedDate: DateTime.now(),
          eventName: _removeFileExtension(originalFileName),
          groupId: groupId, // Assign groupId only if PDF has multiple pages
        );

        tickets.add(ticket);
      }

      // Dispose the original document
      originalPdf.dispose();
    } catch (e) {
      print('Error splitting PDF: $e');
    }

    return tickets;
  }

  String _getFileExtension(String path) {
    return path.split('.').last;
  }

  String _removeFileExtension(String fileName) {
    return fileName.replaceAll(RegExp(r'\.[^.]*$'), '');
  }

  /// Dissociates a ticket from its group by setting its groupId to null.
  Future<void> dissociateGroupFromTicket(int ticketId) async {
    // Retrieve the current list of tickets
    List<Ticket> currentTickets = await getTickets();

    // Find the index of the ticket to dissociate
    int index = currentTickets.indexWhere((t) => t.id == ticketId);

    if (index != -1 && currentTickets[index].groupId != null) {
      // Get the existing ticket
      Ticket oldTicket = currentTickets[index];

      // Create a new Ticket instance with groupId set to null
      Ticket updatedTicket = Ticket(
        id: oldTicket.id,
        filePath: oldTicket.filePath,
        importedDate: oldTicket.importedDate,
        eventId: oldTicket.eventId,
        eventName: oldTicket.eventName,
        eventDate: oldTicket.eventDate,
        eventEndDate: oldTicket.eventEndDate, // Preserve the eventEndDate
        eventLocation: oldTicket.eventLocation,
        ticketType: oldTicket.ticketType,
        groupId: null, // Dissociate the groupId
      );

      // Replace the old ticket with the updated ticket
      currentTickets[index] = updatedTicket;

      // Save the updated list of tickets
      await _saveTickets(currentTickets);
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

  /// Récupère un ticket par son ID local.
  Future<Ticket?> getTicketById(int ticketId) async {
    List<Ticket> currentTickets = await getTickets();
    try {
      return currentTickets.firstWhere((t) => t.id == ticketId);
    } catch (e) {
      return null;
    }
  }

  /// Récupère les tickets à venir en fonction de la date de fin de l'événement.
  Future<List<Ticket>> getUpcomingTickets() async {
    final now = DateTime.now();
    List<Ticket> allTickets = await getTickets();
    return allTickets.where((t) {
      final eventEndDate = t.eventEndDate ?? t.eventDate ?? t.importedDate;
      return isTodayOrAfter(eventEndDate, now);
    }).toList();
  }

  /// Récupère les tickets passés en fonction de la date de fin de l'événement.
  Future<List<Ticket>> getPastTickets() async {
    final now = DateTime.now();
    List<Ticket> allTickets = await getTickets();
    return allTickets.where((t) {
      final eventEndDate = t.eventEndDate ?? t.eventDate ?? t.importedDate;
      return isBeforeToday(eventEndDate, now);
    }).toList();
  }

  /// Helper method to check if date is today or after today
  bool isTodayOrAfter(DateTime date, DateTime reference) {
    final dateOnly = DateTime(date.year, date.month, date.day, 23, 59, 59);
    final refOnly =
        DateTime(reference.year, reference.month, reference.day, 0, 0, 0);
    return dateOnly.isAfter(refOnly) || dateOnly.isAtSameMomentAs(refOnly);
  }

  /// Helper method to check if date is before today
  bool isBeforeToday(DateTime date, DateTime reference) {
    final dateOnly = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final refOnly =
        DateTime(reference.year, reference.month, reference.day, 0, 0, 0);
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
