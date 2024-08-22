import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway_events/features/purchasing/models/order_item_model.dart';

class OrderItemService {
  Future<List<OrderItem>> getOrderItemsByOrderId(int orderId) async {
    final String response = await rootBundle.loadString('assets/databases/order_items.json');
    final List<dynamic> itemsJson = json.decode(response) as List<dynamic>;
    return itemsJson.map((json) => OrderItem.fromJson(json as Map<String, dynamic>)).where((item) => item.orderId == orderId).toList();
  }

  Future<void> createOrderItem(OrderItem orderItem) async {
    // Logic to create a new order item in the database
  }
}
