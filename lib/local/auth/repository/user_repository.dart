import 'package:rdcoletor/local/auth/model/user.dart';
import 'package:rdcoletor/local/app_database.dart';
import 'package:sqflite/sqflite.dart';

class UserRepository {
  // Agora o repositório depende da abstração, não da implementação concreta.
  final AppDatabase _appDatabase;

  // A dependência é injetada pelo construtor.
  UserRepository(this._appDatabase);

  Future<User?> findUserByCredentials(String username, String password) async {
    final List<Map<String, dynamic>> maps = await _appDatabase.query(
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
    final List<Map<String, dynamic>> maps = await _appDatabase.query('users', orderBy: 'username ASC');
    return maps.map((map) => User.fromMap(map)).toList();
  }

  Future<int> insertUser(User user) async {
    // Retorna o ID do novo usuário inserido.
    return await _appDatabase.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.fail);
  }

  Future<int> updateUser(User user) async {
    // Retorna o número de linhas afetadas (deve ser 1).
    return await _appDatabase.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    return await _appDatabase.delete('users', where: 'id = ?', whereArgs: [id]);
  }
}
