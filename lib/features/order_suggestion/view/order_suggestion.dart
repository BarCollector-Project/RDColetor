import 'package:barcollector_sdk/barcollector_sdk.dart';
import 'package:flutter/material.dart';
import 'package:rdcoletor/local/coletor/db/repository/product_repository.dart';
import 'package:rdcoletor/local/coletor/model/product.dart';
import 'package:provider/provider.dart';
import 'package:rdcoletor/local/database/repositories/data_models/product_suggestion.dart';
import 'package:rdcoletor/local/database/repositories/supplier_repository.dart';
import 'package:rdcoletor/local/database_service.dart';
import 'package:rdcoletor/widgets/text_field/scanner_field.dart';

class OrderSuggestion extends StatefulWidget {
  const OrderSuggestion({super.key});

  @override
  State<OrderSuggestion> createState() => _OrderSuggestionState();
}

class _ProductSuggestions extends ChangeNotifier {
  final List<ProductSuggestion> _productsSuggestion = [];
  get suggestions => _productsSuggestion;

  List<ProductSuggestion> get productsSuggestion => _productsSuggestion;

  void addProductSuggestion(ProductSuggestion productSuggestion) {
    _productsSuggestion.add(productSuggestion);
    notifyListeners();
  }

  void removeProductSuggestion(int index) {
    _productsSuggestion.removeAt(index);
    notifyListeners();
  }
}

class _Product extends ChangeNotifier {
  ProductModel? _product;
  get product => _product;

  void setProduct(ProductModel? product) {
    if (_product != product) {
      _product = product;
      notifyListeners();
    }
  }
}

class _OrderSuggestionState extends State<OrderSuggestion> {
  final SupplierModel _noSupplier = SupplierModel(id: 0, nome: 'NÃO DEFINIDO');
  // Repositórios
  late ProductRepository _productRepository;
  late SupplierRepository _supplierRepository;

  // Dados dinâmicos
  late _ProductSuggestions _productSuggestions;
  late _Product _product;

  // Exportação
  void _generatePdf() {}

  // Widget flutuantes
  void _search() async {}

  // Builder de widget
  void _deleteSuggestion(ProductSuggestion suggestion) {
    _productSuggestions.removeProductSuggestion(
      _productSuggestions.productsSuggestion.indexOf(suggestion),
    );
  }

  Widget _buildSugestionItemList(ProductSuggestion suggestion) {
    return Card(
      child: InkWell(
        child: Row(
          children: [
            // Product info
            Column(
              children: [
                Text(suggestion.product.name),
                Text('Fornecedor: ${suggestion.supplierName}'),
              ],
            ),
            // Actions
            Column(
              children: [
                IconButton(
                  onPressed: () => _deleteSuggestion(suggestion),
                  icon: Icon(Icons.delete),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final db = context.read<DatabaseService>();
    _productRepository = ProductRepository(db);
    _supplierRepository = SupplierRepository(db: db);
    _productSuggestions = _ProductSuggestions();
    _product = _Product();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Suggestion'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_sharp),
            onPressed: _generatePdf,
          ),
        ],
      ),
      body: Column(
        children: [
          ListenableBuilder(
            listenable: _product,
            builder: (context, child) => Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey,
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(10.0),
                color: ThemeData.from(colorScheme: ColorScheme.of(context)).scaffoldBackgroundColor,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                ScannerField(
                  onDelay: (value) async {
                    if (value.isEmpty) return;
                    _product.setProduct(await _productRepository.findProductByCode(value));
                  },
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  onPressed: _search,
                  icon: Icon(Icons.search),
                ),
              ],
            ),
          ),
          ListenableBuilder(
            listenable: _productSuggestions,
            builder: (context, child) {
              return Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    child!,
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        itemBuilder: (context, index) {
                          return _buildSugestionItemList(_productSuggestions.productsSuggestion[index]);
                        },
                        itemCount: _productSuggestions.productsSuggestion.length,
                      ),
                    ),
                  ],
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Itens sugeridos'),
            ),
          ),
        ],
      ),
    );
  }
}
