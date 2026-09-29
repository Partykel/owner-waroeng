// Run: flutter run -d emulator-5554 -t tool/verify_backup_android.dart --no-resident
// Uses only an in-memory database and a new temporary recovery directory.
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:owner_waroeng/core/database/db_migrations.dart';
import 'package:owner_waroeng/features/settings/backup_service.dart';

void check(bool condition, String message) {
  if (!condition) throw StateError(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await openDatabase(
    inMemoryDatabasePath,
    version: DbMigrations.currentVersion,
    onConfigure: (db) => db.execute('PRAGMA foreign_keys=ON'),
    onCreate: (db, _) async {
      for (final sql in DbMigrations.onCreateQueries) {
        await db.execute(sql);
      }
    },
  );
  final directory = await Directory.systemTemp.createTemp(
    'owner-backup-verification-',
  );
  try {
    final service = BackupService(db, directory);
    await db.insert('products', {
      'id': 7,
      'name': 'Uji terisolasi',
      'sell_price': 12000,
      'cost_price': 8000,
      'stock': 4,
      'is_deleted': 1,
    });
    await db.insert('transactions', {'id': 9, 'type': 'income'});
    await db.insert('transaction_items', {
      'transaction_id': 9,
      'product_id': 7,
      'quantity': 2,
      'price_at_sale': 11000,
    });
    await db.insert('stock_adjustments', {
      'product_id': 7,
      'quantity_change': -2,
      'reason': 'sale',
      'transaction_id': 9,
    });
    await db.insert('product_categories', {'name': 'Kategori kosong'});
    await db.insert('app_settings', {'key': 'theme', 'value': 'classic'});
    final backup = await service.export();
    await db.update('products', {'stock': 99});
    final recovery = await service.restore(backup);
    final restored = await service.export();
    check(
      jsonEncode(restored.document['data']) ==
          jsonEncode(backup.document['data']),
      'Round trip differs',
    );
    check(restored.theme == 'classic', 'Theme differs');
    check(
      BackupData.decode(
            await recovery.readAsBytes(),
          ).rows('products').single['stock'] ==
          99,
      'Recovery missing',
    );
    await File(
      '${directory.path}/before-restore-999999999999999999.json',
    ).writeAsString('{broken');
    check(
      (await service.latestRecovery())?.path == recovery.path,
      'Corrupt recovery hides valid snapshot',
    );
    await db.update('products', {'stock': 77});
    await db.execute(
      "CREATE TRIGGER fail_restore BEFORE INSERT ON transaction_items BEGIN SELECT RAISE(ABORT, 'test failure'); END",
    );
    var failed = false;
    try {
      await service.restore(backup);
    } on DatabaseException {
      failed = true;
    }
    check(failed, 'Expected failure not raised');
    check(
      (await db.query('products')).single['stock'] == 77,
      'Rollback failed',
    );
    debugPrint(
      'BACKUP_ANDROID_CHECK_PASS: round trip, recovery file, theme, relations, rollback',
    );
    runApp(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('BACKUP_ANDROID_CHECK_PASS'))),
      ),
    );
  } finally {
    await db.close();
    await directory.delete(recursive: true);
  }
}
