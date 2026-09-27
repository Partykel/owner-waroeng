import 'package:ghepek_in/shared/widgets/app_icon.dart';
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
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final Map<int, int> _restockItems = {};

  String _selectedCategory = 'operasional';
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

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.addExpense)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            _buildHeroCard(restockTotal, selectedQty),
            SizedBox(height: 16),
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
                          PhosphorIconsRegular.package,
                        ),
                        _buildCategoryChip(
                          'operasional',
                          AppStrings.categoryOperational,
                          PhosphorIconsRegular.gear,
                        ),
                        _buildCategoryChip(
                          'lainnya',
                          AppStrings.categoryOther,
                          PhosphorIconsRegular.dotsThree,
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: AppButton(
            text: isStockCategory ? 'Simpan Restok' : 'Simpan Pengeluaran',
            onPressed: _isLoading ? null : _saveExpense,
            isLoading: _isLoading,
            fullWidth: true,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(double restockTotal, int selectedQty) {
    final title = isStockCategory
        ? 'Restok dengan nominal otomatis'
        : 'Catat pengeluaran tanpa ribet';
    final subtitle = isStockCategory
        ? 'Setiap penambahan quantity langsung mengakumulasi total modal dari produk yang dipilih.'
        : 'Gunakan kategori yang sesuai agar pencatatan pengeluaran tetap rapi.';

    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppPalette.of(context).primary,
            AppPalette.of(context).primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppPalette.of(context).primary.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: AppIcon(
                  isStockCategory
                      ? PhosphorIconsRegular.sparkle
                      : PhosphorIconsRegular.receipt,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppPalette.of(context).primarySoft,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isStockCategory) ...[
            SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _buildHeroMetric(
                    label: 'Total Modal',
                    value: CurrencyFormatter.format(restockTotal),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildHeroMetric(
                    label: 'Qty Restok',
                    value: '$selectedQty item',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroMetric({required String label, required String value}) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppPalette.of(context).primarySoft,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
              Text(
                'Nominal Restok Otomatis',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppPalette.of(context).textPrimary,
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

  Widget _buildCategoryChip(String value, String label, IconData icon) {
    final isSelected = _selectedCategory == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [AppIcon(icon, size: 16), SizedBox(width: 6), Text(label)],
      ),
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
    final subtotal = product.costPrice * quantity;
    final isSelected = quantity > 0;

    return AnimatedContainer(
      duration: Duration(milliseconds: 180),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSelected ? Color(0xFFF5F7FF) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected
              ? AppPalette.of(context).primarySoft
              : AppPalette.of(context).divider,
          width: isSelected ? 1.4 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppPalette.of(context).textPrimary,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppPalette.of(context).primarySoft,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$quantity x',
                              style: TextStyle(
                                color: AppPalette.of(context).primaryDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Modal ${CurrencyFormatter.format(product.costPrice)} / ${product.unit}',
                      style: TextStyle(
                        color: AppPalette.of(context).textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Stok saat ini: ${product.stock}',
                      style: TextStyle(
                        color: AppPalette.of(context).textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              _buildStepper(product.id!, quantity),
            ],
          ),
          if (isSelected) ...[
            SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Subtotal modal',
                    style: TextStyle(
                      color: AppPalette.of(context).textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(subtotal),
                    style: TextStyle(
                      color: AppPalette.of(context).primaryDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepper(int productId, int quantity) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStepperButton(
          icon: PhosphorIconsRegular.minus,
          onTap: quantity > 0
              ? () => _updateRestock(productId, quantity - 1)
              : null,
        ),
        SizedBox(
          width: 44,
          child: Text(
            quantity.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppPalette.of(context).textPrimary,
            ),
          ),
        ),
        _buildStepperButton(
          icon: PhosphorIconsRegular.plus,
          onTap: () => _updateRestock(productId, quantity + 1),
        ),
      ],
    );
  }

  Widget _buildStepperButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: onTap == null
              ? AppPalette.of(context).background
              : AppPalette.of(context).primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: AppIcon(
          icon,
          color: onTap == null
              ? AppPalette.of(context).textSecondary
              : AppPalette.of(context).primaryDark,
        ),
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
