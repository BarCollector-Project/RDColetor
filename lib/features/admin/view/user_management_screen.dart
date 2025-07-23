import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rdcoletor/local/auth/model/user.dart';
import 'package:rdcoletor/local/auth/repository/user_repository.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  late UserRepository _userRepository;
  late Future<List<User>> _usersFuture;

  @override
  void initState() {
    super.initState();

    _loadUsers();
  }

  void _loadUsers() {
    setState(() {
      _usersFuture = _userRepository.getAllUsers();
    });
  }

  void _showUserDialog(BuildContext context, {User? user}) {
    final isEditing = user != null;
    final usernameController = TextEditingController(text: user?.username);
    final passwordController = TextEditingController(); // A senha sempre é digitada novamente
    var selectedRole = user?.role ?? UserRole.common;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar Usuário' : 'Criar Usuário'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(labelText: 'Nome de usuário'),
                    ),
                    TextField(
                      controller: passwordController,
                      decoration: InputDecoration(labelText: isEditing ? 'Nova Senha (deixe em branco para não alterar)' : 'Senha'),
                      obscureText: true,
                    ),
                    DropdownButton<UserRole>(
                      value: selectedRole,
                      isExpanded: true,
                      items:
                          UserRole.values.map((role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Text(role.name),
                            );
                          }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedRole = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final username = usernameController.text;
                final password = passwordController.text;

                if (username.isEmpty || (!isEditing && password.isEmpty)) {
                  // Mostra erro se campos obrigatórios estiverem vazios
                  return;
                }

                final newUser = User(
                  id: user?.id,
                  username: username,
                  password: (isEditing && password.isEmpty) ? user.password : password,
                  role: selectedRole,
                );

                if (isEditing) {
                  await _userRepository.updateUser(newUser);
                } else {
                  await _userRepository.insertUser(newUser);
                }
                Navigator.pop(context);
                _loadUsers(); // Recarrega a lista
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _userRepository = Provider.of<UserRepository>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Usuários'),
      ),
      body: FutureBuilder<List<User>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Erro ao carregar usuários.'));
          }

          final users = snapshot.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                title: Text(user.username),
                subtitle: Text('Permissão: ${user.role.name}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showUserDialog(context, user: user),
                    ),
                    // Impede que o admin se delete
                    if (user.role != UserRole.admin)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await _userRepository.deleteUser(user.id!);
                          _loadUsers();
                        },
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
