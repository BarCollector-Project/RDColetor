import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rdcoletor/local/auth/service/auth_service.dart';
import 'package:rdcoletor/local/database_service.dart';
import 'package:rdcoletor/local/server/services/connection_service.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _doLogoutObserver();
  }

  /// Chama-se para editar as configurações de enderço do servidor setadas
  Future<void> _doReconfiguration() async {
    final connection = context.read<ConnectionService>();
    await connection.clearConnectionInfo();
  }

  /// Aguarda até que o usuário faça logout para que o database local seja fechado
  Future<void> _doLogoutObserver() async {
    final authService = context.read<AuthService>();
    if (!authService.isLoggedIn) {
      final dbService = context.read<DatabaseService>();
      await dbService.close();
    }
  }

  Future<void> _doLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    FocusScope.of(context).unfocus();

    // Para garantir que o contexto não seja usado após uma operação assíncrona,
    // capturamos os serviços e o navigator/scaffoldMessenger antes.
    final authService = context.read<AuthService>();
    final dbService = context.read<DatabaseService>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final user = await authService.authenticate(
        _userController.text,
        _passwordController.text,
      );

      final initSnackBarController = scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.blue.shade700,
          content: const Row(
            children: [
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              SizedBox(width: 16),
              Text('Inicializando banco de dados...'),
            ],
          ),
          duration: const Duration(minutes: 1),
        ),
      );

      //await Future.delayed(Duration(seconds: 1));
      final dbInitialized = await dbService.init();

      initSnackBarController.close();

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      // 4. Se a inicialização foi bem-sucedida, mostra um SnackBar de sucesso.
      if (dbInitialized) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Banco de dados local inicializado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        if (!mounted) return;
        authService.completeSignIn(user);
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Erro ao inicializar o banco de dados local.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("Ocorreu um erro inesperado: $e");
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Ocorreu um erro inesperado: $e'), backgroundColor: Colors.red),
      );
    } finally {
      // O bloco `finally` sempre será executado.
      // É crucial verificar `mounted` aqui, porque se a navegação ocorreu no `try`,
      // o widget não existe mais e chamar `setState` causaria o erro.
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Um fundo cinza claro para destacar o card de login
      backgroundColor: Colors.grey[200],
      body: Stack(
        children: [
          Center(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                // Uma sombra sutil para dar profundidade
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(128),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              width: 300,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  // Impede a coluna de expandir verticalmente
                  mainAxisSize: MainAxisSize.min,
                  // Faz com que os filhos (como o botão) estiquem para preencher a largura
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Este é o Text para o título ---
                    const Text(
                      'RD Coletor',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Usuário',
                        border: const OutlineInputBorder(),
                      ),
                      controller: _userController,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      obscureText: true, // Para esconder a senha
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        border: const OutlineInputBorder(),
                      ),
                      controller: _passwordController,
                      onSubmitted: (_) => _doLogin(),
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    SizedBox(
                      height: 50,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_isLoading)
                            Positioned.fill(
                              child: LinearProgressIndicator(borderRadius: BorderRadius.circular(100)),
                            ),
                          Positioned.fill(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                                padding: const EdgeInsets.all(0),
                                backgroundColor: _isLoading ? Colors.transparent : null,
                                shadowColor: _isLoading ? Colors.transparent : null,
                              ),
                              onPressed: _isLoading ? null : () => _doLogin(),
                              child: Text(
                                "Entrar",
                                style: TextStyle(color: _isLoading ? Colors.white : null),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 24,
            bottom: 24,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                iconColor: Colors.white,
                padding: EdgeInsets.all(8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
                minimumSize: Size.square(60),
                iconSize: 24,
              ),
              onPressed: _doReconfiguration,
              child: const Icon(Icons.exit_to_app_sharp),
            ),
          ),
        ],
      ),
    );
  }
}
