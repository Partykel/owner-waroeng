import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:owner_waroeng/features/transaction/models/transaction.dart';
import 'package:owner_waroeng/features/transaction/providers/transaction_provider.dart';
import 'package:owner_waroeng/features/transaction/repositories/transaction_repository.dart';
import 'package:owner_waroeng/features/transaction/screens/transaction_history_screen.dart';
import 'package:owner_waroeng/shared/theme/app_theme.dart';
import 'package:intl/date_symbol_data_local.dart';

class _History extends TransactionRepository {
  int deletes = 0;
  @override
  Future<List<Transaction>> getHistory({
    DateTime? startDate,
    DateTime? endDate,
  }) async => [
    Transaction(id: 1, type: 'income'),
    Transaction(id: 2, type: 'expense', category: 'stok'),
  ];
  @override
  Future<List<Map<String, dynamic>>> getTransactionDetails(int id) async => [
    {
      'quantity': 1,
      'price_at_sale': 987654321000.0,
      'product_name': 'Produk nama panjang untuk pengujian layar kecil',
    },
  ];
  @override
  Future<void> deleteTransaction(int id) async {
    deletes++;
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));
  for (final classic in [true, false]) {
    for (final width in [320.0, 360.0, 412.0]) {
      testWidgets(
        'history $classic ${width}px at 200%: filter and cancel accessible delete',
        (tester) async {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final repository = _History();
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                transactionRepositoryProvider.overrideWithValue(repository),
              ],
              child: MaterialApp(
                theme: buildAppTheme(classic),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(2)),
                  child: child!,
                ),
                home: const TransactionHistoryScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(FilterChip, 'Pengeluaran'));
          await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey<int?>(1)), findsNothing);
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey<int?>(2)),
            120,
          );
          await tester.scrollUntilVisible(
            find.byTooltip('Hapus transaksi').hitTestable(),
            120,
          );
          await tester.tap(find.byTooltip('Hapus transaksi'));
          await tester.pumpAndSettle();
          expect(find.text('Hapus Transaksi?'), findsOneWidget);
          expect(
            find.textContaining('stok pembelian dikurangi'),
            findsOneWidget,
          );
          await tester.tap(find.text('Batal'));
          await tester.pumpAndSettle();
          expect(repository.deletes, 0);
          expect(find.byKey(const ValueKey<int?>(2)), findsOneWidget);
          await tester.scrollUntilVisible(find.text('Beli Stok'), 100);
          expect(find.textContaining('987.654.321.000'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
