import 'package:flutter/material.dart';
import 'package:rdcoletor/features/auth/view/auth_wrapper.dart';
import 'package:rdcoletor/features/setup/view/initial_setup_screen.dart';
import 'package:rdcoletor/local/app_database.dart';

class DatabaseSetupWrapper extends StatefulWidget {
  const DatabaseSetupWrapper({super.key});

  @override
  State<DatabaseSetupWrapper> createState() => _DatabaseSetupWrapperState();
}

class _DatabaseSetupWrapperState extends State<DatabaseSetupWrapper> {
  // Usando uma chave para forçar a reconstrução quando a configuração for concluída.
  Key _key = UniqueKey();

  // Obtém a implementação correta do banco de dados (nativa ou web) através da fábrica.
  final AppDatabase _appDatabase = DatabaseProvider.getDatabase();

  Future<bool> _checkDatabaseSetup() async {
    try {
      final initialized = await _appDatabase.init();
      return initialized;
    } catch (e) {
      debugPrint("Database connection check failed: $e");
      return false;
    }
  }

  void _onSetupComplete() {
    // Muda a chave do FutureBuilder para forçá-lo a re-executar o future.
    setState(() {
      _key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      key: _key,
      future: _checkDatabaseSetup(),
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
