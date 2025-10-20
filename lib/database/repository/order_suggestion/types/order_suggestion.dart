class OrderSuggestion {
  final int orderId;
  final int companyId;
  final DateTime createdAt;
  final int status;
  final List<dynamic>? products;

  const OrderSuggestion({
    required this.orderId,
    required this.createdAt,
    required this.status,
    required this.companyId,
    this.products,
  });

  factory OrderSuggestion.fromMap(Map<String, dynamic> map) {
    return OrderSuggestion(
      orderId: map['id'],
      createdAt: DateTime.parse(map['timestamp']),
      status: map['status'],
      companyId: map['company_id'],
      products: map['products'],
    );
  }
}
