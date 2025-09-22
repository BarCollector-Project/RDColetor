import 'package:barcollector_sdk/types/product/product_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rdcoletor/local/coletor/db/repository/product_repository.dart';
import 'package:rdcoletor/local/coletor/model/product.dart';

class Products extends StatefulWidget {
  const Products({super.key});

  @override
  State<Products> createState() => _ProductsState();
}

class _ProductsState extends State<Products> {
  late final ProductRepository _productRepository;
  final TextEditingController _searchController = TextEditingController();

  late Future<List<ProductModel>> _productsFuture;
  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _productRepository = Provider.of<ProductRepository>(context, listen: false);
    _productsFuture = _loadProducts();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<ProductModel>> _loadProducts() async {
    final products = await _productRepository.getProducts();
    setState(() {
      _allProducts = products;
      _filteredProducts = products;
    });
    return products;
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        final nameMatches = product.name.toLowerCase().contains(query);
        final codeMatches = product.barcode.toLowerCase().contains(query);
        return nameMatches || codeMatches;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Produtos"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Buscar por nome ou código',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ProductModel>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Erro ao carregar produtos: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Nenhum produto encontrado.'));
                }

                if (_filteredProducts.isEmpty && _searchController.text.isNotEmpty) {
                  return const Center(child: Text('Nenhum produto corresponde à busca.'));
                }

                return ListView.builder(
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = _filteredProducts[index];
                    return ListTile(
                      title: Text(product.name),
                      subtitle: Text('Código: ${product.barcode}'),
                      trailing: Text('R\$ ${product.price?.toStringAsFixed(2)}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
