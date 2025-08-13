import 'package:rdcoletor/local/database/repositories/types/system_tables.dart';
import 'package:rdcoletor/local/database_service.dart';

class SystemTables {
  final DatabaseService db;

  SystemTables({required this.db});

  Future<List<CostCenter>> getCostCenter() async {
    try {
      //TODO: implementar a logica de comunicação com o servidor para consultar a lista
      return [
        CostCenter(id: "1", description: "Perdas açougue"),
        CostCenter(id: "2", description: "Perdas padaria"),
        CostCenter(id: "3", description: "Perdas hortifruti"),
      ];
    } catch (e) {
      return [];
    }
  }

  Future<List<FinancialNature>> getFinancialNatures() async {
    try {
      //TODO: implementar a logica de comunicação com o servidor para consultar a lista
      return [
        FinancialNature(id: "1", description: "PERDAS ACOUGUE"),
        FinancialNature(id: "2", description: "PERDAS PADARIA"),
        FinancialNature(id: "3", description: "PERDAS HORTIFRUTI"),
      ];
    } catch (e) {
      return [];
    }
  }

  Future<List<Reason>> getReason() async {
    try {
      //TODO: implementar a logica de comunicação com o servidor para consultar a lista
      return [
        Reason(id: "1", description: "AVARIA"),
        Reason(id: "2", description: "USO E CONSUMO"),
        Reason(id: "3", description: "INSUMOS DE PRODUÇÃO"),
      ];
    } catch (e) {
      return [];
    }
  }

  Future<List<Origin>> getOrigin() async {
    try {
      //TODO: implementar a logica de comunicação com o servidor para consultar a lista
      return [
        Origin(id: "1", description: "ACOUGUE"),
        Origin(id: "2", description: "PADARIA"),
        Origin(id: "3", description: "HORTIFRUTI"),
      ];
    } catch (e) {
      return [];
    }
  }
}
