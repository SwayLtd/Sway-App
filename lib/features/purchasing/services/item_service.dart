import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway/features/purchasing/models/item_model.dart';

class ItemService {
  Future<List<Item>> getItems() async {
    final String response = await rootBundle.loadString('assets/databases/items.json');
    final List<dynamic> itemsJson = json.decode(response) as List<dynamic>;
    return itemsJson.map((json) => Item.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Item> getItemById(int itemId) async {
    final String response = await rootBundle.loadString('assets/databases/items.json');
    final List<dynamic> itemsJson = json.decode(response) as List<dynamic>;
    return itemsJson.map((json) => Item.fromJson(json as Map<String, dynamic>)).firstWhere((item) => item.id == itemId);
  }
}
