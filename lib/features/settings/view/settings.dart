import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rdcoletor/features/app_route.dart';
import 'package:rdcoletor/local/auth/service/auth_service.dart';
import 'package:rdcoletor/local/coletor/db/repository/product_repository.dart';
import 'package:rdcoletor/local/database_service.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  late final ProductRepository _productRepository;

  @override
  void initState() {
    super.initState();
    _productRepository = ProductRepository(Provider.of<DatabaseService>(context, listen: false));
  }

  void _showChangeCredentialDialog({required bool isChangingUsername}) {
    final controller = TextEditingController();
    final passwordController = TextEditingController();

    final authService = Provider.of<AuthService>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isChangingUsername ? 'Alterar Nome de Usuário' : 'Alterar Senha'),
          content: Column(
            children: [
              TextField(
                controller: passwordController,
                decoration: InputDecoration(labelText: isChangingUsername ? 'Senha' : 'Senha atual'),
                obscureText: !isChangingUsername,
              ),
              TextField(
                controller: controller,
                decoration: InputDecoration(labelText: isChangingUsername ? 'Novo nome de usuário' : 'Nova senha'),
                obscureText: !isChangingUsername,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.isNotEmpty && passwordController.text.isNotEmpty) {
                  await authService.updateUserCredentials(
                    password: passwordController.text,
                    newUsername: isChangingUsername ? controller.text : null,
                    newPassword: !isChangingUsername ? controller.text : null,
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Preencha todos os campos.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
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
            leading: const Icon(Icons.camera_enhance),
            title: const Text('Seleção da câmera'),
            subtitle: const Text('Selecione a melhor câmera para ler código de barras'),
            onTap: () => Navigator.pushNamed(context, AppRoute.cameraSettings),
          ),
          const Divider(),
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
