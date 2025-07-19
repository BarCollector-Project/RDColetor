import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ConnectionService {
  // --- Singleton Setup ---
  static final ConnectionService _instance = ConnectionService._();
  factory ConnectionService() {
    return _instance;
  }
  ConnectionService._();

  // --- State ---
  static const _keyHostname = 'hostname';
  static const _keyPort = 'port';

  String? _hostname;
  int? _port;
  final http.Client _client = http.Client();

  // --- Public Getters ---

  /// Retorna o hostname do servidor configurado. Retorna null se não configurado.
  String? get hostname => _hostname;

  /// Retorna a porta do servidor configurada. Retorna null se não configurado.
  int? get port => _port;

  /// Retorna true se os detalhes da conexão foram carregados e não estão vazios.
  bool get isConfigured => _hostname != null && _hostname!.isNotEmpty && _port != null;

  /// A URL base para fazer chamadas de API. Lança um erro se não estiver configurado.
  String get baseUrl {
    if (!isConfigured) {
      throw StateError('ConnectionService não está configurado. Execute a configuração inicial.');
    }
    return 'http://$_hostname:$_port';
  }

  // --- Initialization ---

  /// Carrega as informações de conexão do armazenamento.
  /// Deve ser chamado uma vez na inicialização do aplicativo.
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _hostname = prefs.getString(_keyHostname);
    _port = prefs.getInt(_keyPort);
  }

  // --- Core Logic ---

  /// Testa a conexão com um endereço de servidor e porta.
  /// Também verifica se o servidor é um servidor de aplicação válido.
  Future<bool> testConnection(String address, int port, [bool save = false]) async {
    // Validação básica de entrada
    if (address.trim().isEmpty || port <= 0 || port > 65535) {
      return false;
    }

    // É uma boa prática ter um endpoint de "health check" no seu servidor.
    // Isso garante que você está se conectando à aplicação correta.
    // Vamos supor que seu servidor tenha um endpoint `/api/health`.
    final testUrl = Uri.parse('http://$address:$port/api/health');

    try {
      final response = await _client.get(testUrl).timeout(const Duration(seconds: 5));
      // Verificamos se o servidor está acessível (código 200).
      // O ideal é também checar o corpo da resposta para ter certeza
      // de que é o servidor correto, ex: if (response.body == 'API_OK')
      if (response.statusCode == 200) {
        if (save) {
          await saveConnectionInfo(address, port);
        }
        return true;
      }
    } catch (e) {
      // Captura erros de Timeout, SocketException (rede), etc.
      //return false;
    }
    return false;
  }

  /// Salva as informações de conexão no armazenamento local e atualiza o estado do serviço.
  Future<void> saveConnectionInfo(String address, int port) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyHostname, address);
    await prefs.setInt(_keyPort, port);

    // Atualiza o estado da instância atual
    _hostname = address;
    _port = port;
  }
}
