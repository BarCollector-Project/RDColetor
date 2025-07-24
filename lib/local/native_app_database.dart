import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'app_database.dart';

/// Implementação do [AppBatch] para a plataforma nativa, usando o `Batch` do sqflite.
class _NativeAppBatch implements AppBatch {
  final Batch _batch;

  _NativeAppBatch(this._batch);

  @override
  void insert(String table, Map<String, dynamic> values, {ConflictAlgorithm? conflictAlgorithm}) {
    _batch.insert(table, values, conflictAlgorithm: conflictAlgorithm);
  }

  @override
  void update(String table, Map<String, dynamic> values, {String? where, List<Object?>? whereArgs}) {
    _batch.update(table, values, where: where, whereArgs: whereArgs);
  }

  @override
  void delete(String table, {String? where, List<Object?>? whereArgs}) {
    _batch.delete(table, where: where, whereArgs: whereArgs);
  }

  @override
  Future<List<Object?>> commit({bool? exclusive, bool? noResult}) => _batch.commit(exclusive: exclusive, noResult: noResult);
}

class NativeAppDatabase extends AppDatabase {
  Database? _database;

  /// Getter privado para acessar a instância do banco de dados.
  /// Lança um [StateError] claro se o banco de dados não for inicializado
  /// antes de ser usado, prevenindo erros de "null check".
  Database get _db {
    if (_database == null) {
      throw StateError('O banco de dados não foi inicializado. Chame init() primeiro.');
    }
    return _database!;
  }

  @override
  Future<bool> init() async {
    // Evita reinicializações desnecessárias.
    if (_database?.isOpen ?? false) {
      return true;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      debugPrint("DB Path: ${dir.path}");
      final path = join(dir.path, 'barcollector.db');

      _database = await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
      );
      return _database?.isOpen ?? false;
    } catch (e) {
      debugPrint('Falha ao inicializar o banco de dados: $e');
      _database = null; // Garante que o estado é consistente em caso de falha.
      return false;
    }
  }

  void _onCreate(Database db, int version) async {
    // Exemplo: crie as tabelas iniciais se necessário
    await db.execute('''
      -- Corrigido para espelhar o modelo Product e o schema do servidor
      CREATE TABLE IF NOT EXISTS products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        barcode TEXT NOT NULL UNIQUE,
        price REAL NOT NULL,
        created_at TEXT,
        updated_at TEXT
      );
    ''');

    //Cria a tabela 'users'
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL
      );
    ''');
  }

  @override
  Future<bool> close() async {
    await _database?.close();
    return true;
  }

  @override
  Future<int> insert(String table, Map<String, dynamic> values, {ConflictAlgorithm? conflictAlgorithm}) async {
    return await _db.insert(table, values, conflictAlgorithm: conflictAlgorithm ?? ConflictAlgorithm.replace);
  }

  @override
  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<Object?>? whereArgs, String? orderBy, int? limit}) async {
    return await _db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  @override
  Future<int> update(String table, Map<String, dynamic> values, {String? where, List<Object?>? whereArgs}) async {
    return await _db.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
    );
  }

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    return await _db.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }

  @override
  Future<AppBatch> batch() async {
    // Usa o getter _db para garantir que o banco está inicializado.
    final sqfliteBatch = _db.batch();
    return _NativeAppBatch(sqfliteBatch);
  }
}
