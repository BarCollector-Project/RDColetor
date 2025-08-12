import 'package:flutter/material.dart';
import 'package:rdcoletor/features/coletor/models/collect_register.dart';

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

  @override
  void initState() {
    super.initState();
  }

  Future<void> _updateRegisters() async {
    //TODO: Temporário. Em produção isto obterá os registro do banco de dados
    registers = [
      CollectRegister()
        ..coletedItens.add(CollectedItem(
          name: "Produto 1",
          code: "123456789",
          quantity: 10,
          reason: "INSUMO",
          origin: "LOJA",
        )),
    ];
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Coletas'),
      ),
      body: Column(
        children: [
          Text("Ultimos registros de coleta."),
          ListView.builder(
            itemBuilder: (constext, index) {
              return Column(children: [Text("Uso e consumo")]);
            },
            itemCount: 10,
          ),
        ],
      ),
    );
  }
}
