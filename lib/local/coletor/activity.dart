import 'package:flutter/material.dart';

class Activity extends StatelessWidget {
  const Activity({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ActivityWidget(),
      theme: ThemeData(primarySwatch: Colors.blue),
    );
  }
}

class ActivityWidget extends StatefulWidget {
  const ActivityWidget({super.key});

  @override
  State<ActivityWidget> createState() => _ActivityState();
}

class _ActivityState extends State<ActivityWidget> {
  //Controllers
  TextEditingController tecBarcode = TextEditingController();
  TextEditingController tecProduto = TextEditingController();
  TextEditingController tecQuantidade = TextEditingController();

  List<String> _produtos = [];

  void addItem(String barcode, String produto, String quantidade) {
    setState(() {
      _produtos.add("$barcode;$produto;$quantidade");
    });
  }

  Map<String, dynamic> _parseProdutoString(String produtoString) {
    List<String> partes = produtoString.split(';');
    return {
      'codigo': partes[0],
      'nome': partes[1],
      'quantidade': int.parse(partes[2]),
    };
  }

  Map<String, dynamic> getItemFromIndex(int index) {
    return _parseProdutoString(_produtos[index]);
  }

  @override
  Widget build(BuildContext context) {
    final drawer = Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: const Text(
              'Menu',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            title: const Center(
              child: Text(
                "Importar Arquivo Coletor",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            onTap: () {},
          ),
          ListTile(
            title: const Center(
              child: Text(
                "Produtos Cadastrados",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            onTap: () {},
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Coletor')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Código'),
            TextField(
              controller: tecBarcode,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: tecProduto,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              enabled: false,
              cursorHeight: 15,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Quantidade'),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: tecQuantidade,
                    decoration: InputDecoration(border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  addItem(tecBarcode.text, tecProduto.text, tecQuantidade.text);
                  setState(() {
                    tecBarcode.text = '';
                    tecProduto.text = '';
                    tecQuantidade.text = '';
                  });
                },
                child: const Text('Adicionar'),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _produtos.length,
                itemBuilder: (context, index) {
                  return Text(_produtos[index]);
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    child: Text("Importar"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      drawer: drawer,
    );
  }
}
