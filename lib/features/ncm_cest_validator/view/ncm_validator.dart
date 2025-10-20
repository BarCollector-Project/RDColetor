import 'package:barcollector_sdk/routes/product/parameters/include.dart';
import 'package:barcollector_sdk/types/product/product_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rdcoletor/local/coletor/db/repository/product_repository.dart';
import 'package:rdcoletor/local/database_service.dart';
import 'package:rdcoletor/widgets/alert_dialog/search_product.dart';
import 'package:rdcoletor/widgets/text_field/scanner_field.dart';

class NcmValidator extends StatefulWidget {
  const NcmValidator({super.key});

  @override
  State<NcmValidator> createState() => _NcmValidatorState();
}

class _NcmValidatorState extends State<NcmValidator> {
  final ValueNotifier<ProductModel?> _product = ValueNotifier(null);

  late ProductRepository _productRepository;

  String? _messageError;

  @override
  void initState() {
    _productRepository = ProductRepository(context.read<DatabaseService>());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Validação de NCM/CEST'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ValueListenableBuilder<ProductModel?>(
                valueListenable: _product,
                builder: (context, product, child) {
                  if (product == null) {
                    return _EmptyProductState(
                      title: _messageError,
                      subtitle: _messageError != null ? '' : _messageError,
                      icon: _messageError == null ? Icons.search_off_rounded : Icons.error_outline_rounded,
                    );
                  }
                  _messageError = null;
                  return _ProductInfoCard(product: product);
                },
              ),
              const SizedBox(height: 24.0),
              ScannerField(
                onDelay: (value) async {
                  if (value.isEmpty) return;
                  ProductModel? detailedResult;
                  try {
                    final result = await _productRepository.findProductByCode(value);
                    if (result == null) {
                      _product.value = null;
                      return;
                    }
                    detailedResult = await _productRepository.getProductDetails(
                      result.id,
                      [
                        Includes.promotion,
                        Includes.wholesale,
                      ],
                    );
                  } catch (e) {
                    String msg = e.toString();
                    setState(() => _messageError = msg.substring(msg.indexOf(RegExp('\\s'))));
                  }
                  _product.value = detailedResult;
                },
                onSearchClick: () async {
                  final selectedProduct = await showSearchProductDialog(context);
                  if (selectedProduct != null) {
                    final detailedResult = await _productRepository.getProductDetails(
                      selectedProduct.id,
                      [
                        Includes.promotion,
                        Includes.wholesale,
                      ],
                    );
                    _product.value = detailedResult;
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductInfoCard extends StatelessWidget {
  const _ProductInfoCard({required this.product});

  final ProductModel product;

  String _dataTimeToString(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
  }

  DateTime onlyDate(DateTime from) {
    return DateTime(from.year, from.month, from.day);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = onlyDate(DateTime.now());
    debugPrint(now.toIso8601String());

    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary.withValues(alpha: 0.1),
              colorScheme.primary.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8.0),
            Wrap(
              spacing: 16.0,
              runSpacing: 8.0,
              children: [
                _PriceItem(
                  label: 'Varejo',
                  price: product.price,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (product.wholesale != null && product.wholesale!.triggerQuantity > 0) ...[
                  () {
                    String subLabel = '';
                    subLabel = '${product.wholesale!.triggerName ?? (product.wholesale!.trigger == 0 ? 'A partir' : 'Multiplos')} de: ${product.wholesale!.triggerQuantity}.';

                    return _PriceItem(
                      label: 'Atacado',
                      price: product.wholesale!.price,
                      subLabel: subLabel,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.8),
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }(),
                ],
                if (product.promotion != null &&
                    ((product.promotion!.startIn.isBefore(now) && product.promotion!.endIn.isAfter(now)) ||
                        (product.promotion!.startIn.difference(now).inDays == 0 && product.promotion!.endIn.difference(now).inDays == 0)))
                  _PriceItem(
                    label:
                        'Promoção${product.promotion!.promotionName != null && product.promotion!.promotionName != '0' ? ': ${product.promotion!.promotionName}' : ': NÃO DEFINIDO'}',
                    subLabel: 'Válido de ${_dataTimeToString(product.promotion!.startIn)} até ${_dataTimeToString(product.promotion!.endIn)}',
                    price: product.promotion!.price,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const Divider(height: 32.0),
            _InfoRow(
              icon: Icons.barcode_reader,
              label: 'Código de Barras',
              value: product.barcode,
            ),
            const SizedBox(height: 12.0),
            _InfoRow(
              icon: Icons.inventory_2_outlined,
              label: 'Código Interno',
              value: '${product.id}',
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceItem extends StatelessWidget {
  const _PriceItem({
    required this.label,
    this.price,
    this.subLabel,
    this.style,
  });

  final String label;
  final double? price;
  final String? subLabel;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.8)),
          ),
          Text(
            'R\$ ${price?.toStringAsFixed(2) ?? '0.00'}',
            style: style,
          ),
          if (subLabel != null && subLabel!.isNotEmpty) ...[
            const SizedBox(height: 2.0),
            Text(
              subLabel!,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 20),
        const SizedBox(width: 12.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.bodySmall),
            Text(value, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}

class _EmptyProductState extends StatelessWidget {
  final String _title;
  final String _subtite;
  final IconData _icon;

  const _EmptyProductState({
    String? title,
    String? subtitle,
    IconData? icon,
  })  : _title = title ?? 'Nenhum produto encontrado',
        _subtite = subtitle ?? 'Use o leitor ou a busca para ver os detalhes',
        _icon = icon ?? Icons.search_off_rounded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _icon,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16.0),
          Text(
            _title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            _subtite,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
