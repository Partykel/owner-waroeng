import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ghepek_in/features/transaction/models/transaction.dart';
import 'package:ghepek_in/features/transaction/providers/transaction_provider.dart';
import 'package:ghepek_in/features/transaction/repositories/transaction_repository.dart';
import 'package:ghepek_in/features/transaction/screens/transaction_history_screen.dart';
import 'package:ghepek_in/shared/theme/app_theme.dart';

class _FailingDelete extends TransactionRepository {
  int attempts = 0;
  @override
  Future<List<Transaction>> getHistory({
    DateTime? startDate,
    DateTime? endDate,
  }) async => [Transaction(id: 1, type: 'expense', category: 'stok')];
  @override
  Future<List<Map<String, dynamic>>> getTransactionDetails(int id) async => [];
  @override
  Future<void> deleteTransaction(int id) async {
    attempts++;
    throw StateError('Stok pembelian sudah terpakai');
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));
  for (final classic in [true, false]) {
    testWidgets(
      'theme $classic: failed deletion keeps transaction visible and shows error',
      (tester) async {
        final repo = _FailingDelete();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [transactionRepositoryProvider.overrideWithValue(repo)],
            child: MaterialApp(
              theme: buildAppTheme(classic),
              home: const TransactionHistoryScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.drag(
          find.byKey(const ValueKey<int?>(1)),
          const Offset(-700, 0),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Hapus').last);
        await tester.pumpAndSettle();
        expect(repo.attempts, 1);
        expect(find.byKey(const ValueKey<int?>(1)), findsOneWidget);
        expect(find.textContaining('Gagal menghapus:'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
