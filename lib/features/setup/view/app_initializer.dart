import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rdcoletor/features/load_screen/view/loading_screen.dart';
import 'package:rdcoletor/local/auth/repository/user_repository.dart';
import 'package:rdcoletor/local/auth/service/auth_service.dart';
import 'package:rdcoletor/local/coletor/db/repository/product_repository.dart';
import 'package:rdcoletor/local/database_service.dart';
import 'package:rdcoletor/local/server/services/connection_service.dart' hide ConnectionState;
import 'package:rdcoletor/main.dart';

/// Um registro simples para retornar os serviços inicializados.
typedef InitializedServices = ({
  ConnectionService connectionService,
  DatabaseService databaseService,
});

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  late final Future<InitializedServices> _servicesFuture;

  @override
  void initState() {
    super.initState();
    _servicesFuture = _initializeServices();
  }

  Future<InitializedServices> _initializeServices() async {
    // FORÇA a função a ser assíncrona desde o início.
    // Isso garante que o FutureBuilder mostre o LoadingScreen() imediatamente,
    // antes de qualquer trabalho pesado começar.
    await Future.delayed(Duration.zero);

    // Todas as tarefas pesadas que estavam no main() agora estão aqui.
    final connectionService = ConnectionService();
    await connectionService.initialize();

    final databaseService = DatabaseService();
    // Se o databaseService tiver um método init() assíncrono, chame-o aqui.
    // await databaseService.initialize();

    return (
      connectionService: connectionService,
      databaseService: databaseService,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<InitializedServices>(
      future: _servicesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Enquanto os serviços estão inicializando, mostre a tela de loading
          // dentro de um MaterialApp para ter um contexto visual básico.
          return const MaterialApp(home: LoadingScreen());
        }

        if (snapshot.hasError) {
          // Se algo der errado, mostre uma tela de erro.
          return MaterialApp(
            home: Scaffold(body: Center(child: Text('Erro ao inicializar: ${snapshot.error}'))),
          );
        }

        // Quando a inicialização estiver completa, injeta os providers
        // ACIMA do MaterialApp (MainApp) para que todas as rotas (home, named routes)
        // tenham acesso a eles.
        final services = snapshot.requireData;
        return MultiProvider(
          providers: [
            ChangeNotifierProvider<ConnectionService>.value(value: services.connectionService),
            Provider<DatabaseService>.value(value: services.databaseService),
            Provider<UserRepository>(create: (context) => UserRepository(context.read<DatabaseService>())),
            ChangeNotifierProvider<AuthService>(create: (context) => AuthService(context.read<UserRepository>())),
            Provider<ProductRepository>(create: (context) => ProductRepository(context.read<DatabaseService>())),
          ],
          child: const MainApp(),
        );
      },
    );
  }
}
