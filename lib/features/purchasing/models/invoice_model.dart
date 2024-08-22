class Invoice {
  final int id;
  final int orderId;
  final int userId;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final String totalAmount;
  final String status;
  final String billingAddress; // Adresse de facturation
  final String vatNumber; // Numéro de TVA

  Invoice({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.totalAmount,
    required this.status,
    required this.billingAddress,
    required this.vatNumber,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'],
      orderId: json['orderId'],
      userId: json['userId'],
      invoiceNumber: json['invoiceNumber'] as String,
      invoiceDate: DateTime.parse(json['invoiceDate'] as String),
      totalAmount: json['totalAmount'] as String,
      status: json['status'] as String,
      billingAddress: json['billingAddress'] as String,
      vatNumber: json['vatNumber'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'userId': userId,
      'invoiceNumber': invoiceNumber,
      'invoiceDate': invoiceDate.toIso8601String(),
      'totalAmount': totalAmount,
      'status': status,
      'billingAddress': billingAddress,
      'vatNumber': vatNumber,
    };
  }
}
