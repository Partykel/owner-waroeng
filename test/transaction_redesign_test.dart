import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:owner_waroeng/features/product/models/product.dart';
import 'package:owner_waroeng/features/product/providers/product_provider.dart';
import 'package:owner_waroeng/features/product/repositories/product_repository.dart';
import 'package:owner_waroeng/features/transaction/models/transaction.dart';
import 'package:owner_waroeng/features/transaction/providers/transaction_provider.dart';
import 'package:owner_waroeng/features/transaction/repositories/transaction_repository.dart';
import 'package:owner_waroeng/features/transaction/screens/add_sale_screen.dart';
import 'package:owner_waroeng/features/transaction/screens/add_expense_screen.dart';
import 'package:owner_waroeng/shared/theme/app_theme.dart';

class _Products extends ProductRepository {
  @override
  Future<List<Product>> getAll() async => [
    Product(
      id: 1,
      name: 'Beras premium panjang',
      sellPrice: 12000,
      costPrice: 8000,
      stock: 15,
    ),
  ];
  @override
  Future<Product?> getById(int id) async => null;
}

class _Sales extends TransactionRepository {
  int sales = 0, expenses = 0;
  bool fail = false;
  @override
  Future<Transaction> createSale({
    required List<Map<String, dynamic>> items,
    String? note,
  }) async {
    if (fail) throw StateError('gagal uji');
    sales++;
    return Transaction(type: 'income', id: sales);
  }

  @override
  Future<Transaction> createExpense({
    double? amount,
    required String category,
    String? note,
    List<Map<String, dynamic>>? restockItems,
  }) async {
    expenses++;
    return Transaction(type: 'expense', category: category, id: expenses);
  }

  @override
  Future<double> getTodayIncome() async => 0;
  @override
  Future<double> getTodayExpense() async => 0;
}

void main() {
  for (final classic in [true, false]) {
    for (final width in [320.0, 360.0, 412.0]) {
      testWidgets('sale and restock at ${width}px 200% theme $classic', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final products = _Products(), sales = _Sales();
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const Scaffold(body: Text('Home')),
            ),
            GoRoute(path: '/sale', builder: (_, _) => const AddSaleScreen()),
            GoRoute(
              path: '/stock',
              builder: (_, _) =>
                  const AddExpenseScreen(initialCategory: 'stok'),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              productRepositoryProvider.overrideWithValue(products),
              transactionRepositoryProvider.overrideWithValue(sales),
            ],
            child: MaterialApp.router(
              theme: buildAppTheme(classic),
              routerConfig: router,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
            ),
          ),
        );
        router.push('/sale');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.byTooltip('Tambah Beras premium panjang'),
          120,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Tambah Beras premium panjang'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Simpan penjualan'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(sales.sales, 1);
        expect(find.text('Penjualan tersimpan'), findsOneWidget);
        await tester.tap(find.text('Lanjutkan'));
        await tester.pumpAndSettle();
        expect(sales.sales, 1);
        expect(find.text('Home'), findsOneWidget);
        router.push('/stock');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.byTooltip('Tambah Beras premium panjang'),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Tambah Beras premium panjang'));
        await tester.pumpAndSettle();
        expect(find.textContaining('8.000'), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }
    testWidgets(
      'failed sale keeps selection and shows no success theme $classic',
      (tester) async {
        final products = _Products(), sales = _Sales()..fail = true;
        final router = GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, _) => const AddSaleScreen()),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              productRepositoryProvider.overrideWithValue(products),
              transactionRepositoryProvider.overrideWithValue(sales),
            ],
            child: MaterialApp.router(
              theme: buildAppTheme(classic),
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Tambah Beras premium panjang'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Simpan penjualan'));
        await tester.pumpAndSettle();
        expect(sales.sales, 0);
        expect(find.text('Penjualan tersimpan'), findsNothing);
        expect(find.textContaining('gagal uji'), findsWidgets);
        expect(find.textContaining('Dipilih (1)'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
