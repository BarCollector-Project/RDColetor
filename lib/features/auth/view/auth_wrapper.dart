import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rdcoletor/features/home/view/home.dart';
import 'package:rdcoletor/features/login/view/login.dart';
import 'package:rdcoletor/local/auth/service/auth_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    // Se o serviço indicar que o usuário está logado, mostra a Home.
    // Caso contrário, mostra a tela de Login.
    // O Provider garante que este widget será reconstruído quando o login/logout ocorrer.
    return authService.isLoggedIn ? const Home() : const Login();
  }
}
