import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PathService {
  static const _dbDirectoryKey = 'database_directory_path';

  /// Salva o caminho do diretório selecionado para o banco de dados.
  Future<void> saveDatabaseDirectory(String directoryPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dbDirectoryKey, directoryPath);
  }

  /// Obtém o caminho completo para o arquivo do banco de dados, usando um diretório personalizado se disponível.
  Future<String> getDatabaseFullPath() async {
    final prefs = await SharedPreferences.getInstance();
    final customDir = prefs.getString(_dbDirectoryKey);

    if (customDir != null && customDir.isNotEmpty) {
      return join(customDir, 'rdcoletor.db');
    }
    // Caminho padrão
    return join(await getDatabasesPath(), 'rdcoletor.db');
  }
}
