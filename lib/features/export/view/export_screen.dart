import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rdcoletor/local/database_service.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  late final DatabaseService _databaseService;
  bool _isLoading = false;
  String _statusMessage = 'Pressione para exportar os dados.';

  @override
  void initState() {
    super.initState();
    _databaseService = context.read<DatabaseService>();
  }

  Future<bool> _sentToBackend(Uint8List fileBytes, String fileName) async {
    try {
      return await _databaseService.updateProdctsFromFile(fileBytes, fileName);
    } catch (e) {
      return false;
    }
  }

  Future<void> _exportData({bool picker = false}) async {
    if (_isLoading) return;

    setState(() {
      _statusMessage = 'Aguarde.';
      _isLoading = true;
    });

    if (picker) {
      //TODO: Mudar o arquivo: O CSV não contém todos os código de barras.
      // Será usado o XML exportado pelo SGLinear em:
      // Relatorios > Materiais > Produtos > Tipo de documento: Todos os código de barras.
      setState(() => _statusMessage = 'Selecione um arquivo .csv compatível.');

      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (picked == null) {
        setState(() {
          _statusMessage = 'Nenhum arquivo selecionado.';
          _isLoading = false;
        });
        return;
      }

      final fileBytes = picked.files.single.bytes!;
      final fileName = picked.files.single.name;

      setState(() => _statusMessage = "Tentando enviar dados...");

      final result = await _sentToBackend(fileBytes, fileName);
      setState(() {
        _statusMessage = result ? 'Dados exportados com sucesso!' : 'Erro ao enviar para o backend.';
        _isLoading = false;
      });

      return;
    }

    setState(() {
      _statusMessage = 'Exportando dados...';
    });

    // Simulação de uma operação de exportação
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Exportação concluída!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exportar Dados'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.upload_file, size: 100, color: Colors.grey),
              const SizedBox(height: 20),
              if (_isLoading)
                const CircularProgressIndicator()
              else ...[
                ElevatedButton.icon(
                  onPressed: _exportData,
                  icon: const Icon(Icons.file_upload),
                  label: const Text('Exportar Dados Agora'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _exportData(picker: true),
                  icon: const Icon(Icons.file_upload),
                  label: const Text('Exportar com um arquivo'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              ],
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
