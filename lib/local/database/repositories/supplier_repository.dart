import 'package:barcollector_sdk/types/supplier/supplier_model.dart';
import 'package:rdcoletor/local/database_service.dart';

class SupplierRepository {
  final DatabaseService _db;
  SupplierRepository({required db}) : _db = db;

  Future<List<SupplierModel>> getSuppliers() async {
    final results = await _db.getSuppliers();
    return results.map(SupplierModel.fromMap).toList();
  }

  Future<SupplierModel?> findSupplierById(int id) async {
    final result = await _db.getSupplierById(id);
    if (result != null) {
      return SupplierModel.fromMap(result);
    }
  }
}
