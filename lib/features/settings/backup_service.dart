import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import '../../core/database/db_helper.dart';
import '../../core/database/db_migrations.dart';
import 'settings_provider.dart';

class BackupData {
  static const maxBytes = 20 * 1024 * 1024;
  static const tables = [
    'products',
    'product_categories',
    'transactions',
    'transaction_items',
    'stock_adjustments',
  ];
  final Map<String, dynamic> document;
  BackupData._(this.document);
  String get theme => document['theme'] as String;
  DateTime get createdAt => DateTime.parse(document['createdAt'] as String);
  List<Map<String, Object?>> rows(String table) =>
      (document['data'][table] as List)
          .map((e) => Map<String, Object?>.from(e as Map))
          .toList();
  Uint8List encode() => Uint8List.fromList(utf8.encode(jsonEncode(document)));

  static Future<BackupData> read(Stream<List<int>> stream) async {
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in stream) {
      if (bytes.length + chunk.length > maxBytes) {
        throw const FormatException('Backup maksimal 20 MB.');
      }
      bytes.add(chunk);
    }
    return decode(bytes.takeBytes());
  }

  static BackupData decode(List<int> bytes) {
    if (bytes.isEmpty || bytes.length > maxBytes) {
      throw const FormatException(
        'Ukuran backup tidak valid (maksimal 20 MB).',
      );
    }
    try {
      final raw = jsonDecode(utf8.decode(bytes));
      if (raw is! Map<String, dynamic>) {
        throw const FormatException('Struktur backup tidak valid.');
      }
      final backup = BackupData._(raw);
      backup._validate();
      return backup;
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException(
        'Struktur atau tipe data backup tidak valid.',
      );
    }
  }

  void _validate() {
    void require(bool valid, String message) {
      if (!valid) throw FormatException(message);
    }

    final d = document;
    require(
      d['appId'] == 'com.ghepek_in',
      'File ini bukan backup owner waroeng.',
    );
    require(
      d['formatVersion'] == 1 &&
          d['schemaVersion'] == DbMigrations.currentVersion,
      'Versi backup belum didukung.',
    );
    require(
      d['appVersion'] is String && (d['appVersion'] as String).isNotEmpty,
      'Versi aplikasi tidak valid.',
    );
    require(_validDate(d['createdAt']), 'Tanggal backup tidak valid.');
    require(
      ['classic', 'forui'].contains(d['theme']),
      'Tema backup tidak dikenal.',
    );
    require(
      d['data'] is Map && (d['data'] as Map).length == tables.length,
      'Tabel backup tidak lengkap.',
    );
    final ids = <String, Set<int>>{};
    final categories = <String>{};
    for (final table in tables) {
      final rawRows = d['data'][table];
      require(
        rawRows is List && rawRows.length <= 100000,
        'Jumlah baris $table tidak valid.',
      );
      ids[table] = {};
      for (final rawRow in rawRows) {
        require(rawRow is Map, 'Baris $table tidak valid.');
        final row = Map<String, Object?>.from(rawRow as Map);
        final schema = _columns[table]!;
        require(
          row.length == schema.length && schema.keys.every(row.containsKey),
          'Kolom $table tidak lengkap atau tidak dikenal.',
        );
        for (final column in schema.entries) {
          final value = row[column.key];
          final nullable = column.value.endsWith('?');
          if (nullable && value == null) continue;
          final type = column.value.replaceAll('?', '');
          final valid = switch (type) {
            'id' => value is int && value > 0 && value <= 9007199254740991,
            'int' => value is int && value.abs() <= 9007199254740991,
            'count' => value is int && value >= 0 && value <= 9007199254740991,
            'quantity' =>
              value is int && value > 0 && value <= 9007199254740991,
            'money' => value is num && value.isFinite && value >= 0,
            'date' => _validDate(value),
            'bool' => value is int && (value == 0 || value == 1),
            _ => value is String && value.length <= 10000,
          };
          require(valid, 'Nilai $table.${column.key} tidak valid.');
        }
        if (row.containsKey('id')) {
          require(ids[table]!.add(row['id'] as int), 'ID $table duplikat.');
        }
        if (table == 'products') {
          require(
            (row['name'] as String).trim().isNotEmpty &&
                (row['unit'] as String).trim().isNotEmpty,
            'Nama/satuan produk kosong.',
          );
          require(
            (row['category'] as String).length <= 60,
            'Kategori produk terlalu panjang.',
          );
        }
        if (table == 'product_categories') {
          final name = row['name'] as String;
          // SQLite NOCASE folds ASCII only, matching the database constraint.
          final key = name.replaceAllMapped(
            RegExp('[A-Z]'),
            (m) => m[0]!.toLowerCase(),
          );
          require(
            name.trim().isNotEmpty && name.length <= 60 && categories.add(key),
            'Kategori kosong, terlalu panjang, atau duplikat.',
          );
        }
        if (table == 'transactions') {
          require(
            ['income', 'expense'].contains(row['type']),
            'Jenis transaksi tidak valid.',
          );
          require(
            row['category'] == null ||
                ['stok', 'operasional', 'lainnya'].contains(row['category']),
            'Kategori transaksi tidak valid.',
          );
        }
        if (table == 'stock_adjustments') {
          require(
            (row['reason'] as String).trim().isNotEmpty,
            'Alasan perubahan stok kosong.',
          );
        }
      }
    }
    for (final table in ['transaction_items', 'stock_adjustments']) {
      for (final row in rows(table)) {
        for (final link in {
          'product_id': 'products',
          'transaction_id': 'transactions',
        }.entries) {
          final id = row[link.key];
          require(
            id == null || ids[link.value]!.contains(id),
            'Hubungan $table.${link.key} tidak ditemukan.',
          );
        }
      }
    }
    final sequences = d['sequences'];
    require(
      sequences is Map && sequences.length == 4,
      'Urutan ID tidak lengkap.',
    );
    for (final table in tables.where((t) => t != 'product_categories')) {
      final seq = sequences[table];
      require(
        seq is int && seq >= 0 && seq < 9007199254740991,
        'Urutan ID tidak valid.',
      );
      require(
        ids[table]!.every((id) => id <= seq),
        'Urutan ID lebih kecil dari data.',
      );
    }
  }

  static bool _validDate(Object? value) {
    if (value is! String ||
        value.length > 40 ||
        DateTime.tryParse(value) == null) {
      return false;
    }
    final match = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2}):(\d{2})',
    ).firstMatch(value);
    if (match == null) return false;
    final parts = [for (var i = 1; i <= 6; i++) int.parse(match[i]!)];
    final date = DateTime.utc(parts[0], parts[1], parts[2]);
    return date.year == parts[0] &&
        date.month == parts[1] &&
        date.day == parts[2] &&
        parts[3] < 24 &&
        parts[4] < 60 &&
        parts[5] < 60;
  }

  static const _columns = {
    'products': {
      'id': 'id',
      'name': 'text',
      'category': 'text',
      'sell_price': 'money',
      'cost_price': 'money',
      'stock': 'count',
      'min_stock': 'count',
      'unit': 'text',
      'is_deleted': 'bool',
      'deleted_at': 'date?',
      'last_notified_at': 'date?',
      'created_at': 'date',
      'updated_at': 'date',
    },
    'product_categories': {'name': 'text'},
    'transactions': {
      'id': 'id',
      'type': 'text',
      'category': 'text?',
      'note': 'text?',
      'created_at': 'date',
      'updated_at': 'date',
    },
    'transaction_items': {
      'id': 'id',
      'transaction_id': 'id',
      'product_id': 'id?',
      'quantity': 'quantity',
      'price_at_sale': 'money',
    },
    'stock_adjustments': {
      'id': 'id',
      'product_id': 'id',
      'quantity_change': 'int',
      'reason': 'text',
      'transaction_id': 'id?',
      'created_at': 'date',
    },
  };
}

