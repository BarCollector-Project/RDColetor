import 'package:barcollector_sdk/barcollector_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:rdcoletor/database/repository/order_suggestion/order_suggestion_repository.dart';
import 'package:rdcoletor/database/repository/order_suggestion/types/order_suggestion.dart';
import 'package:rdcoletor/local/coletor/db/repository/product_repository.dart';
import 'package:rdcoletor/local/database/repositories/data_models/product_suggestion.dart';
import 'package:rdcoletor/local/database/repositories/supplier_repository.dart';
import 'package:rdcoletor/local/database_service.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:rdcoletor/widgets/alert_dialog/search_product.dart';
import 'package:rdcoletor/widgets/text_field/scanner_field.dart';

class OrderSuggestionScreen extends StatefulWidget {
  const OrderSuggestionScreen({super.key});

  @override
  State<OrderSuggestionScreen> createState() => _OrderSuggestionState();
}

class OrderSuggestions extends ChangeNotifier {
  bool _newOrder = false;
  bool get newOrder => _newOrder;

  String? _messageError;
  String? get messageError {
    if (_messageError == null) return null;
    final message = _messageError;
    _messageError = null;
    return message;
  }

  void _setMessageError(Object? exception) {
    if (exception is String) {
      _messageError = exception;
    } else if (exception is ClientException) {
      _messageError = 'Falha ao se conectar ao servidor. Contate o administrador!';
    } else if (exception is Exception) {
      _messageError = 'Ocoreu uma falha ao obter a lista de produtos. Contate o administrador!';
    } else {
      _messageError = 'Ocorreu um erro desconhecido. Contate o administrador! ${exception.toString()}';
    }
  }

  final SupplierModel _noSupplier = SupplierModel(id: 0, nome: 'NÃO DEFINIDO', cpf: '');
  OrderSuggestion? _selected;
  List<OrderSuggestion> orders = [];

  final OrderSuggestionRepository orderSuggestionRepository;

  final List<ProductSuggestion> _productsSuggestion = [];
  bool _isLoading = false;

  OrderSuggestion? get selectedOrder => _selected;
  bool get isLoading => _isLoading;
  final ProductRepository productRepository;
  final SupplierRepository supplierRepository;

  List<ProductSuggestion> get productsSuggestion => _productsSuggestion;

  OrderSuggestions._({
    required this.orderSuggestionRepository,
    required this.productRepository,
    required this.supplierRepository,
  });

  // Builder de widget
  String _formatDocument(String document) {
    if (document.isEmpty) {
      return '';
    }
    // CPF format: 000.000.000-00
    if (document.length == 11) {
      return '${document.substring(0, 3)}.${document.substring(3, 6)}.${document.substring(6, 9)}-${document.substring(9)}';
    }
    // CNPJ format: 00.000.000/0000-00
    if (document.length == 14) {
      return '${document.substring(0, 2)}.${document.substring(2, 5)}.${document.substring(5, 8)}/${document.substring(8, 12)}-${document.substring(12)}';
    }
    return document;
  }

  Future<void> _updateListProducts() async {
    if (_selected == null) {
      _productsSuggestion.clear();
    } else if (_selected!.products != null && _selected!.products!.isNotEmpty) {
      _productsSuggestion.clear(); // Limpa antes de adicionar novos
      for (final product in _selected!.products!) {
        try {
          final result = await productRepository.getProductDetails(product['prod_id'], []);
          final supplier = await supplierRepository.findSupplierById(result.defaultSuppierId ?? 0);
          final suggestion = ProductSuggestion(
            product: result,
            quantitySuggestion: product['quantity'],
            supplierName: supplier?.nome ?? _noSupplier.nome,
            supplierRegistration: _formatDocument(
              supplier?.cnpj ?? supplier?.cpf ?? _noSupplier.cnpj ?? _noSupplier.cpf ?? '',
            ),
          );
          _productsSuggestion.add(suggestion);
        } catch (e, s) {
          debugPrint('$s');
        }
      }
    }
    notifyListeners();
  }

