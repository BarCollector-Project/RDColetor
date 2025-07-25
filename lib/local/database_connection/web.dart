import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:flutter/foundation.dart';

/// Obtém um executor de query para a web.
QueryExecutor connect() {
  // A nova abordagem recomendada pelo Drift para a web usa WebAssembly (WASM)
  // para rodar o SQLite diretamente no navegador, oferecendo mais performance
  // e funcionalidades.
  return LazyDatabase(() async {
    final db = await WasmDatabase.open(
      databaseName: 'barcollector-db', // Nome do arquivo do banco de dados
      sqlite3Uri: Uri.parse('/sqlite3.wasm'), // Caminho para o worker do SQLite
      driftWorkerUri: Uri.parse('/drift_worker.js'), // Caminho para o worker do Drift
    );

    if (db.missingFeatures.isNotEmpty) {
      // Informa no console se o navegador não suportar alguma feature avançada.
      debugPrint('Usando ${db.chosenImplementation} devido a features ausentes no navegador: ${db.missingFeatures}');
    }

    return db.resolvedExecutor;
  });
}
