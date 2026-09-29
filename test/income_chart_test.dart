import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:owner_waroeng/features/dashboard/widgets/income_chart.dart';
import 'package:owner_waroeng/shared/theme/app_theme.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));
  for (final classic in [true, false]) {
    testWidgets(
      'chart sequential 350ms, celebration after last bar, replay only after exit $classic',
      (tester) async {
        tester.view.physicalSize = const Size(320, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final scroll = ScrollController();
        addTearDown(scroll.dispose);
        final now = DateTime.now();
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(classic),
            home: Scaffold(
              body: SingleChildScrollView(
                controller: scroll,
                child: Column(
                  children: [
                    const SizedBox(height: 800),
                    IncomeChart(
                      scrollController: scroll,
                      data: [
                        for (var i = 0; i < 7; i++)
                          {
                            'date': DateFormat('yyyy-MM-dd').format(
                              DateTime(now.year, now.month, now.day - i),
                            ),
                            'income': 10000,
                          },
                      ],
                    ),
                    const SizedBox(height: 800),
                  ],
                ),
              ),
            ),
          ),
        );
        final celebration = find.byKey(const ValueKey('chart-celebration'));
        expect(celebration, findsNothing);
        scroll.jumpTo(650);
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(
          tester.getSize(find.byKey(const ValueKey('income-bar-0'))).height,
          greaterThan(100),
        );
        expect(
          tester.getSize(find.byKey(const ValueKey('income-bar-1'))).height,
          0,
        );
        expect(celebration, findsNothing);
        await tester.pump(const Duration(milliseconds: 2099));
        expect(celebration, findsNothing);
        await tester.pump(const Duration(milliseconds: 2));
        expect(celebration, findsOneWidget);
        await tester.pump(const Duration(milliseconds: 1931));
        expect(celebration, findsNothing);
        scroll.jumpTo(660);
        await tester.pump();
        await tester.pump(const Duration(seconds: 3));
        expect(celebration, findsNothing);
        scroll.jumpTo(0);
        await tester.pump();
        scroll.jumpTo(650);
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 2451));
        expect(celebration, findsOneWidget);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();
        expect(celebration, findsNothing);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
    for (final peakIndex in [0, 3, 6]) {
      for (final (width, scale) in [
        (320.0, 1.0),
        (320.0, 2.0),
        (360.0, 2.0),
        (412.0, 2.0),
      ]) {
        testWidgets(
          'celebration follows highest bar $peakIndex theme $classic at ${width}px ${scale}x',
          (tester) async {
            tester.view.physicalSize = Size(width, 740);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final scroll = ScrollController();
            addTearDown(scroll.dispose);
            final now = DateTime.now();
            await tester.pumpWidget(
              MaterialApp(
                theme: buildAppTheme(classic),
                home: MediaQuery(
                  data: MediaQueryData(
                    size: Size(width, 740),
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: Scaffold(
                    body: SingleChildScrollView(
                      controller: scroll,
                      child: Column(
                        children: [
                          const SizedBox(height: 800),
                          IncomeChart(
                            scrollController: scroll,
                            data: [
                              for (var i = 0; i < 7; i++)
                                {
                                  'date': DateFormat('yyyy-MM-dd').format(
                                    DateTime(
                                      now.year,
                                      now.month,
                                      now.day - 6 + i,
                                    ),
                                  ),
                                  'income': i == peakIndex ? 60000 : 10000,
                                },
                            ],
                          ),
                          const SizedBox(height: 800),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
            scroll.jumpTo(650);
            await tester.pump();
            await tester.pump();
            final start = (peakIndex + 1) * 350;
            await tester.pump(Duration(milliseconds: start - 1));
            final celebration = find.byKey(const ValueKey('chart-celebration'));
            expect(celebration, findsNothing);
            await tester.pump(const Duration(milliseconds: 2));
            final bar = find.byKey(ValueKey('income-bar-$peakIndex'));
            expect(celebration, findsOneWidget);
            expect(
              tester.getCenter(celebration).dx,
              closeTo(tester.getCenter(bar).dx, 1),
            );
            expect(
              tester.getRect(celebration).bottom,
              closeTo(tester.getRect(bar).top, 1),
            );
            if (peakIndex < 6) {
              expect(
                tester
                    .getSize(
                      find.byKey(ValueKey('income-bar-${peakIndex + 1}')),
                    )
                    .height,
                lessThan(5),
              );
            }
            expect(
              tester
                  .getRect(celebration)
                  .overlaps(tester.getRect(find.text('Dalam ribuan rupiah'))),
              isFalse,
              reason:
                  'sprite ${tester.getRect(celebration)}, label ${tester.getRect(find.text('Dalam ribuan rupiah'))}',
            );
            await tester.pump(const Duration(milliseconds: 1930));
            expect(celebration, findsNothing);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets('reduced motion shows full bars without celebration', (
    tester,
  ) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    final today = DateTime.now();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(false),
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: SingleChildScrollView(
              controller: scroll,
              child: IncomeChart(
                scrollController: scroll,
                data: [
                  {
                    'date': DateFormat('yyyy-MM-dd').format(today),
                    'income': 60000,
                  },
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(
      tester.getSize(find.byKey(const ValueKey('income-bar-6'))).height,
      greaterThan(100),
    );
    expect(find.byKey(const ValueKey('chart-celebration')), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    expect(find.byKey(const ValueKey('chart-celebration')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('covering the dashboard cancels and restarts the chart', (
    tester,
  ) async {
    final active = ValueNotifier(true);
    final scroll = ScrollController();
    addTearDown(active.dispose);
    addTearDown(scroll.dispose);
    final today = DateTime.now();
    final data = [
      for (var i = 0; i < 7; i++)
        {
          'date': DateFormat(
            'yyyy-MM-dd',
          ).format(DateTime(today.year, today.month, today.day - i)),
          'income': 10000,
        },
    ];
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(false),
        home: Scaffold(
          body: ValueListenableBuilder<bool>(
            valueListenable: active,
            builder: (context, enabled, _) => TickerMode(
              enabled: enabled,
              child: SingleChildScrollView(
                controller: scroll,
                child: Column(
                  children: [
                    const SizedBox(height: 800),
                    IncomeChart(data: data, scrollController: scroll),
                    const SizedBox(height: 800),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    scroll.jumpTo(650);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2451));
    final celebration = find.byKey(const ValueKey('chart-celebration'));
    expect(celebration, findsOneWidget);
    active.value = false;
    await tester.pump();
    await tester.pump();
    expect(celebration, findsNothing);
    active.value = true;
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2451));
    expect(celebration, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
