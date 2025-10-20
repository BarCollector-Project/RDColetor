import 'package:barcollector_sdk/barcollector_sdk.dart';

class ProductSuggestion {
  final ProductModel product;
  final double quantitySuggestion;
  final String supplierName;
  final String supplierRegistration;

  ProductSuggestion({
    required this.product,
    required this.quantitySuggestion,
    required this.supplierName,
    required this.supplierRegistration,
  });

  factory ProductSuggestion.fromJson(Map<String, dynamic> json) {
    return ProductSuggestion(
      product: ProductModel.fromMap(json['product'] as Map<String, dynamic>),
      quantitySuggestion: (json['quantitySuggestion'] as num).toDouble(),
      supplierName: json['supplierName'] as String,
      supplierRegistration: json['supplierRegistration'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantitySuggestion': quantitySuggestion,
      'supplierName': supplierName,
      'supplierRegistration': supplierRegistration,
    };
  }

  ProductSuggestion copyWith({
    ProductModel? product,
    double? quantitySuggestion,
    String? supplierName,
    String? supplierRegistration,
  }) {
    return ProductSuggestion(
      product: product ?? this.product,
      quantitySuggestion: quantitySuggestion ?? this.quantitySuggestion,
      supplierName: supplierName ?? this.supplierName,
      supplierRegistration: supplierRegistration ?? this.supplierRegistration,
    );
  }
}
