class OrderItem {
  final int orderId;
  final int itemId;
  final String itemType;
  final int quantity;
  final String price;

  OrderItem({
    required this.orderId,
    required this.itemId,
    required this.itemType,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      orderId: json['order_id'],
      itemId: json['item_id'],
      itemType: json['item_type'] as String,
      quantity: json['quantity'] as int,
      price: json['price'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'item_id': itemId,
      'item_type': itemType,
      'quantity': quantity,
      'price': price,
    };
  }
}
