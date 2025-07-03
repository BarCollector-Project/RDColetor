import 'package:rdcoletor/local/auth/model/user.dart';
import 'package:rdcoletor/local/database_service.dart';
import 'package:sqflite/sqflite.dart';

class UserRepository {
  final _dbService = DatabaseService();

  Future<User?> findUserByCredentials(String username, String password) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<List<User>> getAllUsers() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query('users', orderBy: 'username ASC');
    return maps.map((map) => User.fromMap(map)).toList();
  }

  Future<int> insertUser(User user) async {
    final db = await _dbService.database;
    // Retorna o ID do novo usuário inserido.
    return await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.fail);
  }

  Future<int> updateUser(User user) async {
    final db = await _dbService.database;
    // Retorna o número de linhas afetadas (deve ser 1).
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await _dbService.database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }
}
