import 'package:flutter/material.dart';
import 'package:rdcoletor/local/server/services/connection_service.dart';

// TODO: Criar um serviço para salvar e carregar as informações de conexão.
// import 'package:rdcoletor/api/connection_service.dart';

class InitialSetupScreen extends StatefulWidget {
  final VoidCallback onSetupComplete;

  const InitialSetupScreen({super.key, required this.onSetupComplete});

  @override
  State<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends State<InitialSetupScreen> {
  // TODO: Substituir por uma implementação real de um serviço de conexão.
  final ConnectionService _connectionService = ConnectionService();
  final TextEditingController _serverAddressController = TextEditingController();
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
    setState(() {
      _isLoading = true;
      _statusMessage = 'Testando a conexão com o servidor...';
    });

    try {
      final address = _serverAddressController.text;
      final port = _portController.text;

      if (address.isEmpty || port.isEmpty) {
        setState(() {
          _statusMessage = 'O endereço do servidor e a porta não podem estar vazios.';
        });
        return;
      }

      final isConnectionOk = await _connectionService.testConnection(address, int.parse(port));

      // Para este exemplo, vamos simular uma conexão bem-sucedida após 2 segundos.
      await Future.delayed(const Duration(seconds: 2));

      if (isConnectionOk) {
        await _connectionService.saveConnectionInfo(address, int.parse(port));
        setState(() {
          _statusMessage = 'Conexão bem-sucedida! O aplicativo será iniciado.';
        });
        widget.onSetupComplete();
      } else {
        setState(() {
          _statusMessage = 'Não foi possível conectar ao servidor. Verifique os dados e tente novamente.';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Ocorreu um erro ao tentar conectar: $e';
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
                controller: _serverAddressController,
                decoration: InputDecoration(
                  labelText: 'Endereço do Servidor (IP ou domínio)',
                  border: const OutlineInputBorder(),
                  hintText: 'ex: 192.168.0.10',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _portController,
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
