import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:owner_waroeng/main.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID', null));

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: OwnerWaroengApp()));
    expect(find.text('owner waroeng'), findsOneWidget);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).title,
      'owner waroeng',
    );
  });
}
