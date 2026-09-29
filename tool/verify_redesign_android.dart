// Production screens with a separate, persistent test database. Never opens the
// owner's normal database directory. Restart this target to check preferences.
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:sqflite/sqflite.dart';
import 'package:ghepek_in/core/database/db_helper.dart';
import 'package:ghepek_in/main.dart' as app;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final directory = Directory(
    '${Directory.systemTemp.path}/owner-redesign-verification',
  );
  await directory.create(recursive: true);
  await databaseFactory.setDatabasesPath(directory.path);
  final db = await DbHelper().database;
  if ((await db.query('products', limit: 1)).isEmpty) {
    await db.transaction((txn) async {
      for (final row in [
        {
          'id': 1,
          'name': 'Beras premium 5 kg',
          'category': 'Sembako',
          'sell_price': 75000,
          'cost_price': 62000,
          'stock': 25,
          'unit': 'pak',
        },
        {
          'id': 2,
          'name': 'Keripik singkong balado',
          'category': 'Snack',
          'sell_price': 10000,
          'cost_price': 6500,
          'stock': 40,
          'unit': 'pcs',
        },
        {
          'id': 3,
          'name': 'Minyak goreng 1 liter',
          'category': 'Sembako',
          'sell_price': 20000,
          'cost_price': 17000,
          'stock': 3,
          'unit': 'botol',
        },
      ]) {
        await txn.insert('products', row);
      }
      final now = DateTime.now();
      final values = [220000, 310000, 260000, 390000, 340000, 410000, 485000];
      for (var i = 0; i < 7; i++) {
        final date = DateTime(
          now.year,
          now.month,
          now.day - 6 + i,
          10,
        ).toIso8601String();
        final id = await txn.insert('transactions', {
          'type': 'income',
          'created_at': date,
        });
        await txn.insert('transaction_items', {
          'transaction_id': id,
          'product_id': 2,
          'quantity': 10,
          'price_at_sale': values[i] / 10,
        });
        await txn.insert('stock_adjustments', {
          'transaction_id': id,
          'product_id': 2,
          'quantity_change': -10,
          'reason': 'sale',
          'created_at': date,
        });
      }
      await txn.insert('product_categories', {
        'name': 'Kategori contoh kosong',
      });
    });
  }
  app.main();
}
