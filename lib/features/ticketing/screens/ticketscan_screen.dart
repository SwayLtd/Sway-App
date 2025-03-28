/* // lib/features/ticketing/screens/ticketscan_screen.dart
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/core/services/database_service.dart';
import 'package:sway/features/ticketing/models/isar_online_ticket.dart';
import 'package:sway/features/ticketing/models/isar_scan_history.dart';

class TicketScanPage extends StatefulWidget {
  final Event event; // The event for which tickets are being scanned
  TicketScanPage(this.event);

  @override
  _TicketScanPageState createState() => _TicketScanPageState();
}

class _TicketScanPageState extends State<TicketScanPage> {
  String? scanMessage;
  bool scanSuccess = false;
  MobileScannerController scannerController = MobileScannerController();
  late final Future<Isar> _isarFuture = DatabaseService().isar;

  // Callback for barcode detection using BarcodeCapture
  void _onDetect(BarcodeCapture capture) async {
    try {
      final Barcode barcode = capture.barcodes.first;
      final String? code = barcode.rawValue;
      if (code == null) return;
      // Stop the scanner to avoid duplicate scans
      scannerController.stop();
      // Extract ticket ID from the scanned code
      String ticketId = code.startsWith("ticket:") ? code.substring(7) : code;

      // Invoke the edge function 'ticket-scan' for validation
      final response = await Supabase.instance.client.functions
          .invoke('ticket-scan', body: {'ticket_id': ticketId});

      // If no exception is thrown, process the response data
      final data = response.data;
      bool valid = data['valid'] == true;
      setState(() {
        scanSuccess = valid;
        scanMessage =
            data['message'] ?? (valid ? "Ticket valid" : "Ticket invalid");
      });

      if (valid) {
        // Mark the ticket as used in local Isar database
        final isar = await _isarFuture;
        final localTicket = await isar.onlineTicketIsars.getById(ticketId);
        if (localTicket != null) {
          localTicket.used = true;
          localTicket.usedAt = DateTime.now();
          await isar.writeTxn(() async {
            await isar.onlineTicketIsars.put(localTicket);
          });
        }
        // Record a local scan log
        final scan = IsarScanHistory(
          ticketId: ticketId,
          eventId: widget.event.id ?? 0,
          scannedAt: DateTime.now(),
        );
        await isar.writeTxn(() async {
          await isar.isarScanHistorys.put(scan);
        });
      }
    } catch (e) {
      setState(() {
        scanSuccess = false;
        scanMessage = "Verification error: $e";
      });
    }

    // Restart the scanner after a short delay to allow the user to read the message
    await Future.delayed(Duration(seconds: 2));
    setState(() {
      scanMessage = null;
    });
    scannerController.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Scan Tickets - ${widget.event.title}"),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: scannerController,
            onDetect: _onDetect,
          ),
          if (scanMessage != null)
            Center(
              child: Container(
                color: Colors.black54,
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(scanSuccess ? Icons.check_circle : Icons.error,
                        color: scanSuccess ? Colors.green : Colors.red,
                        size: 80),
                    SizedBox(height: 8),
                    Text(scanMessage!,
                        style: TextStyle(color: Colors.white, fontSize: 18)),
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }
}
*/
