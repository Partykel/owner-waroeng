import 'package:ghepek_in/shared/widgets/app_icon.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';
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
    final allProductsAsync = ref.watch(allProductsProvider);

    return allProductsAsync.when(
      data: (allProducts) {
        final lowStockProducts = allProducts
            .where((p) => p.stock <= 0 || p.stock <= p.minStock)
            .toList();
        final filtered = _applyFilterAndSort(lowStockProducts);

        final emptyCount = lowStockProducts.where((p) => p.stock <= 0).length;
        final lowCount = lowStockProducts
            .where((p) => p.stock > 0 && p.stock <= p.minStock)
            .length;

        return Scaffold(
          backgroundColor: AppPalette.of(context).background,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Monitor Stok'),
                if (lowStockProducts.isNotEmpty)
                  Text(
                    '${lowStockProducts.length} produk perlu perhatian',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: AppPalette.of(context).textSecondary,
                    ),
                  ),
              ],
            ),
            actions: [
              PopupMenuButton<StockSort>(
                icon: AppIcon(PhosphorIconsRegular.sortDescending),
                tooltip: 'Urutkan',
                onSelected: (s) => setState(() => _sort = s),
                itemBuilder: (_) => [
                  _sortItem(
                    StockSort.statusAsc,
                    PhosphorIconsRegular.exclamationMark,
                    'Status Kritis Dulu',
                  ),
                  _sortItem(
                    StockSort.stockAsc,
                    PhosphorIconsRegular.arrowUp,
                    'Stok Terendah Dulu',
                  ),
                  _sortItem(
                    StockSort.stockDesc,
                    PhosphorIconsRegular.arrowDown,
                    'Stok Tertinggi Dulu',
                  ),
                  _sortItem(
                    StockSort.nameAsc,
                    PhosphorIconsRegular.sortAscending,
                    'Nama A → Z',
                  ),
                  _sortItem(
                    StockSort.nameDesc,
                    PhosphorIconsRegular.sortAscending,
                    'Nama Z → A',
                  ),
                ],
              ),
              IconButton(
                icon: AppIcon(PhosphorIconsRegular.arrowClockwise),
                tooltip: 'Refresh',
                onPressed: () => ref.invalidate(allProductsProvider),
              ),
            ],
          ),
          body: lowStockProducts.isEmpty
              ? _buildAllSafeState()
              : Column(
                  children: [
                    _buildSummaryBanner(emptyCount, lowCount),
                    _buildFilterBar(emptyCount, lowCount),
                    _buildSortChip(),
                    Expanded(
                      child: filtered.isEmpty
                          ? _buildEmptyFilter()
                          : RefreshIndicator(
                              onRefresh: () async =>
                                  ref.invalidate(allProductsProvider),
                              child: ListView.builder(
                                padding: EdgeInsets.fromLTRB(16, 8, 16, 80),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) =>
                                    _buildStockCard(filtered[index]),
                              ),
                            ),
                    ),
                  ],
                ),
        );
      },
      loading: () => Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  PopupMenuItem<StockSort> _sortItem(
    StockSort value,
    IconData icon,
    String label,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          AppIcon(
            icon,
            size: 18,
            color: _sort == value
                ? AppPalette.of(context).primary
                : AppPalette.of(context).textSecondary,
          ),
          SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: _sort == value
                  ? AppPalette.of(context).primary
                  : AppPalette.of(context).textPrimary,
              fontWeight: _sort == value ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          if (_sort == value) ...[
            Spacer(),
            AppIcon(
              PhosphorIconsRegular.check,
              size: 16,
              color: AppPalette.of(context).primary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryBanner(int emptyCount, int lowCount) {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF2C5282)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _bannerStat(
            emptyCount.toString(),
            'Stok Habis',
            AppPalette.of(context).stockEmpty,
          ),
          Container(width: 1, height: 36, color: Colors.white24),
          _bannerStat(
            lowCount.toString(),
            'Stok Menipis',
            AppPalette.of(context).stockLow,
          ),
          Container(width: 1, height: 36, color: Colors.white24),
          _bannerStat('${emptyCount + lowCount}', 'Total Produk', Colors.white),
        ],
      ),
    );
  }

  Widget _bannerStat(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.white60),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(int emptyCount, int lowCount) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _filterChip(
            StockFilter.all,
            'Semua',
            '${emptyCount + lowCount}',
            AppPalette.of(context).primary,
          ),
          SizedBox(width: 8),
          _filterChip(
            StockFilter.empty,
            'Habis',
            '$emptyCount',
            AppPalette.of(context).stockEmpty,
          ),
          SizedBox(width: 8),
          _filterChip(
            StockFilter.low,
            'Menipis',
            '$lowCount',
            AppPalette.of(context).stockLow,
          ),
        ],
      ),
    );
  }

  Widget _filterChip(
    StockFilter value,
    String label,
    String count,
    Color color,
  ) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.12)
              : AppPalette.of(context).surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppPalette.of(context).divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? color
                    : AppPalette.of(context).textSecondary,
              ),
            ),
            SizedBox(width: 4),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? color : AppPalette.of(context).divider,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : AppPalette.of(context).textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          AppIcon(
            PhosphorIconsRegular.sortDescending,
            size: 14,
            color: AppPalette.of(context).textSecondary,
          ),
          SizedBox(width: 4),
          Text(
            'Diurutkan: $_sortLabel',
            style: TextStyle(
              fontSize: 12,
              color: AppPalette.of(context).textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockCard(Product product) {
    final isEmpty = product.stock <= 0;
    final statusColor = isEmpty
        ? AppPalette.of(context).stockEmpty
        : AppPalette.of(context).stockLow;
    final statusLabel = isEmpty ? 'HABIS' : 'MENIPIS';
    final percentage = product.minStock > 0
        ? (product.stock / product.minStock).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppPalette.of(context).surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: AppIcon(
                    isEmpty
                        ? PhosphorIconsRegular.package
                        : PhosphorIconsRegular.warning,
                    color: statusColor,
                    size: 22,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppPalette.of(context).textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '${CurrencyFormatter.format(product.sellPrice)} / ${product.unit}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppPalette.of(context).textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14),
            Row(
              children: [
                _stockInfoPill(
                  'Stok Saat Ini',
                  '${product.stock} ${product.unit}',
                  statusColor,
                ),
                SizedBox(width: 8),
                _stockInfoPill(
                  'Stok Minimum',
                  '${product.minStock} ${product.unit}',
                  AppPalette.of(context).textSecondary,
                ),
                SizedBox(width: 8),
                _stockInfoPill(
                  'Kekurangan',
                  isEmpty
                      ? '${product.minStock} ${product.unit}'
                      : '${product.minStock - product.stock} ${product.unit}',
                  AppPalette.of(context).textSecondary,
                ),
              ],
            ),
            if (!isEmpty) ...[
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: AppPalette.of(context).divider,
                        color: percentage < 0.3
                            ? AppPalette.of(context).stockEmpty
                            : percentage < 0.6
                            ? AppPalette.of(context).stockLow
                            : AppPalette.of(context).stockSafe,
                        minHeight: 6,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '${(percentage * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stockInfoPill(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppPalette.of(context).background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: AppPalette.of(context).textSecondary,
              ),
            ),
            SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllSafeState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppPalette.of(context).stockSafe.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: AppIcon(
              PhosphorIconsRegular.sealCheck,
              size: 64,
              color: AppPalette.of(context).stockSafe,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Semua Stok Aman!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppPalette.of(context).textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tidak ada produk yang menipis atau habis.',
            style: TextStyle(
              fontSize: 14,
              color: AppPalette.of(context).textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          TextButton.icon(
            onPressed: () => ref.invalidate(allProductsProvider),
            icon: AppIcon(PhosphorIconsRegular.arrowClockwise),
            label: Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilter() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            PhosphorIconsRegular.funnelX,
            size: 48,
            color: AppPalette.of(context).divider,
          ),
          SizedBox(height: 12),
          Text(
            'Tidak ada produk dengan filter ini',
            style: TextStyle(color: AppPalette.of(context).textSecondary),
          ),
          SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _filter = StockFilter.all),
            child: Text('Tampilkan Semua'),
          ),
        ],
      ),
    );
  }
}