  Future<void> updateOrderSuggestionList({int days = 7}) async {
    _isLoading = true;
    notifyListeners();
    try {
      orders = await orderSuggestionRepository.getOrderSuggestionsList(days: days);
      if (_selected != null && !orders.any((o) => o.orderId == _selected!.orderId)) {
        clearSelection();
      }
    } catch (e) {
      _setMessageError(e);
      debugPrint(e.toString());
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<CommandStatus> _handleNewOrderProductAddition(ProductModel product, double quantity) async {
    final newOrderSuggestion = await orderSuggestionRepository.putNew(
      companyId: _selected!.companyId,
      productId: product.id,
      quantity: quantity,
    );

    if (newOrderSuggestion == null) {
      return CommandStatus.createFailed;
    }

    _selected = newOrderSuggestion;
    _newOrder = false;
    await _updateListProducts(); // Atualiza a lista a partir do pedido recém-criado
    return CommandStatus.ok;
  }

  Future<CommandStatus> _handleExistingOrderProductAddition(ProductModel product, double quantity, {bool replace = false, int? indexOf}) async {
    final putResult = await orderSuggestionRepository.putOrderSuggestion(
      orderId: _selected!.orderId,
      companyId: _selected!.companyId,
      timestamp: _selected!.createdAt,
      productId: product.id,
      quantity: quantity,
      status: _selected!.status,
      replace: replace,
    );

    if (putResult == CommandStatus.ok) {
      await _updateLocalProductList(product, quantity, indexOf: indexOf);
    }

    return putResult;
  }

  Future<void> _updateLocalProductList(ProductModel product, double quantity, {int? indexOf}) async {
    // Se um índice válido foi fornecido, atualiza o item existente.
    if (indexOf != null && indexOf >= 0 && indexOf < _productsSuggestion.length) {
      _productsSuggestion[indexOf] = _productsSuggestion[indexOf].copyWith(quantitySuggestion: quantity);
    } else {
      // Caso contrário, busca os dados do fornecedor e adiciona um novo item.
      final supplier = await supplierRepository.findSupplierById(product.defaultSuppierId ?? 0);
      final newSuggestion = ProductSuggestion(
        product: product,
        quantitySuggestion: quantity,
        supplierName: supplier?.nome ?? 'NÃO DEFINIDO',
        supplierRegistration: _formatDocument(supplier?.cnpj ?? supplier?.cpf ?? ''),
      );
      _productsSuggestion.add(newSuggestion);
    }
    notifyListeners();
  }

  Future<CommandStatus> addProductSuggestion(ProductModel product, double quantity, {bool replace = false}) async {
    if (_selected == null && !newOrder) {
      return CommandStatus.fail;
    } else if (_selected!.status > 0) {
      return CommandStatus.closed;
    }

    if (newOrder) {
      return _handleNewOrderProductAddition(product, quantity);
    }

    final existingIndex = _productsSuggestion.indexWhere((p) => p.product.id == product.id);
    return _handleExistingOrderProductAddition(product, quantity, replace: replace, indexOf: existingIndex > -1 ? existingIndex : null);
  }

  Future<CommandStatus> removeProductSuggestion(ProductSuggestion productSuggestion) async {
    if (!_productsSuggestion.contains(productSuggestion) && _selected == null) {
      return CommandStatus.fail;
    } else if (_selected!.status > 0) {
      return CommandStatus.closed;
    }
    final result = await orderSuggestionRepository.removeOrderSuggestion(
      orderId: _selected!.orderId,
      companyId: _selected!.companyId,
      timestamp: _selected!.createdAt,
      productId: productSuggestion.product.id,
    );
    if (result == CommandStatus.ok) {
      _productsSuggestion.remove(productSuggestion);
      if (_productsSuggestion.isEmpty) {
        _clearSelection();
        updateOrderSuggestionList();
      } else {
        notifyListeners();
      }
    }
    return result;
  }

  Future<void> selectOrderSuggestion(int orderId) async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      _selected = await orderSuggestionRepository.getOrderSuggestionById(orderId);
      await _updateListProducts();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSelection() {
    _clearSelection();
    notifyListeners();
  }

  void _clearSelection() {
    _selected = null;
    _newOrder = false;
    _productsSuggestion.clear();
  }

  void createNew({required int companyId}) {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    _newOrder = true;
    _selected = OrderSuggestion(
      orderId: 0,
      companyId: companyId,
      createdAt: DateTime.now(),
      status: 0,
    );
    _productsSuggestion.clear();
    _isLoading = false;
    notifyListeners();
  }
}

class _Product extends ChangeNotifier {
  ProductModel? _product;
  ProductModel? get product => _product;

  void setProduct(ProductModel? product) {
    if (_product != product) {
      _product = product;
      notifyListeners();
    }
  }
}

class _OrderSuggestionState extends State<OrderSuggestionScreen> {
  // Repositórios
  late ProductRepository _productRepository;
  late SupplierRepository _supplierRepository;
  late OrderSuggestionRepository _orderSuggestionRepository;

  late final OrderSuggestions _orderSuggestions;

  // Dados dinâmicos
  final _Product _product = _Product();

  // Controladores e Foco
  final _quantityController = TextEditingController();
  final _scannerFocusNode = FocusNode();

  // Exportação
  bool _isGeneratingPdf = false;

  Future<void> _handlePdfGenerationAndFeedback(
    BuildContext context,
    String fileName,
    // Sua função real que retorna os bytes
    Future<Uint8List> Function() getPdfBytesCallback,
  ) async {
    // 1. Variáveis de controle
    bool generatedSuccessfully = false;
    Uint8List pdfBytes = Uint8List(0);
    BuildContext? loadingContext;

    try {
      // A. Mostrar Diálogo de Carregamento
      // Capturamos o BuildContext do Diálogo para poder fechá-lo depois.
      loadingContext = _showLoadingDialog(context);
      // B. Gerar os Bytes do PDF (Operação Assíncrona 1)
      pdfBytes = await getPdfBytesCallback();

      // C. Abrir/Compartilhar o PDF (Operação Assíncrona 2)
      // O sharePdf NÃO retorna um booleano (bool), ele apenas completa (void) ou lança um erro (Exception).
      // Se a chamada completar sem erro, consideramos Sucesso.
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: fileName,
      );

      generatedSuccessfully = true;
    } catch (e) {
      // Se ocorrer qualquer erro (falha na geração ou no Printing.sharePdf)
      generatedSuccessfully = false;
      print("ERRO ao processar PDF: $e");
    } finally {
      // Este bloco é executado garantidamente, ocorrendo erro ou não.

      // 2. Fechar o Diálogo de Carregamento
      // Usamos o contexto capturado anteriormente.
      if (loadingContext != null && context.mounted) {
        Navigator.of(loadingContext, rootNavigator: true).pop();
      }

      // 3. Mostrar Diálogo de Feedback (Sucesso/Erro)
      if (context.mounted) {
        _showFeedbackDialog(context, isSuccess: generatedSuccessfully);
      }
    }
  }

// ----------------------------------------------------------------------
// FUNÇÕES AUXILIARES (SEPARADAS PARA CLAREZA)
// ----------------------------------------------------------------------

// Função para mostrar o Diálogo de Carregamento
  BuildContext _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        // Retorna o Widget do Diálogo de Carregamento
        return const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 15),
              Text("Processando...", style: TextStyle(fontSize: 16)),
            ],
          ),
        );
      },
    );
    // Retornamos o contexto original da tela, mas ele também pode ser usado
    // como referência para o diálogo (embora o método ideal seja o do código anterior).
    // Neste caso, vou manter a simplificação de usar o contexto original para o pop
    // já que o loadingDialog estará no topo.
    return context;
  }

