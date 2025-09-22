import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rdcoletor/local/coletor/db/repository/product_repository.dart';
import 'package:barcollector_sdk/types/product/product_model.dart';

/// Um widget que encapsula a UI e a lógica para buscar produtos.
///
/// Ele gerencia seu próprio estado (texto de busca, resultados, carregamento)
/// e notifica o widget pai quando um produto é selecionado através do
/// callback [onProductSelected].
class SearchProductView extends StatefulWidget {
  /// Callback executado quando um produto é selecionado na lista.
  final ValueChanged<ProductModel> onProductSelected;

  const SearchProductView({
    super.key,
    required this.onProductSelected,
  });

  @override
  State<SearchProductView> createState() => _SearchProductViewState();
}

class _SearchProductViewState extends State<SearchProductView> {
  final _searchController = TextEditingController();
  final _debounce = _Debounce(const Duration(milliseconds: 500));

  String _searchError = '';

  // Estado do widget
  bool _isLoading = false;
  List<ProductModel> _foundProducts = [];
  String _lastSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.trim() == _lastSearchQuery) return;

    _debounce.run(() async {
      final query = _searchController.text.trim();
      _lastSearchQuery = query;

      if (query.isEmpty) {
        if (mounted) setState(() => _foundProducts = []);
        return;
      }

      if (mounted) setState(() => _isLoading = true);

      // Acessa o repositório via Provider
      final repository = context.read<ProductRepository>();
      // No backend, a busca é feita por nome, código de barras ou código interno.
      try {
        final products = await repository.searchProducts(query: query);
        if (mounted) {
          setState(() {
            _searchError = '';
            _foundProducts = products;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _searchError = e.toString().substring(e.toString().indexOf(' ') + 1);
            _foundProducts = [];
            _isLoading = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min, // Para se ajustar ao conteúdo no Dialog
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Buscar por nome ou código',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_foundProducts.isEmpty && _searchController.text.isNotEmpty)
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                _searchError.isEmpty ? 'Nenhum produto encontrado.' : _searchError,
              ),
            ),
          )
        else
          // O Flexible é importante para que a lista não tente ocupar um espaço infinito
          // dentro de um Dialog.
          Flexible(
            child: ListView.builder(
              shrinkWrap: true, // Importante para o Dialog
              itemCount: _foundProducts.length,
              itemBuilder: (context, index) {
                final product = _foundProducts[index];
                return ListTile(
                  title: Text(product.name),
                  subtitle: Text('Código: ${product.barcode}'),
                  onTap: () => widget.onProductSelected(product),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Uma classe auxiliar para adicionar um "debounce" (atraso) à execução de uma função.
/// Útil para evitar chamadas excessivas à API enquanto o usuário digita.
class _Debounce {
  final Duration delay;
  Timer? _timer;

  _Debounce(this.delay);

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

/// Exibe o [SearchProductView] como um [AlertDialog].
///
/// Retorna o [ProductModel] selecionado ou `null` se o diálogo for fechado.
Future<ProductModel?> showSearchProductDialog(BuildContext context) {
  return showDialog<ProductModel>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Buscar Produto'),
        content: SizedBox(
          width: double.maxFinite, // Faz o dialog usar a largura máxima possível
          child: SearchProductView(
            onProductSelected: (product) {
              // Fecha o dialog e retorna o produto selecionado.
              Navigator.of(dialogContext).pop(product);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fechar'),
          ),
        ],
      );
    },
  );
}
