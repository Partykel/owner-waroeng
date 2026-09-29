import '../../core/services/app_feedback.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/database/db_helper.dart';

final themePreferenceProvider = AsyncNotifierProvider<ThemePreference, String>(
  ThemePreference.new,
);

Future<String> readTheme(DatabaseExecutor db) async {
  final rows = await db.query(
    'app_settings',
    where: 'key = ?',
    whereArgs: ['theme'],
  );
  return rows.isNotEmpty && rows.first['value'] == 'classic'
      ? 'classic'
      : 'forui';
}

class ThemePreference extends AsyncNotifier<String> {
  @override
  Future<String> build() async => readTheme(await DbHelper().database);

  Future<void> select(String theme) async {
    if (!['classic', 'forui'].contains(theme)) {
      throw ArgumentError('Tema tidak dikenal.');
    }
    final db = await DbHelper().database;
    DbHelper().ensureWritable();
    await db.insert('app_settings', {
      'key': 'theme',
      'value': theme,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    state = AsyncData(theme);
  }
}

final soundPreferenceProvider = AsyncNotifierProvider<SoundPreference, bool>(
  SoundPreference.new,
);

class SoundPreference extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final db = await DbHelper().database;
    final rows = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['sound'],
    );
    return AppFeedback.enabled = rows.isEmpty || rows.first['value'] != 'off';
  }

  Future<void> select(bool enabled) async {
    final db = await DbHelper().database;
    DbHelper().ensureWritable();
    await db.insert('app_settings', {
      'key': 'sound',
      'value': enabled ? 'on' : 'off',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    AppFeedback.enabled = enabled;
    state = AsyncData(enabled);
  }
}
