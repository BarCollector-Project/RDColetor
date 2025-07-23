import 'dart:async';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'app_database.dart';

class NativeAppDatabase extends AppDatabase {
  Database? _db;

  @override
  Future<bool> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'app_database.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
    return _db != null;
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
    await _db?.close();
    return true;
  }

  @override
  Future<int> insert(String table, Map<String, dynamic> values, {ConflictAlgorithm? conflictAlgorithm}) async {
    return await _db!.insert(table, values, conflictAlgorithm: conflictAlgorithm ?? ConflictAlgorithm.replace);
  }

  @override
  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<Object?>? whereArgs, String? orderBy, int? limit}) async {
    return await _db!.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  @override
  Future<int> update(String table, Map<String, dynamic> values, {String? where, List<Object?>? whereArgs}) async {
    return await _db!.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
    );
  }

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    return await _db!.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }

  @override
  Future<AppBatch> batch() {
    // TODO: implement batch
    throw UnimplementedError();
  }
}
