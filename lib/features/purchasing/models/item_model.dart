// item_model.dart

class Item {
  final String id;
  final String name;
  final String price;
  final String type; // Type de l'article (ticket, token, merchandise, etc.)

  Item({
    required this.id,
    required this.name,
    required this.price,
    required this.type,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as String,
      name: json['name'] as String,
      price: json['price'] as String,
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'type': type,
    };
  }
}
