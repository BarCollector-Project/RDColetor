import 'package:flutter/material.dart';
import 'package:rdcoletor/local/coletor/service/background_import_service.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final BackgroundImportService _importService = BackgroundImportService();
  bool _isLoading = false;
  String _statusMessage = 'Pronto para sincronização manual.';

  Future<void> _runManualImport({bool usePicker = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Iniciando sincronização...';
    });

    final result = await _importService.runImport(picker: usePicker);

    if (mounted) {
      final message = result.success ? '${result.productsImported} produtos sincronizados com sucesso!' : 'Falha na sincronização: ${result.errorMessage}';
      final color = result.success ? Colors.green : Colors.red;

      setState(() {
        _isLoading = false;
        _statusMessage = message;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sincronizar Produtos'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sync_alt_rounded, size: 100, color: Colors.grey),
              const SizedBox(height: 20),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _runManualImport,
                      icon: const Icon(Icons.sync),
                      label: const Text('Sincronizar Agora'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _runManualImport(usePicker: true),
                      icon: const Icon(Icons.file_open),
                      label: const Text('Importar do CSV'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
