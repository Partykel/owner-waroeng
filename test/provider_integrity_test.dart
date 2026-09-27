import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghepek_in/features/product/models/product.dart';
import 'package:ghepek_in/features/product/providers/product_provider.dart';
import 'package:ghepek_in/features/product/repositories/product_repository.dart';
import 'package:ghepek_in/features/transaction/models/transaction.dart';
import 'package:ghepek_in/features/transaction/providers/transaction_provider.dart';
import 'package:ghepek_in/features/transaction/repositories/transaction_repository.dart';

class Products extends ProductRepository {
  bool notificationReadFails = false;
  Product product = Product(
    id: 1,
    name: 'Beras',
    sellPrice: 10,
    costPrice: 5,
    stock: 9,
    minStock: 5,
  );
  @override
  Future<List<Product>> getAll() async => [product];
  @override
  Future<List<Product>> getLowStockProducts() async =>
      product.stock <= product.minStock ? [product] : [];
  @override
  Future<Product?> getById(int id) async {
    if (notificationReadFails) {
      throw StateError('Injected notification read failure');
    }
    return null;
  }

  @override
  Future<int> update(Product next) async {
    product = next;
    return 1;
  }

  @override
  Future<List<String>> getCategories() async => [
    '\u00c9pices',
    '\u00e9pices',
    'SNACK',
    'Snack',
  ];
}

class Sales extends TransactionRepository {
  final saved = <Transaction>[];
  bool notificationReadFails = false;
  @override
  Future<Transaction> createSale({
    required List<Map<String, dynamic>> items,
    String? note,
  }) async {
    final tx = Transaction(id: saved.length + 1, type: 'income');
    saved.add(tx);
    return tx;
  }

  @override
  Future<Transaction> createExpense({
    double? amount,
    required String category,
    String? note,
    List<Map<String, dynamic>>? restockItems,
  }) async {
    final tx = Transaction(
      id: saved.length + 1,
      type: 'expense',
      category: category,
    );
    saved.add(tx);
    return tx;
  }

  @override
  Future<double> getTodayIncome() async {
    if (notificationReadFails) {
      throw StateError('Injected notification read failure');
    }
    return 0;
  }

  @override
  Future<double> getTodayExpense() async => 0;
  @override
  Future<List<Transaction>> getHistory({
    DateTime? startDate,
    DateTime? endDate,
  }) async => List.of(saved);
}

void main() {
  late Products products;
  late Sales sales;
  late ProviderContainer container;
  setUp(() {
    products = Products();
    sales = Sales();
    container = ProviderContainer(
      overrides: [
        productRepositoryProvider.overrideWithValue(products),
        transactionRepositoryProvider.overrideWithValue(sales),
      ],
    );
  });
  tearDown(() => container.dispose());
  test(
    'committed sale still succeeds when notification preparation fails',
    () async {
      products.notificationReadFails = true;
      await expectLater(
        container
            .read(addSaleProvider.notifier)
            .call(
              items: [
                {'product_id': 1, 'quantity': 1, 'price_at_sale': 10.0},
              ],
            ),
        completion(isA<Transaction>()),
      );
      expect(sales.saved.length, 1);
      expect(container.read(addSaleProvider)?.id, 1);
    },
  );
  test(
    'committed expense still succeeds when notification preparation fails',
    () async {
      sales.notificationReadFails = true;
      await expectLater(
        container
            .read(addExpenseProvider.notifier)
            .call(amount: 5, category: 'operasional'),
        completion(isA<Transaction>()),
      );
      expect(sales.saved.length, 1);
      expect(container.read(addExpenseProvider)?.id, 1);
    },
  );
  test(
    'saving sale and expense refreshes an already watched history',
    () async {
      container.listen(transactionHistoryProvider, (_, _) {});
      expect(await container.read(transactionHistoryProvider.future), isEmpty);
      await container
          .read(addSaleProvider.notifier)
          .call(
            items: [
              {'product_id': 1, 'quantity': 1, 'price_at_sale': 10.0},
            ],
          );
      expect(
        (await container.read(transactionHistoryProvider.future)).length,
        1,
      );
      await container
          .read(addExpenseProvider.notifier)
          .call(amount: 5, category: 'operasional');
      expect(
        (await container.read(transactionHistoryProvider.future)).length,
        2,
      );
    },
  );
  test('editing product refreshes low stock', () async {
    container.listen(lowStockProductsProvider, (_, _) {});
    await container.read(allProductsProvider.future);
    expect(await container.read(lowStockProductsProvider.future), isEmpty);
    await container
        .read(allProductsProvider.notifier)
        .updateProduct(products.product.copyWith(stock: 2));
    expect(
      (await container.read(lowStockProductsProvider.future)).single.stock,
      2,
    );
  });
  test('Unicode categories remain distinct under SQLite NOCASE', () async {
    container.listen(productCategoriesProvider, (_, _) {});
    final categories = await container.read(productCategoriesProvider.future);
    expect(categories, containsAll(['\u00c9pices', '\u00e9pices']));
    expect(categories.where((c) => c.toLowerCase() == 'snack').length, 1);
  });
}
