import 'package:flutter/material.dart';
import 'package:rdcoletor/features/app_route.dart';
import 'package:rdcoletor/models/screen/blocks_layout.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  late final BlocksLayout bLayout;

  @override
  void initState() {
    super.initState();
    bLayout = BlocksLayout(context: context);
  }

  void onTapSendCango() {
    Navigator.pushNamed(
      context,
      AppRoute.adminExport,
    );
  }

  void onTapModifyProducts() {}

  void onTapManagerRecords() {}

  void onTapRegistrations() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Para administradores"),
      ),
      body: bLayout.buildBody(
        children: [
          bLayout.buildSectionTitle("Banco de dados"),
          bLayout.buildGridButton(icon: Icons.cloud_upload, label: "Enviar carga", onTap: onTapSendCango),
          bLayout.buildGridButton(icon: Icons.cloud_upload, label: "Modificar produtos", onTap: onTapModifyProducts),
          bLayout.buildGridButton(icon: Icons.cloud_upload, label: "Gerenciar registros", onTap: onTapManagerRecords),
          bLayout.buildSectionTitle("Usuários"),
          bLayout.buildGridButton(icon: Icons.person, label: "Cadastros", onTap: onTapRegistrations),
        ],
      ),
    );
  }
}
