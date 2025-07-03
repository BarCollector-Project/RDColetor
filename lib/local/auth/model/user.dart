enum UserRole {
  admin,
  common;

  // Helper para converter String do DB para Enum
  static UserRole fromString(String role) {
    return UserRole.values.firstWhere((e) => e.name == role, orElse: () => UserRole.common);
  }
}

class User {
  final int? id;
  final String username;
  final String password; // Em um app real, isso deve ser um hash!
  final UserRole role;

  User({
    this.id,
    required this.username,
    required this.password,
    required this.role,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      username: map['username'] as String,
      password: map['password'] as String,
      role: UserRole.fromString(map['role'] as String),
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
  User copyWith({
    int? id,
    String? username,
    String? password,
    UserRole? role,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
    );
  }
}
