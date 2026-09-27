import 'package:ghepek_in/shared/widgets/app_icon.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../shared/widgets/summary_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/services/notification_service.dart';
import '../../product/providers/product_provider.dart';
import '../../transaction/providers/transaction_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  DateTime _lastActiveDate = DateTime.now();
  String? _selectedProductCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastActiveDate = _today();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndSendLowStockNotifications();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final today = _today();
      if (today.isAfter(_lastActiveDate)) {
        _lastActiveDate = today;
        _refreshAll();
      }
      _checkAndSendLowStockNotifications();
    }
  }

  void _refreshAll() {
    ref.invalidate(todayStatsProvider);
    ref.invalidate(topProductsProvider);
    ref.invalidate(sevenDayTrendProvider);
    ref.invalidate(lowStockProductsProvider);
    ref.invalidate(productCategoriesProvider);
  }

  Future<void> _checkAndSendLowStockNotifications() async {
    try {
      final lowProducts = await ref
          .read(productRepositoryProvider)
          .getLowStockProducts();
      final today = DateTime.now();
      final notif = NotificationService();
      for (final product in lowProducts) {
        final last = product.lastNotifiedAt;
        final alreadyToday =
            last != null &&
            last.year == today.year &&
            last.month == today.month &&
            last.day == today.day;
        if (!alreadyToday) {
          await notif.showStockAlert(
            product.name,
            product.stock,
            productId: product.id ?? 0,
          );
          await ref
              .read(productRepositoryProvider)
              .updateLastNotifiedAt(product.id!);
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(todayStatsProvider);
    final topProductsAsync = ref.watch(
      topProductsProvider(_selectedProductCategory),
    );
    final trendAsync = ref.watch(sevenDayTrendProvider);
    final lowStockAsync = ref.watch(lowStockProductsProvider);

    final lowStockCount = lowStockAsync.when(
      data: (list) => list.length,
      loading: () => 0,
      error: (_, _) => 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.appName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: AppIcon(PhosphorIconsRegular.storefront),
            onPressed: () => context.push('/products'),
            tooltip: 'Kelola Produk',
          ),
          if (MediaQuery.sizeOf(context).width >= 400) ...[
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: AppIcon(PhosphorIconsRegular.package),
                  onPressed: () => context.push('/low-stock'),
                  tooltip: 'Monitor Stok',
                ),
                if (lowStockCount > 0)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Color(0xFF25D366),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      constraints: BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        lowStockCount > 99 ? '99+' : '$lowStockCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            IconButton(
              icon: AppIcon(PhosphorIconsRegular.clockCounterClockwise),
              onPressed: () => context.push('/transactions'),
              tooltip: 'Riwayat Transaksi',
            ),
            IconButton(
              icon: AppIcon(PhosphorIconsRegular.chartBar),
              onPressed: () => context.push('/reports'),
              tooltip: 'Laporan',
            ),
          ] else
            PopupMenuButton<String>(
              tooltip: 'Menu lainnya',
              icon: const AppIcon(PhosphorIconsRegular.dotsThree),
              onSelected: (route) => context.push(route),
              itemBuilder: (context) => const [
                PopupMenuItem(value: '/low-stock', child: Text('Monitor Stok')),
                PopupMenuItem(
                  value: '/transactions',
                  child: Text('Riwayat Transaksi'),
                ),
                PopupMenuItem(value: '/reports', child: Text('Laporan')),
              ],
            ),
          IconButton(
            tooltip: 'Pengaturan',
            icon: const AppIcon(PhosphorIconsRegular.gear),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshAll();
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppPalette.of(context).pageTopTint,
                AppPalette.of(context).background,
                AppPalette.of(context).pageBottomTint,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, 0.35, 1],
            ),
          ),
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeBanner(lowStockCount),
                SizedBox(height: 24),
                _buildStatsCards(statsAsync),
                SizedBox(height: 24),
                _buildTrendChart(trendAsync),
                SizedBox(height: 24),
                _buildTopProducts(topProductsAsync),
                SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'expense',
            onPressed: () => context.push('/expense/new'),
            icon: AppIcon(PhosphorIconsRegular.money),
            label: Text('Pengeluaran'),
            backgroundColor: AppPalette.of(context).danger,
          ),
          SizedBox(width: 8),
          FloatingActionButton.extended(
            heroTag: 'sale',
            onPressed: () => context.push('/sale/new'),
            icon: AppIcon(PhosphorIconsRegular.shoppingCart),
            label: Text('Penjualan'),
            backgroundColor: AppPalette.of(context).primary,
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner(int lowStockCount) {
    final today = DateFormatter.formatFull(DateTime.now());

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppPalette.of(context).classic
              ? [
                  AppPalette.of(context).primary,
                  AppPalette.of(context).secondary,
                  AppPalette.of(context).accent,
                ]
              : [
                  AppPalette.of(context).primaryDark,
                  AppPalette.of(context).primary,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppPalette.of(context).primary.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              today,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Kasir harian yang lebih hidup',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            lowStockCount > 0
                ? '$lowStockCount produk perlu perhatian. Semua data penjualan, stok, dan laporan siap dipakai hari ini.'
                : 'Semua area utama siap dipakai. Catat transaksi, cek stok, dan pantau usaha tanpa ribet.',
            style: TextStyle(
              color: AppPalette.of(context).pageTopTint,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(AsyncValue<Map<String, double>> statsAsync) {
    return statsAsync.when(
      data: (stats) {
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    title: AppStrings.income,
                    value: CurrencyFormatter.format(stats['income'] ?? 0),
                    icon: PhosphorIconsRegular.trendUp,
                    color: AppPalette.of(context).secondary,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: SummaryCard(
                    title: AppStrings.expense,
                    value: CurrencyFormatter.format(stats['expense'] ?? 0),
                    icon: PhosphorIconsRegular.trendDown,
                    color: AppPalette.of(context).danger,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            SummaryCard(
              title: AppStrings.profit,
              value: CurrencyFormatter.format(stats['profit'] ?? 0),
              icon: PhosphorIconsRegular.wallet,
              color: (stats['profit'] ?? 0) >= 0
                  ? AppPalette.of(context).secondary
                  : AppPalette.of(context).danger,
            ),
          ],
        );
      },
      loading: () => Center(child: CircularProgressIndicator()),
      error: (error, stack) => EmptyState(
        title: 'Gagal memuat data',
        subtitle: error.toString(),
        icon: PhosphorIconsRegular.warningCircle,
      ),
    );
  }

  Widget _buildTrendChart(AsyncValue<List<Map<String, dynamic>>> trendAsync) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tren Pemasukan 7 Hari Terakhir',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppPalette.of(context).textPrimary,
              ),
            ),
            SizedBox(height: 16),
            trendAsync.when(
              data: (data) {
                final now = DateTime.now();
                final Map<String, double> incomeMap = {};
                for (final d in data) {
                  incomeMap[d['date'] as String] = (d['income'] as num)
                      .toDouble();
                }

                final List<BarChartGroupData> barGroups = [];
                double maxY = 1000;
                for (int i = 6; i >= 0; i--) {
                  final day = now.subtract(Duration(days: i));
                  final key =
                      '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                  final income = incomeMap[key] ?? 0;
                  if (income > maxY) maxY = income;
                  barGroups.add(
                    BarChartGroupData(
                      x: 6 - i,
                      barRods: [
                        BarChartRodData(
                          toY: income,
                          color: income > 0
                              ? AppPalette.of(context).primary
                              : AppPalette.of(
                                  context,
                                ).primary.withValues(alpha: 0.2),
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  );
                }

                if (barGroups.every((g) => g.barRods.first.toY == 0)) {
                  return SizedBox(
                    height: 80,
                    child: Center(
                      child: Text(
                        'Belum ada data penjualan minggu ini',
                        style: TextStyle(
                          color: AppPalette.of(context).textSecondary,
                        ),
                      ),
                    ),
                  );
                }

                return SizedBox(
                  height: 140,
                  child: BarChart(
                    BarChartData(
                      maxY: maxY * 1.2,
                      barGroups: barGroups,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY / 4,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: AppPalette.of(context).divider,
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final day = now.subtract(
                                Duration(days: 6 - value.toInt()),
                              );
                              return Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  DateFormatter.formatShortDay(day),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppPalette.of(context).textSecondary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
              loading: () => SizedBox(
                height: 140,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SizedBox(height: 40),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addProductCategory() async {
    final formKey = GlobalKey<FormState>();
    var draft = '';
    var saving = false;
    String? error;
    final repository = ref.read(productRepositoryProvider);
    final name = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => PopScope(
          canPop: !saving,
          child: AlertDialog(
            title: Text('Tambahkan kategori produk'),
            content: Form(
              key: formKey,
              child: TextFormField(
                autofocus: true,
                enabled: !saving,
                maxLength: 60,
                decoration: InputDecoration(
                  labelText: 'Nama kategori',
                  hintText: 'Contoh: Peralatan Dapur',
                  errorText: error,
                ),
                onChanged: (value) {
                  draft = value;
                  if (error != null) setDialogState(() => error = null);
                },
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nama kategori wajib diisi'
                    : null,
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialogContext),
                child: Text('Batal'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() {
                          saving = true;
                          error = null;
                        });
                        try {
                          final category = await repository.addCategory(draft);
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext, category);
                          }
                        } catch (e) {
                          if (!dialogContext.mounted) return;
                          setDialogState(() {
                            saving = false;
                            error = e is ArgumentError
                                ? e.message.toString()
                                : 'Gagal menyimpan kategori. Coba lagi.';
                          });
                        }
                      },
                child: Text(saving ? 'Menyimpan...' : 'Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
    if (name == null || !mounted) return;
    ref.invalidate(productCategoriesProvider);
    setState(() => _selectedProductCategory = name);
  }

  Widget _buildTopProducts(
    AsyncValue<List<Map<String, dynamic>>> productsAsync,
  ) {
    final categoriesAsync = ref.watch(productCategoriesProvider);
    final categories = <String, String>{
      for (final name
          in categoriesAsync.asData?.value ?? suggestedProductCategories)
        productCategoryKey(name): name,
      if (_selectedProductCategory != null &&
          _selectedProductCategory!.isNotEmpty)
        productCategoryKey(_selectedProductCategory!):
            _selectedProductCategory!,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Produk Terlaris Hari Ini',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppPalette.of(context).textPrimary,
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Flexible(
              child: IntrinsicWidth(
                child: DropdownButtonFormField<String>(
                  icon: const AppIcon(PhosphorIconsRegular.caretDown),
                  key: ValueKey(_selectedProductCategory),
                  initialValue: _selectedProductCategory,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Filter kategori produk',
                  ),
                  hint: _selectedProductCategory == null
                      ? Text('Semua kategori')
                      : null,
                  selectedItemBuilder: (_) => [
                    for (var i = 0; i < categories.length + 2; i++)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _selectedProductCategory == null
                              ? 'Semua kategori'
                              : _selectedProductCategory!.isEmpty
                              ? 'Tanpa kategori'
                              : _selectedProductCategory!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text('Semua kategori'),
                    ),
                    DropdownMenuItem(value: '', child: Text('Tanpa kategori')),
                    for (final category in categories.values)
                      DropdownMenuItem(
                        value: category,
                        child: Text(category, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedProductCategory = value),
                ),
              ),
            ),
            SizedBox(width: 8),
            Tooltip(
              message: 'Tambahkan kategori produk',
              child: TextButton.icon(
                onPressed: _addProductCategory,
                icon: AppIcon(PhosphorIconsRegular.plus),
                label: Text('Tambah kategori'),
              ),
            ),
          ],
        ),
        if (categoriesAsync.hasError)
          Text(
            'Daftar kategori belum dapat dimuat. Tarik layar untuk mencoba lagi.',
          ),
        SizedBox(height: 12),
        productsAsync.when(
          data: (products) {
            if (products.isEmpty) {
              return EmptyState(
                title: _selectedProductCategory == null
                    ? 'Belum ada penjualan hari ini'
                    : 'Belum ada penjualan di kategori ini hari ini',
                icon: PhosphorIconsRegular.shoppingBag,
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: products.length,
              separatorBuilder: (_, _) => SizedBox(height: 8),
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppPalette.of(
                        context,
                      ).primary.withValues(alpha: 0.1),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: AppPalette.of(context).primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(product['name'] as String? ?? 'Unknown'),
                    trailing: Text(
                      '${product['total_sold']} terjual',
                      style: TextStyle(
                        color: AppPalette.of(context).textSecondary,
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => Center(child: CircularProgressIndicator()),
          error: (error, stack) => EmptyState(
            title: 'Gagal memuat produk terlaris',
            icon: PhosphorIconsRegular.warningCircle,
          ),
        ),
      ],
    );
  }
}
