import 'package:rdcoletor/local/database/repositories/types/financial_nature.dart';
import 'package:rdcoletor/local/database_service.dart';

class SystemTables {
  final DatabaseService db;

  SystemTables({required this.db});

  Future<List<FinancialNature>> getFinancialNatures() async {
    try {
      return [];
    } catch (e) {
      return [];
    }
  }
}