class BackupService {
  final Database db;
  final Directory recoveryDirectory;
  BackupService(this.db, this.recoveryDirectory);

  static Future<BackupService> open() async => BackupService(
    await DbHelper().database,
    Directory(path.join(await getDatabasesPath(), 'recovery')),
  );

  Future<BackupData> export() => db.transaction(_snapshot);

  Future<BackupData> _snapshot(DatabaseExecutor txn) async {
    final sequences = await txn.query('sqlite_sequence');
    final data = <String, Object?>{};
    for (final table in BackupData.tables) {
      data[table] = await txn.query(
        table,
        orderBy: table == 'product_categories' ? 'name' : 'id',
      );
    }
    final result = BackupData._({
      'appId': 'com.ghepek_in',
      'formatVersion': 1,
      'appVersion': '1.1.0+2',
      'schemaVersion': DbMigrations.currentVersion,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'theme': await readTheme(txn),
      'data': data,
      'sequences': {
        for (final table in BackupData.tables.where(
          (t) => t != 'product_categories',
        ))
          table:
              sequences.where((r) => r['name'] == table).firstOrNull?['seq'] ??
              0,
      },
    });
    return BackupData.decode(result.encode());
  }

  Future<File?> latestRecovery() async {
    if (!await recoveryDirectory.exists()) return null;
    final files = await recoveryDirectory
        .list()
        .where((f) => f is File && f.path.endsWith('.json'))
        .cast<File>()
        .toList();
    files.sort((a, b) => b.path.compareTo(a.path));
    for (final file in files) {
      try {
        await BackupData.read(file.openRead());
        return file;
      } on FormatException {
        continue;
      } on FileSystemException {
        continue;
      }
    }
    return null;
  }

  Future<File> restore(BackupData input) async {
    // Revalidate so callers cannot mutate an already validated document.
    final backup = BackupData.decode(input.encode());
    final helper = DbHelper();
    helper.ensureWritable();
    helper.restoring = true;
    try {
      return await db.transaction((txn) async {
        final previous = await _snapshot(txn);
        await recoveryDirectory.create(recursive: true);
        final file = File(
          path.join(
            recoveryDirectory.path,
            'before-restore-${DateTime.now().microsecondsSinceEpoch}.json',
          ),
        );
        final temporary = File('${file.path}.tmp');
        await temporary.writeAsBytes(previous.encode(), flush: true);
        final verified = BackupData.decode(await temporary.readAsBytes());
        if (jsonEncode(verified.document) != jsonEncode(previous.document)) {
          throw const FileSystemException('Salinan pemulihan tidak lengkap.');
        }
        await temporary.rename(file.path);
        for (final table in BackupData.tables.reversed) {
          await txn.delete(table);
        }
        for (final table in BackupData.tables) {
          for (final row in backup.rows(table)) {
            await txn.insert(table, row);
          }
        }
        for (final table in BackupData.tables.where(
          (t) => t != 'product_categories',
        )) {
          await txn.delete(
            'sqlite_sequence',
            where: 'name = ?',
            whereArgs: [table],
          );
          await txn.insert('sqlite_sequence', {
            'name': table,
            'seq': backup.document['sequences'][table],
          });
        }
        await txn.insert('app_settings', {
          'key': 'theme',
          'value': backup.theme,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        if ((await txn.rawQuery('PRAGMA foreign_key_check')).isNotEmpty) {
          throw const FormatException('Hubungan data tidak valid.');
        }
        return file;
      });
    } finally {
      helper.restoring = false;
    }
  }
}
