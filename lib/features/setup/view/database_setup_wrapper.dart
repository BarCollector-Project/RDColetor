import 'package:flutter/material.dart';
import 'package:rdcoletor/features/auth/view/auth_wrapper.dart';
import 'package:rdcoletor/features/setup/view/initial_setup_screen.dart';
import 'package:rdcoletor/local/database_service.dart';

class DatabaseSetupWrapper extends StatefulWidget {
  const DatabaseSetupWrapper({super.key});

  @override
  State<DatabaseSetupWrapper> createState() => _DatabaseSetupWrapperState();
}

class _DatabaseSetupWrapperState extends State<DatabaseSetupWrapper> {
  // Usando uma chave para forçar a reconstrução quando a configuração for concluída.
  Key _key = UniqueKey();

  Future<bool> _checkDatabaseConnection() async {
    try {
      // Tenta obter uma conexão. Se o arquivo não existir ou o caminho não estiver
      // configurado, o DatabaseService lançará uma exceção.
      await DatabaseService().database;
      return true;
    } catch (e) {
      debugPrint("Database connection check failed: $e");
      return false;
    }
  }

  void _onSetupComplete() {
    // Muda a chave do FutureBuilder para forçá-lo a re-executar o future.
    //setState(() {
    //_key = UniqueKey();
    //});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      key: _key,
      future: _checkDatabaseConnection(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData && snapshot.data == true) {
          return const AuthWrapper();
        }

        return InitialSetupScreen(onSetupComplete: _onSetupComplete);
      },
    );
  }
}
