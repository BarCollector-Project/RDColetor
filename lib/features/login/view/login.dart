import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rdcoletor/features/app_route.dart';
import 'package:rdcoletor/local/auth/service/auth_service.dart';

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

  Future<void> _doLogin() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    FocusScope.of(context).unfocus();

    final authService = Provider.of<AuthService>(context, listen: false);

    final success = await authService.login(_userController.text, _passwordController.text);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuário ou senha inválidos.'),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Um fundo cinza claro para destacar o card de login
      backgroundColor: Colors.grey[200],
      body: Center(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            // Uma sombra sutil para dar profundidade
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.5),
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
                SizedBox(
                  height: 24,
                ),
                SizedBox(
                  height: 50,
                  child: Stack(
                    alignment: Alignment.center,

                    children: [
                      if (_isLoading)
                        Positioned(
                          bottom: 0,
                          top: 0,
                          left: 0,
                          right: 0,
                          child: LinearProgressIndicator(borderRadius: BorderRadius.circular(100)),
                        ),
                      Positioned(
                        bottom: 0,
                        top: 0,
                        left: 0,
                        right: 0,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            padding: EdgeInsets.all(0),
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
    );
  }
}
