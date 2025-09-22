import 'package:barcollector_sdk/routes/product/parameters/include.dart';
import 'package:barcollector_sdk/types/product/product_model.dart';
import 'package:rdcoletor/local/coletor/model/product.dart';
import 'package:rdcoletor/local/database_service.dart';

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

  /// Busca um produto pelo código.
  /// Retorna um objeto Product ou null se não encontrar.
  /// Possível [Exception]
  Future<ProductModel?> findProductByCode(String code) async {
    String searchCode = code.padLeft(_kBarcodeMinLength, '0');

    final product = await _dbService.getProductByBarcode(searchCode);
    if (product != null) {
      return ProductModel.fromMap(product);
    }
    return null;
  }

  // Busca todos os produtos no banco de dados.
  Future<List<ProductModel>> getProducts({int offset = 0, int limit = 50}) async {
    final results = await _dbService.getProducts(offset: offset, limit: limit);
    if (results.isNotEmpty) {
      return results.map(ProductModel.fromMap).toList();
    }
    return [];
  }

  // Busca produtos por nome ou código no servidor.
  Future<List<ProductModel>> searchProducts({required String query}) async {
    final results = await _dbService.searchProducts(query: query);
    if (results.isNotEmpty) {
      return results.map(ProductModel.fromMap).toList();
    }
    return [];
  }

  Future<ProductModel> getProductDetails(int id, List<Includes> include) async {
    final product = await _dbService.getProductDetails(id, include);
    return ProductModel.fromMap(product);
  }
}
