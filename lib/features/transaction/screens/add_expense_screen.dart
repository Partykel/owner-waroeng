import 'package:owner_waroeng/shared/widgets/app_icon.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../product/models/product.dart';
import '../../product/providers/product_provider.dart';
import '../../transaction/providers/transaction_provider.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key, this.initialCategory = 'operasional'});
  final String initialCategory;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final Map<int, int> _restockItems = {};

  late String _selectedCategory;
  @override
  void initState() {
    super.initState();
    _selectedCategory =
        ['stok', 'operasional', 'lainnya'].contains(widget.initialCategory)
        ? widget.initialCategory
        : 'operasional';
  }

  bool _isLoading = false;

  bool get isStockCategory => _selectedCategory == 'stok';

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(allProductsProvider);
    final products = productsAsync.when(
      data: (items) => items,
      loading: () => <Product>[],
      error: (_, _) => <Product>[],
    );
    final restockTotal = _calculateRestockTotal(products);
    final selectedQty = _restockItems.values.fold<int>(
      0,
      (sum, qty) => sum + qty,
    );

    return PopScope(
      canPop: !_isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isStockCategory ? 'Beli stok' : AppStrings.addExpense),
        ),
        body: AbsorbPointer(
          absorbing: _isLoading,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kategori',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppPalette.of(context).textPrimary,
                          ),
                        ),
                        SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildCategoryChip(
                              'stok',
                              AppStrings.categoryStock,
                            ),
                            _buildCategoryChip(
                              'operasional',
                              AppStrings.categoryOperational,
                            ),
                            _buildCategoryChip(
                              'lainnya',
                              AppStrings.categoryOther,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                if (isStockCategory)
                  _buildAutoTotalCard(restockTotal, selectedQty)
                else
                  AppTextField(
                    label: 'Nominal',
                    hint: 'Contoh: 50000',
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nominal wajib diisi';
                      }
                      final parsed = double.tryParse(value);
                      if (parsed == null || !parsed.isFinite) {
                        return 'Format nominal tidak valid';
                      }
                      if (parsed <= 0) return 'Nominal harus lebih dari 0';
                      return null;
                    },
                  ),
                if (isStockCategory) ...[
                  SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Produk yang Direstok',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppPalette.of(context).textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Nominal dihitung otomatis dari harga modal per produk. Tinggal tekan tombol tambah pada produk yang ingin direstok.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppPalette.of(context).textSecondary,
                              height: 1.4,
                            ),
                          ),
                          SizedBox(height: 16),
                          productsAsync.when(
                            data: (items) {
                              if (items.isEmpty) {
                                return Column(
                                  children: [
                                    EmptyState(
                                      title: 'Belum ada produk terdaftar',
                                      subtitle:
                                          'Buat produk dulu, lalu restok akan otomatis menghitung total modal.',
                                      icon: PhosphorIconsRegular.package,
                                    ),
                                    SizedBox(height: 8),
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          context.push('/products/new'),
                                      icon: AppIcon(PhosphorIconsRegular.plus),
                                      label: Text('Tambah Produk Baru'),
                                    ),
                                  ],
                                );
                              }

                              return Column(
                                children: [
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemCount: items.length,
                                    separatorBuilder: (_, _) =>
                                        SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      return _buildRestockTile(items[index]);
                                    },
                                  ),
                                  SizedBox(height: 16),
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      await context.push('/products/new');
                                      ref.invalidate(allProductsProvider);
                                    },
                                    icon: AppIcon(PhosphorIconsRegular.plus),
                                    label: Text('Tambah Produk Baru'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppPalette.of(
                                        context,
                                      ).primary,
                                    ),
                                  ),
                                ],
                              );
                            },
                            loading: () => Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            error: (error, _) => EmptyState(
                              title: 'Gagal memuat produk',
                              subtitle: error.toString(),
                              icon: PhosphorIconsRegular.warningCircle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 96),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              12 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: AppButton(
              text: isStockCategory ? 'Simpan Restok' : 'Simpan Pengeluaran',
              onPressed: _isLoading ? null : _saveExpense,
              isLoading: _isLoading,
              fullWidth: true,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAutoTotalCard(double restockTotal, int selectedQty) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.of(context).surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(
                PhosphorIconsRegular.calculator,
                color: AppPalette.of(context).primary,
                size: 18,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Total belanja stok',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppPalette.of(context).textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            CurrencyFormatter.format(restockTotal),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppPalette.of(context).textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            selectedQty == 0
                ? 'Pilih produk yang direstok untuk mulai menghitung total modal.'
                : '$selectedQty item restok sedang dihitung otomatis dari harga modal.',
            style: TextStyle(
              color: AppPalette.of(context).textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String value, String label) {
    final isSelected = _selectedCategory == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (!selected) return;

        setState(() {
          _selectedCategory = value;
          if (!isStockCategory) {
            _restockItems.clear();
          }
        });
      },
      selectedColor: AppPalette.of(context).primary.withValues(alpha: 0.18),
      checkmarkColor: AppPalette.of(context).primary,
      side: BorderSide(
        color: isSelected
            ? AppPalette.of(context).primary
            : AppPalette.of(context).divider,
      ),
    );
  }

  Widget _buildRestockTile(Product product) {
    final quantity = _restockItems[product.id] ?? 0;
    final palette = AppPalette.of(context);
    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 160),
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
            'Modal ${CurrencyFormatter.format(product.costPrice)} / ${product.unit}',
          ),
          Text(
            'Stok saat ini: ${product.stock}',
            style: TextStyle(color: palette.textSecondary),
          ),
          if (quantity > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Subtotal ${CurrencyFormatter.format(product.costPrice * quantity)}',
                style: TextStyle(
                  color: palette.primary,
                  fontWeight: FontWeight.w700,
                ),
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
                      ? () => _updateRestock(product.id!, quantity - 1)
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
                  onPressed: () => _updateRestock(product.id!, quantity + 1),
                  icon: const AppIcon(PhosphorIconsRegular.plus),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateRestockTotal(List<Product> products) {
    final productMap = {for (final product in products) product.id: product};

    return _restockItems.entries.fold<double>(0, (sum, entry) {
      final product = productMap[entry.key];
      if (product == null) return sum;
      return sum + (product.costPrice * entry.value);
    });
  }

  void _updateRestock(int productId, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _restockItems.remove(productId);
      } else {
        _restockItems[productId] = quantity;
      }
    });
  }

  Future<void> _saveExpense() async {
    if (_isLoading) return;
    if (!isStockCategory && !_formKey.currentState!.validate()) return;

    if (isStockCategory && _restockItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pilih minimal satu produk untuk restok.')),
      );
      return;
    }

    final products = ref
        .read(allProductsProvider)
        .when(
          data: (items) => items,
          loading: () => <Product>[],
          error: (_, _) => <Product>[],
        );

    if (isStockCategory && products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data produk belum siap. Coba lagi sebentar.')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final restockItems = isStockCategory
          ? _restockItems.entries
                .map(
                  (entry) => {'product_id': entry.key, 'quantity': entry.value},
                )
                .toList()
          : null;

      final amount = isStockCategory
          ? _calculateRestockTotal(products)
          : double.parse(_amountController.text);

      await ref
          .read(addExpenseProvider.notifier)
          .call(
            amount: amount,
            category: _selectedCategory,
            restockItems: restockItems,
          );

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppStrings.saveSuccess)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${AppStrings.error}: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
