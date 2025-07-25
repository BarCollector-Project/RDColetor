import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:rdcoletor/local/drift_database.dart';
import 'package:rdcoletor/local/server/services/connection_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

/// Serviço central para gerenciar o banco de dados local e a comunicação com o servidor.
class DatabaseService {
  // A instância do banco de dados Drift, que funciona em todas as plataformas.
  late final AppDb _db;
  final ConnectionService _connectionService = ConnectionService();

  DatabaseService() {
    // A lógica de qual banco usar (SQLite ou IndexedDB) já está encapsulada.
    _db = AppDb();
  }

  ///Inicializa o banco de dados local
  Future<bool> init() async {
    //Execulta um comando para consulta no banco apenas para chegar se está funcionando. Logo após, iniciar a sincronização
    try {
      await _db.customSelect('SELECT 1').getSingle();
      // Sincronizar com o banco de dados web na inicialização
      await syncProductsFromServer();

      return true;
    } catch (e) {
      debugPrint('Falha ao inicializar ou sincronizar o banco de dados: $e');
      return false;
    }
  }

  Future<bool> close() async {
    try {
      await _db.close();
      debugPrint("Banco de dados local fechado com sucesso.");
      return true;
    } catch (e) {
      debugPrint("Erro ao fechar o banco de dados: $e");
      return false;
    }
  }

  // ===========================================================================
  // PARTE 1: Operações do Banco de Dados Local (Drift)
  // ===========================================================================

  // --- Product Operations ---

  /// Busca todos os produtos salvos no banco de dados local.
  Future<List<Product>> getAllProducts() async {
    // A chamada agora é type-safe e muito mais simples!
    return _db.select(_db.products).get();
  }

  /// Busca um produto específico pelo código de barras no banco local.
  Future<Product?> getProductByBarcode(String barcode) async {
    return (_db.select(_db.products)..where((tbl) => tbl.barcode.equals(barcode))).getSingleOrNull();
  }

  /// Insere ou atualiza um produto no banco de dados local.
  Future<void> insertOrUpdateProduct(Product product) async {
    // O Drift lida com a lógica de "insert or replace" de forma elegante.
    await _db.into(_db.products).insertOnConflictUpdate(product);
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
    return (_db.select(_db.users)..orderBy([(u) => OrderingTerm(expression: u.username)])).get();
  }

  /// Insere um novo usuário no banco local.
  Future<int> insertUser(User user) async {
    // O modo padrão já é falhar em caso de conflito.
    return _db.into(_db.users).insert(user);
  }

  /// Atualiza um usuário existente no banco local.
  Future<int> updateUser(User user) async {
    return (_db.update(_db.users)..where((u) => u.id.equals(user.id))).write(user);
  }

  /// Deleta um usuário pelo ID.
  Future<int> deleteUser(String id) async {
    return (_db.delete(_db.users)..where((u) => u.id.equals(id))).go();
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
        return User(
          id: payload['id'] as String,
          username: payload['username'] as String,
          name: payload['name'] as String,
          role: payload['role'] as String,
        );
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
      // O Drift gera o método fromJson para nós!
      return productListJson.map((json) => Product.fromJson(json as Map<String, dynamic>)).toList();
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
      body: json.encode(product.toJson()),
    );

    if (response.statusCode == 201) {
      // 201: Created
      return Product.fromJson(json.decode(response.body) as Map<String, dynamic>);
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
