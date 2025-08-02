import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:rdcoletor/features/settings/global/app_settings.dart';

import 'package:web/web.dart' hide Navigator, Text;

class CameraSettings extends StatefulWidget {
  const CameraSettings({super.key});

  @override
  State<CameraSettings> createState() => _CameraSettingsState();
}

class _CameraSettingsState extends State<CameraSettings> {
  MobileScannerController? _scannerController;

  List<CameraInfo> _cameras = [];
  String? _selectedCameraId;
  bool _isLoading = true;

  String rawBarcode = '';

  @override
  void initState() {
    super.initState();
    _initializeCameras();
  }

  Future<void> setCamera([String? cameraId]) async {
    setState(() => _isLoading = true);
    await Future.delayed(Duration.zero);

    await _scannerController?.dispose();
    _scannerController = null;

    _scannerController = MobileScannerController(
      autoStart: false,
      cameraId: cameraId,
    );

    setState(() {
      _selectedCameraId = cameraId;
      _isLoading = false;
    });

    await Future.delayed(Duration.zero);

    await _scannerController?.start();
  }

  Future<void> _initializeCameras() async {
    final camerasFromScanner = await MobileScannerController(autoStart: false).getAvailableCameras();
    final preferredId = AppSettings.preferCameraId;

    debugPrint("preferredId: $preferredId");

    _cameras = camerasFromScanner;
    // Se um ID preferido existe e está na lista, use-o.
    // Senão, use a primeira câmera da lista (geralmente a traseira).
    if (preferredId.isNotEmpty && _cameras.any((c) => c.cameraId == preferredId)) {
      debugPrint("usando Camera preferida");
      await setCamera(preferredId);
    } else if (_cameras.isNotEmpty) {
      debugPrint("usando primeira Camera detectada");
      await setCamera(_cameras.first.cameraId);
    } else {
      debugPrint("usando Camera detectada padrão");
      _selectedCameraId = '';
      await setCamera();
    }
  }

  @override
  Future<void> dispose() async {
    console.log('dispose'.toJS);
    super.dispose();
    await _scannerController?.dispose();
    _scannerController = null;
  }

  void _saveAndExit() {
    if (_selectedCameraId != null) {
      final selectedCamera = _cameras.firstWhere((c) => c.cameraId == _selectedCameraId);
      AppSettings.setPreferCamera(selectedCamera);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuração da Câmera'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    rawBarcode.isEmpty ? 'Tente escanear um código de barras' : 'Código de barras: $rawBarcode',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: MobileScanner(
                    controller: _scannerController,
                    onDetect: (barcode) {
                      setState(() => rawBarcode = barcode.barcodes.first.rawValue ?? '');
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _selectedCameraId?.isEmpty ?? true ? 'Não há câmeras disponíveis' : 'Selecione uma câmera',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _cameras.length,
                    itemBuilder: (context, index) {
                      final camera = _cameras[index];
                      return RadioListTile<String>(
                        title: Text(camera.name),
                        value: camera.cameraId,
                        groupValue: _selectedCameraId,
                        onChanged: (value) {
                          if (value == null) return;
                          setCamera(value);
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
                      const SizedBox(width: 8),
                      ElevatedButton(onPressed: _saveAndExit, child: const Text('Salvar')),
                    ],
                  ),
                )
              ],
            ),
    );
  }
}
