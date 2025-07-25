import 'package:rdcoletor/local/database_service.dart';
import 'package:rdcoletor/local/drift_database.dart' show User;

/// O Repositório de Usuários atua como uma camada intermediária entre a
/// lógica de negócios (AuthService) e a camada de acesso a dados (DatabaseService).
/// Ele define as operações de dados necessárias para a entidade 'User'.
class UserRepository {
  // O repositório depende do DatabaseService, que é a única fonte de verdade
  // para todas as operações de banco de dados.
  final DatabaseService _databaseService;

  // A dependência é injetada via construtor, seguindo o princípio de Inversão de Dependência.
  UserRepository(this._databaseService);

  /// Encontra um usuário por nome de usuário e senha, delegando a chamada para o DatabaseService.
  Future<User?> findUserByCredentials(String username, String password) async {
    return await _databaseService.findUserByCredentials(username, password);
  }

  /// Busca todos os usuários, delegando a chamada para o DatabaseService.
  Future<List<User>> getAllUsers() async {
    return await _databaseService.getAllUsers();
  }

  /// Insere um novo usuário, delegando a chamada para o DatabaseService.
  Future<int> insertUser(User user) async {
    return await _databaseService.insertUser(user);
  }

  /// Atualiza um usuário existente, delegando a chamada para o DatabaseService.
  /// O parâmetro 'token' foi removido pois não era utilizado na lógica de banco de dados.
  Future<int> updateUser(User user) async {
    return await _databaseService.updateUser(user);
  }

  /// Deleta um usuário pelo seu ID, delegando a chamada para o DatabaseService.
  Future<int> deleteUser(String id) async {
    return await _databaseService.deleteUser(id);
  }
}
