import 'package:ghepek_in/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghepek_in/features/dashboard/screens/dashboard_screen.dart';
import 'package:ghepek_in/features/product/models/product.dart';
import 'package:ghepek_in/features/product/providers/product_provider.dart';
import 'package:ghepek_in/features/product/repositories/product_repository.dart';
import 'package:ghepek_in/features/product/screens/add_edit_product_screen.dart';
import 'package:ghepek_in/features/transaction/providers/transaction_provider.dart';
import 'package:ghepek_in/features/transaction/repositories/transaction_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

class _Products extends ProductRepository {
  final savedCategories = <String>[];
  bool failCategorySave = false;

  @override
  Future<String> addCategory(String category) async {
    if (failCategorySave) throw StateError('Database unavailable');
    final name = category.trim();
    if ([
      ...suggestedProductCategories,
      ...savedCategories,
      product.category,
    ].any((value) => value.toLowerCase() == name.toLowerCase())) {
      throw ArgumentError('Kategori sudah ada.');
    }
    savedCategories.add(name);
    return name;
  }

  Product product = Product(
    id: 1,
    name: 'Beras',
    category: 'Sembako',
    sellPrice: 15000,
    costPrice: 10000,
    stock: 12,
  );

  @override
  Future<List<Product>> getAll() async => [product];
  @override
  Future<Product?> getById(int id) async => product;
  @override
  Future<List<String>> getCategories() async => [
    product.category,
    ...savedCategories,
  ];
  @override
  Future<List<Product>> getLowStockProducts() async => [];
  @override
  Future<int> create(Product value) async {
    product = value;
    return 1;
  }

  @override
  Future<int> update(Product value) async {
    product = value;
    return 1;
  }
}

class _Sales extends TransactionRepository {
  final categories = <String?>[];
  @override
  Future<List<Map<String, dynamic>>> getTopProductsToday({
    int limit = 3,
    String? category,
  }) async {
    categories.add(category);
    return category == ''
        ? []
        : [
            {'name': 'Hasil ${category ?? "semua"}', 'total_sold': 2},
          ];
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID', null));

  test(
    'Category survives serialization, editing and clearing; old products remain uncategorized',
    () {
      final product = Product(
        name: 'Beras',
        sellPrice: 15000,
        costPrice: 10000,
        category: 'Sembako',
      );
      expect(Product.fromMap(product.toMap()).category, 'Sembako');
      expect(product.copyWith(stock: 3).category, 'Sembako');
      expect(product.copyWith(category: '').category, '');
      expect(Product.fromMap(product.toMap()..remove('category')).category, '');
    },
  );

  for (final edit in [false, true]) {
    testWidgets(
      'Shared product form ${edit ? "edits" : "creates"} custom category',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1400));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final products = _Products();
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const Scaffold(body: Text('Kembali')),
            ),
            GoRoute(
              path: '/form',
              builder: (_, _) =>
                  AddEditProductScreen(productId: edit ? 1 : null),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [productRepositoryProvider.overrideWithValue(products)],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        router.push('/form');
        await tester.pumpAndSettle();
        if (edit) expect(find.text('Sembako'), findsOneWidget);
        await tester.enterText(find.byType(TextFormField).at(0), 'Beras');
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'Peralatan Dapur',
        );
        await tester.enterText(find.byType(TextFormField).at(2), '15000');
        await tester.enterText(find.byType(TextFormField).at(3), '10000');
        await tester.tap(find.text(edit ? 'Update Produk' : 'Simpan Produk'));
        await tester.pumpAndSettle();
        expect(products.product.category, 'Peralatan Dapur');
        expect(products.product.stock, edit ? 12 : 0);
        expect(find.text('Kembali'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final classic in [true, false]) {
    testWidgets(
      'Theme $classic: Dashboard selects categories, resets to all and refreshes after product edits',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1600));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final products = _Products();
        final sales = _Sales();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              productRepositoryProvider.overrideWithValue(products),
              transactionRepositoryProvider.overrideWithValue(sales),
              todayStatsProvider.overrideWith(
                (ref) async => {'income': 0, 'expense': 0, 'profit': 0},
              ),
              sevenDayTrendProvider.overrideWith((ref) async => []),
            ],
            child: MaterialApp(
              theme: buildAppTheme(classic),
              home: const DashboardScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final dropdown = find.byType(DropdownButtonFormField<String>);
        await tester.ensureVisible(dropdown);
        final allWidth = tester.getSize(dropdown).width;
        expect(allWidth, lessThan(500));
        await tester.tap(dropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Snack').last);
        await tester.pumpAndSettle();
        expect(sales.categories.last, 'Snack');
        expect(tester.getSize(dropdown).width, lessThanOrEqualTo(allWidth));
        expect(find.text('Hasil Snack'), findsOneWidget);
        await tester.tap(dropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tanpa kategori').last);
        await tester.pumpAndSettle();
        expect(sales.categories.last, '');
        expect(
          find.text('Belum ada penjualan di kategori ini hari ini'),
          findsOneWidget,
        );
        await tester.tap(dropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Semua kategori').last);
        await tester.pumpAndSettle();
        expect(sales.categories.last, isNull);
        final container = ProviderScope.containerOf(
          tester.element(find.byType(DashboardScreen)),
        );
        final before = sales.categories.length;
        await container
            .read(allProductsProvider.notifier)
            .updateProduct(products.product.copyWith(category: 'Dapur'));
        await tester.pumpAndSettle();
        expect(sales.categories.length, greaterThan(before));
        await tester.tap(dropdown);
        await tester.pumpAndSettle();
        expect(find.text('Dapur'), findsOneWidget);
        await tester.tapAt(const Offset(5, 5));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tambah kategori'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Simpan'));
        await tester.pumpAndSettle();
        expect(find.text('Nama kategori wajib diisi'), findsOneWidget);
        await tester.enterText(find.byType(TextFormField), 'snack');
        await tester.tap(find.text('Simpan'));
        await tester.pumpAndSettle();
        expect(find.text('Kategori sudah ada.'), findsOneWidget);
        await tester.enterText(find.byType(TextFormField), 'Peralatan Dapur');
        products.failCategorySave = true;
        await tester.tap(find.text('Simpan'));
        await tester.pumpAndSettle();
        expect(
          find.text('Gagal menyimpan kategori. Coba lagi.'),
          findsOneWidget,
        );
        products.failCategorySave = false;
        await tester.tap(find.text('Simpan'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
        expect(products.savedCategories, ['Peralatan Dapur']);
        expect(sales.categories.last, 'Peralatan Dapur');
        expect(tester.getSize(dropdown).width, greaterThan(allWidth));
        // Test the category controls at phone width independently of existing FABs.
        final categoryRow = tester.widget<Flex>(
          find.ancestor(of: dropdown, matching: find.byType(Flex)).first,
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(classic),
            home: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(width: 320, child: categoryRow),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getRect(dropdown).right,
          lessThanOrEqualTo(tester.getRect(find.text('Tambah kategori')).left),
        );
      },
    );
  }
}
