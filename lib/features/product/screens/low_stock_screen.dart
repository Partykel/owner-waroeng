import 'package:owner_waroeng/shared/widgets/app_icon.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';
import '../../../core/utils/currency_formatter.dart';

enum StockFilter { all, empty, low }

enum StockSort { nameAsc, nameDesc, stockAsc, stockDesc, statusAsc }

class LowStockScreen extends ConsumerStatefulWidget {
  const LowStockScreen({super.key});

  @override
  ConsumerState<LowStockScreen> createState() => _LowStockScreenState();
}

class _LowStockScreenState extends ConsumerState<LowStockScreen> {
  StockFilter _filter = StockFilter.all;
  StockSort _sort = StockSort.statusAsc;

  List<Product> _applyFilterAndSort(List<Product> products) {
    List<Product> result;

    switch (_filter) {
      case StockFilter.empty:
        result = products.where((p) => p.stock <= 0).toList();
        break;
      case StockFilter.low:
        result = products
            .where((p) => p.stock > 0 && p.stock <= p.minStock)
            .toList();
        break;
      case StockFilter.all:
        result = List.from(products);
        break;
    }

    switch (_sort) {
      case StockSort.nameAsc:
        result.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case StockSort.nameDesc:
        result.sort(
          (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
        );
        break;
      case StockSort.stockAsc:
        result.sort((a, b) {
          final s = a.stock.compareTo(b.stock);
          return s != 0
              ? s
              : a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        break;
      case StockSort.stockDesc:
        result.sort((a, b) {
          final s = b.stock.compareTo(a.stock);
          return s != 0
              ? s
              : a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        break;
      case StockSort.statusAsc:
        result.sort((a, b) {
          int rank(Product p) => p.stock <= 0
              ? 0
              : p.stock <= p.minStock
              ? 1
              : 2;
          final s = rank(a).compareTo(rank(b));
          return s != 0 ? s : a.stock.compareTo(b.stock);
        });
        break;
    }

    return result;
  }

  String get _sortLabel {
    switch (_sort) {
      case StockSort.nameAsc:
        return 'Nama A→Z';
      case StockSort.nameDesc:
        return 'Nama Z→A';
      case StockSort.stockAsc:
        return 'Stok Terendah';
      case StockSort.stockDesc:
        return 'Stok Tertinggi';
      case StockSort.statusAsc:
        return 'Status Kritis';
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(allProductsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitor Stok'),
        actions: [
          PopupMenuButton<StockSort>(
            tooltip: 'Urutkan',
            icon: const AppIcon(PhosphorIconsRegular.sortDescending),
            onSelected: (sort) => setState(() => _sort = sort),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: StockSort.statusAsc,
                child: Text('Status Kritis Dulu'),
              ),
              PopupMenuItem(
                value: StockSort.stockAsc,
                child: Text('Stok Terendah Dulu'),
              ),
              PopupMenuItem(
                value: StockSort.stockDesc,
                child: Text('Stok Tertinggi Dulu'),
              ),
              PopupMenuItem(value: StockSort.nameAsc, child: Text('Nama A?Z')),
              PopupMenuItem(value: StockSort.nameDesc, child: Text('Nama Z?A')),
            ],
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(allProductsProvider),
            icon: const AppIcon(PhosphorIconsRegular.arrowClockwise),
          ),
        ],
      ),
      body: products.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Gagal memuat stok'),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(allProductsProvider),
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            ),
          ),
        ),
        data: (all) {
          final low = all.where((p) => p.stock <= p.minStock).toList();
          final filtered = _applyFilterAndSort(low);
          final emptyCount = low.where((p) => p.stock <= 0).length;
          return RefreshIndicator(
            onRefresh: () => ref.read(allProductsProvider.notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  low.isEmpty
                      ? 'Semua stok aman'
                      : '${low.length} produk perlu perhatian',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '$emptyCount habis · ${low.length - emptyCount} menipis',
                  style: TextStyle(color: AppPalette.of(context).textSecondary),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in const {
                      StockFilter.all: 'Semua',
                      StockFilter.empty: 'Habis',
                      StockFilter.low: 'Menipis',
                    }.entries)
                      Semantics(
                        selected: _filter == entry.key,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            backgroundColor: _filter == entry.key
                                ? AppPalette.of(context).primarySoft
                                : null,
                          ),
                          onPressed: () => setState(() => _filter = entry.key),
                          child: Text(entry.value),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Diurutkan: $_sortLabel',
                  style: TextStyle(color: AppPalette.of(context).textSecondary),
                ),
                const SizedBox(height: 12),
                if (filtered.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      low.isEmpty
                          ? 'Tidak ada produk yang menipis atau habis.'
                          : 'Tidak ada produk dengan filter ini',
                    ),
                  ),
                  if (low.isNotEmpty)
                    TextButton(
                      onPressed: () =>
                          setState(() => _filter = StockFilter.all),
                      child: const Text('Tampilkan Semua'),
                    ),
                ],
                for (final product in filtered) _buildStockCard(product),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.push('/expense/new?category=stok'),
                  icon: const AppIcon(PhosphorIconsRegular.shoppingCart),
                  label: const Text('Beli Stok'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStockCard(Product product) {
    final empty = product.stock <= 0;
    final color = empty
        ? AppPalette.of(context).stockEmpty
        : AppPalette.of(context).stockLow;
    final percentage = product.minStock > 0
        ? (product.stock / product.minStock).clamp(0.0, 1.0)
        : 0.0;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              '${CurrencyFormatter.format(product.sellPrice)} / ${product.unit}',
              style: TextStyle(color: AppPalette.of(context).textSecondary),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                Text(
                  '${empty ? 'Habis' : 'Menipis'} · ${product.stock} ${product.unit}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Minimum ${product.minStock} · Kurang ${product.minStock - product.stock}',
                ),
              ],
            ),
            if (!empty) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: percentage,
                backgroundColor: AppPalette.of(context).divider,
                color: color,
                minHeight: 6,
                semanticsLabel: 'Stok dibanding minimum',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
