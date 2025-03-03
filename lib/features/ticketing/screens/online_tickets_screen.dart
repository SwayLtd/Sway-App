// lib/features/ticketing/screens/online_tickets_screen.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Using QrImageView from qr_flutter 4.1.0
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/user/services/user_service.dart';

class MyTicketsPage extends StatefulWidget {
  @override
  _MyTicketsPageState createState() => _MyTicketsPageState();
}

class _MyTicketsPageState extends State<MyTicketsPage> {
  Future<List<dynamic>>? _ticketsFuture;

  @override
  void initState() {
    super.initState();
    // Use UserService to get the current user
    UserService().getCurrentUser().then((user) {
      if (user != null) {
        // Load tickets for the user (response is directly a List)
        _ticketsFuture = Supabase.instance.client
            .from('tickets')
            .select(
                'id, used, used_at, product:products(name, event_id, event:events(name, date))')
            .order('created_at', ascending: false)
            .then((res) => res as List? ?? []);
        setState(() {});
      } else {
        _ticketsFuture = Future.value([]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Mes billets")),
      body: FutureBuilder<List<dynamic>>(
        future: _ticketsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final tickets = snapshot.data!;
          if (tickets.isEmpty) {
            return Center(child: Text("Aucun billet pour le moment."));
          }
          return ListView.builder(
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              final eventName = ticket['product']['event'] != null &&
                      ticket['product']['event']['name'] != null
                  ? ticket['product']['event']['name']
                  : ticket['product']['name'];
              final eventDate = ticket['product']['event'] != null
                  ? ticket['product']['event']['date']
                  : null;
              final used = ticket['used'] as bool;
              final ticketId = ticket['id'] as String;
              return Card(
                margin: EdgeInsets.all(12),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(eventName,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      if (eventDate != null)
                        Text("Date : ${eventDate.toString().substring(0, 10)}"),
                      SizedBox(height: 8),
                      // Display QR code using QrImageView
                      QrImageView(
                        data: "ticket:$ticketId",
                        version: QrVersions.auto,
                        size: 200.0,
                      ),
                      SizedBox(height: 8),
                      Text("Billet #${ticketId.substring(0, 8)}...",
                          style: TextStyle(fontSize: 12)),
                      used
                          ? Text("**Utilisé**",
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold))
                          : Text("Valide",
                              style: TextStyle(color: Colors.green)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
