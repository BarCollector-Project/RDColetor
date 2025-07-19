import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rdcoletor/features/app_route.dart';
import 'package:rdcoletor/features/setup/view/database_setup_wrapper.dart';
import 'package:rdcoletor/local/auth/service/auth_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o FFI do SQFlite apenas em plataformas desktop, e não na web.
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(
    // O `ChangeNotifierProvider` disponibiliza o AuthService para toda a
    // árvore de widgets abaixo dele.
    ChangeNotifierProvider(
      create: (context) => AuthService(),
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
