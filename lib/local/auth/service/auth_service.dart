import 'package:flutter/foundation.dart';
import 'package:rdcoletor/local/auth/model/user.dart';
import 'package:rdcoletor/local/auth/repository/user_repository.dart';

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
  bool get isAdmin => _currentUser?.role == UserRole.admin;

  Future<bool> login(String username, String password) async {
    // NOTA: Em um app real, a senha `password` seria transformada em hash
    // antes de ser comparada no banco de dados.
    debugPrint("Checando usuário $username com senha $password");
    final user = await _userRepository.findUserByCredentials(username, password);

    if (user != null) {
      _currentUser = user;
      notifyListeners(); // Notifica os "ouvintes" (widgets) que o estado mudou.
      return true;
    }
    return false;
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
