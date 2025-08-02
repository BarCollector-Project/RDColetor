import 'package:flutter/material.dart';
import 'package:rdcoletor/features/app_route.dart';
import 'package:rdcoletor/features/settings/global/app_settings.dart';
import 'package:rdcoletor/features/setup/view/app_initializer.dart';
import 'package:rdcoletor/features/setup/view/database_setup_wrapper.dart';

/// Load screen
/// Carregamento em segundo plano

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.init();
  // O AppInitializer se torna a raiz do aplicativo. Ele cuidará de mostrar
  // uma tela de loading e, em seguida, injetar os providers acima do MaterialApp.
  runApp(const AppInitializer());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Este é o aplicativo principal, que é construído DEPOIS que os providers
    // foram inicializados e injetados pelo AppInitializer.
    return MaterialApp(
      title: 'BarColletor',
      theme: ThemeData(primarySwatch: Colors.blue),
      // A tela inicial agora é o DatabaseSetupWrapper, pois a inicialização já ocorreu.
      home: const DatabaseSetupWrapper(),
      routes: AppRoute.routes,
    );
  }
}
