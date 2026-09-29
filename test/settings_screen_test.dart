import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghepek_in/core/database/db_helper.dart';
import 'package:ghepek_in/features/settings/settings_provider.dart';
import 'package:ghepek_in/features/settings/settings_screen.dart';
import 'package:ghepek_in/shared/theme/app_theme.dart';
import 'package:ghepek_in/shared/constants/app_colors.dart';
import 'package:intl/date_symbol_data_local.dart';

class _Theme extends ThemePreference {
  @override
  Future<String> build() async => 'forui';
  @override
  Future<void> select(String theme) async {
    state = AsyncData(theme);
  }
}

class _Sound extends SoundPreference {
  @override
  Future<bool> build() async => true;
  @override
  Future<void> select(bool enabled) async => state = AsyncData(enabled);
}

final class _MemoryFile extends PlatformFile {
  final Uint8List bytes;
  _MemoryFile(this.bytes);
  @override
  String get name => 'test.json';
  @override
  Uri get uri => Uri.parse('memory:test');
  @override
  Never get xFile => throw UnsupportedError('Unused in test');
  @override
  int? lengthSync() => bytes.length;
  @override
  Future<int?> length() async => bytes.length;
  @override
  Future<Uint8List> readAsBytes() async => bytes;
  @override
  Stream<Uint8List> readAsByteStream() => Stream.value(bytes);
}

class _Picker extends FilePickerPlatform {
  PlatformFile? result;
  int calls = 0;
  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    calls++;
    return result;
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID', null));
  late _Picker picker;
  late FilePickerPlatform previous;
  setUp(() {
    previous = FilePickerPlatform.instance;
    picker = _Picker();
    FilePickerPlatform.instance = picker;
  });
  tearDown(() {
    FilePickerPlatform.instance = previous;
  });
  Future<void> show(
    WidgetTester tester, {
    double width = 320,
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themePreferenceProvider.overrideWith(_Theme.new),
          soundPreferenceProvider.overrideWith(_Sound.new),
        ],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp(
            themeAnimationDuration: Duration.zero,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            theme: buildAppTheme(
              ref.watch(themePreferenceProvider).value == 'classic',
            ),
            home: const SettingsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('theme changes palette and controls without overflow at 320px', (
    tester,
  ) async {
    await show(tester);
    var context = tester.element(find.byType(SettingsScreen));
    expect(AppPalette.of(context).classic, false);
    await tester.tap(find.text('Klasik — Ungu'));
    await tester.pumpAndSettle();
    context = tester.element(find.byType(SettingsScreen));
    expect(AppPalette.of(context).classic, true);
    expect(Theme.of(context).colorScheme.primary, const Color(0xFF6543C5));
    await tester.tap(find.text('Forui — Oranye'));
    await tester.pumpAndSettle();
    expect(Theme.of(context).colorScheme.primary, const Color(0xFFB84009));
    expect(tester.takeException(), isNull);
  });
  for (final width in [320.0, 360.0, 412.0]) {
    testWidgets('settings both themes at ${width}px with 200% text', (
      tester,
    ) async {
      await show(tester, width: width, scale: 2);
      for (final theme in ['Klasik \u2014 Ungu', 'Forui \u2014 Oranye']) {
        await tester.scrollUntilVisible(find.text(theme).hitTestable(), -160);
        await tester.pumpAndSettle();
        await tester.tap(find.text(theme));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byType(Switch).first.hitTestable(),
          160,
        );
        await tester.tap(find.byType(Switch).first);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Pulihkan Backup').hitTestable(),
          160,
        );
        await tester.tap(find.text('Pulihkan Backup'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.text('Simpan Salinan Sebelum Pemulihan'),
          120,
        );
        expect(tester.takeException(), isNull);
      }
      expect(picker.calls, 2);
    });
  }
  testWidgets(
    'picker cancellation, bad file and declined restore never start replacement',
    (tester) async {
      await show(tester);
      final button = find.text('Pulihkan Backup');
      await tester.scrollUntilVisible(button.hitTestable(), 160);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(picker.calls, 1);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      picker.result = _MemoryFile(Uint8List.fromList(utf8.encode('{bad')));
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      final doc = {
        'appId': 'com.ghepek_in',
        'formatVersion': 1,
        'schemaVersion': 5,
        'appVersion': '1.1.0+2',
        'createdAt': '2026-09-24T12:00:00Z',
        'theme': 'classic',
        'data': {
          for (final t in [
            'products',
            'product_categories',
            'transactions',
            'transaction_items',
            'stock_adjustments',
          ])
            t: [],
        },
        'sequences': {
          for (final t in [
            'products',
            'transactions',
            'transaction_items',
            'stock_adjustments',
          ])
            t: 0,
        },
      };
      picker.result = _MemoryFile(
        Uint8List.fromList(utf8.encode(jsonEncode(doc))),
      );
      await tester.scrollUntilVisible(button.hitTestable(), 160);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Ganti data dengan backup?'), findsOneWidget);
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(DbHelper().restoring, false);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
