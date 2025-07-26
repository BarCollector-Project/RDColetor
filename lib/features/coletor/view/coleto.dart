import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rdcoletor/local/coletor/db/repository/product_repository.dart';
import 'package:rdcoletor/local/coletor/model/product.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

/// Um modelo de dados para os itens coletados, garantindo type-safety.
class CollectedItem {
  const CollectedItem({
    required this.name,
    required this.code,
    required this.quantity,
  });
  final String name;
  final String code;
  final int quantity;
}

class Coletor extends StatefulWidget {
  const Coletor({super.key});

  @override
  State<Coletor> createState() => _ColetorScreenState();
}

class _ColetorScreenState extends State<Coletor> {
  final _barcodeController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  late final ProductRepository _productRepository;

  Timer? _debounce;

  Product? _foundProduct;
  final List<CollectedItem> _collectedItems = [];

  @override
  void initState() {
    super.initState();
    _productRepository = context.read<ProductRepository>();
    _barcodeController.addListener(_onBarcodeChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _barcodeController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  /// Controla a busca por código de barras com um atraso (debounce) para
  /// evitar múltiplas chamadas ao banco de dados enquanto o usuário digita.
  void _onBarcodeChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final barcode = _barcodeController.text;
      if (barcode.isNotEmpty) {
        _lookupBarcode(barcode);
      } else if (mounted) {
        setState(() => _foundProduct = null);
      }
    });
  }

  Future<void> _lookupBarcode(String barcode) async {
    final product = await _productRepository.findProductByCode(barcode);
    if (mounted) {
      setState(() {
        _foundProduct = product;
      });
    }
  }

  Future<String?> _scanBarcode() async {
    String? res = await SimpleBarcodeScanner.scanBarcode(
      context,
      barcodeAppBar: const BarcodeAppBar(
        appBarTitle: 'Test',
        centerTitle: false,
        enableBackButton: true,
        backButtonIcon: Icon(Icons.arrow_back_ios),
      ),
      isShowFlashIcon: true,
      delayMillis: 2000,
      cameraFace: CameraFace.front,
    );
    return res;
  }

  void _addItemToList() {
    if (_foundProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum produto encontrado para este código.')),
      );
      return;
    }

    final quantity = int.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, insira uma quantidade válida.')),
      );
      return;
    }

    setState(() {
      _collectedItems.insert(
        0, // Adiciona o item no topo da lista para visualização imediata
        CollectedItem(
          name: _foundProduct!.name,
          code: _foundProduct!.barcode,
          quantity: quantity,
        ),
      );

      // Limpa os campos para a próxima coleta
      _foundProduct = null;
      _barcodeController.clear();
      _quantityController.text = '1';
      // Esconde o teclado
      FocusScope.of(context).unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coletor de Dados'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Display do nome do produto
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              height: 80,
              child: Center(
                child: Text(
                  _foundProduct?.name ?? 'Digite ou escaneie um código',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _foundProduct != null ? Colors.black87 : Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Campos de entrada (Código e Quantidade)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _barcodeController,
                    decoration: InputDecoration(
                      labelText: 'Código de Barras',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner),
                        onPressed: () async => _barcodeController.text = await _scanBarcode() ?? '',
                      ),
                    ),
                    keyboardType: TextInputType.text,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Qtd.',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3. Botão para adicionar à lista
            ElevatedButton.icon(
              onPressed: _addItemToList,
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Adicionar à Lista'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            const Divider(height: 32),

            // 4. Lista de produtos coletados
            const Text('Itens Coletados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: _collectedItems.isEmpty
                  ? const Center(child: Text('Nenhum item coletado ainda.'))
                  : ListView.builder(
                      itemCount: _collectedItems.length,
                      itemBuilder: (context, index) {
                        final item = _collectedItems[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            title: Text(item.name),
                            subtitle: Text('Código: ${item.code}'),
                            trailing: Text(
                              'Qtd: ${item.quantity}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
