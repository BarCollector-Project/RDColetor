import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rdcoletor/features/app_route.dart';
import 'package:rdcoletor/features/setup/view/database_setup_wrapper.dart';
import 'package:rdcoletor/local/auth/service/auth_service.dart';
import 'package:rdcoletor/local/auth/repository/user_repository.dart';
import 'package:rdcoletor/local/database_service.dart';
import 'package:rdcoletor/local/server/services/connection_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o FFI do SQFlite apenas em plataformas desktop, e não na web.
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await ConnectionService().initialize();

  // Cria e inicializa o DatabaseService antes de o app rodar.
  // Isso garante que o banco de dados estará pronto para uso.
  final databaseService = DatabaseService();
  await databaseService.init();

  runApp(
    // MultiProvider permite registrar vários providers de uma vez.
    MultiProvider(
      providers: [
        // 1. Provider para o ConnectionService.
        //    É um ChangeNotifier, então a UI pode reagir às suas mudanças.
        ChangeNotifierProvider<ConnectionService>(
          create: (_) => ConnectionService(),
        ),
        // 2. Fornece a instância JÁ INICIALIZADA do DatabaseService.
        //    Usamos Provider.value para instâncias pré-criadas.
        Provider<DatabaseService>.value(
          value: databaseService,
        ),
        // 3. Provider para o UserRepository.
        //    Ele depende do AppDatabase, que é lido do contexto (`context.read<AppDatabase>()`).
        Provider<UserRepository>(
          create: (context) => UserRepository(context.read<DatabaseService>()),
        ),
        // 4. Provider para o AuthService, que agora depende de ambos os serviços.
        ChangeNotifierProvider<AuthService>(
          create: (context) {
            // A injeção de dependência correta é crucial.
            // O AuthService precisa tanto do DatabaseService (para login via API)
            // quanto do UserRepository (para gerenciar usuários locais).
            return AuthService(
              context.read<UserRepository>(),
            );
          },
        ),
      ],
      builder: (context, child) => const RDColetor(),
    ),
  );
}

class RDColetor extends StatelessWidget {
  const RDColetor({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'RD Coletor', theme: ThemeData(primarySwatch: Colors.blue), home: const DatabaseSetupWrapper(), routes: AppRoute.routes);
  }
}
