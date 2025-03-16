import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'produtos.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE produtos (
            id INTEGER PRIMARY KEY,
            codigo TEXT UNIQUE,
            nome TEXT,
            preco REAL
          )
        ''');
      },
    );
  }

  Future<void> inserirProduto(String codigo, String nome, double preco) async {
    final db = await DatabaseHelper().database;
    await db.insert('produtos', {
      'codigo': codigo,
      'nome': nome,
      'preco': preco,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> buscarProdutos(String filtro) async {
    final db = await DatabaseHelper().database;
    return await db.query(
      'produtos',
      where: 'nome LIKE ?',
      whereArgs: ['%$filtro%'],
    );
  }

  Future<Map<String, dynamic>?> buscarProdutoPorCodigo(String codigo) async {
    final db = await DatabaseHelper().database;

    // Consulta no banco pelo código exato
    List<Map<String, dynamic>> resultado = await db.query(
      'produtos',
      where: 'codigo = ?',
      whereArgs: [codigo],
    );

    // Retorna o primeiro item encontrado, ou null se não existir
    return resultado.isNotEmpty ? resultado.first : null;
  }
}
