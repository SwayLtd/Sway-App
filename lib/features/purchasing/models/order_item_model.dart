class OrderItem {
  final String orderId;
  final String itemId;
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
      orderId: json['orderId'] as String,
      itemId: json['itemId'] as String,
      itemType: json['itemType'] as String,
      quantity: json['quantity'] as int,
      price: json['price'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'itemId': itemId,
      'itemType': itemType,
      'quantity': quantity,
      'price': price,
    };
  }
}
