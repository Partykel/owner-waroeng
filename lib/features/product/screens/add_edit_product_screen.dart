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
import '../../transaction/providers/transaction_provider.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';

class AddEditProductScreen extends ConsumerStatefulWidget {
  final int? productId;

  const AddEditProductScreen({super.key, this.productId});

  @override
  ConsumerState<AddEditProductScreen> createState() =>
      _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _sellPriceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _minStockController = TextEditingController();

  String _unit = 'pcs';
  bool _isLoading = false;
  bool _isInitializing = false;
  bool _productNotFound = false;
  bool _loadFailed = false;
  Product? _existingProduct;

  @override
  void initState() {
    super.initState();
    if (widget.productId != null) {
      _isInitializing = true;
      _loadProduct();
    }
  }

  Future<void> _loadProduct() async {
    setState(() {
      _isInitializing = true;
      _loadFailed = false;
    });
    try {
      final product = await ref
          .read(productRepositoryProvider)
          .getById(widget.productId!);
      if (!mounted) return;

      if (product != null) {
        setState(() {
          _existingProduct = product;
          _nameController.text = product.name;
          _categoryController.text = product.category;
          _sellPriceController.text = product.sellPrice.toString();
          _costPriceController.text = product.costPrice.toString();
          _minStockController.text = product.minStock.toString();
          _unit = product.unit;
          _isInitializing = false;
          _productNotFound = false;
        });
        return;
      }

      setState(() {
        _isInitializing = false;
        _productNotFound = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _loadFailed = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _sellPriceController.dispose();
    _costPriceController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.productId != null;
    final categories =
        ref.watch(productCategoriesProvider).asData?.value ??
        suggestedProductCategories;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? AppStrings.editProduct : AppStrings.addProduct),
      ),
      body: _isInitializing
          ? Center(child: CircularProgressIndicator())
          : _loadFailed
          ? Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Gagal memuat produk'),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _loadProduct,
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : _productNotFound
          ? EmptyState(
              title: 'Produk tidak ditemukan',
              subtitle: 'Produk ini mungkin sudah dihapus dari daftar aktif.',
              icon: PhosphorIconsRegular.package,
            )
          : Form(
              key: _formKey,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.all(16),
                children: [
                  AppTextField(
                    label: 'Nama Produk',
                    hint: 'Contoh: Keripik Singkong',
                    controller: _nameController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama produk wajib diisi';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  AppTextField(
                    label: 'Kategori Produk (opsional)',
                    hint: 'Pilih atau ketik kategori baru',
                    controller: _categoryController,
                    validator: (value) => (value?.trim().length ?? 0) > 60
                        ? 'Kategori maksimal 60 karakter'
                        : null,
                    suffixIcon: PopupMenuButton<String>(
                      tooltip: 'Pilih kategori produk',
                      icon: AppIcon(PhosphorIconsRegular.caretDown),
                      onSelected: (value) => _categoryController.text = value,
                      itemBuilder: (_) => [
                        PopupMenuItem(value: '', child: Text('Tanpa kategori')),
                        for (final category in categories)
                          PopupMenuItem(value: category, child: Text(category)),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  AppTextField(
                    label: 'Harga Jual',
                    hint: 'Contoh: 10000',
                    controller: _sellPriceController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Harga jual wajib diisi';
                      }
                      final parsed = double.tryParse(value);
                      if (parsed == null || !parsed.isFinite) {
                        return 'Format harga tidak valid';
                      }
                      if (parsed <= 0) return 'Harga jual harus lebih dari 0';
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  AppTextField(
                    label: 'Harga Modal',
                    hint: 'Contoh: 7000',
                    controller: _costPriceController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Harga modal wajib diisi';
                      }
                      final parsed = double.tryParse(value);
                      if (parsed == null || !parsed.isFinite) {
                        return 'Format harga tidak valid';
                      }
                      if (parsed < 0) return 'Harga modal tidak boleh negatif';
                      final sellPrice = double.tryParse(
                        _sellPriceController.text,
                      );
                      if (sellPrice != null && parsed > sellPrice) {
                        return 'Harga modal tidak boleh melebihi harga jual';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  _buildStockInfoCard(isEdit),
                  SizedBox(height: 16),
                  AppTextField(
                    label: 'Stok Minimum',
                    hint: '5',
                    controller: _minStockController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return null;
                      final parsed = int.tryParse(value);
                      if (parsed == null) return 'Harus berupa angka';
                      if (parsed < 0) return 'Tidak boleh negatif';
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    icon: const AppIcon(PhosphorIconsRegular.caretDown),
                    initialValue: _unit,
                    decoration: InputDecoration(
                      labelText: 'Satuan',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(value: 'pcs', child: Text('Pcs')),
                      DropdownMenuItem(
                        value: 'bungkus',
                        child: Text('Bungkus'),
                      ),
                      DropdownMenuItem(value: 'botol', child: Text('Botol')),
                      DropdownMenuItem(value: 'kg', child: Text('Kg')),
                      DropdownMenuItem(value: 'liter', child: Text('Liter')),
                    ],
                    onChanged: (value) => setState(() => _unit = value!),
                  ),
                  if (isEdit) ...[SizedBox(height: 24), _buildDeleteSection()],
                  SizedBox(height: 96),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: AppButton(
            text: isEdit ? 'Update Produk' : 'Simpan Produk',
            onPressed: _productNotFound || _isInitializing || _loadFailed
                ? null
                : _saveProduct,
            isLoading: _isLoading,
            fullWidth: true,
          ),
        ),
      ),
    );
  }

  Widget _buildStockInfoCard(bool isEdit) {
    final stockLabel = isEdit ? _existingProduct?.stock ?? 0 : 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.of(context).surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.of(context).divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stok saat ini: $stockLabel $_unit',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            isEdit
                ? 'Ubah persediaan melalui Beli Stok.'
                : 'Produk baru dimulai dari stok 0. Isi melalui Beli Stok.',
            style: TextStyle(color: AppPalette.of(context).textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(
                PhosphorIconsRegular.trash,
                color: AppPalette.of(context).danger,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Hapus Produk',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.of(context).textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Produk akan dihapus dari daftar aktif, tetapi seluruh histori pemasukan, pengeluaran, dan laporan yang sudah tercatat tetap aman di sistem.',
            style: TextStyle(
              color: AppPalette.of(context).textSecondary,
              height: 1.4,
            ),
          ),
          SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _deleteProduct,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppPalette.of(context).danger,
                side: BorderSide(color: AppPalette.of(context).danger),
                padding: EdgeInsets.symmetric(vertical: 14),
              ),
              icon: AppIcon(PhosphorIconsRegular.trash),
              label: Text('Hapus Produk'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct() async {
    final productId = widget.productId;
    if (productId == null) return;

    final repo = ref.read(productRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final impact = await repo.getDeletionImpact(productId);
      if (!mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Hapus ${impact.productName}?'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Produk ini akan hilang dari daftar aktif dan tidak bisa dipakai lagi untuk jual/restok. Histori keuangan lama tetap tersimpan.',
                ),
                SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppPalette.of(context).surfaceMuted,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Riwayat penjualan: ${impact.totalSales} transaksi'),
                      SizedBox(height: 6),
                      Text(
                        'Total pemasukan tersimpan: ${CurrencyFormatter.format(impact.incomeTotal)}',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Riwayat restok: ${impact.totalRestocks} transaksi - ${impact.totalRestockUnits} item',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.of(context).danger,
              ),
              child: Text('Ya, Hapus'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      await ref.read(allProductsProvider.notifier).deleteProduct(productId);
      ref.invalidate(todaySoldCountByProductProvider);
      ref.invalidate(topProductsProvider);
      ref.invalidate(lowStockProductsProvider);

      if (!mounted) return;
      context.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${impact.productName} berhasil dihapus dari daftar aktif',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal menghapus produk: $e')),
      );
    }
  }

  Future<void> _saveProduct() async {
    if (_isLoading ||
        _isInitializing ||
        _loadFailed ||
        _productNotFound ||
        !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.productId != null) {
        final existing = _existingProduct;
        final product =
            (existing ??
                    Product(
                      id: widget.productId,
                      name: _nameController.text.trim(),
                      sellPrice: double.parse(_sellPriceController.text),
                      costPrice: double.parse(_costPriceController.text),
                      stock: 0,
                    ))
                .copyWith(
                  name: _nameController.text.trim(),
                  category: _categoryController.text,
                  sellPrice: double.parse(_sellPriceController.text),
                  costPrice: double.parse(_costPriceController.text),
                  minStock: int.tryParse(_minStockController.text) ?? 5,
                  unit: _unit,
                );

        await ref.read(allProductsProvider.notifier).updateProduct(product);
      } else {
        final product = Product(
          name: _nameController.text.trim(),
          category: _categoryController.text,
          sellPrice: double.parse(_sellPriceController.text),
          costPrice: double.parse(_costPriceController.text),
          stock: 0,
          minStock: int.tryParse(_minStockController.text) ?? 5,
          unit: _unit,
        );

        await ref.read(allProductsProvider.notifier).addProduct(product);
      }

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
