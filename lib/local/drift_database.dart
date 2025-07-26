/// O local databasse servirá apenns para consultas de  produtos que, em algum momento, já foram sincronizados
/// Talvez seja possível, no futuro, que a sincronização ocorra uma autenticação, pois e a
/// autenticação servirá apenas para envio de informações persistentes ao banco para fins de reegistro
library;

import 'package:drift/drift.dart';

// Importa os conectores de forma condicional dependendo da plataforma.
import 'database_connection/native.dart' if (dart.library.html) 'database_connection/web.dart';

// O 'part' informa ao Drift que o código gerado estará neste arquivo.
part 'drift_database.g.dart';

/// Para evitar conflitos de nome com classes de modelo do aplicativo, "Data" é adicionado ao final
/// do nome da tabela.

// Define a tabela de produtos. O Drift gerará a classe de dados 'Product'.
@DataClassName('ProductData')
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get barcode => text().unique()();
  RealColumn get price => real()();

  @override
  Set<Column> get primaryKey => {id};
}

// A classe principal do banco de dados.
@DriftDatabase(tables: [Products])
class AppDb extends _$AppDb {
  // O construtor chama o método 'connect()' que é importado condicionalmente.
  AppDb() : super(connect());

  @override
  int get schemaVersion => 1;
}
