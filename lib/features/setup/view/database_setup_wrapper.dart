import 'package:flutter/material.dart' hide ConnectionState;
import 'package:provider/provider.dart';
import 'package:rdcoletor/features/auth/view/auth_wrapper.dart';
import 'package:rdcoletor/features/setup/view/initial_setup_screen.dart';
import 'package:rdcoletor/local/server/services/connection_service.dart';

/// Este widget decide qual tela mostrar com base no estado da conexão com o servidor.
///
/// Ele escuta o [ConnectionService] e reage a mudanças:
/// - Se a conexão não foi inicializada, mostra um loading.
/// - Se a conexão não está configurada, mostra a [InitialSetupScreen].
/// - Se a conexão está configurada, mostra o [AuthWrapper] para o login.
class DatabaseSetupWrapper extends StatelessWidget {
  const DatabaseSetupWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos um Consumer para escutar as mudanças no ConnectionService.
    // Ele reconstrói a UI automaticamente quando `notifyListeners()` é chamado.
    return Consumer<ConnectionService>(
      builder: (context, connectionService, child) {
        switch (connectionService.state) {
          case ConnectionState.uninitialized:
            // Mostra um indicador de progresso enquanto o serviço carrega
            // as configurações salvas do disco.
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );

          case ConnectionState.configured:
            // Se a conexão já está configurada, o usuário pode prosseguir
            // para a tela de autenticação.
            return const AuthWrapper();

          case ConnectionState.notConfigured:
            // Se a conexão não foi configurada, direciona o usuário para a
            // tela de configuração inicial.
            return const InitialSetupScreen();
        }
      },
    );
  }
}
