import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  static late final SharedPreferences _sharedPreferences;

  static Future<void> init() async {
    _sharedPreferences = await SharedPreferences.getInstance();
  }

  static String get preferCameraId => _sharedPreferences.getString('prefer_camera_id') ?? '';
  static void setPreferCamera(CameraInfo value) {
    _sharedPreferences.setString('prefer_camera_id', value.cameraId);
  }
}
