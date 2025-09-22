import 'dart:async';

import 'package:barcollector_sdk/types/product/product_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:rdcoletor/features/settings/global/app_settings.dart';
import 'package:rdcoletor/local/coletor/db/repository/product_repository.dart';
import 'package:rdcoletor/features/coletor/models/collect_register.dart';
import 'package:rdcoletor/local/database/repositories/types/system_tables.dart';

class ColetorViewModel extends ChangeNotifier {
  final ProductRepository productRepository;
  ProductModel? foundProduct;
  List<CollectedItem> collectedItems;
  bool isWaiting = false;

  /// Forneça [collectedItems] caso for editar um registro
  /// Do contrário, será criado um novo vazio
  ColetorViewModel({required this.productRepository, this.collectedItems = const []});

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

/// Cria uma nova tela para coletagem de produtos
/// Retornar uma [List<CollectedItem>] caso não seja fornecido um e for usado um botão "Salvar".
/// Retornar [true] caso [List<CollectedItem>] for fornecido e o botão "Salvar" for usado
/// Retorna [null] (Comportamento padrão) caso o usuário toque em "Cancelar".
class CollectScreen extends StatefulWidget {
  final List<CollectedItem>? registerCollectedItems;
  const CollectScreen({super.key, this.registerCollectedItems});

  @override
  State<CollectScreen> createState() => _CollectScreenState();
}

class _CollectScreenState extends State<CollectScreen> {
  // Indetificação da coleta
  Reason? reason;
  Origin? origin;

  final _barcodeController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  late final ColetorViewModel _viewModel;
  bool _showingScanner = false;
  Timer? _debounce;

  MobileScannerController cameraController = MobileScannerController(
    cameraId: AppSettings.preferCameraId,
  );

  @override
  void initState() {
    super.initState();
    _viewModel = ColetorViewModel(
      productRepository: context.read<ProductRepository>(),
      collectedItems: widget.registerCollectedItems ?? [],
    );
    _barcodeController.addListener(_onBarcodeChanged);
    _setupScanner();
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _quantityController.dispose();
    _debounce?.cancel();
    cameraController.dispose();
    super.dispose();
  }

  void _onBarcodeChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _viewModel.findProduct(_barcodeController.text);
    });
  }

  void _setupScanner() {}

  void _startScanner() {
    setState(() {
      _showingScanner = true;
    });
    cameraController.start();
  }

  void _stopScanner() {
    setState(() {
      _showingScanner = false;
    });
    cameraController.stop();
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

    if (reason == null || origin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione a origem e o motivo da coleta.')),
      );
      return;
    }

    _viewModel.addItem(
      CollectedItem(
        name: _viewModel.foundProduct!.name,
        code: _viewModel.foundProduct!.barcode,
        quantity: quantity,
        reason: reason!,
        origin: origin!,
      ),
    );

    _viewModel.clearProduct();
    _barcodeController.clear();
    _quantityController.text = '1';
    FocusScope.of(context).unfocus();
  }

  void save() {
    Navigator.pop(
      context,
      widget.registerCollectedItems != null ? _viewModel.collectedItems : true,
    );
  }

  void cancel() {
    Navigator.pop(context);
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
                      return _viewModel.isWaiting
                          ? const CircularProgressIndicator()
                          : Text(
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
                      alignment: Alignment.centerRight,
                      children: [
                        TextField(
                          enabled: !_showingScanner,
                          controller: _barcodeController,
                          decoration: const InputDecoration(
                            labelText: 'Código de Barras',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        if (_showingScanner)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4.0),
                              child: MobileScanner(
                                controller: cameraController,
                                onDetect: (capture) {
                                  final barcode = capture.barcodes.firstOrNull;
                                  if (barcode?.rawValue != null) {
                                    _barcodeController.text = barcode!.rawValue!;
                                    _stopScanner();
                                  }
                                },
                              ),
                            ),
                          ),
                        IconButton(
                          icon: Icon(_showingScanner ? Icons.close : Icons.barcode_reader),
                          onPressed: _showingScanner ? _stopScanner : _startScanner,
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
              const Divider(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: save,
                      child: const Text('Salvar'),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: cancel,
                      child: const Text('Cancelar'),
                    ),
                  ),
                ],
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
