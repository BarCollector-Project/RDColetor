import 'dart:convert';

enum UserRole {
  admin,
  common;

  // Helper para converter String do DB para Enum
  static UserRole fromString(String role) {
    return UserRole.values.firstWhere((e) => e.name == role, orElse: () => UserRole.common);
  }
}

class User {
  final String? id;
  final String username;
  final String? password;
  final UserRole role;
  String? token;

  User({
    this.id,
    required this.username,
    this.password,
    required this.role,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String?,
      username: map['username'] as String,
      password: map['password'] as String?,
      role: UserRole.fromString(map['role'] as String),
    );
  }

  factory User.fromJson(String json) {
    final Map<String, dynamic> jsonMap = jsonDecode(json) as Map<String, dynamic>;
    return User(
      id: jsonMap['id'] as String?,
      username: jsonMap['username'] as String,
      role: UserRole.fromString(jsonMap['role'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'role': role.name,
    };
  }

  /// Cria uma cópia do objeto User, permitindo a alteração de alguns campos.
  User copyWith({String? id, String? username, String? password, UserRole? role}) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
    );
  }
}
