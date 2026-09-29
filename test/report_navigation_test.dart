import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:owner_waroeng/core/database/db_helper.dart';
import 'package:owner_waroeng/core/utils/date_formatter.dart';
import 'package:owner_waroeng/core/utils/currency_formatter.dart';
import 'package:owner_waroeng/features/report/screens/report_screen.dart';
import 'package:owner_waroeng/features/report/screens/report_detail_screen.dart';
import 'package:owner_waroeng/shared/theme/app_theme.dart';

void main() {
  late Directory directory;
  late Database db;
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    directory = await Directory.systemTemp.createTemp('owner-report-layout-');
    await databaseFactory.setDatabasesPath(directory.path);
    db = await DbHelper().database;
    await db.insert('products', {
      'id': 1,
      'name': 'Beras premium ukuran keluarga',
      'sell_price': 1,
      'cost_price': 0,
      'stock': 0,
    });
    for (final day in [
      '2026-09-21',
      '2026-09-22',
      '2026-09-30',
      '2026-10-01',
    ]) {
      final id = await db.insert('transactions', {
        'type': 'income',
        'created_at': '${day}T12:00:00',
      });
      await db.insert('transaction_items', {
        'transaction_id': id,
        'product_id': 1,
        'quantity': 1,
        'price_at_sale': 123456789,
      });
    }
  });
  tearDownAll(() async {
    await db.close();
    await directory.delete(recursive: true);
  });

  for (final classic in [true, false]) {
    testWidgets(
      'report routes use daily drilldown and all four monthly buckets, theme $classic',
      (tester) async {
        tester.view.physicalSize = const Size(320, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        Map<String, dynamic>? captured;
        final router = GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, _) => const ReportScreen()),
            GoRoute(
              path: '/reports/detail',
              builder: (_, state) {
                captured = state.extra! as Map<String, dynamic>;
                return const Scaffold(body: Text('Detail tujuan'));
              },
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            theme: buildAppTheme(classic),
            builder: (_, child) => MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 740),
                textScaler: TextScaler.linear(2),
              ),
              child: child!,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Mingguan'));
        await tester.pumpAndSettle();
        final now = DateTime.now();
        final day = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 6));
        await tester.scrollUntilVisible(
          find.text(DateFormatter.formatRelative(day)),
          250,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(DateFormatter.formatRelative(day)));
        await tester.pumpAndSettle();
        expect(captured!['period'], 'harian');
        expect(
          captured!['date'],
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}',
        );
        router.pop();
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text('Bulanan'), -300);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Bulanan'));
        await tester.pumpAndSettle();
        for (var week = 0; week < 4; week++) {
          await tester.scrollUntilVisible(find.text('Minggu ${week + 1}'), 250);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Minggu ${week + 1}'));
          await tester.pumpAndSettle();
          expect(captured!['period'], 'mingguan');
          expect(
            DateTime.parse(captured!['startDate'] as String).day,
            1 + week * 7,
          );
          expect(
            DateTime.parse(captured!['endDate'] as String).day,
            week == 3 ? DateTime(now.year, now.month + 1, 0).day : 7 + week * 7,
          );
          expect(captured!['date'], captured!['endDate']);
          router.pop();
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'exact last monthly bucket includes end day and renders large amounts at 320px, theme $classic',
      (tester) async {
        tester.view.physicalSize = const Size(320, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.runAsync(() async {
          await tester.pumpWidget(
            MaterialApp(
              theme: buildAppTheme(classic),
              home: const MediaQuery(
                data: MediaQueryData(
                  size: Size(320, 740),
                  textScaler: TextScaler.linear(2),
                ),
                child: ReportDetailScreen(
                  period: 'mingguan',
                  date: '2026-09-30',
                  startDate: '2026-09-22',
                  endDate: '2026-09-30',
                  label: 'Minggu 4',
                ),
              ),
            ),
          );
          for (
            var i = 0;
            i < 100 &&
                find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
            i++
          ) {
            await Future<void>.delayed(const Duration(milliseconds: 10));
            await tester.pump();
          }
        });
        await tester.pumpAndSettle();
        expect(
          find.text(CurrencyFormatter.format(246913578)),
          findsNWidgets(2),
        );
        final chart = tester.widget<BarChart>(find.byType(BarChart));
        expect(chart.data.barGroups.length, 9);
        expect(chart.data.barGroups.first.barRods.single.toY, 123456789);
        expect(chart.data.barGroups.last.barRods.single.toY, 123456789);
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -1800),
        );
        await tester.pumpAndSettle();
        expect(find.text('Beras premium ukuran keluarga'), findsNWidgets(2));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
