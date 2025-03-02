import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  runApp(const Main());
}

class Main extends StatelessWidget {
  const Main({super.key});
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: QRScannerPage(),
      theme: ThemeData(primarySwatch: Colors.blue),
    );
  }
}

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});
  @override
  QRScannerPageState createState() => QRScannerPageState();
}

class QRScannerPageState extends State<QRScannerPage> {
  late final WebViewController _webviewController;

  bool _isInitialized = false;
  String? _qrCode = "Nenhum QR Code detectado";

  bool _exibirScanner = false;
  String _codigoBarras = '';

  Future<void> _scanBarcode() async {
    String barcodeScanRes;
  }

  // Função para iniciar a câmera
  void _startCamera() {}

  // Função para alternar o foco manual
  void _focus() async {}

  @override
  void initState() {
    _webviewController =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(Uri.parse('http://192.168.10.41:8080'));
    super.initState();
  }

  void showScanner(bool show) {
    setState(() {
      _exibirScanner = show;
    });
  }

  @override
  Widget build(BuildContext context) {
    final telaLargura = MediaQuery.of(context).size.width;
    final telaAltura = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(title: Text("a, troço")),
      body: Column(
        children: <Widget>[
          Expanded(child: WebViewWidget(controller: _webviewController)),
          Container(
            color: Colors.red,
            width: telaLargura,
            height: telaAltura * 0.15,
            child:
                (_exibirScanner)
                    ? MobileScanner(
                      onDetect: (capture) {
                        final List<Barcode> barcodes = capture.barcodes;
                        for (final barcode in barcodes) {
                          debugPrint('Barcode found! ${barcode.rawValue}');
                          print(barcode);
                        }
                      },
                    )
                    : Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          showScanner(true);
                        },
                        child: Text('Iniciar Scanner'),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
