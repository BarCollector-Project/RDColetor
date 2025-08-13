import 'package:rdcoletor/local/database/table/models/register.dart';

class CollectRegister extends Register {
  final String financialNature;
  final String costCenter;

  List<CollectedItem> coletedItens = [];

  CollectRegister({required this.financialNature, required this.costCenter})
      : super(
          id: RegiterID.collect,
          timestamp: DateTime.now(),
        );

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id.name,
      'timestamp': timestamp.toIso8601String(),
      'coletedItens': coletedItens.map((item) => item.toJson()).toList(),
    };
  }
}

class CollectedItem {
  const CollectedItem({
    required this.name,
    required this.code,
    required this.quantity,
    required this.reason,
    required this.origin,
  });
  final String name;
  final String code;
  final int quantity;
  final String reason;
  final String origin;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'quantity': quantity,
      'reason': reason,
      'origin': origin,
    };
  }
}
