import 'package:flutter/foundation.dart';
import 'package:rdcoletor/local/native_app_database.dart';
import 'package:rdcoletor/local/web_app_database.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

/// Interface para operações em lote (batch), para abstrair a implementação
/// específica da plataforma (ex: sqflite's Batch).
abstract class AppBatch {
  /// Adiciona uma operação de inserção ao lote.
  void insert(String table, Map<String, dynamic> values, {ConflictAlgorithm? conflictAlgorithm});

  /// Adiciona uma operação de atualização ao lote.
  void update(String table, Map<String, dynamic> values, {String? where, List<Object?>? whereArgs});

  /// Adiciona uma operação de exclusão ao lote.
  void delete(String table, {String? where, List<Object?>? whereArgs});

  /// Executa todas as operações no lote.
  Future<List<Object?>> commit({bool? exclusive, bool? noResult});
}

/// Classe abstrata que define o "contrato" para qualquer implementação de banco de dados.
/// O resto do aplicativo usará esta interface, sem se preocupar com os detalhes
/// de cada plataforma (nativa vs. web).
abstract class AppDatabase {
  /// Inicializa a conexão com o banco de dados.
  Future<bool> init();

  /// Fecha a conexão com o banco de dados.
  Future<bool> close();

  // Métodos de CRUD que os repositórios usarão.
  // Isso desacopla os repositórios da implementação específica (sqflite).
  Future<int> insert(String table, Map<String, dynamic> values, {ConflictAlgorithm? conflictAlgorithm});
  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<Object?>? whereArgs, String? orderBy, int? limit});
  Future<int> update(String table, Map<String, dynamic> values, {String? where, List<Object?>? whereArgs});
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs});

  /// Cria um novo objeto de lote para executar múltiplas operações.
  Future<AppBatch> batch();
}

/// Fábrica (Factory) que fornece a instância correta do banco de dados
/// com base na plataforma em que o aplicativo está sendo executado.
class DatabaseProvider {
  static AppDatabase getDatabase() {
    if (kIsWeb) {
      // Para a web, retornamos uma implementação compatível.
      return WebAppDatabase();
    } else {
      // Para plataformas nativas (mobile/desktop), retornamos a implementação com sqflite.
      return NativeAppDatabase();
    }
  }
}
