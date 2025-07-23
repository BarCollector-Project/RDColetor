import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:rdcoletor/local/app_database.dart';
import 'package:rdcoletor/local/auth/model/user.dart';
import 'package:rdcoletor/local/coletor/db/tables.dart';
import 'package:rdcoletor/local/coletor/model/product.dart';
import 'package:rdcoletor/local/native_app_database.dart';
import 'package:rdcoletor/local/server/services/connection_service.dart';
import 'package:rdcoletor/local/web_app_database.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

/// Serviço central para gerenciar o banco de dados local e a comunicação com o servidor.
class DatabaseService {
  late final AppDatabase _db;
  final ConnectionService _connectionService = ConnectionService();

  DatabaseService() : _db = kIsWeb ? WebAppDatabase() : NativeAppDatabase();

  ///Inicializa o banco de dados local
  Future<void> init() async {
    await _db.init();
  }

  // ===========================================================================
  // PARTE 1: Operações do Banco de Dados Local (SQLite)
  // ===========================================================================

  // --- Product Operations ---

  /// Busca todos os produtos salvos no banco de dados local.
  /// Retorna uma lista de objetos [Product] para segurança de tipo.
  Future<List<Product>> getAllProducts() async {
    // Corrigido: Especifica a tabela a ser consultada.
    final List<Map<String, dynamic>> maps = await _db.query(Tables.products);

    // Converte o resultado do banco (Map) para uma lista de objetos (Product).
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  /// Busca um produto específico pelo código de barras no banco local.
  /// Retorna um objeto [Product] ou `null` se não for encontrado.
  Future<Product?> getProductByBarcode(String barcode) async {
    // Corrigido: Adiciona a cláusula 'where' para filtrar pelo código de barras.
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        Tables.products,
        where: 'barcode = ?',
        whereArgs: [barcode],
        limit: 1, // Otimização: só precisamos de um resultado.
      );

      if (maps.isNotEmpty) {
        return Product.fromMap(maps.first);
      }
    } catch (_) {}
    return null;
  }

  /// Insere ou atualiza um produto no banco de dados local.
  /// Se o produto já existir (baseado na chave primária), ele será substituído.
  /// Essencial para a sincronização.
  Future<void> insertOrUpdateProduct(Product product) async {
    await _db.insert(
      Tables.products,
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- User Operations ---

  /// Busca um usuário pelas credenciais no servidor.
  Future<User?> findUserByCredentials(String username, String password) async {
    debugPrint("Buscando no banco de dados pro $username com senha $password");
    // A autenticação é sempre feita contra o servidor, que é a fonte da verdade.
    // O método _fetchUserFromServer cuidará da chamada de API e do armazenamento do token.
    return await _fetchUserFromServer(username, password);
  }

  /// Busca todos os usuários no banco local.
  Future<List<User>> getAllUsers() async {
    final List<Map<String, dynamic>> maps = await _db.query(Tables.users, orderBy: 'username ASC');
    return maps.map((map) => User.fromMap(map)).toList();
  }

  /// Insere um novo usuário no banco local.
  Future<int> insertUser(User user) async {
    return await _db.insert(
      Tables.users,
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.fail, // Falha se o usuário já existir
    );
  }

  /// Atualiza um usuário existente no banco local.
  Future<int> updateUser(User user) async {
    return await _db.update(
      Tables.users,
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  /// Deleta um usuário pelo ID.
  Future<int> deleteUser(String id) async {
    return await _db.delete(Tables.users, where: 'id = ?', whereArgs: [id]);
  }

  // ===========================================================================
  // PARTE 2: Comunicação com o Servidor (API Dart Frog)
  // ===========================================================================

  /// Obtém o token de autenticação salvo localmente.
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    // Supondo que o token é salvo com a chave 'auth_token' após o login.
    return prefs.getString('auth_token');
  }

  /// Busca pelo [username] e valida o [password] forneceidos
  Future<User?> _fetchUserFromServer(String username, String password) async {
    final serverUrl = _connectionService.baseUrl;

    final response = await http.post(
      Uri.parse('$serverUrl/login'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      final token = responseBody['token'] as String?;

      if (token != null) {
        // Salva o token para uso futuro
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);

        // Decodifica o payload para criar o objeto User
        final jwt = JWT.decode(token);
        final payload = jwt.payload as Map<String, dynamic>;
        // A senha não é retornada ou armazenada no estado do app por segurança.
        payload['password'] = '';
        return User.fromMap(payload);
      }
    }
    return null;
  }

  /// Busca a lista completa de produtos da API do servidor.
  /// Este método é privado, pois será usado internamente pela sincronização.
  Future<List<Product>> _fetchProductsFromServer() async {
    // O getter `baseUrl` agora lança uma exceção clara se não estiver configurado.
    final serverUrl = _connectionService.baseUrl;

    final token = await _getAuthToken();
    if (token == null) {
      throw Exception('Usuário não autenticado. Faça o login novamente.');
    }

    final response = await http.get(
      Uri.parse('$serverUrl/products'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> productListJson = json.decode(response.body);
      // Assumindo que seu modelo Product tem um construtor `fromJson`.
      return productListJson.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar produtos do servidor: ${response.statusCode}');
    }
  }

  /// Envia um novo produto para ser criado no servidor.
  Future<Product> createProductOnServer(Product product) async {
    final serverUrl = _connectionService.baseUrl;

    final token = await _getAuthToken();
    if (token == null) {
      throw Exception('Usuário não autenticado. Faça o login novamente.');
    }

    final response = await http.post(
      Uri.parse('$serverUrl/products'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      // Assumindo que seu modelo Product tem um método `toJson`.
      body: json.encode(product.toJson()),
    );

    if (response.statusCode == 201) {
      // 201: Created
      return Product.fromJson(json.decode(response.body));
    } else {
      throw Exception('Falha ao criar produto no servidor: ${response.statusCode}');
    }
  }

  // ===========================================================================
  // PARTE 3: Lógica de Sincronização
  // ===========================================================================

  /// Orquestra a sincronização: busca dados do servidor e os salva localmente.
  /// Este é o método que você chamaria para atualizar os dados do app.
  Future<void> syncProductsFromServer() async {
    try {
      debugPrint('Iniciando sincronização de produtos...');
      // 1. Busca os dados mais recentes da API.
      final serverProducts = await _fetchProductsFromServer();

      // 2. Salva cada produto no banco local.
      // O `insertOrUpdateProduct` garante que produtos novos sejam adicionados
      // e os existentes sejam atualizados.
      for (final product in serverProducts) {
        await insertOrUpdateProduct(product);
      }

      debugPrint('Sincronização concluída com sucesso! ${serverProducts.length} produtos atualizados.');
    } catch (e) {
      debugPrint('Erro durante a sincronização: $e');
      // Re-lança a exceção para que a UI possa mostrar uma mensagem de erro.
      rethrow;
    }
  }
}
