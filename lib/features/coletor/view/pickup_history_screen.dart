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
    // Carrega os registros iniciais ao entrar na tela
    _updateRegisters();
  }

  Future<void> _updateRegisters() async {
    //TODO: Temporário. Em produção isto obterá os registro do banco de dados
    final loadedRegisters = [
      CollectRegister()
        ..coletedItens.add(
          CollectedItem(
            name: "Produto 1",
            code: "123456789",
            quantity: 10,
            reason: "INSUMO",
            origin: "LOJA",
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
                // Assumindo que cada registro tem pelo menos um item
                final item = register.coletedItens.first;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(item.name),
                    subtitle: Text('Código: ${item.code}\nQuantidade: ${item.quantity}'),
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
