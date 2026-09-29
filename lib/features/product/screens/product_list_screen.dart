import 'package:owner_waroeng/shared/widgets/app_icon.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../transaction/providers/transaction_provider.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';

enum ProductSortOption { name, stock, status, sold }

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  ProductSortOption _sortOption = ProductSortOption.name;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> _sortProducts(
    List<Product> products,
    Map<int, int> soldCountByProduct,
  ) {
    final sorted = List<Product>.from(products);

    int statusRank(Product p) {
      if (p.stock <= 0) return 0;
      if (p.stock <= p.minStock) return 1;
      return 2;
    }

    sorted.sort((a, b) {
      switch (_sortOption) {
        case ProductSortOption.name:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case ProductSortOption.stock:
          final byStock = a.stock.compareTo(b.stock);
          if (byStock != 0) return byStock;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case ProductSortOption.status:
          final byStatus = statusRank(a).compareTo(statusRank(b));
          if (byStatus != 0) return byStatus;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case ProductSortOption.sold:
          final soldA = soldCountByProduct[a.id] ?? 0;
          final soldB = soldCountByProduct[b.id] ?? 0;
          final bySold = soldB.compareTo(soldA);
          if (bySold != 0) return bySold;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
    });

    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(allProductsProvider);
    final soldCountAsync = ref.watch(todaySoldCountByProductProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.products),
        actions: [
          PopupMenuButton<ProductSortOption>(
            icon: AppIcon(PhosphorIconsRegular.sortDescending),
            tooltip: 'Urutkan',
            onSelected: (option) => setState(() => _sortOption = option),
            itemBuilder: (context) => [
              CheckedPopupMenuItem(
                value: ProductSortOption.name,
                checked: _sortOption == ProductSortOption.name,
                child: Text('Nama (A-Z)'),
              ),
              CheckedPopupMenuItem(
                value: ProductSortOption.stock,
                checked: _sortOption == ProductSortOption.stock,
                child: Text('Stok (Rendah -> Tinggi)'),
              ),
              CheckedPopupMenuItem(
                value: ProductSortOption.status,
                checked: _sortOption == ProductSortOption.status,
                child: Text('Status Stok'),
              ),
              CheckedPopupMenuItem(
                value: ProductSortOption.sold,
                checked: _sortOption == ProductSortOption.sold,
                child: Text('Terlaris Hari Ini'),
              ),
            ],
          ),
          IconButton(
            icon: AppIcon(PhosphorIconsRegular.plus),
            onPressed: () => context.push('/products/new'),
            tooltip: AppStrings.addProduct,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: AppStrings.search,
                    prefixIcon: AppIcon(PhosphorIconsRegular.magnifyingGlass),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    filled: true,
                    fillColor: AppPalette.of(context).surface,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => context.push('/low-stock'),
                    icon: const AppIcon(PhosphorIconsRegular.package),
                    label: const Text('Monitor Stok'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: productsAsync.when(
              data: (products) {
                return soldCountAsync.when(
                  data: (soldCountByProduct) {
                    final filtered = _sortProducts(
                      _searchQuery.isEmpty
                          ? products
                          : products
                                .where(
                                  (p) => p.name.toLowerCase().contains(
                                    _searchQuery.toLowerCase(),
                                  ),
                                )
                                .toList(),
                      soldCountByProduct,
                    );

                    if (filtered.isEmpty) {
                      return EmptyState(
                        title: _searchQuery.isEmpty
                            ? 'Belum ada produk'
                            : 'Produk tidak ditemukan',
                        icon: _searchQuery.isEmpty
                            ? PhosphorIconsRegular.package
                            : PhosphorIconsRegular.magnifyingGlassMinus,
                      );
                    }

                    return ListView.separated(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final product = filtered[index];
                        return _buildProductCard(product, soldCountByProduct);
                      },
                    );
                  },
                  loading: () => Center(child: CircularProgressIndicator()),
                  error: (error, stack) => EmptyState(
                    title: 'Gagal memuat data penjualan',
                    subtitle: error.toString(),
                    icon: PhosphorIconsRegular.warningCircle,
                  ),
                );
              },
              loading: () => Center(child: CircularProgressIndicator()),
              error: (error, stack) => EmptyState(
                title: 'Gagal memuat produk',
                subtitle: error.toString(),
                icon: PhosphorIconsRegular.warningCircle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product, Map<int, int> soldCountByProduct) {
    final stockColor = product.stock <= 0
        ? AppPalette.of(context).stockEmpty
        : product.stock <= product.minStock
        ? AppPalette.of(context).stockLow
        : AppPalette.of(context).stockSafe;
    final soldCount = soldCountByProduct[product.id] ?? 0;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/products/${product.id}/edit'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.category.isEmpty
                              ? 'Tanpa kategori'
                              : product.category,
                          style: TextStyle(
                            color: AppPalette.of(context).textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Aksi Produk',
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await context.push('/products/${product.id}/edit');
                      } else {
                        await _confirmDeleteProduct(product);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit Produk')),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Hapus Produk'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${CurrencyFormatter.format(product.sellPrice)} / ${product.unit}',
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  Text(
                    'Stok ${product.stock} · ${product.stockStatus}',
                    style: TextStyle(
                      color: stockColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Terjual $soldCount hari ini',
                    style: TextStyle(
                      color: AppPalette.of(context).textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteProduct(Product product) async {
    final repo = ref.read(productRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final impact = await repo.getDeletionImpact(product.id!);
      if (!mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Hapus ${product.name}?'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Produk akan dihapus dari daftar aktif, tetapi histori pemasukan, pengeluaran, dan laporan yang sudah tercatat akan tetap tersimpan di sistem.',
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
                      Text(
                        'Riwayat penjualan: ${impact.totalSales} transaksi',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Total pemasukan tercatat: ${CurrencyFormatter.format(impact.incomeTotal)}',
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Riwayat restok: ${impact.totalRestocks} transaksi - ${impact.totalRestockUnits} item',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Setelah dihapus, produk tidak akan muncul lagi di menu jual, restok, dan daftar produk aktif.',
                  style: TextStyle(
                    color: AppPalette.of(context).textSecondary,
                    height: 1.4,
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

      await ref.read(allProductsProvider.notifier).deleteProduct(product.id!);
      ref.invalidate(todaySoldCountByProductProvider);
      ref.invalidate(topProductsProvider);
      ref.invalidate(lowStockProductsProvider);

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('${product.name} berhasil dihapus dari daftar aktif'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal menghapus produk: $e')),
      );
    }
  }
}
