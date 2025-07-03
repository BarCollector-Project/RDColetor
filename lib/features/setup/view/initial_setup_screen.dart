import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:rdcoletor/local/path_service.dart';

class InitialSetupScreen extends StatefulWidget {
  final VoidCallback onSetupComplete;

  const InitialSetupScreen({super.key, required this.onSetupComplete});

  @override
  State<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends State<InitialSetupScreen> {
  final PathService _pathService = PathService();
  final TextEditingController _pathController = TextEditingController();

  bool _isLoading = false;
  String _statusMessage = 'Por favor, selecione a pasta onde o arquivo "rdcoletor.db" está localizado.';

  String? selectedDirectory;

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _pickerDatabaseDirectory() async {
    selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Selecione a pasta do banco de dados',
    );

    if (selectedDirectory == null) {
      // User canceled the picker
      setState(() {
        _statusMessage = 'Seleção cancelada. Por favor, selecione a pasta onde o arquivo "rdcoletor.db" está localizado.';
      });
    } else {
      _pathController.text = selectedDirectory!;
      _readDatabaseDirectory();
    }
  }

  Future<void> _readDatabaseDirectory() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Lendo o diretório...';
    });

    try {
      if (selectedDirectory != null) {
        final dbPath = join(selectedDirectory!, 'rdcoletor.db');
        if (await File(dbPath).exists()) {
          await _pathService.saveDatabaseDirectory(selectedDirectory!);
          setState(() {
            _statusMessage = 'Configuração concluída! O aplicativo será iniciado.';
          });
          // Notifica o wrapper que a configuração foi concluída.
          widget.onSetupComplete();
        } else {
          setState(() {
            _statusMessage = 'O arquivo "rdcoletor.db" não foi encontrado nesta pasta. Por favor, tente novamente.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Ocorreu um erro: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
              Icon(Icons.folder_special_rounded, size: 100, color: Theme.of(context).primaryColor),
              const SizedBox(height: 20),
              const Text('Configuração Inicial', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(_statusMessage, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.black54)),
              const SizedBox(height: 24),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Caminho do Banco de Dados',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(onPressed: _pickerDatabaseDirectory, icon: Icon(Icons.search)),
                ),
                controller: _pathController,
              ),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  onPressed: _readDatabaseDirectory,
                  icon: const Icon(Icons.search),
                  label: const Text('Selecionar Pasta'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
