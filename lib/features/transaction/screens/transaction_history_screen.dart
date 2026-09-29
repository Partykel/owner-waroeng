import 'package:owner_waroeng/shared/widgets/app_icon.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../product/providers/product_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  String _filterType = 'all';
  DateTime? _selectedDate;
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat'),
        actions: [
          IconButton(
            icon: AppIcon(PhosphorIconsRegular.calendar),
            tooltip: 'Pilih tanggal',
            onPressed: _pickDate,
          ),
          if (_selectedDate != null)
            IconButton(
              icon: AppIcon(PhosphorIconsRegular.x),
              tooltip: 'Hapus filter tanggal',
              onPressed: () => setState(() => _selectedDate = null),
            ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildDateBanner()),
            SliverToBoxAdapter(child: _buildFilterChips()),
            transactionsAsync.when(
              data: (transactions) {
                final filtered = transactions.where((t) {
                  final matchesType =
                      _filterType == 'all' || t.type == _filterType;
                  final matchesDate =
                      _selectedDate == null ||
                      _isSameDate(t.createdAt, _selectedDate!);
                  return matchesType && matchesDate;
                }).toList();
                if (filtered.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: EmptyState(
                      title: 'Belum ada transaksi',
                      subtitle: 'Coba tanggal atau jenis transaksi lainnya.',
                      icon: PhosphorIconsRegular.receipt,
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildTransactionCard(filtered[index]),
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (error, stack) => SliverToBoxAdapter(
                child: Column(
                  children: [
                    const EmptyState(
                      title: 'Gagal memuat transaksi',
                      icon: PhosphorIconsRegular.warningCircle,
                    ),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(transactionHistoryProvider),
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateBanner() {
    final label = _selectedDate == null
        ? 'Semua tanggal'
        : DateFormatter.formatFull(_selectedDate!);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          AppIcon(
            PhosphorIconsRegular.calendarCheck,
            size: 18,
            color: AppPalette.of(context).textSecondary,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppPalette.of(context).textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          _buildFilterChip('all', 'Semua'),
          _buildFilterChip('income', 'Pemasukan'),
          _buildFilterChip('expense', 'Pengeluaran'),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final initial = _selectedDate ?? DateTime.now();
    final firstDate = DateTime(2020);
    final lastDate = DateTime.now().add(Duration(days: 365));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null && mounted) {
      setState(
        () => _selectedDate = DateTime(picked.year, picked.month, picked.day),
      );
    }
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filterType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _filterType = value);
      },
      selectedColor: AppPalette.of(context).primary.withValues(alpha: 0.2),
      checkmarkColor: AppPalette.of(context).primary,
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final isIncome = transaction.isIncome;

    return FutureBuilder<_TransactionCardData>(
      future: _getTransactionCardData(transaction),
      builder: (context, snapshot) {
        final cardData =
            snapshot.data ??
            _TransactionCardData(
              amount: 0,
              title: _getTransactionTypeLabel(transaction),
              subtitle: _getTransactionTypeLabel(transaction),
            );

        return Dismissible(
          key: ValueKey(transaction.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppPalette.of(context).danger,
              borderRadius: BorderRadius.circular(12),
            ),
            child: AppIcon(PhosphorIconsRegular.trash, color: Colors.white),
          ),
          confirmDismiss: (_) => _confirmDelete(transaction),
          onDismissed: (_) => _refreshAfterDelete(transaction),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          cardData.title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Hapus transaksi',
                        onPressed: _deleting
                            ? null
                            : () async {
                                if (await _confirmDelete(transaction) &&
                                    mounted) {
                                  _refreshAfterDelete(transaction);
                                }
                              },
                        icon: const AppIcon(PhosphorIconsRegular.trash),
                      ),
                    ],
                  ),
                  Text(
                    snapshot.hasError
                        ? 'Nominal belum dapat dimuat'
                        : snapshot.hasData
                        ? CurrencyFormatter.format(cardData.amount)
                        : 'Memuat nominal...',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isIncome
                          ? AppPalette.of(context).secondary
                          : AppPalette.of(context).danger,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (cardData.subtitle.isNotEmpty) Text(cardData.subtitle),
                  Text(
                    DateFormatter.formatDateTime(transaction.createdAt),
                    style: TextStyle(
                      color: AppPalette.of(context).textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirmDelete(Transaction transaction) async {
    if (_deleting) return false;
    setState(() => _deleting = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Hapus Transaksi?'),
          content: SingleChildScrollView(
            child: Text(
              transaction.isIncome
                  ? 'Transaksi dihapus permanen dan stok barang penjualan dikembalikan.'
                  : transaction.category == 'stok'
                  ? 'Transaksi dihapus permanen dan stok pembelian dikurangi. Penghapusan ditolak jika stok sudah terpakai.'
                  : 'Transaksi ini akan dihapus secara permanen.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.of(context).danger,
              ),
              child: const Text(AppStrings.delete),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return false;
      await ref
          .read(transactionRepositoryProvider)
          .deleteTransaction(transaction.id!);
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menghapus: $error')));
      }
      return false;
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  void _refreshAfterDelete(Transaction transaction) {
    ref.invalidate(transactionHistoryProvider);
    ref.invalidate(todayStatsProvider);
    ref.invalidate(sevenDayTrendProvider);
    if (transaction.isIncome ||
        (transaction.isExpense && transaction.category == 'stok')) {
      ref.invalidate(allProductsProvider);
      ref.invalidate(lowStockProductsProvider);
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text(AppStrings.deleteSuccess)));
  }

  Future<_TransactionCardData> _getTransactionCardData(
    Transaction transaction,
  ) async {
    final details = await ref
        .read(transactionRepositoryProvider)
        .getTransactionDetails(transaction.id!);

    final amount = details.fold<double>(
      0.0,
      (sum, item) =>
          sum +
          ((item['quantity'] as num).toDouble() *
              (item['price_at_sale'] as num).toDouble()),
    );

    final title = _buildTransactionItemTitle(transaction, details);

    return _TransactionCardData(
      amount: amount,
      title: title,
      subtitle: _buildTransactionSubtitle(transaction, title),
    );
  }

  String _buildTransactionItemTitle(
    Transaction transaction,
    List<Map<String, dynamic>> details,
  ) {
    final itemSummary = _summarizeProductNames(details);

    if (transaction.isIncome) {
      return itemSummary ?? 'Penjualan';
    }

    if (transaction.category == 'stok') {
      return itemSummary ?? 'Beli Stok';
    }

    final note = transaction.note?.trim();
    if (note != null && note.isNotEmpty) {
      return note;
    }

    return _getTransactionTypeLabel(transaction);
  }

  String _buildTransactionSubtitle(Transaction transaction, String title) {
    final typeLabel = _getTransactionTypeLabel(transaction);
    return title == typeLabel ? '' : typeLabel;
  }

  String _getTransactionTypeLabel(Transaction transaction) {
    const categoryMap = {
      'stok': 'Beli Stok',
      'operasional': 'Operasional',
      'lainnya': 'Lainnya',
    };

    if (transaction.isIncome) {
      return 'Penjualan';
    }

    return categoryMap[transaction.category] ?? 'Pengeluaran';
  }

  String? _summarizeProductNames(List<Map<String, dynamic>> details) {
    final uniqueNames = LinkedHashSet<String>.from(
      details
          .map((item) => (item['product_name'] as String?)?.trim())
          .whereType<String>()
          .where((name) => name.isNotEmpty),
    ).toList();

    if (uniqueNames.isEmpty) return null;
    if (uniqueNames.length == 1) return uniqueNames.first;

    return '${uniqueNames.first} +${uniqueNames.length - 1} lainnya';
  }
}

class _TransactionCardData {
  final double amount;
  final String title;
  final String subtitle;

  const _TransactionCardData({
    required this.amount,
    required this.title,
    required this.subtitle,
  });
}
