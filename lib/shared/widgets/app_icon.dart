import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../constants/app_colors.dart';

class AppIcon extends StatelessWidget {
  final IconData? icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;
  const AppIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  });
  @override
  Widget build(BuildContext context) => Icon(
    AppPalette.of(context).classic ? (_classic[icon] ?? icon) : icon,
    size: size,
    color: color,
    semanticLabel: semanticLabel,
  );
  static final _classic = <IconData, IconData>{
    PhosphorIconsRegular.house: Icons.home_outlined,
    PhosphorIconsRegular.wallet: Icons.account_balance_wallet,
    PhosphorIconsRegular.plus: Icons.add,
    PhosphorIconsRegular.shoppingCart: Icons.add_shopping_cart,
    PhosphorIconsRegular.chartBar: Icons.bar_chart,
    PhosphorIconsRegular.warningCircle: Icons.error_outline,
    PhosphorIconsRegular.clockCounterClockwise: Icons.history,
    PhosphorIconsRegular.package: Icons.inventory_2_outlined,
    PhosphorIconsRegular.money: Icons.money_off,
    PhosphorIconsRegular.shoppingBag: Icons.shopping_bag_outlined,
    PhosphorIconsRegular.storefront: Icons.storefront_outlined,
    PhosphorIconsRegular.trendDown: Icons.trending_down,
    PhosphorIconsRegular.trendUp: Icons.trending_up,
    PhosphorIconsRegular.caretDown: Icons.arrow_drop_down,
    PhosphorIconsRegular.trash: Icons.delete_outline,
    PhosphorIconsRegular.arrowDown: Icons.arrow_downward_rounded,
    PhosphorIconsRegular.arrowUp: Icons.arrow_upward_rounded,
    PhosphorIconsRegular.check: Icons.check_rounded,
    PhosphorIconsRegular.funnelX: Icons.filter_list_off_rounded,
    PhosphorIconsRegular.exclamationMark: Icons.priority_high_rounded,
    PhosphorIconsRegular.arrowClockwise: Icons.refresh_rounded,
    PhosphorIconsRegular.sortAscending: Icons.sort_by_alpha_rounded,
    PhosphorIconsRegular.sortDescending: Icons.sort_rounded,
    PhosphorIconsRegular.sealCheck: Icons.verified_rounded,
    PhosphorIconsRegular.warning: Icons.warning_amber_rounded,
    PhosphorIconsRegular.pencilSimple: Icons.edit_outlined,
    PhosphorIconsRegular.magnifyingGlass: Icons.search,
    PhosphorIconsRegular.magnifyingGlassMinus: Icons.search_off,
    PhosphorIconsRegular.receipt: Icons.receipt_long_outlined,
    PhosphorIconsRegular.calendar: Icons.calendar_month,
    PhosphorIconsRegular.calendarBlank: Icons.calendar_today,
    PhosphorIconsRegular.caretRight: Icons.chevron_right,
    PhosphorIconsRegular.calendarDots: Icons.date_range,
    PhosphorIconsRegular.calendarCheck: Icons.event_outlined,
    PhosphorIconsRegular.calendarDot: Icons.today,
    PhosphorIconsRegular.sparkle: Icons.auto_awesome,
    PhosphorIconsRegular.calculator: Icons.calculate_rounded,
    PhosphorIconsRegular.dotsThree: Icons.more_horiz,
    PhosphorIconsRegular.minus: Icons.remove,
    PhosphorIconsRegular.gear: Icons.settings_outlined,
    PhosphorIconsRegular.x: Icons.clear,
    PhosphorIconsRegular.tray: Icons.inbox_outlined,
    PhosphorIconsRegular.arrowLeft: Icons.arrow_back,
    PhosphorIconsRegular.downloadSimple: Icons.download,
    PhosphorIconsRegular.uploadSimple: Icons.upload,
    PhosphorIconsRegular.clock: Icons.history,
  };
}
