import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:rdcoletor/local/path_service.dart';

/// Serviço que gerencia a conexão com o banco de dados usando o padrão Singleton.
///
/// O Singleton garante que haverá apenas uma instância desta classe (e, portanto,
/// uma única conexão com o banco de dados) em todo o aplicativo.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  static Database? _database;
  final PathService _pathService = PathService();

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = await _pathService.getDatabaseFullPath();

    // Se o arquivo não existir no caminho especificado, lança uma exceção.
    if (path.isEmpty || !await File(path).exists()) {
      throw Exception('Arquivo de banco de dados não encontrado em: $path. Por favor, configure o caminho correto.');
    }

    debugPrint("Database path: $path");
    // Removido o `onCreate`. O aplicativo agora espera que o banco de dados
    // e suas tabelas já existam.
    return await openDatabase(
      path,
      version: 1,
    );
  }

  /// Fecha a conexão atual com o banco de dados.
  /// Necessário ao alterar o caminho do banco de dados para liberar o arquivo.
  Future<void> closeDatabase() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }
}
