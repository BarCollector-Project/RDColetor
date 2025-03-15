import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

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
      home: ScannerPage(),
      theme: ThemeData(primarySwatch: Colors.blue),
    );
  }
}

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});
  @override
  QRScannerPageState createState() => QRScannerPageState();
}

class QRScannerPageState extends State<ScannerPage> {
  late WebViewController _webViewController;
  MobileScannerController _scannerController = MobileScannerController();

  bool _exibirScanner = false;

  @override
  void initState() {
    _webViewController =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageFinished: (q) {
                debugPrint("A página $q foi carregada!");
                _webViewController.runJavaScript('''
                    function simulateKeyPress(text) {
                    var targetElement = document.body;//.getElementById('guac-display') || document.querySelector('canvas');

                    //if (targetElement) {

                      var eventKeyDown = new KeyboardEvent('keydown', {
                        bubbles: true,
                        cancelable: true,
                        key: text, // Usamos 'key' para a string
                        keyCode: text.charCodeAt(0),
                        char: text
                      });
                      targetElement.dispatchEvent(eventKeyDown);

                      var eventKeyPress = new KeyboardEvent('keypress', {
                        bubbles: true,
                        cancelable: true,
                        key: text, // Usamos 'key' para a string
                        keyCode: text.charCodeAt(0),
                        char: text
                      });
                      targetElement.dispatchEvent(eventKeyPress);

                      var eventKeyUp = new KeyboardEvent('keyup', {
                        bubbles: true,
                        cancelable: true,
                        key: text, // Usamos 'key' para a string
                        keyCode: text.charCodeAt(0),
                        char: text
                      });
                      targetElement.dispatchEvent(eventKeyUp);
                    //} else {
                      console.error('Elemento alvo não encontrado.');
                    //}
                  }
                ''');
              },
            ),
          )
          ..loadRequest(Uri.parse("http://192.168.10.41:8080"));
    super.initState();
  }

  void showScanner(bool show) {
    setState(() {
      _exibirScanner = show;
    });
  }

  void sendCodeToWebView(String code) {
    //_webViewController.runJavaScript(script);
  }

  Future<void> injectKeyboardEvent(String input) async {
    // Injetar JavaScript para simular a entrada de teclado
    String jsCode = '''

      var event = new KeyboardEvent('keydown', {
        key: '$input',
        code: 'Key${input.toUpperCase()}',
        char: '$input',
        keyCode: '$input'.charCodeAt(0),
        bubbles: true
      });
      document.dispatchEvent(event);
    ''';
    _webViewController?.runJavaScript(jsCode);
  }

  Future<void> _sendSequenceToWebView(String sequence) async {
    // Itera sobre cada caractere na sequência
    for (int i = 0; i < sequence.length; i++) {
      String char = sequence[i];
      // Chama a função JavaScript, passando o caractere
      _webViewController.runJavaScript('simulateKeyPress("$char");');
      // Adiciona um atraso
      await Future.delayed(
        const Duration(milliseconds: 10),
      ); // Ajuste conforme necessário
    }
  }

  @override
  Widget build(BuildContext context) {
    final telaLargura = MediaQuery.of(context).size.width;
    final telaAltura = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(title: Text("a, troço")),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(child: WebViewWidget(controller: _webViewController)),
            Container(
              color: Colors.red,
              width: telaLargura,
              height: telaAltura * 0.15,
              child:
                  (_exibirScanner)
                      ? MobileScanner(
                        controller: _scannerController,
                        onDetect: (capture) async {
                          final List<Barcode> barcodes = capture.barcodes;
                          String? barcodeString;
                          for (final barcode in barcodes) {
                            barcodeString = barcode.rawValue;
                            if (barcodeString != null) {
                              debugPrint('Barcode found! ${barcode.rawValue}');
                              showScanner(false);
                              _scannerController.stop();
                              sendCodeToWebView(barcodeString);
                              break;
                            }
                          }
                        },
                      )
                      : ElevatedButton(
                        onPressed: () {
                          _sendSequenceToWebView("TESTEE 1234567890");
                          //showScanner(true);
                        },
                        child: Text('Iniciar Scanner'),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
