import 'package:rdcoletor/local/database/repositories/types/system_table_model.dart';

class FinancialNature extends SystemTableModel {
  FinancialNature({required super.id, required super.description});
}

class CostCenter extends SystemTableModel {
  CostCenter({required super.id, required super.description});
}

class Reason extends SystemTableModel {
  Reason({required super.id, required super.description});
}

class Origin extends SystemTableModel {
  Origin({required super.id, required super.description});
}
