import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rdcoletor/features/app_route.dart';
import 'package:rdcoletor/features/coletor/models/collect_register.dart';
import 'package:rdcoletor/local/database/repositories/system_table_repository.dart';
import 'package:rdcoletor/local/database/repositories/types/system_tables.dart';
import 'package:rdcoletor/local/database_service.dart';

class PickupHistoryScreen extends StatefulWidget {
  const PickupHistoryScreen({super.key});

  @override
  State<PickupHistoryScreen> createState() => _PickupHistoryScreenState();
}

class _PickupHistoryScreenState extends State<PickupHistoryScreen> {
  //TODO: Implementar a possibilidade de selecionar um prerodo específico
  DateTime start = DateTime.now();
  DateTime end = DateTime.now();

  //TODO: Implementar a função para carregar os registro com base em um periodo
  List<CollectRegister> registers = [];

  late final List<Reason> _reasonList;
  late final List<Origin> _originList;
  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    await _loadSystemTables();
    await _updateRegisters();
  }

  Future<void> _loadSystemTables() async {
    SystemTables systemTables = SystemTables(db: context.read<DatabaseService>());
    _originList = await systemTables.getOrigin();
    _reasonList = await systemTables.getReason();
  }

  Future<void> _updateRegisters() async {
    //TODO: Temporário. Em produção isto obterá os registro do banco de dados
    final loadedRegisters = [
      CollectRegister(
        userName: "Usuário 1",
        financialNature: "Natureza Financeira 1",
        costCenter: "Centro de Custo 1",
      )..coletedItens.add(
          CollectedItem(
            name: "Produto 1",
            code: "123456789",
            quantity: 10,
            reason: _reasonList.first,
            origin: _originList.first,
          ),
        ),
    ];
    setState(() {
      registers = loadedRegisters;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Coletas'),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Ultimos registros de coleta."),
          ),
          Expanded(
            child: ListView.builder(
              itemBuilder: (context, index) {
                final register = registers[index];

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(register.userName),
                    subtitle: Text('${register.timestamp} - ${register.financialNature} - ${register.costCenter}'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () async {
                      final result = await Navigator.pushNamed(context, AppRoute.collect, arguments: register.coletedItens);
                      if (result != null) {
                        if (result == true) {
                          await _updateRegisters();
                        }
                      }
                    },
                    isThreeLine: true,
                  ),
                );
              },
              itemCount: registers.length,
            ),
          ),
        ],
      ),
    );
  }
}
