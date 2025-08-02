import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:rdcoletor/features/settings/global/app_settings.dart';

/// Um widget que encapsula a UI do scanner de código de barras,
/// incluindo a sobreposição visual para guiar o usuário.
///
/// Este widget é stateless e espera receber um [controller] e um callback [onDetect]
/// para ser controlado pelo widget pai.
class BarcodeScanner extends StatelessWidget {
  BarcodeScanner({
    super.key,
    required this.onDetect,
    this.scanWindow,
  });

  /// O controlador para o [MobileScanner].
  final MobileScannerController controller = MobileScannerController(
    autoStart: false,
    cameraId: AppSettings.preferCameraId,
  );

  /// O callback que é chamado quando um código de barras é detectado.
  final void Function(BarcodeCapture capture) onDetect;

  /// A área retangular na qual o scanner deve focar. Se nulo, o scanner
  /// usará a tela inteira. Fornecer um [scanWindow] melhora a performance.
  final Rect? scanWindow;

  Future<void> start() async => controller.start();

  Future<void> stop() async => controller.stop();

  void dispose() async {
    await stop();
    await controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Define a área de scan padrão se nenhuma for fornecida.
    final Rect effectiveScanWindow = scanWindow ??
        Rect.fromCenter(
          center: MediaQuery.of(context).size.center(Offset.zero),
          width: 250,
          height: 250,
        );

    return Stack(
      alignment: Alignment.center,
      children: [
        // Câmera em tela cheia
        MobileScanner(
          controller: controller,
          onDetect: onDetect,
          // A propriedade mais importante para melhorar o foco e performance.
          scanWindow: effectiveScanWindow,
        ),

        // Overlay visual para guiar o usuário.
        ScannerOverlay(scanWindow: effectiveScanWindow),

        // Controles (Tocha) - O botão de fechar pode ser adicionado pelo widget pai
        // que usa este scanner, para maior flexibilidade.
        Positioned(
          top: 10,
          left: 10,
          child: ValueListenableBuilder<MobileScannerState>(
            valueListenable: controller,
            builder: (context, state, child) {
              if (state.torchState == TorchState.unavailable) {
                return const SizedBox.shrink();
              }
              return IconButton(
                color: Colors.white,
                icon: Icon(
                  state.torchState == TorchState.on ? Icons.flash_on : Icons.flash_off,
                ),
                onPressed: () => controller.toggleTorch(),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Desenha uma sobreposição escura ao redor da [scanWindow] para guiar o usuário.
class ScannerOverlay extends StatelessWidget {
  const ScannerOverlay({super.key, required this.scanWindow});

  final Rect scanWindow;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ScannerPainter(scanWindow),
    );
  }
}

class ScannerPainter extends CustomPainter {
  ScannerPainter(this.scanWindow);

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
