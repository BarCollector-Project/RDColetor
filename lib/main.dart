import 'package:flutter/material.dart';
import 'package:rdcoletor/features/app_route.dart';
import 'package:rdcoletor/features/setup/view/app_initializer.dart';

/// Load screen
/// Carregamento em segundo plano

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BarCollector());
}

class BarCollector extends StatelessWidget {
  const BarCollector({super.key});

  @override
  Widget build(BuildContext context) {
    // O MaterialApp agora envolve o AppInitializer, que cuidará de mostrar
    // a tela de loading e, em seguida, o restante do aplicativo.
    return MaterialApp(title: 'BarColletor', theme: ThemeData(primarySwatch: Colors.blue), home: const AppInitializer(), routes: AppRoute.routes);
  }
}
