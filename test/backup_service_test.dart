import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:owner_waroeng/core/database/db_migrations.dart';
import 'package:owner_waroeng/core/database/db_helper.dart';
import 'package:owner_waroeng/features/settings/backup_service.dart';
import 'package:owner_waroeng/features/settings/settings_provider.dart';

void main() {
  late Database db;
  late Directory directory;
  late BackupService service;
  setUpAll(sqfliteFfiInit);
  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        version: DbMigrations.currentVersion,
        onCreate: (db, _) async {
          for (final sql in DbMigrations.onCreateQueries) {
            await db.execute(sql);
          }
        },
      ),
    );
    directory = await Directory.systemTemp.createTemp('owner-backup-test-');
    service = BackupService(db, directory);
    await db.insert('products', {
      'id': 7,
      'name': 'Arsip',
      'category': 'Snack',
      'sell_price': 12000.5,
      'cost_price': 8000,
      'stock': 4,
      'is_deleted': 1,
      'deleted_at': '2026-09-24T12:00:00',
    });
    await db.insert('products', {
      'id': 8,
      'name': 'Aktif',
      'category': 'Snack',
      'sell_price': 15000,
      'cost_price': 9000,
      'stock': 6,
    });
    await db.insert('product_categories', {'name': 'Tanpa produk'});
    await db.insert('transactions', {'id': 11, 'type': 'income'});
    await db.insert('transactions', {
      'id': 12,
      'type': 'expense',
      'category': 'stok',
    });
    await db.insert('transaction_items', {
      'id': 21,
      'transaction_id': 11,
      'product_id': 7,
      'quantity': 2,
      'price_at_sale': 10000.25,
    });
    await db.insert('transaction_items', {
      'id': 22,
      'transaction_id': 12,
      'product_id': null,
      'quantity': 1,
      'price_at_sale': 8000,
    });
    await db.insert('stock_adjustments', {
      'id': 31,
      'product_id': 7,
      'quantity_change': -2,
      'reason': 'sale',
      'transaction_id': 11,
    });
    await db.insert('stock_adjustments', {
      'id': 32,
      'product_id': 7,
      'quantity_change': 1,
      'reason': 'restock',
      'transaction_id': 12,
    });
    await db.insert('app_settings', {'key': 'theme', 'value': 'classic'});
  });
  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });

  test(
    'round trip preserves all rows, relations, sequences, report totals and theme',
    () async {
      final original = await service.export();
      expect(original.document['appId'], 'com.pendodol.ownerwaroeng');
      await db.update('products', {'stock': 99}, where: 'id=7');
      await db.update('app_settings', {'value': 'forui'});
      final recovery = await service.restore(
        BackupData.decode(original.encode()),
      );
      final actual = await service.export();
      expect(actual.document['data'], original.document['data']);
      expect(actual.document['sequences'], original.document['sequences']);
      expect(actual.theme, 'classic');
      expect(
        (await db.rawQuery(
          'SELECT SUM(quantity * price_at_sale) total FROM transaction_items WHERE transaction_id=11',
        )).single['total'],
        20000.5,
      );
      final old = BackupData.decode(await recovery.readAsBytes());
      expect(old.rows('products').first['stock'], 99);
      expect(old.theme, 'forui');
      expect((await service.latestRecovery())!.path, recovery.path);
    },
  );

  test(
    'invalid structure, versions, duplicate IDs, relations and numeric values rejected without writes',
    () async {
      final original = await service.export();
      final edits = <void Function(Map<String, dynamic>)>[
        (d) => d['formatVersion'] = 99,
        (d) => d['createdAt'] = '2026-02-31T12:00:00Z',
        (d) => d['schemaVersion'] = 99,
        (d) => d['appId'] = 'other',
        (d) => d['data']['products'][0]['stock'] = '4',
        (d) => d['data']['products'][0]['stock'] = -1,
        (d) => d['data']['products'][0]['is_deleted'] = true,
        (d) => d['data']['products'][0].remove('name'),
        (d) => d['data']['products'].add(d['data']['products'][0]),
        (d) => d['data']['transaction_items'][0]['product_id'] = 999,
        (d) => d['data']['transactions'][0]['created_at'] = 'broken',
        (d) => d['data']['product_categories'].add({'name': 'sNaCk'}),
        (d) => d['sequences']['products'] = 0,
      ];
      for (final edit in edits) {
        final doc =
            jsonDecode(utf8.decode(original.encode())) as Map<String, dynamic>;
        edit(doc);
        expect(
          () => BackupData.decode(utf8.encode(jsonEncode(doc))),
          throwsFormatException,
        );
      }
      expect(
        () => BackupData.decode(utf8.encode('{broken')),
        throwsFormatException,
      );
      await expectLater(
        BackupData.read(Stream.value(List.filled(BackupData.maxBytes + 1, 0))),
        throwsFormatException,
      );
      expect(
        (await service.export()).document['data'],
        original.document['data'],
      );
    },
  );

  test(
    'failed recovery copy and failure halfway through inserts roll back everything',
    () async {
      final backup = await service.export();
      await db.update('products', {'stock': 88});
      await db.update('app_settings', {'value': 'forui'});
      final before = await service.export();
      final blockingFile = File('${directory.path}/not-a-directory');
      await blockingFile.writeAsString('test');
      await expectLater(
        BackupService(db, Directory(blockingFile.path)).restore(backup),
        throwsA(isA<FileSystemException>()),
      );
      expect(
        (await service.export()).document['data'],
        before.document['data'],
      );
      await db.execute(
        "CREATE TRIGGER fail_restore BEFORE INSERT ON transaction_items BEGIN SELECT RAISE(ABORT, 'injected failure'); END",
      );
      await expectLater(
        service.restore(backup),
        throwsA(isA<DatabaseException>()),
      );
      final after = await service.export();
      expect(after.document['data'], before.document['data']);
      expect(after.document['sequences'], before.document['sequences']);
      expect(after.theme, 'forui');
      expect(DbHelper().restoring, false);
      expect(await service.latestRecovery(), isNotNull);
    },
  );

  test(
    'recovery selection skips incomplete and invalid newer snapshots',
    () async {
      final backup = await service.export();
      final valid = File(path.join(directory.path, 'before-restore-100.json'));
      await valid.writeAsBytes(backup.encode());
      await File(
        '${directory.path}/before-restore-200.json',
      ).writeAsString('{');
      await File(
        '${directory.path}/before-restore-300.json.tmp',
      ).writeAsBytes(backup.encode());

      expect((await service.latestRecovery())?.path, valid.path);
      await valid.delete();
      expect(await service.latestRecovery(), isNull);
    },
  );

  test(
    'migration v4 to v5 preserves data and stored theme survives reopened database',
    () async {
      final file = '${directory.path}/migration.db';
      var local = await databaseFactoryFfi.openDatabase(
        file,
        options: OpenDatabaseOptions(
          version: 4,
          onCreate: (db, _) async {
            for (final sql in DbMigrations.onCreateQueries.where(
              (s) => !s.contains('app_settings'),
            )) {
              await db.execute(sql);
            }
            await db.insert('products', {
              'name': 'Lama',
              'stock': 13,
              'sell_price': 10,
              'cost_price': 5,
            });
          },
        ),
      );
      await local.close();
      local = await databaseFactoryFfi.openDatabase(
        file,
        options: OpenDatabaseOptions(
          version: 5,
          onUpgrade: (db, old, next) async {
            for (final sql in DbMigrations.getUpgradeQueries(old, next)) {
              await db.execute(sql);
            }
          },
        ),
      );
      expect((await local.query('products')).single['stock'], 13);
      expect(await readTheme(local), 'forui');
      await local.insert('app_settings', {'key': 'theme', 'value': 'classic'});
      await local.close();
      local = await databaseFactoryFfi.openDatabase(file);
      expect(await readTheme(local), 'classic');
      await local.close();
    },
  );
}
