import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rdcoletor/features/app_route.dart';
import 'package:rdcoletor/features/setup/view/database_setup_wrapper.dart';
import 'package:rdcoletor/local/app_database.dart';
import 'package:rdcoletor/local/auth/service/auth_service.dart';
import 'package:rdcoletor/local/auth/repository/user_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o FFI do SQFlite apenas em plataformas desktop, e não na web.
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(
    // MultiProvider permite registrar vários providers de uma vez.
    MultiProvider(
      providers: [
        // 1. Provider para a instância do banco de dados (AppDatabase).
        //    Ele é criado uma vez e disponibilizado para os outros providers.
        Provider<AppDatabase>(
          create: (_) => DatabaseProvider.getDatabase(),
        ),
        // 2. Provider para o UserRepository.
        //    Ele depende do AppDatabase, que é lido do contexto (`context.read<AppDatabase>()`).
        Provider<UserRepository>(
          create: (context) => UserRepository(context.read<AppDatabase>()),
        ),
        // 3. Provider para o AuthService.
        //    Ele depende do UserRepository.
        ChangeNotifierProvider<AuthService>(
          create: (context) => AuthService(context.read<UserRepository>()),
        ),
      ],
      child: const RDColetor(),
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
