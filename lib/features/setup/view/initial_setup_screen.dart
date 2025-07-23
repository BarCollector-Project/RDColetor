import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rdcoletor/local/server/services/connection_service.dart';

class InitialSetupScreen extends StatefulWidget {
  /// Tela para o usuário configurar a conexão inicial com o servidor.
  /// Ela interage com o [ConnectionService] para testar e salvar as configurações.
  /// A navegação para a próxima tela é gerenciada reativamente pelo [DatabaseSetupWrapper].
  const InitialSetupScreen({super.key});

  @override
  State<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends State<InitialSetupScreen> {
  final _serverAddressController = TextEditingController();
  final TextEditingController _portController = TextEditingController(text: '8080');

  bool _isLoading = false;
  String _statusMessage = 'Por favor, insira o endereço e a porta do servidor.';

  @override
  void dispose() {
    _serverAddressController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _testAndSaveConnection() async {
    // Usa o ConnectionService provido pelo Provider.
    final connectionService = context.read<ConnectionService>();

    setState(() {
      _isLoading = true;
      _statusMessage = 'Testando a conexão com o servidor...';
    });

    try {
      final address = _serverAddressController.text.trim();
      final port = int.tryParse(_portController.text.trim());

      if (address.isEmpty || port == null) {
        throw ConnectionException('O endereço e a porta devem ser preenchidos.');
      }

      // A chamada abaixo irá salvar a conexão e notificar os listeners.
      // O DatabaseSetupWrapper irá reagir e trocar de tela automaticamente.
      // Não precisamos fazer mais nada aqui em caso de sucesso.
      await connectionService.testAndSaveConnection(address, port);
    } on ConnectionException catch (e) {
      setState(() {
        _statusMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Ocorreu um erro inesperado: $e';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_queue_rounded, size: 100, color: Theme.of(context).primaryColor),
              const SizedBox(height: 20),
              const Text('Configuração Inicial', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(_statusMessage, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.black54)),
              const SizedBox(height: 24),
              TextField(
                controller: _serverAddressController..text = "192.168.1.98",
                decoration: InputDecoration(
                  labelText: 'Endereço do Servidor (IP ou domínio)',
                  border: const OutlineInputBorder(),
                  hintText: 'ex: 192.168.0.10',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _portController..text = "8082",
                decoration: InputDecoration(
                  labelText: 'Porta',
                  border: const OutlineInputBorder(),
                  hintText: 'ex: 8080',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  onPressed: _testAndSaveConnection,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Testar e Salvar Conexão'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
