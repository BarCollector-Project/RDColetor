import 'package:rdcoletor/database/repository/order_suggestion/types/order_suggestion.dart';
import 'package:rdcoletor/local/database_service.dart';

enum CommandStatus {
  ok,
  fail,
  duplicate,
  notFound,
  createFailed,
  closed,
  ;

  static CommandStatus fromNum(int statusNum) {
    switch (statusNum) {
      case 0:
        return CommandStatus.ok;
      case -1:
        return CommandStatus.duplicate;
      case -3:
        return CommandStatus.notFound;
      case -4:
        return CommandStatus.createFailed;
      default:
        return CommandStatus.fail;
    }
  }
}

class OrderSuggestionRepository {
  final DatabaseService _db;
  OrderSuggestionRepository({required db}) : _db = db;

  Future<List<OrderSuggestion>> getOrderSuggestionsList({int days = 7}) async {
    final results = await _db.getOrderSuggestionList(days: days);
    return results.map((value) => OrderSuggestion.fromMap(value)).toList();
  }

  Future<OrderSuggestion?> getOrderSuggestionById(int id) async {
    if (id <= 0) return null;
    final result = await _db.getOrderSuggestion(id);
    if (result.isNotEmpty) {
      return OrderSuggestion.fromMap(result);
    }
    return null;
  }

  Future<CommandStatus> putOrderSuggestion({
    required int orderId,
    required int companyId,
    required DateTime timestamp,
    required int productId,
    required double quantity,
    required int status,
    bool replace = false,
  }) async {
    return CommandStatus.fromNum(
      await _db.putProductSuggestion(
        orderId: orderId,
        companyId: companyId,
        timestampIso8601: timestamp.toIso8601String(),
        productId: productId,
        quantity: quantity,
        status: status.toString(),
        replace: replace,
      ),
    );
  }

  Future<CommandStatus> removeOrderSuggestion({
    required int orderId,
    required int companyId,
    required DateTime timestamp,
    required int productId,
  }) async {
    return CommandStatus.fromNum(
      await _db.removeProductSuggestion(
        orderId: orderId,
        companyId: companyId,
        timestampIso8601: timestamp.toIso8601String(),
        productId: productId,
      ),
    );
  }

  Future<OrderSuggestion?> putNew({
    required int companyId,
    required int productId,
    required double quantity,
  }) async {
    final result = await _db.putNewOrderSuggestion(
      companyId: companyId,
      productId: productId,
      quantity: quantity,
    );

    return getOrderSuggestionById(result);
  }

  Future<bool> markSuggestion({required int orderId, required int numPed}) async {
    final result = await _db.markSuggestion(orderId: orderId, numPed: numPed);
    return result >= 0;
  }
}
