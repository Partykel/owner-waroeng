import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:owner_waroeng/core/database/db_helper.dart';
import 'package:owner_waroeng/features/product/models/product.dart';
import 'package:owner_waroeng/features/product/repositories/product_repository.dart';
import 'package:owner_waroeng/features/transaction/repositories/transaction_repository.dart';

void main() {
  late Directory directory;
  late Database db;
  final products = ProductRepository();
  final sales = TransactionRepository();
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    directory = await Directory.systemTemp.createTemp(
      'owner-repository-audit-',
    );
    await databaseFactory.setDatabasesPath(directory.path);
    db = await DbHelper().database;
  });
  setUp(() async {
    for (final table in [
      'stock_adjustments',
      'transaction_items',
      'transactions',
      'products',
    ]) {
      await db.delete(table);
    }
    await db.insert('products', {
      'id': 1,
      'name': 'Beras',
      'sell_price': 10,
      'cost_price': 5,
      'stock': 0,
    });
  });
  tearDownAll(() async {
    await db.close();
    await directory.delete(recursive: true);
  });
  test(
    'non-finite product prices and expenses cannot corrupt database or backup',
    () async {
      await db.update('products', {'stock': 2});
      for (final price in [double.infinity, double.nan]) {
        await expectLater(
          products.create(
            Product(name: 'Invalid', sellPrice: price, costPrice: 1),
          ),
          throwsArgumentError,
        );
        await expectLater(
          products.update(
            Product(id: 1, name: 'Beras', sellPrice: 10, costPrice: price),
          ),
          throwsArgumentError,
        );
        await expectLater(
          sales.createSale(
            items: [
              {'product_id': 1, 'quantity': 1, 'price_at_sale': price},
            ],
          ),
          throwsArgumentError,
        );
        await expectLater(
          sales.createExpense(amount: price, category: 'operasional'),
          throwsArgumentError,
        );
      }
      expect((await db.query('products')).length, 1);
      expect((await db.query('products')).single['stock'], 2);
      expect(await db.query('transactions'), isEmpty);
    },
  );
  test(
    'restock consumed by a sale cannot be deleted and invent stock on undo',
    () async {
      final restock = await sales.createExpense(
        category: 'stok',
        restockItems: [
          {'product_id': 1, 'quantity': 10},
        ],
      );
      final sale = await sales.createSale(
        items: [
          {'product_id': 1, 'quantity': 8, 'price_at_sale': 10.0},
        ],
      );
      await expectLater(sales.deleteTransaction(restock.id!), throwsStateError);
      expect((await db.query('products')).single['stock'], 2);
      expect((await db.query('transactions')).length, 2);
      await sales.deleteTransaction(sale.id!);
      await sales.deleteTransaction(restock.id!);
      expect((await db.query('products')).single['stock'], 0);
      expect(await db.query('transactions'), isEmpty);
    },
  );
}
