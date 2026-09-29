import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghepek_in/features/product/models/product.dart';
import 'package:ghepek_in/features/product/providers/product_provider.dart';
import 'package:ghepek_in/features/product/repositories/product_repository.dart';
import 'package:ghepek_in/features/product/screens/add_edit_product_screen.dart';
import 'package:ghepek_in/features/product/screens/product_list_screen.dart';
import 'package:ghepek_in/features/product/screens/low_stock_screen.dart';
import 'package:ghepek_in/features/transaction/providers/transaction_provider.dart';
import 'package:ghepek_in/shared/theme/app_theme.dart';
import 'package:ghepek_in/shared/widgets/app_button.dart';

class _Products extends ProductRepository {
  final product = Product(
    id: 1,
    name: 'Beras premium ukuran keluarga',
    category: 'Sembako',
    sellPrice: 10000,
    costPrice: 8000,
    stock: 2,
  );
  Future<Product?> Function() load = () async => null;
  @override
  Future<Product?> getById(int id) => load();
  @override
  Future<List<Product>> getAll() async => [product];
  @override
  Future<List<String>> getCategories() async => [];
}

void main() {
  for (final classic in [false, true]) {
    for (final width in [320.0, 360.0, 412.0]) {
      testWidgets(
        'product screens fit $width at 200 percent classic=$classic',
        (tester) async {
          tester.view.physicalSize = Size(width, 850);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final repo = _Products();
          repo.load = () async => repo.product;
          for (final screen in [
            const ProductListScreen(),
            const LowStockScreen(),
            const AddEditProductScreen(productId: 1),
          ]) {
            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  productRepositoryProvider.overrideWithValue(repo),
                  todaySoldCountByProductProvider.overrideWith(
                    (ref) async => {1: 2},
                  ),
                ],
                child: MaterialApp(
                  theme: buildAppTheme(classic),
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: const TextScaler.linear(2)),
                    child: child!,
                  ),
                  home: screen,
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            if (screen is AddEditProductScreen) {
              await tester.drag(find.byType(ListView), const Offset(0, -2500));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
            }
            await tester.pumpWidget(const SizedBox());
          }
        },
      );
    }
  }
  testWidgets(
    'edit disables save while loading and offers retry on load failure',
    (tester) async {
      final pending = Completer<Product?>();
      final repo = _Products()..load = () => pending.future;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [productRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            theme: buildAppTheme(false),
            home: const AddEditProductScreen(productId: 1),
          ),
        ),
      );
      expect(
        tester.widget<AppButton>(find.byType(AppButton)).onPressed,
        isNull,
      );
      pending.completeError(StateError('offline test'));
      await tester.pumpAndSettle();
      expect(find.text('Gagal memuat produk'), findsOneWidget);
      expect(
        tester.widget<AppButton>(find.byType(AppButton)).onPressed,
        isNull,
      );
      repo.load = () async => Product(
        id: 1,
        name: 'Beras',
        sellPrice: 10000,
        costPrice: 8000,
        stock: 4,
      );
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      expect(find.text('Beras'), findsOneWidget);
      expect(
        tester.widget<AppButton>(find.byType(AppButton)).onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
