import 'package:drift/drift.dart';

// Importa os conectores de forma condicional dependendo da plataforma.
import 'database_connection/native.dart' if (dart.library.html) 'database_connection/web.dart';

// O 'part' informa ao Drift que o código gerado estará neste arquivo.
part 'drift_database.g.dart';

// Define a tabela de produtos. O Drift gerará a classe de dados 'Product'.
@DataClassName('Product')
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get barcode => text().unique()();
  RealColumn get price => real()();

  @override
  Set<Column> get primaryKey => {id};
}

// Define a tabela de usuários. O Drift gerará a classe de dados 'User'.
@DataClassName('User')
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get username => text().unique()();
  TextColumn get password => text()();
  TextColumn get name => text()();
  TextColumn get role => text()();

  @override
  Set<Column> get primaryKey => {id};
}

// A classe principal do banco de dados.
@DriftDatabase(tables: [Products, Users])
class AppDb extends _$AppDb {
  // O construtor chama o método 'connect()' que é importado condicionalmente.
  AppDb() : super(connect());

  @override
  int get schemaVersion => 1;
}
