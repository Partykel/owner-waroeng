import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../shared/widgets/app_icon.dart';
import '../features/settings/settings_screen.dart';
import 'package:go_router/go_router.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/product/screens/product_list_screen.dart';
import '../features/product/screens/add_edit_product_screen.dart';
import '../features/product/screens/low_stock_screen.dart';
import '../features/transaction/screens/add_sale_screen.dart';
import '../features/transaction/screens/add_expense_screen.dart';
import '../features/transaction/screens/transaction_history_screen.dart';
import '../features/report/screens/report_screen.dart';
import '../features/report/screens/report_detail_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => Scaffold(
        body: TickerMode(
          enabled: ModalRoute.isCurrentOf(context) ?? true,
          child: shell,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (index) => shell.goBranch(index),
          destinations: const [
            NavigationDestination(
              icon: AppIcon(PhosphorIconsRegular.house),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: AppIcon(PhosphorIconsRegular.package),
              label: 'Produk',
            ),
            NavigationDestination(
              icon: AppIcon(PhosphorIconsRegular.clockCounterClockwise),
              label: 'Riwayat',
            ),
            NavigationDestination(
              icon: AppIcon(PhosphorIconsRegular.chartBar),
              label: 'Laporan',
            ),
          ],
        ),
      ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              name: 'dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/products',
              name: 'products',
              builder: (context, state) => const ProductListScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/transactions',
              name: 'transactions',
              builder: (context, state) => const TransactionHistoryScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/reports',
              name: 'reports',
              builder: (context, state) => const ReportScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),

    GoRoute(
      path: '/products/new',
      name: 'product-new',
      builder: (context, state) => const AddEditProductScreen(),
    ),
    GoRoute(
      path: '/products/:id/edit',
      name: 'product-edit',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return AddEditProductScreen(productId: id);
      },
    ),
    GoRoute(
      path: '/low-stock',
      name: 'low-stock',
      builder: (context, state) => const LowStockScreen(),
    ),
    GoRoute(
      path: '/sale/new',
      name: 'sale-new',
      builder: (context, state) => const AddSaleScreen(),
    ),
    GoRoute(
      path: '/expense/new',
      name: 'expense-new',
      builder: (context, state) => AddExpenseScreen(
        initialCategory: state.uri.queryParameters['category'] ?? 'operasional',
      ),
    ),

    GoRoute(
      path: '/reports/detail',
      name: 'report-detail',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return ReportDetailScreen(
          period: extra['period'] as String? ?? 'harian',
          date: extra['date'] as String? ?? '',
          label: extra['label'] as String?,
          startDate: extra['startDate'] as String?,
          endDate: extra['endDate'] as String?,
        );
      },
    ),
  ],
);
