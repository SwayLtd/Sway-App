// lib/services/pdf_service.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sway/features/ticketing/services/ticket_service.dart';

class PdfService {
  final GlobalKey<NavigatorState> navigatorKey;
  static const MethodChannel _pdfChannel = MethodChannel('app.sway.main/pdf');

  PdfService(this.navigatorKey);

  Future<void> initialize() async {
    _pdfChannel.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    try {
      if (call.method == 'openPdf') {
        final String pdfPath = call.arguments as String;
        if (pdfPath.isNotEmpty) {
          await TicketService().importTicketFromPath(pdfPath);
          GoRouter.of(navigatorKey.currentContext!).go('/tickets');
        } else {
          // Gérer le cas où le chemin est vide
          debugPrint('Le chemin du PDF est vide.');
        }
      }
      // Gérer d'autres méthodes si nécessaire
    } catch (e) {
      // Gérer les erreurs
      debugPrint('Erreur lors du traitement de la méthode: $e');
      // Vous pouvez également envoyer des messages d'erreur à la plateforme native si nécessaire
    }
  }

  Future<void> openPdf(String path) async {
    try {
      await _pdfChannel.invokeMethod('openPdf', path);
    } on PlatformException catch (e) {
      // Gérer les erreurs de la plateforme native
      debugPrint('Erreur lors de l\'invocation de openPdf: ${e.message}');
    }
  }
}
