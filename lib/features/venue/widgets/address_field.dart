// lib/features/venue/widgets/address_field.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;

/// A TextField widget that provides dynamic address suggestions using
/// OpenStreetMap's Nominatim API. Suggestions are displayed as the user types.
class AddressField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  const AddressField({
    Key? key,
    required this.controller,
    this.hintText = 'Enter address',
  }) : super(key: key);

  /// Fetches address suggestions from the OSM Nominatim API and returns up to 3 suggestions.
  Future<List<String>> _getAddressSuggestions(String search) async {
    if (search.isEmpty) return [];
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$search&format=json&addressdetails=1');
    final response = await http.get(url, headers: {
      'User-Agent': 'YourAppName/1.0 (your_email@example.com)',
    });
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data
          .map<String>((item) => item['display_name'] as String)
          .take(3)
          .toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: TypeAheadField<String>(
        suggestionsCallback: (pattern) async {
          return await _getAddressSuggestions(pattern);
        },
        itemBuilder: (context, String suggestion) {
          return ListTile(
            title: Text(suggestion),
          );
        },
        onSelected: (String suggestion) {
          controller.text = suggestion;
        },
        builder: (context, typeAheadController, focusNode) {
          return TextField(
            controller: typeAheadController,
            focusNode: focusNode,
            scrollPadding: const EdgeInsets.only(bottom: 300),
            decoration: InputDecoration(
              labelText: hintText,
              border: const OutlineInputBorder(),
            ),
          );
        },
      ),
    );
  }
}
