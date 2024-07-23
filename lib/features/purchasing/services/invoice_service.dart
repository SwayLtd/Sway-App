import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway_events/features/purchasing/models/invoice_model.dart';

class InvoiceService {
  Future<List<Invoice>> getInvoicesByUser(String userId) async {
    final String response = await rootBundle.loadString('assets/databases/invoices.json');
    final List<dynamic> invoicesJson = json.decode(response) as List<dynamic>;
    return invoicesJson.map((json) => Invoice.fromJson(json as Map<String, dynamic>)).where((invoice) => invoice.userId == userId).toList();
  }

  Future<void> createInvoice(Invoice invoice) async {
    // Logic to create a new invoice in the database
  }
}
