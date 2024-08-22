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
      userId: json['userId'],
      totalPrice: json['totalPrice'] as String,
      orderDate: DateTime.parse(json['orderDate'] as String),
      status: json['status'] as String,
      paymentMethod: json['paymentMethod'] as String,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'totalPrice': totalPrice,
      'orderDate': orderDate.toIso8601String(),
      'status': status,
      'paymentMethod': paymentMethod,
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}
