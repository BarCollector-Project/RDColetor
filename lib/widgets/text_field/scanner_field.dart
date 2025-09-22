import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:rdcoletor/features/settings/global/app_settings.dart';

class ScannerField extends StatefulWidget {
  final int timerDelayMs;
  final bool onlyDigits;
  final bool searchButton;
  final TextEditingController? controller;
  final void Function(String value) onDelay;
  final void Function()? onSearchClick;

  const ScannerField({
    super.key,
    this.controller,
    this.timerDelayMs = 500,
    this.onlyDigits = true,
    this.searchButton = true,
    this.onSearchClick,
    required this.onDelay,
  });
  @override
  State<ScannerField> createState() => _ScannerFieldState();
}

class _ScannerFieldState extends State<ScannerField> {
  // Controlhes
  late TextEditingController _controller;
  MobileScannerController cameraController = MobileScannerController(
    cameraId: AppSettings.preferCameraId,
  );

  // Estados
  bool _showingScanner = false;

  // Automatização
  Timer? _timer;

  void _timerListener() {
    _timer?.cancel();
    _timer = Timer(
      Duration(milliseconds: widget.timerDelayMs),
      () {
        widget.onDelay.call(_controller.text);
      },
    );
  }

  // Controle do escaner
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

  // Overriders

  @override
  void initState() {
    _controller = widget.controller ?? TextEditingController();
    if (widget.timerDelayMs > 0) {
      _controller.addListener(_timerListener);
    }
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext concext) {
    return Row(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              TextField(
                enabled: !_showingScanner,
                controller: _controller,
                readOnly: _showingScanner,
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
                          _controller.text = barcode!.rawValue!;
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
        SizedBox(
          width: 6.0,
        ),
        if (widget.searchButton)
          IconButton(
            onPressed: widget.onSearchClick,
            icon: Icon(Icons.search),
          ),
      ],
    );
  }
}
