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
      orderId: json['order_id'],
      userId: json['user_id'],
      invoiceNumber: json['invoice_number'],
      invoiceDate: DateTime.parse(json['invoice_date']),
      totalAmount: json['total_amount'],
      status: json['status'],
      billingAddress: json['billing_address'],
      vatNumber: json['vat_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'user_id': userId,
      'invoice_number': invoiceNumber,
      'invoice_date': invoiceDate.toIso8601String(),
      'total_amount': totalAmount,
      'status': status,
      'billing_address': billingAddress,
      'vat_number': vatNumber,
    };
  }
}
