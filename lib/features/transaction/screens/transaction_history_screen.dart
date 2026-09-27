import 'package:ghepek_in/shared/widgets/app_icon.dart';
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

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat Transaksi'),
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
      body: Column(
        children: [
          _buildDateBanner(),
          _buildFilterChips(),
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                final filtered = transactions.where((t) {
                  final matchesType =
                      _filterType == 'all' || t.type == _filterType;
                  final matchesDate = _selectedDate == null
                      ? true
                      : _isSameDate(t.createdAt, _selectedDate!);
                  return matchesType && matchesDate;
                }).toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    title: 'Belum ada transaksi',
                    icon: PhosphorIconsRegular.receipt,
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return _buildTransactionCard(filtered[index]);
                  },
                );
              },
              loading: () => Center(child: CircularProgressIndicator()),
              error: (error, stack) => EmptyState(
                title: 'Gagal memuat transaksi',
                subtitle: error.toString(),
                icon: PhosphorIconsRegular.warningCircle,
              ),
            ),
          ),
        ],
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
          if (_selectedDate != null)
            TextButton(
              onPressed: () => setState(() => _selectedDate = null),
              child: Text('Tampilkan semua'),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          _buildFilterChip('all', 'Semua'),
          SizedBox(width: 8),
          _buildFilterChip('income', 'Pemasukan'),
          SizedBox(width: 8),
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
          confirmDismiss: (direction) async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Hapus Transaksi?'),
                content: Text('Transaksi ini akan dihapus secara permanen.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(AppStrings.cancel),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.of(context).danger,
                    ),
                    child: Text(AppStrings.delete),
                  ),
                ],
              ),
            );
            if (confirmed != true || !context.mounted) return false;
            try {
              await ref
                  .read(transactionRepositoryProvider)
                  .deleteTransaction(transaction.id!);
              return true;
            } catch (error) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal menghapus: $error')),
                );
              }
              return false;
            }
          },
          onDismissed: (direction) {
            ref.invalidate(transactionHistoryProvider);
            ref.invalidate(todayStatsProvider);
            ref.invalidate(sevenDayTrendProvider);
            if (transaction.isIncome ||
                (transaction.isExpense && transaction.category == 'stok')) {
              ref.invalidate(allProductsProvider);
              ref.invalidate(lowStockProductsProvider);
            }
            if (!context.mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(AppStrings.deleteSuccess)));
          },
          child: Card(
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: isIncome
                    ? AppPalette.of(context).secondary.withValues(alpha: 0.1)
                    : AppPalette.of(context).danger.withValues(alpha: 0.1),
                child: AppIcon(
                  isIncome
                      ? PhosphorIconsRegular.trendUp
                      : PhosphorIconsRegular.trendDown,
                  color: isIncome
                      ? AppPalette.of(context).secondary
                      : AppPalette.of(context).danger,
                ),
              ),
              title: Text(
                cardData.title,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4),
                  if (cardData.subtitle.isNotEmpty)
                    Text(
                      cardData.subtitle,
                      style: TextStyle(
                        color: AppPalette.of(context).textSecondary,
                      ),
                    ),
                  SizedBox(height: 2),
                  Text(
                    DateFormatter.formatDateTime(transaction.createdAt),
                    style: TextStyle(
                      color: AppPalette.of(context).textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              trailing: Text(
                CurrencyFormatter.format(cardData.amount),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isIncome
                      ? AppPalette.of(context).secondary
                      : AppPalette.of(context).danger,
                ),
              ),
            ),
          ),
        );
      },
    );
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
