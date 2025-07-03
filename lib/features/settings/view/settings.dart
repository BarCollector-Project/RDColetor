import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:rdcoletor/features/app_route.dart';
import 'package:rdcoletor/local/auth/model/user.dart';
import 'package:rdcoletor/local/auth/repository/user_repository.dart';
import 'package:rdcoletor/local/auth/service/auth_service.dart';
import 'package:rdcoletor/local/coletor/db/repository/product_repository.dart';
import 'package:rdcoletor/local/database_service.dart';
import 'package:rdcoletor/local/path_service.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final _productRepository = ProductRepository();
  final _userRepository = UserRepository();
  final _pathService = PathService();
  final _dbService = DatabaseService();
  bool _isChangingPath = false;

  void _showChangeCredentialDialog({required bool isChangingUsername}) {
    final controller = TextEditingController();
    final authService = Provider.of<AuthService>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isChangingUsername ? 'Alterar Nome de Usuário' : 'Alterar Senha'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: isChangingUsername ? 'Novo nome de usuário' : 'Nova senha'),
            obscureText: !isChangingUsername,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  await authService.updateUserCredentials(
                    newUsername: isChangingUsername ? controller.text : null,
                    newPassword: !isChangingUsername ? controller.text : null,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changeDatabasePath() async {
    // 1. Pick a new directory
    final String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Selecione a nova pasta do banco de dados',
    );

    if (selectedDirectory == null || !mounted) return; // User canceled or widget is gone

    // 2. Validate that rdcoletor.db exists in the new directory
    final dbPath = path.join(selectedDirectory, 'rdcoletor.db');
    if (!await File(dbPath).exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Arquivo "rdcoletor.db" não encontrado no diretório selecionado.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // 3. Ask for admin credentials to authorize the change
    final adminController = TextEditingController();
    final passwordController = TextEditingController();

    if (mounted) {
      final bool? credentialsConfirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              title: const Text('Autenticação de Administrador'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Para alterar o local do banco de dados, por favor, insira as credenciais de um administrador.'),
                  const SizedBox(height: 16),
                  TextField(controller: adminController, decoration: const InputDecoration(labelText: 'Usuário Admin')),
                  TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Senha Admin'), obscureText: true),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () async {
                    final user = await _userRepository.findUserByCredentials(adminController.text, passwordController.text);
                    if (user != null && user.role == UserRole.admin) {
                      Navigator.pop(context, true);
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Credenciais de administrador inválidas.'), backgroundColor: Colors.red));
                      }
                      Navigator.pop(context, false);
                    }
                  },
                  child: const Text('Confirmar'),
                ),
              ],
            ),
      );

      if (credentialsConfirmed != true) return;
    }
    // 4. Perform the change
    setState(() {
      _isChangingPath = true;
    });

    try {
      await _dbService.closeDatabase();
      await _pathService.saveDatabaseDirectory(selectedDirectory);

      // 5. Show restart dialog
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                title: const Text('Sucesso!'),
                content: const Text('O local do banco de dados foi alterado. Por favor, reinicie o aplicativo para aplicar as mudanças.'),
                actions: [ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
              ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao alterar o local: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isChangingPath = false);
      }
    }
  }

  void _showClearDatabaseConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Ação'),
          content: const Text('Você tem certeza que deseja apagar todos os produtos do banco de dados? Esta ação não pode ser desfeita.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Apagar'),
              onPressed: () async {
                Navigator.of(context).pop(); // Fecha o dialog
                await _clearDatabase();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearDatabase() async {
    // Para limpar, inserimos uma lista vazia, pois nosso método já faz o `delete`.
    await _productRepository.insertProducts([]);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Banco de dados de produtos limpo com sucesso.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Configurações"),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('Ver Produtos Cadastrados'),
            subtitle: const Text('Listar todos os produtos no banco de dados local'),
            onTap: () {
              Navigator.pushNamed(context, AppRoute.products);
            },
          ),
          const Divider(),
          ListTile(
            leading: _isChangingPath ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.storage_rounded),
            title: const Text('Alterar Local do Banco de Dados'),
            subtitle: const Text('Requer credenciais de administrador'),
            onTap: _isChangingPath ? null : _changeDatabasePath,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Alterar nome de usuário'),
            onTap: () => _showChangeCredentialDialog(isChangingUsername: true),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Alterar senha'),
            onTap: () => _showChangeCredentialDialog(isChangingUsername: false),
          ),
          // Opções visíveis apenas para administradores
          if (authService.isAdmin) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.manage_accounts),
              title: const Text('Gerenciar Usuários'),
              onTap: () => Navigator.pushNamed(context, AppRoute.userManagement),
            ),
          ],
          const Divider(),
          // A opção de limpar o banco de dados só aparece para administradores.
          if (authService.isAdmin)
            ListTile(
              leading: Icon(Icons.delete_forever, color: Colors.red.shade700),
              title: Text(
                'Limpar Banco de Dados',
                style: TextStyle(color: Colors.red.shade700),
              ),
              subtitle: const Text('Remove todos os produtos do dispositivo. Será necessário sincronizar novamente.'),
              onTap: _showClearDatabaseConfirmation,
            ),
          if (authService.isAdmin) const Divider(),
        ],
      ),
    );
  }
}
