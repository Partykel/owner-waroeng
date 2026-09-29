import 'package:owner_waroeng/shared/widgets/app_icon.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/income_chart.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_strings.dart';
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
  final _scrollController = ScrollController();

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
    _scrollController.dispose();
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
            tooltip: 'Kelola Produk',
            icon: const AppIcon(PhosphorIconsRegular.storefront),
            onPressed: () => context.go('/products'),
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
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ringkasan hari ini',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                DateFormatter.formatFull(DateTime.now()),
                style: TextStyle(color: AppPalette.of(context).textSecondary),
              ),
              const SizedBox(height: 16),
              _buildStatsCards(statsAsync),
              const SizedBox(height: 16),
              AppButton(
                text: 'Catat penjualan',
                icon: PhosphorIconsRegular.shoppingCart,
                fullWidth: true,
                onPressed: () => context.push('/sale/new'),
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final buttons = [
                    AppButton(
                      text: 'Beli stok',
                      type: AppButtonType.secondary,
                      icon: PhosphorIconsRegular.package,
                      onPressed: () =>
                          context.push('/expense/new?category=stok'),
                    ),
                    AppButton(
                      text: 'Pengeluaran',
                      type: AppButtonType.secondary,
                      icon: PhosphorIconsRegular.money,
                      onPressed: () => context.push('/expense/new'),
                    ),
                  ];
                  if (MediaQuery.textScalerOf(context).scale(14) > 19) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        buttons[0],
                        const SizedBox(height: 8),
                        buttons[1],
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: buttons[0]),
                      const SizedBox(width: 8),
                      Expanded(child: buttons[1]),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: AppIcon(
                  PhosphorIconsRegular.package,
                  color: AppPalette.of(context).primary,
                ),
                title: const Text('Stok perlu perhatian'),
                subtitle: Text('$lowStockCount produk mulai menipis'),
                trailing: const AppIcon(PhosphorIconsRegular.caretRight),
                onTap: () => context.push('/low-stock'),
              ),
              const Divider(height: 32),
              _buildTopProducts(topProductsAsync),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '7 hari terakhir',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/reports'),
                    child: const Text('Laporan'),
                  ),
                ],
              ),
              trendAsync.when(
                data: (data) => IncomeChart(
                  data: data,
                  scrollController: _scrollController,
                ),
                loading: () => const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, st) => TextButton(
                  onPressed: () => ref.invalidate(sevenDayTrendProvider),
                  child: const Text('Gagal memuat grafik. Coba lagi'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards(AsyncValue<Map<String, double>> statsAsync) =>
      statsAsync.when(
        data: (stats) => Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppPalette.of(context).summary,
            borderRadius: BorderRadius.circular(18),
          ),
          child: DefaultTextStyle(
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Noto Sans',
              fontSize: 14,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pemasukan hari ini'),
                const SizedBox(height: 8),
                Text(
                  CurrencyFormatter.format(stats['income'] ?? 0),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 24,
                  runSpacing: 16,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pengeluaran'),
                        Text(
                          CurrencyFormatter.format(stats['expense'] ?? 0),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Selisih'),
                        Text(
                          CurrencyFormatter.format(stats['profit'] ?? 0),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Selisih = pemasukan - pengeluaran',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => TextButton(
          onPressed: () => ref.invalidate(todayStatsProvider),
          child: const Text('Gagal memuat ringkasan. Coba lagi'),
        ),
      );

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
        Flex(
          direction: MediaQuery.textScalerOf(context).scale(14) > 19
              ? Axis.vertical
              : Axis.horizontal,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              flex: MediaQuery.textScalerOf(context).scale(14) > 19 ? 0 : 1,
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
                    subtitle: Text(
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