// Função para mostrar o Diálogo de Feedback
  void _showFeedbackDialog(BuildContext context, {required bool isSuccess}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ok'),
            ),
          ],
          title: Row(
            children: isSuccess
                ? [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    const Text('Sucesso'),
                  ]
                : [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    const Text('Erro'),
                  ],
          ),
          content: Text(isSuccess ? 'PDF gerado com sucesso!' : 'Não foi possível gerar o PDF. Tente novamente.'),
        );
      },
    );
  }

  Future<void> _generatePdf(OrderSuggestion orderSuggestion) async {
    if (_isGeneratingPdf) return;

    setState(() => _isGeneratingPdf = true);

    try {
      // Prepara os dados para serem enviados para o Isolate.
      // Eles precisam ser tipos primitivos ou mapas/listas (JSON).
      final args = {
        'orderId': orderSuggestion.orderId,
        'companyId': orderSuggestion.companyId,
        'products': _orderSuggestions.productsSuggestion.map((p) => p.toJson()).toList(),
      };

      final String fileName = 'sugestao_pedido_${orderSuggestion.orderId}.pdf';

      if (mounted) {
        await _handlePdfGenerationAndFeedback(
          context,
          fileName,
          () => compute(_PdfGenerator.generate, args),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao gerar o PDF: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  // Widget flutuantes
  void _search() async {
    final selectedProduct = await showSearchProductDialog(context);
    if (selectedProduct != null) {
      _product.setProduct(selectedProduct);
    }
  }

  void _addSuggestion(OrderSuggestions productSuggestions, ProductModel product, double quantity) async {
    if (quantity > 0) {
      bool replace = false;
      while (true) {
        final status = await productSuggestions.addProductSuggestion(product, quantity, replace: replace); // A passagem do indexOf foi removida daqui
        if (status == CommandStatus.duplicate) {
          if (mounted) {
            final result = await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Atenção'),
                  content: Text('Deseja substituir o produto na lista?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Substituir'),
                    ),
                  ],
                );
              },
            );
            if (result == null || result == false) {
              break;
            } else {
              replace = true;
            }
          }
        } else if (status == CommandStatus.ok) {
          break;
        } else {
          if (mounted) {
            await showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text("Erro"),
                  content: Text(
                    status == CommandStatus.closed
                        ? 'Não é possível editar uma sugestão fechado!'
                        : 'Tivermos um erro ao tentar adicionar este produto\nID: ${product.id}\nNome: ${product.name}',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Ok'),
                    ),
                  ],
                );
              },
            );
          }
          break;
        }
      }

      // Limpa os campos para a próxima leitura
      _product.setProduct(null);
      _quantityController.clear();
      _scannerFocusNode.requestFocus();
    }
  }

  Widget _buildSugestionItemList(OrderSuggestions productSuggestions, ProductSuggestion suggestion) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        child: InkWell(
          child: Row(
            children: [
              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${suggestion.product.id} - ${suggestion.product.name}',
                            style: Theme.of(context).textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis, // Adiciona "..." se o texto for muito longo
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Sugestão: ${suggestion.quantitySuggestion.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Cód. Barras: ${suggestion.product.barcode}'),
                    const SizedBox(height: 8),
                    Text(
                      'Fornecedor: ${suggestion.supplierName}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Actions
              Column(
                children: [
                  IconButton(
                    onPressed: () async {
                      final bool confirmDelete = await showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => AlertDialog(
                          actions: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: Text(
                                      'Sim',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: Text('Não'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          title: Row(
                            children: [
                              Icon(
                                Icons.warning,
                                color: Colors.yellow.shade700,
                              ),
                              SizedBox(width: 8),
                              Text('Atenção!'),
                            ],
                          ),
                          content: Text('Deseja realmente remover este produto da lista?'),
                          actionsAlignment: MainAxisAlignment.center,
                        ),
                      );
                      if (confirmDelete) {
                        final status = await productSuggestions.removeProductSuggestion(suggestion);
                        if (status != CommandStatus.ok) {
                          if (mounted) {
                            await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Ok'),
                                  ),
                                ],
                                title: Text('Erro'),
                                content: Text(
                                  status == CommandStatus.closed
                                      ? 'Não é possível editar uma sugestão fechada!'
                                      : '${status == CommandStatus.notFound ? 'Este produto não existe nesta lista!' : 'Tivermos um erro ao tentar remover este produto.'}\n'
                                          'ID: ${suggestion.product.id}\nNome: ${suggestion.product.name}',
                                ),
                              ),
                            );
                          }
                        }
                      }
                    },
                    icon: const Icon(Icons.delete),
                    color: Colors.red,
                  ),
                ],
              ),
            ],
          ),
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
    _orderSuggestionRepository = OrderSuggestionRepository(db: db);

    _orderSuggestions = OrderSuggestions._(
      orderSuggestionRepository: _orderSuggestionRepository,
      productRepository: _productRepository,
      supplierRepository: _supplierRepository,
    );
    _orderSuggestions.updateOrderSuggestionList();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _scannerFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: _orderSuggestions,
        builder: (context, _) {
          final messageError = _orderSuggestions.messageError;
          if (messageError != null) {
            return Center(
              child: Column(
                children: [
                  Text(messageError),
                  TextButton(
                    onPressed: () async => await _orderSuggestions.updateOrderSuggestionList(),
                    child: Text('Recarregar'),
                  ),
                ],
              ),
            );
          } else if (_orderSuggestions.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_orderSuggestions.selectedOrder == null && !_orderSuggestions.newOrder) {
            return _buildOrderSuggestionListScaffold();
          } else {
            return _buildOrderSuggestionDetails();
          }
        },
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _orderSuggestions,
        builder: (context, _) {
          // Mostra o botão apenas se nenhuma sugestão de pedido estiver selecionada
          // e não estiver carregando a lista inicial.
          if (_orderSuggestions.selectedOrder == null && !_orderSuggestions.isLoading) {
            return FloatingActionButton(
              onPressed: () => _orderSuggestions.createNew(companyId: 1),
              tooltip: 'Nova sugestão',
              child: const Icon(Icons.add),
            );
          }
          return const SizedBox.shrink(); // Retorna um widget vazio quando não deve ser exibido
        },
      ),
    );
  }

  Widget _buildOrderSuggestionListScaffold() {
    return Scaffold(
      appBar: AppBar(
        // Garante que o título use a cor correta do tema para o texto da AppBar.
        title: Text('Sugestão de Pedido', style: Theme.of(context).textTheme.titleLarge),
        actions: [
          IconButton(
            onPressed: _orderSuggestions.isLoading ? null : _orderSuggestions.updateOrderSuggestionList,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar Lista',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _orderSuggestions.updateOrderSuggestionList(),
        child: _orderSuggestions.orders.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Nenhum pedido encontrado.'),
                    TextButton(
                      onPressed: () => _orderSuggestions.createNew(companyId: 1),
                      child: Text('Crie uma nova sugestão.'),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: _orderSuggestions.orders.length,
                itemBuilder: (context, index) {
                  final order = _orderSuggestions.orders[index];
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    clipBehavior: Clip.antiAlias, // Importante para cortar o efeito do InkWell
                    color: order.status > 0 ? Colors.green.shade50 : Colors.red.shade50,
                    child: InkWell(
                      onTap: () => _orderSuggestions.selectOrderSuggestion(order.orderId),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Sugestão Nº: ${order.orderId}', style: Theme.of(context).textTheme.titleMedium),
                                  Text('Empresa: ${order.companyId}'),
                                ],
                              ),
                            ),
                            if (order.status > 0)
                              Row(
                                children: [
                                  Text(
                                    'Fechada: Nº ',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  SizedBox(
                                    width: 40,
                                    child: Text(
                                      textAlign: TextAlign.center,
                                      '${order.status}',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildOrderSuggestionDetails() {
    final selectedOrder = _orderSuggestions.selectedOrder;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 90,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            _orderSuggestions.clearSelection();
            await _orderSuggestions.updateOrderSuggestionList();
          },
          tooltip: 'Voltar para a lista de pedidos',
        ),
        backgroundColor: (selectedOrder?.status ?? 0) > 0 ? Colors.green.shade50 : Colors.red.shade50,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _orderSuggestions.newOrder ? 'Nova Sugestão' : 'Pedido Nº: ${selectedOrder?.orderId ?? ''} (Empresa: ${selectedOrder?.companyId ?? ''})',
              style: Theme.of(context).textTheme.titleLarge,
              overflow: TextOverflow.ellipsis,
            ),
            if (!_orderSuggestions.newOrder)
              Text(
                'Data: ${selectedOrder?.createdAt.toLocal().toString().substring(0, 16) ?? '--/--/----'}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            if ((selectedOrder?.status ?? 0) > 0) ...[
              SizedBox(
                height: 4,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Fechada: Nº ',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      textAlign: TextAlign.center,
                      '${selectedOrder!.status}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          if (!_orderSuggestions.newOrder)
            IconButton(
              icon: Icon(Icons.check_circle_outline_rounded, color: Theme.of(context).appBarTheme.actionsIconTheme?.color),
              onPressed: (selectedOrder?.status ?? 0) > 0
                  ? null
                  : () async {
                      final numPed = await showDialog<String>(
                        context: context,
                        builder: (context) {
                          final formKey = GlobalKey<FormState>();
                          final controller = TextEditingController();
                          bool isChecking = false;
                          String? asyncError;

                          return StatefulBuilder(
                            builder: (context, setState) {
                              return AlertDialog(
                                title: const Text('Marcar Pedido'),
                                content: Form(
                                  key: formKey,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Marque este pedido como "Concluído" digitando o número do pedido do sistema principal.'),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: controller,
                                        autofocus: true,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Nº Pedido',
                                          border: OutlineInputBorder(),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'O campo está vazio!';
                                          }
                                          if (int.tryParse(value) == null) {
                                            return 'Digite apenas números';
                                          }
                                          return null;
                                        },
                                      ),
                                      if (asyncError != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            asyncError!,
                                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    // Desabilita o botão de cancelar durante a verificação
                                    onPressed: isChecking ? null : () => Navigator.pop(context),
                                    child: const Text('Cancelar'),
                                  ),
                                  ElevatedButton(
                                    onPressed: isChecking
                                        ? null // Desabilita o botão enquanto estiver verificando
                                        : () async {
                                            // Limpa erros antigos e valida o formulário
                                            setState(() => asyncError = null);
                                            if (formKey.currentState!.validate()) {
                                              setState(() => isChecking = true);

                                              // --- SUA LÓGICA ASSÍNCRONA AQUI ---
                                              // Simula uma chamada de API que pode falhar
                                              int numPed = int.parse(controller.text);
                                              final bool isValidOnSystem = await _orderSuggestionRepository.markSuggestion(
                                                orderId: _orderSuggestions.selectedOrder!.orderId,
                                                numPed: numPed,
                                              ); // Simula falha se digitar '123'

                                              if (isValidOnSystem) {
                                                if (context.mounted) Navigator.pop(context, controller.text);
                                              } else {
                                                setState(() {
                                                  asyncError = 'Este número não é válido!';
                                                  isChecking = false;
                                                });
                                              }
                                            }
                                          },
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Opacity(
                                          opacity: isChecking ? 0.0 : 1.0,
                                          child: const Text('Marcar'),
                                        ),
                                        if (isChecking)
                                          const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                      if (numPed != null && numPed.isNotEmpty) {
                        _orderSuggestions.clearSelection();
                        await _orderSuggestions.updateOrderSuggestionList();
                      }
                    },
            ),
          if (_orderSuggestions.selectedOrder != null && !_orderSuggestions.isLoading && !_orderSuggestions.newOrder)
            _isGeneratingPdf
                ? Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Theme.of(context).appBarTheme.actionsIconTheme?.color,
                      ),
                    ),
                  )
                : IconButton(
                    onPressed: () async {
                      if (selectedOrder != null) await _generatePdf(selectedOrder);
                    },
                    icon: const Icon(Icons.save),
                    tooltip: 'Salvar PDF',
                  ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Lista de produtos sugeridos
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Text('Produtos Sugeridos${_orderSuggestions.newOrder ? '' : ': ${selectedOrder!.products?.length ?? 0}'}', style: Theme.of(context).textTheme.titleMedium),
          ),
          Expanded(
            child: _orderSuggestions.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    itemCount: _orderSuggestions.productsSuggestion.length,
                    itemBuilder: (context, index) {
                      return _buildSugestionItemList(_orderSuggestions, _orderSuggestions.productsSuggestion[index]);
                    },
                  ),
          ),

          // Seção para adicionar novo produto na parte inferior
          ListenableBuilder(
            listenable: _product,
            builder: (context, child) {
              final product = _product.product;
              if (product == null) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ScannerField(
                    focusNode: _scannerFocusNode,
                    onDelay: (value) async {
                      if (value.isEmpty || _product.product != null) return;
                      _product.setProduct(await _productRepository.findProductByCode(value));
                    },
                    onSearchClick: _search,
                  ),
                );
              }
              // Usando Material para dar elevação e cor de fundo
              return Material(
                elevation: 8,
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: SafeArea(
                    top: false, // A SafeArea superior já é tratada pelo Scaffold
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(product.name, style: Theme.of(context).textTheme.titleLarge)),
                            IconButton(onPressed: () => _product.setProduct(null), icon: Icon(Icons.close)),
                          ],
                        ),
                        Text('Código: ${product.barcode}', style: Theme.of(context).textTheme.bodyMedium),
                        Text('Estoque atual: ${product.quatity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12.0),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _quantityController,
                                autofocus: true,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Quantidade', border: OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            ElevatedButton.icon(
                              onPressed: () {
                                if (_product.product == null || _quantityController.text.isEmpty) return;
                                _addSuggestion(
                                  _orderSuggestions,
                                  _product.product!,
                                  double.parse(
                                    _quantityController.text.replaceAll(',', '.'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Adicionar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Defina esta classe fora da classe _OrderSuggestionState
class _PdfGenerator {
  // Esta função será executada em um Isolate separado
  static Future<Uint8List> generate(Map<String, dynamic> args) async {
    final orderId = args['orderId'] as int;
    final companyId = args['companyId'] as int;
    final productsJson = args['products'] as List;

    // Recriamos os objetos a partir dos dados simples (JSON)
    // Assumindo que ProductSuggestion tem um construtor fromJson
    final products = productsJson.map((json) => ProductSuggestion.fromJson(json as Map<String, dynamic>)).toList();

    final pdf = pw.Document();

    // Agrupar produtos por fornecedor
    final Map<String, List<ProductSuggestion>> productsBySupplier = {};
    for (final suggestion in products) {
      final key = '${suggestion.supplierName} (${suggestion.supplierRegistration})';
      if (productsBySupplier[key] == null) {
        productsBySupplier[key] = [];
      }
      productsBySupplier[key]!.add(suggestion);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Cabeçalho
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Sugestão de Compra de Mercadoria', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Text('Pedido Nº: $orderId', style: const pw.TextStyle(fontSize: 16)),
                  pw.Text('Empresa: $companyId', style: const pw.TextStyle(fontSize: 16)),
                  pw.Divider(height: 20),
                ],
              ),
            ),

            // Conteúdo
            ...productsBySupplier.entries.map(
              (entry) {
                final supplierInfo = entry.key;
                final supplierProducts = entry.value;

                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(supplierInfo, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 10),
                    pw.Table.fromTextArray(
                      headers: ['ID', 'Produto', 'Cód. Barras', 'Sugestão'],
                      data: supplierProducts.map((s) {
                        return [
                          s.product.id.toString(),
                          s.product.name,
                          s.product.barcode,
                          s.quantitySuggestion.toStringAsFixed(2),
                        ];
                      }).toList(),
                      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      cellAlignment: pw.Alignment.centerLeft,
                      cellAlignments: {3: pw.Alignment.centerRight},
                    ),
                    pw.SizedBox(height: 20),
                  ],
                );
              },
            ),
          ];
        },
      ),
    );

    // pdf.save() é a parte pesada que agora roda no Isolate
    return pdf.save();
  }
}
