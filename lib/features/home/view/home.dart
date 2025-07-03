import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rdcoletor/features/app_route.dart';
import 'package:rdcoletor/local/auth/service/auth_service.dart';
import 'package:rdcoletor/local/coletor/service/background_import_service.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _importService = BackgroundImportService();
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    // Dispara a importação em segundo plano ao entrar na tela.
    _triggerBackgroundImport();
  }

  Future<void> _triggerBackgroundImport() async {
    if (mounted) {
      setState(() {
        _isImporting = true;
      });
    }

    final result = await _importService.runImport();

    if (mounted) {
      setState(() {
        _isImporting = false;
      });
      final message = result.success ? 'Sincronização concluída: ${result.productsImported} produtos.' : 'Falha na sincronização: ${result.errorMessage}';
      final color = result.success ? Colors.green : Colors.red;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
    }
  }

  /// Constrói um botão padrão para o GridView da home.
  Widget _buildGridButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    double maxSize = 160.0, // Tamanho ideal para um layout com quebra de linha.
  }) {
    // O SizedBox força o botão a ter um tamanho máximo específico,
    // permitindo que o Wrap os organize lado a lado.
    return SizedBox(
      width: maxSize,
      height: maxSize,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12), // Para o efeito de clique
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: Theme.of(context).primaryColor),
              const SizedBox(height: 12),
              Padding(
                // Adiciona um padding para evitar que o texto encoste nas bordas.
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userName = authService.currentUser?.username ?? 'Usuário';

    return Scaffold(
      appBar: AppBar(
        // Usei o operador '??' para evitar erros caso o nome do usuário seja nulo.
        title: Text("Olá, $userName!"),
        actions: [
          if (_isImporting)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
            ),
        ],
      ),
      // Adicionando o menu lateral (Drawer) ao Scaffold.
      drawer: Drawer(
        child: ListView(
          // Remove o padding padrão da ListView para que o header ocupe todo o topo.
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text('RD Coletor', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Usuário: $userName', style: const TextStyle(color: Colors.white, fontSize: 14)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Início'),
              onTap: () {
                // Fecha o drawer, pois já estamos na home.
                Navigator.pop(context);
              },
            ),
            const Divider(), // Uma linha para separar os itens.
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: () {
                // Limpa a sessão e volta para a tela de login.
                authService.logout();
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        // Adiciona rolagem para evitar overflow em telas menores ou com muitos botões.
        padding: const EdgeInsets.all(16.0),
        child: Wrap(
          spacing: 16.0, // Espaçamento horizontal entre os botões.
          runSpacing: 16.0, // Espaçamento vertical entre as linhas.
          alignment: WrapAlignment.center, // Centraliza os botões.
          children: <Widget>[
            _buildGridButton(
              icon: Icons.cloud_upload,
              label: 'Importar Produtos',
              onTap: () => Navigator.pushNamed(context, AppRoute.import),
            ),
            _buildGridButton(
              icon: Icons.qr_code_scanner,
              label: 'Coletar Dados',
              onTap: () => Navigator.pushNamed(context, AppRoute.coletor),
            ),
            _buildGridButton(
              icon: Icons.settings,
              label: 'Configurações',
              onTap: () => Navigator.pushNamed(context, AppRoute.settings),
            ),
            // Adicione mais botões conforme necessário
          ],
        ),
      ),
    );
  }
}
