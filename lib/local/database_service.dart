import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:rdcoletor/local/coletor/model/product.dart';

import 'app_database.dart';

class DatabaseService {
  late final AppDatabase _db;

  DatabaseService();

  Future<void> init() async {
    _db = DatabaseProvider.getDatabase();

    if (kIsWeb) {
      await _db.init();
      return;
    }

    await _db.init();
  }

  Future<void> dispose() async {
    await _db.close();
  }

  Future<List<Product>> getProdutosLocal() async {
    final maps = await _db.query('produtos');
    return maps.map((e) => Product.fromMap(e)).toList();
  }

  Future<void> salvarProdutosLocal(List<Product> produtos) async {
    for (final produto in produtos) {
      await _db.insert('produtos', produto.toMap());
    }
  }

  Future<List<Product>> syncProdutosFromServer() async {
    final uri = Uri.parse('http://192.168.1.98:8082/api/produtos');
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(res.body);
      final produtos = jsonList.map((e) => Product.fromMap(e)).toList();

      // Atualiza local
      await _db.delete('produtos'); // Limpa antigos
      await salvarProdutosLocal(produtos);

      return produtos;
    } else {
      throw Exception('Erro ao buscar dados do servidor');
    }
  }

  Future<List<Product>> getProdutos({bool forceRemote = false}) async {
    if (forceRemote) {
      return await syncProdutosFromServer();
    }

    final local = await getProdutosLocal();
    if (local.isNotEmpty) return local;

    return await syncProdutosFromServer();
  }
}
