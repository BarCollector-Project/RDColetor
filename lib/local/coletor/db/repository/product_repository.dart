import 'package:rdcoletor/local/coletor/model/product.dart';
import 'package:rdcoletor/local/database_service.dart';
import 'package:sqflite/sqflite.dart';

const int _kBarcodeMinLength = 13;

class ProductRepository {
  final _dbService = DatabaseService();

  // Insere uma lista de produtos no banco de dados.
  // Usa um batch para performance e limpa a tabela antes para evitar duplicatas.
  Future<void> insertProducts(List<Product> products) async {
    final db = await _dbService.database;
    final batch = db.batch();

    batch.delete('produtos'); // Limpa a tabela antes de inserir

    for (final product in products) {
      batch.insert(
        'produtos',
        product.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  // Busca um produto pelo código.
  // Retorna um objeto Product ou null se não encontrar.
  Future<Product?> findProductByCode(String code) async {
    final db = await _dbService.database;
    String searchCode = code.padLeft(_kBarcodeMinLength, '0');

    final List<Map<String, dynamic>> maps = await db.query(
      'produtos',
      where: 'codigo = ?',
      whereArgs: [searchCode],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  // Busca todos os produtos no banco de dados.
  Future<List<Product>> getAllProducts() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query('produtos', orderBy: 'nome ASC');

    return List.generate(maps.length, (i) {
      return Product.fromMap(maps[i]);
    });
  }
}
