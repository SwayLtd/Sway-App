import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway_events/features/purchasing/models/order_model.dart';

class OrderService {
  Future<List<Order>> getOrdersByUser(int userId) async {
    final String response = await rootBundle.loadString('assets/databases/orders.json');
    final List<dynamic> ordersJson = json.decode(response) as List<dynamic>;
    return ordersJson.map((json) => Order.fromJson(json as Map<String, dynamic>)).where((order) => order.userId == userId).toList();
  }

  Future<void> createOrder(Order order) async {
    // Logic to create a new order in the database
  }
}
