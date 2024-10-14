// order_model.dart

class Order {
  final int id;
  final int userId;
  final String totalPrice;
  final DateTime orderDate;
  final String status;
  final String paymentMethod; // Méthode de paiement
  final DateTime? completedAt; // Date de complétion de la commande

  Order({
    required this.id,
    required this.userId,
    required this.totalPrice,
    required this.orderDate,
    required this.status,
    required this.paymentMethod,
    this.completedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      userId: json['user_id'],
      totalPrice: json['total_price'],
      orderDate: DateTime.parse(json['order_date']),
      status: json['status'],
      paymentMethod: json['payment_method'],
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'total_price': totalPrice,
      'order_date': orderDate.toIso8601String(),
      'status': status,
      'payment_method': paymentMethod,
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}
