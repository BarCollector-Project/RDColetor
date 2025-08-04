import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:rdcoletor/features/settings/global/app_settings.dart';

class CameraSettings extends StatefulWidget {
  const CameraSettings({super.key});

  @override
  State<CameraSettings> createState() => _CameraSettingsState();
}

class _CameraSettingsState extends State<CameraSettings> {
  late MobileScannerController _scannerController;

  List<CameraInfo> _cameras = [];
  String? _selectedCameraId;
  bool _isLoading = true;

  String rawBarcode = '';

  @override
  void initState() {
    super.initState();
    // Inicializa com um controlador padrão. Ele será substituído em _initializeCameras.
    _scannerController = MobileScannerController(
      autoStart: false,
    );
    _initializeAndStartCamera();
  }

  /// Troca a câmera ativa, descartando o controlador antigo e criando um novo.
  Future<void> _setCamera(String? cameraId) async {
    setState(() => _isLoading = true);

    await Future<void>.delayed(Duration.zero);

    await _scannerController.dispose();

    _scannerController = MobileScannerController(
      autoStart: false,
      cameraId: cameraId,
    );

    if (mounted) {
      setState(() {
        _selectedCameraId = cameraId;
        _isLoading = false;
      });
    }

    await Future<void>.delayed(Duration.zero);
    await _scannerController.start();
  }

  /// Busca as câmeras disponíveis e inicia a câmera preferida ou a primeira da lista.
  Future<void> _initializeAndStartCamera() async {
    _cameras = await MobileScannerController(autoStart: false).getAvailableCameras();
    final preferredId = AppSettings.preferCameraId;
    String? initialCameraId;

    // Se um ID preferido existe e está na lista, use-o.
    // Senão, use a primeira câmera da lista (geralmente a traseira).
    if (preferredId.isNotEmpty && _cameras.any((c) => c.cameraId == preferredId)) {
      initialCameraId = preferredId;
    } else if (_cameras.isNotEmpty) {
      initialCameraId = _cameras.first.cameraId;
    } else {
      initialCameraId = null;
    }

    // Descarta o controlador antigo e cria um novo com a câmera correta.
    // O setState vai reconstruir o widget MobileScanner, que iniciará a câmera automaticamente.
    await _scannerController.dispose();
    setState(() {
      _scannerController = MobileScannerController(cameraId: initialCameraId);
      _selectedCameraId = initialCameraId;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _saveAndExit() {
    if (_selectedCameraId != null && _cameras.isNotEmpty) {
      // Garante que a câmera selecionada ainda existe antes de salvar.
      final selectedCamera = _cameras.firstWhere(
        (c) => c.cameraId == _selectedCameraId,
        orElse: () => _cameras.first,
      );
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
                          if (value == null || value == _selectedCameraId) return;
                          _setCamera(value);
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
