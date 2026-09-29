import '../../../shared/widgets/sale_success_dialog.dart';
import 'package:ghepek_in/shared/widgets/app_icon.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../product/providers/product_provider.dart';
import '../../product/models/product.dart';
import '../../transaction/providers/transaction_provider.dart';

class AddSaleScreen extends ConsumerStatefulWidget {
  const AddSaleScreen({super.key});

  @override
  ConsumerState<AddSaleScreen> createState() => _AddSaleScreenState();
}

class _AddSaleScreenState extends ConsumerState<AddSaleScreen> {
  final Map<int, int> _selectedItems = {};
  final TextEditingController _noteController = TextEditingController();
  bool _isLoading = false;
  bool _onlySelected = false;
  String _search = '';

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(allProductsProvider);
    final products = productsAsync.asData?.value ?? <Product>[];
    final total = _calculateTotal(products);
    final visible = products
        .where(
          (p) =>
              p.stock > 0 &&
              p.name.toLowerCase().contains(_search.toLowerCase()) &&
              (!_onlySelected || (_selectedItems[p.id] ?? 0) > 0),
        )
        .toList();
    return PopScope(
      canPop: !_isLoading,
      child: Scaffold(
        appBar: AppBar(title: const Text('Catat penjualan')),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: AbsorbPointer(
                  absorbing: _isLoading,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Cari produk',
                          prefixIcon: AppIcon(
                            PhosphorIconsRegular.magnifyingGlass,
                          ),
                        ),
                        onChanged: (value) => setState(() => _search = value),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Semua produk'),
                            selected: !_onlySelected,
                            onSelected: (_) =>
                                setState(() => _onlySelected = false),
                          ),
                          ChoiceChip(
                            label: Text('Dipilih (${_selectedItems.length})'),
                            selected: _onlySelected,
                            onSelected: (_) =>
                                setState(() => _onlySelected = true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (productsAsync.isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (productsAsync.hasError)
                        TextButton(
                          onPressed: () => ref.invalidate(allProductsProvider),
                          child: const Text('Gagal memuat produk. Coba lagi'),
                        )
                      else if (visible.isEmpty)
                        EmptyState(
                          title: _search.isNotEmpty
                              ? 'Produk tidak ditemukan'
                              : _onlySelected
                              ? 'Belum ada produk dipilih'
                              : 'Tidak ada produk dengan stok tersedia',
                          icon: PhosphorIconsRegular.package,
                        )
                      else
                        ...visible.map(_buildProductTile),
                      const SizedBox(height: 12),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text('Tambahkan catatan (opsional)'),
                        children: [
                          AppTextField(
                            label: 'Catatan',
                            controller: _noteController,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppPalette.of(context).surface,
                  border: Border(
                    top: BorderSide(color: AppPalette.of(context).divider),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_selectedItems.length} produk - ${_selectedItems.values.fold<int>(0, (a, b) => a + b)} unit',
                    ),
                    Text(
                      CurrencyFormatter.format(total),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    AppButton(
                      text: 'Simpan penjualan',
                      fullWidth: true,
                      isLoading: _isLoading,
                      onPressed:
                          _selectedItems.isEmpty ||
                              _isLoading ||
                              !productsAsync.hasValue
                          ? null
                          : _saveSale,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductTile(Product product) {
    final quantity = _selectedItems[product.id] ?? 0;
    final palette = AppPalette.of(context);
    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 160),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: quantity > 0 ? palette.primarySoft : palette.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '${CurrencyFormatter.format(product.sellPrice)} / ${product.unit}',
          ),
          Text(
            '${product.stock} tersedia',
            style: TextStyle(color: palette.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            quantity > 0
                ? CurrencyFormatter.format(product.sellPrice * quantity)
                : 'Tambah ke penjualan',
            style: TextStyle(
              color: palette.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Kurangi ${product.name}',
                  onPressed: quantity > 0
                      ? () => _updateQuantity(product.id!, quantity - 1)
                      : null,
                  icon: const AppIcon(PhosphorIconsRegular.minus),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Semantics(
                    label: 'Jumlah ${product.name}',
                    child: Text(
                      '$quantity',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Tambah ${product.name}',
                  onPressed: quantity < product.stock
                      ? () => _updateQuantity(product.id!, quantity + 1)
                      : null,
                  icon: const AppIcon(PhosphorIconsRegular.plus),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateQuantity(int productId, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _selectedItems.remove(productId);
      } else {
        _selectedItems[productId] = quantity;
      }
    });
  }

  double _calculateTotal(List<Product> products) {
    final productMap = {for (final product in products) product.id: product};
    return _selectedItems.entries.fold<double>(0, (sum, entry) {
      final product = productMap[entry.key];
      if (product == null) return sum;
      return sum + (product.sellPrice * entry.value);
    });
  }

  Future<void> _saveSale() async {
    if (_isLoading) return;
    final products = ref
        .read(allProductsProvider)
        .when(
          data: (products) => products,
          loading: () => <Product>[],
          error: (error, stackTrace) => <Product>[],
        );

    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Pilih minimal satu produk.')));
      return;
    }

    final savedTotal = _calculateTotal(products);
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final productMap = {for (final product in products) product.id: product};

      final items = <Map<String, dynamic>>[];
      for (final entry in _selectedItems.entries) {
        final product = productMap[entry.key];
        if (product == null) {
          throw StateError('Produk dengan ID ${entry.key} tidak ditemukan.');
        }
        if (entry.value <= 0) {
          throw ArgumentError('Jumlah penjualan harus lebih dari 0.');
        }
        if (entry.value > product.stock) {
          throw StateError('Stok ${product.name} tidak mencukupi.');
        }
        items.add({
          'product_id': entry.key,
          'quantity': entry.value,
          'price_at_sale': product.sellPrice,
        });
      }

      await ref
          .read(addSaleProvider.notifier)
          .call(
            items: items,
            note: _noteController.text.isEmpty ? null : _noteController.text,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${AppStrings.error}: $e')));
      }
      return;
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
    if (!mounted) return;
    setState(() => _isLoading = true);
    await showSaleSuccess(context, savedTotal);
    if (mounted) {
      setState(() => _isLoading = false);
      context.pop();
    }
  }
}
