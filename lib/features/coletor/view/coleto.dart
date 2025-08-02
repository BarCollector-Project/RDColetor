import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:rdcoletor/features/coletor/widgets/barcode_scanner.dart';
import 'package:rdcoletor/local/coletor/db/repository/product_repository.dart';
import 'package:rdcoletor/local/coletor/model/product.dart';

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

class ColetorViewModel extends ChangeNotifier {
  final ProductRepository productRepository;
  Product? foundProduct;
  List<CollectedItem> collectedItems = [];
  bool isWaiting = false;

  ColetorViewModel({required this.productRepository});

  Future<void> findProduct(String barcode) async {
    isWaiting = true;
    notifyListeners();
    try {
      foundProduct = await productRepository.findProductByCode(barcode);
    } finally {
      isWaiting = false;
      notifyListeners();
    }
  }

  void addItem(CollectedItem item) {
    collectedItems.insert(0, item);
    notifyListeners();
  }

  void clearProduct() {
    foundProduct = null;
    notifyListeners();
  }
}

class Coletor extends StatefulWidget {
  const Coletor({Key? key}) : super(key: key);
  @override
  State<Coletor> createState() => _ColetorScreenState();
}

class _ColetorScreenState extends State<Coletor> {
  final _barcodeController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  late final ColetorViewModel _viewModel;
  bool _showingScanner = false;
  Timer? _debounce;
  late final BarcodeScanner _scanner;
  bool _wait = false;
  @override
  void initState() {
    super.initState();
    _viewModel = ColetorViewModel(productRepository: context.read<ProductRepository>());
    _barcodeController.addListener(_onBarcodeChanged);
    _setupScanner();
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _quantityController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onBarcodeChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _viewModel.findProduct(_barcodeController.text);
    });
  }

  void _setupScanner() {
    _scanner = BarcodeScanner(
      onDetect: (capture) => setState(() {
        _barcodeController.text = capture.barcodes.firstOrNull?.rawValue ?? '';
        _showingScanner = false;
      }),
    );
  }

  Future<void> _startScanner() async {
    _wait = true;
    setState(() => _showingScanner = true);

    await _scanner.start();
    _wait = false;
  }

  void _stopScanner() {
    _wait = true;
    setState(() => _showingScanner = false);
    _scanner.stop().then((value) => _wait = false);
  }

  void _addItemToList() {
    if (_viewModel.foundProduct == null) {
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

    _viewModel.addItem(
      CollectedItem(
        name: _viewModel.foundProduct!.name,
        code: _viewModel.foundProduct!.barcode,
        quantity: quantity,
      ),
    );

    _viewModel.clearProduct();
    _barcodeController.clear();
    _quantityController.text = '1';
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        appBar: AppBar(title: const Text('Coletor de Dados')),
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
                  child: Consumer<ColetorViewModel>(
                    builder: (context, viewModel, _) {
                      return Text(
                        viewModel.foundProduct?.name ?? 'Digite ou escaneie um código',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: viewModel.foundProduct != null ? Colors.black87 : Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Campos de entrada (Código e Quantidade)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        TextField(
                          enabled: !_showingScanner,
                          controller: _barcodeController,
                          decoration: InputDecoration(
                            labelText: 'Código de Barras',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.qr_code_scanner),
                              onPressed: _showingScanner ? _stopScanner : _startScanner,
                            ),
                          ),
                          keyboardType: TextInputType.text,
                        ),
                        if (_showingScanner)
                          SizedBox(
                            width: double.maxFinite,
                            height: 100,
                            child: _scanner,
                          ),
                      ],
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
                child: Consumer<ColetorViewModel>(
                  builder: (context, viewModel, _) {
                    return viewModel.collectedItems.isEmpty
                        ? const Center(child: Text('Nenhum item coletado ainda.'))
                        : ListView.builder(
                            itemCount: viewModel.collectedItems.length,
                            itemBuilder: (context, index) {
                              final item = viewModel.collectedItems[index];
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
                          );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Um widget para exibir o scanner de código de barras em um ModalBottomSheet.
class BarcodeScannerSheet extends StatefulWidget {
  const BarcodeScannerSheet({super.key});

  @override
  State<BarcodeScannerSheet> createState() => _BarcodeScannerSheetState();
}

class _BarcodeScannerSheetState extends State<BarcodeScannerSheet> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scannerController.start();
    if (mounted) {
      // Um zoom moderado para começar. Ajuste entre 0.0 e 1.0.
      _scannerController.setZoomScale(0.4).catchError((e) {
        debugPrint('Erro ao definir o zoom: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define a área de scan. O scanner focará seus esforços aqui.
    final scanWindow = Rect.fromCenter(
      center: MediaQuery.of(context).size.center(Offset.zero),
      width: 250,
      height: 250,
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        // Câmera em tela cheia no BottomSheet
        MobileScanner(
          // A propriedade mais importante para melhorar o foco e performance.
          scanWindow: scanWindow,
          controller: _scannerController,
          onDetect: (capture) {
            final barcode = capture.barcodes.firstOrNull?.rawValue;
            if (barcode != null) {
              // Para evitar múltiplas detecções, paramos o scanner e fechamos.
              _scannerController.stop();
              Navigator.of(context).pop(barcode);
            }
          },
          // Callback executado quando a câmera está pronta.
        ),

        // Overlay visual para guiar o usuário.
        _ScannerOverlay(scanWindow: scanWindow),

        // Controles (Fechar, Tocha)
        Positioned(
          top: 10,
          left: 10,
          right: 10,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ValueListenableBuilder<MobileScannerState>(
                valueListenable: _scannerController,
                builder: (context, state, child) {
                  if (state.torchState == TorchState.unavailable) return const SizedBox.shrink();
                  return IconButton(
                    color: Colors.white,
                    icon: Icon(state.torchState == TorchState.on ? Icons.flash_on : Icons.flash_off),
                    onPressed: () => _scannerController.toggleTorch(),
                  );
                },
              ),
              IconButton(color: Colors.white, icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
            ],
          ),
        ),
      ],
    );
  }
}

/// Desenha uma sobreposição escura ao redor da [scanWindow] para guiar o usuário.
class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay({required this.scanWindow});

  final Rect scanWindow;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ScannerPainter(scanWindow),
    );
  }
}

class _ScannerPainter extends CustomPainter {
  _ScannerPainter(this.scanWindow);

  final Rect scanWindow;
  final double borderRadius = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()..addRect(Rect.largest);
    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          scanWindow,
          topLeft: Radius.circular(borderRadius),
          topRight: Radius.circular(borderRadius),
          bottomLeft: Radius.circular(borderRadius),
          bottomRight: Radius.circular(borderRadius),
        ),
      );

    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final backgroundWithCutout = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final RRect cutoutRRect = RRect.fromRectAndCorners(
      scanWindow,
      topLeft: Radius.circular(borderRadius),
      topRight: Radius.circular(borderRadius),
      bottomLeft: Radius.circular(borderRadius),
      bottomRight: Radius.circular(borderRadius),
    );

    canvas.drawPath(backgroundWithCutout, backgroundPaint);
    canvas.drawRRect(cutoutRRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
