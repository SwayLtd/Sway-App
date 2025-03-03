// lib/features/purchasing/screens/checkout_screen.dart
// Payment screen using WebViewWidget for Lemon Squeezy checkout

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/core/services/database_service.dart';
import 'package:sway/features/purchasing/services/product_service.dart';
import 'package:sway/features/ticketing/screens/online_tickets_screen.dart';
import 'package:sway/features/user/services/user_service.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/ticketing/models/isar_online_ticket.dart';

class CheckoutPage extends StatefulWidget {
  final String lemonCheckoutUrl;
  CheckoutPage(this.lemonCheckoutUrl);

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.lemonCheckoutUrl))
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith("myapp://payment_success")) {
              Navigator.pop(context, true);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (String url) {
            if (url.contains("/checkout/complete") ||
                url.contains("order_confirmed")) {
              Navigator.pop(context, true);
            }
          },
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Paiement des billets")),
      body: WebViewWidget(controller: _controller),
    );
  }
}

// Order confirmation page shown after payment.
class OrderConfirmationPage extends StatelessWidget {
  final int ticketCount;
  OrderConfirmationPage(this.ticketCount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Commande confirmée")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 80),
            SizedBox(height: 16),
            Text("Thank you for your purchase!",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
                "Your order has been confirmed and $ticketCount ticket(s) have been generated.",
                textAlign: TextAlign.center),
            SizedBox(height: 16),
            ElevatedButton(
              child: Text("View My Tickets"),
              onPressed: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => MyTicketsPage()));
              },
            )
          ],
        ),
      ),
    );
  }
}

// Example usage from the event details page.
Future<void> onBuyTicketsPressed(BuildContext context, Event event) async {
  final user = await UserService().getCurrentUser();
  if (user == null) {
    // Redirect to login if no user is connected.
    return;
  }
  // Retrieve the product for the event using your ProductService.
  final product = await getProductForEvent(event.id!);
  if (product == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Ticket type not available for this event.")),
    );
    return;
  }
  // Use the variant ID from the product.
  final variantId = product['ls_variant_id'];
  if (variantId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Variant ID is missing for this product.")),
    );
    return;
  }

  // Build the Lemon Squeezy checkout URL using the product's variant ID.
  String checkoutUrl =
      "https://swayapp.lemonsqueezy.com/checkout/buy/$variantId";
  // Append email and user_id as custom data.
  checkoutUrl += "?checkout[email]=${Uri.encodeComponent(user.email)}";
  checkoutUrl += "&checkout[custom][user_id]=${user.id}";
  // Optionally add a coupon code if available (if applicable).
  if (event.metadata?['couponCode'] != null) {
    checkoutUrl += "&checkout[discount_code]=${event.metadata!['couponCode']}";
  }
  // Open the WebView and wait for its closure.
  final result = await Navigator.push(
      context, MaterialPageRoute(builder: (_) => CheckoutPage(checkoutUrl)));
  if (result == true) {
    // Payment validated (custom redirection intercepted)
    final response = await Supabase.instance.client
        .from('tickets')
        .select()
        .eq('event_id', event.id!) // forcer non-null avec "!"
        .filter('order_id', 'is',
            null); // Filtrer pour les tickets dont order_id est NULL.
    final tickets = response as List? ?? [];
    // Save tickets in Isar for offline access.
    late final Future<Isar> _isarFuture = DatabaseService().isar;
    final isar = await _isarFuture;
    await isar.writeTxn(() async {
      for (var t in tickets) {
        await isar.onlineTicketIsars
            .put(OnlineTicketIsar.fromMap(t as Map<String, dynamic>));
      }
    });
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => OrderConfirmationPage(tickets.length)));
  }
}
