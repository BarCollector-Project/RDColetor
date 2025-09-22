import 'package:barcollector_sdk/barcollector_sdk.dart';

class ProductSuggestion {
  final ProductModel product;
  final double quantitySuggestion;
  final String supplierName;

  ProductSuggestion({
    required this.product,
    required this.quantitySuggestion,
    required this.supplierName,
  });
}
