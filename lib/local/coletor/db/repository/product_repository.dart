import 'package:rdcoletor/local/database_service.dart';
import 'package:rdcoletor/local/drift_database.dart';

const int _kBarcodeMinLength = 13;

class ProductRepository {
  final DatabaseService _dbService;

  // Injeta o DatabaseService para garantir que a mesma instância inicializada seja usada.
  ProductRepository(this._dbService);

  // Insere uma lista de produtos no banco de dados.
  // Usa um batch para performance e limpa a tabela antes para evitar duplicatas.
  Future<void> insertProducts(List<Product> products) async {
    for (final product in products) {
      _dbService.insertOrUpdateProduct(product);
    }
  }

  // Busca um produto pelo código.
  // Retorna um objeto Product ou null se não encontrar.
  Future<Product?> findProductByCode(String code) async {
    String searchCode = code.padLeft(_kBarcodeMinLength, '0');

    final product = await _dbService.getProductByBarcode(searchCode);

    return product;
  }

  // Busca todos os produtos no banco de dados.
  Future<List<Product>> getAllProducts() async {
    return await _dbService.getAllProducts();
  }
}
