import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Enum para representar o estado da conexão de forma clara.
enum ConnectionState {
  uninitialized,
  notConfigured,
  configured,
}

// Mensagem de erro customizada para falhas de conexão.
class ConnectionException implements Exception {
  final String message;
  ConnectionException(this.message);
  @override
  String toString() => message;
}

// Agora estende ChangeNotifier para notificar os ouvintes (UI) sobre mudanças.
class ConnectionService with ChangeNotifier {
  // --- Singleton Setup ---
  static final ConnectionService _instance = ConnectionService._();
  factory ConnectionService() => _instance;
  ConnectionService._();

  // --- State ---
  static const _keyHostname = 'hostname';
  static const _keyPort = 'port';

  String? _hostname;
  int? _port;
  ConnectionState _state = ConnectionState.uninitialized;
  final http.Client _client = http.Client();

  // --- Public Getters ---
  String? get hostname => _hostname;
  int? get port => _port;
  ConnectionState get state => _state;
  bool get isConfigured => _state == ConnectionState.configured;

  /// Retorna a URL base para a API. Lança uma exceção se não estiver configurado.
  /// Garante que a URL está sempre bem formada.
  String get baseUrl {
    if (!isConfigured || _hostname == null || _port == null) {
      throw ConnectionException('Servidor não configurado. Verifique as configurações de conexão.');
    }
    return 'http://$_hostname:$_port';
  }

  // --- Initialization ---
  /// Carrega as informações de conexão do SharedPreferences.
  /// Deve ser chamado na inicialização do app (ex: no main.dart).
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _hostname = prefs.getString(_keyHostname);
    _port = prefs.getInt(_keyPort);

    if (_hostname != null && _hostname!.isNotEmpty && _port != null) {
      _state = ConnectionState.configured;
    } else {
      _state = ConnectionState.notConfigured;
    }
    // Notifica os ouvintes que a inicialização foi concluída.
    notifyListeners();
  }

  // --- Core Logic ---

  /// Testa a conexão com o servidor e, se for bem-sucedido, salva as informações.
  /// Lança uma [ConnectionException] em caso de falha.
  ///
  /// Retorna `true` se a conexão for bem-sucedida.
  Future<bool> testAndSaveConnection(String address, int port) async {
    debugPrint("Testando conexão com o servidor em $address:$port");

    if (address.trim().isEmpty || port <= 0 || port > 65535) {
      throw ConnectionException('Endereço ou porta inválidos.');
    }

    // Usamos um endpoint de "health check" da API. Se não tiver, pode ser só a base.
    // Baseado na sua API, um GET /products deve funcionar.
    final testUrl = Uri.http('$address:$port', '/api/health');

    try {
      // Usamos um timeout curto para não deixar o usuário esperando muito.
      final response = await _client.get(testUrl).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        // Conexão bem-sucedida, vamos salvar.
        await _saveConnectionInfo(address, port);
        debugPrint("Conexão bem-sucedida e salva!");
        return true;
      } else {
        // O servidor respondeu, mas com um erro.
        throw ConnectionException('Servidor respondeu com erro: ${response.statusCode}');
      }
    } on TimeoutException {
      throw ConnectionException('Tempo de conexão esgotado. Verifique o endereço e a rede.');
    } on SocketException {
      throw ConnectionException('Não foi possível conectar. Verifique o endereço e a rede.');
    } catch (e) {
      debugPrint("Erro inesperado ao testar conexão: $e");
      throw ConnectionException('Ocorreu um erro desconhecido ao tentar conectar.');
    }
  }

  /// Salva as informações de conexão no armazenamento e atualiza o estado.
  /// Este método agora é privado, pois a lógica de salvar está junto com o teste.
  Future<void> _saveConnectionInfo(String address, int port) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyHostname, address);
    await prefs.setInt(_keyPort, port);

    // Atualiza o estado da instância atual
    _hostname = address;
    _port = port;
    _state = ConnectionState.configured;

    // Notifica a UI que a configuração mudou!
    notifyListeners();
  }

  /// Limpa as informações de conexão salvas.
  Future<void> clearConnectionInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyHostname);
    await prefs.remove(_keyPort);

    _hostname = null;
    _port = null;
    _state = ConnectionState.notConfigured;
    notifyListeners();
  }
}
