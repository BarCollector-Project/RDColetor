import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:js_interop';

// Points to the same global object as window
/*@JS('globalThis')
external JSObject get globalThis;
*/

extension type DSBarcodeError(JSObject _) implements JSObject {
  external String name;
  external String message;
}

extension type DSBarcodeResultCoord(JSObject _) implements JSObject {
  external int x;
  external int y;
}

extension type DSBarcodeResult(JSObject _) implements JSObject {
  external int bt;
  external String type;
  external JSInt8Array data;
  external String strdata;
  external JSArray<DSBarcodeResultCoord> points;
  external bool barcodeAtPoint;
  external bool previouslyDecoded;
}

@JS()
external void embedScanner(int x, int y, int width, int height);
//external void embedScanner(JSFunction drCallback, int x, int y, int width, int height);

@JS()
external void updateScannerPos(int x, int y, int width, int height);

@JS()
external void destroyScanner();

@JS()
external void addScannerCallback(JSString funcName, JSFunction dsFuncCallback);

class BarcodeScannerWidget extends StatefulWidget {
  final double width;
  final double height;
  final void Function(String barcode) onBarcodeScanned;
  final void Function(String error) onError;

  const BarcodeScannerWidget({
    super.key,
    required this.width,
    required this.height,
    required this.onBarcodeScanned,
    required this.onError,
  });

  @override
  State<BarcodeScannerWidget> createState() => _BarcodeScannerWidgetState();
}

class _BarcodeScannerWidgetState extends State<BarcodeScannerWidget> with WidgetsBindingObserver {
  final GlobalKey _key = GlobalKey();
  bool _isScannerInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Garante que o scanner seja inicializado após o primeiro frame ser renderizado.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeScanner());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Chama a função JS para limpar os recursos do scanner.
    destroyScanner();
    super.dispose();
  }

  /// Lida com o redimensionamento da janela para atualizar a posição do scanner.
  @override
  void didChangeMetrics() {
    // Adiciona um callback para ser executado após o frame ser redesenhado.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isScannerInitialized || !mounted) return;
      final rc = _getBarcodeViewBox();
      updateScannerPos(
        rc.left.toInt(),
        rc.top.toInt(),
        rc.width.toInt(),
        rc.height.toInt(),
      );
    });
  }

  /// Obtém as dimensões e a posição do widget na tela.
  Rectangle<int> _getBarcodeViewBox() {
    if (_key.currentContext == null) {
      return const Rectangle(0, 0, 0, 0);
    }
    final RenderBox renderBox = _key.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    return Rectangle(
      position.dx.toInt(),
      position.dy.toInt(),
      renderBox.size.width.toInt(),
      renderBox.size.height.toInt(),
    );
  }

  /// Inicializa o scanner de código de barras.
  void _initializeScanner() {
    if (_isScannerInitialized || !mounted) return;
    _isScannerInitialized = true;

    // Converte os callbacks do Dart para funções que o JS pode chamar.
    final jsOnBarcode = (DSBarcodeResult dr) {
      widget.onBarcodeScanned(dr.strdata);
    }.toJS;

    final jsOnError = (DSBarcodeError err) {
      widget.onError('${err.name}, ${err.message}');
    }.toJS;

    // Registra os callbacks na biblioteca JS.
    addScannerCallback('onBarcode'.toJS, jsOnBarcode);
    addScannerCallback('onError'.toJS, jsOnError);

    // Obtém as dimensões e incorpora o scanner.
    final rc = _getBarcodeViewBox();
    embedScanner(
      rc.left.toInt(),
      rc.top.toInt(),
      rc.width.toInt(),
      rc.height.toInt(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: _key,
      width: widget.width,
      height: widget.height,
      child: const Center(child: Text('Barcode Scanner Loading ...')),
    );
  }
}
