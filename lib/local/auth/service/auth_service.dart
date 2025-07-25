import 'package:flutter/foundation.dart';
import 'package:rdcoletor/local/auth/model/user.dart' show UserRole;
import 'package:rdcoletor/local/auth/repository/user_repository.dart';
import 'package:rdcoletor/local/drift_database.dart' show User;

/// Serviço para gerenciar o estado de autenticação do usuário.
///
/// Utiliza `ChangeNotifier` para permitir que widgets na UI reajam
/// a mudanças no estado de autenticação (login/logout).
class AuthService with ChangeNotifier {
  final UserRepository _userRepository;

  // O repositório agora é injetado, não mais criado aqui dentro.
  AuthService(this._userRepository);

  User? _currentUser;
  User? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == UserRole.admin.name;

  /// Autentica as credenciais do usuário contra o repositório.
  ///
  /// Em caso de sucesso, retorna o objeto [User].
  /// Em caso de falha, lança uma [Exception].
  /// Este método **não** altera o estado de login global (`isLoggedIn`).
  Future<User> authenticate(String username, String password) async {
    debugPrint("Checando usuário $username com senha $password");
    final user = await _userRepository.findUserByCredentials(username, password);

    if (user == null) {
      throw Exception('Usuário ou senha inválidos.');
    }
    return user;
  }

  /// Finaliza o processo de login, definindo o usuário atual e notificando a UI.
  ///
  /// O `AuthWrapper` reagirá a esta chamada para navegar para a tela principal.
  void completeSignIn(User user) {
    _currentUser = user;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    notifyListeners(); // Notifica os "ouvintes" que o usuário fez logout.
  }

  /// Atualiza as credenciais do usuário logado e atualiza o estado local.
  Future<void> updateUserCredentials({String? newUsername, String? newPassword}) async {
    if (_currentUser == null) return;

    final updatedUser = _currentUser!.copyWith(
      username: newUsername ?? _currentUser!.username,
      password: newPassword ?? _currentUser!.password,
    );

    // O método updateUser no repositório não precisa mais do token.
    await _userRepository.updateUser(updatedUser);
    _currentUser = updatedUser;
    notifyListeners();
  }
}
