import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:rdcoletor/local/coletor/db/repository/product_repository.dart';
import 'package:rdcoletor/local/coletor/model/product.dart';

class Importer {
  final ProductRepository _productRepository = ProductRepository();

  //Os CSV é gerado pela rotina RELATORIOS>PRODUTOS, assim gravar o relatório no formato CSV.
  Future<int> importFromSGLinearCSV(File csv) async {
    if (await csv.exists()) {
      try {
        final String csvContent = await csv.readAsString();
        final List<List<dynamic>> rowOnCsv = const CsvToListConverter(
          fieldDelimiter: ",",
          eol: "\n",
        ).convert(csvContent);
        final List<Product> productsToImport = [];

        for (var csvRowData in rowOnCsv) {
          if (csvRowData.length > 20) {
            var productInternalCode = csvRowData[20];
            if (productInternalCode.toString().length == 6) {
              final product = Product.fromMap({
                'codigo': csvRowData[21].toString(),
                'nome': csvRowData[22].toString(),
                'preco': csvRowData[31],
              });
              productsToImport.add(product);
            }
          }
        }
        await _productRepository.insertProducts(productsToImport);
        return productsToImport.length;
      } catch (e) {
        debugPrint("Ocorreu um erro ao import o CSV: $e");
      }
    }
    return 0;
  }
}
