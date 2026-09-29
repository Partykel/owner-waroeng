import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFB84009);
  static const Color pageTopTint = Color(0xFFFFF7ED);
}

class AppPalette extends ThemeExtension<AppPalette> {
  final bool classic;
  const AppPalette({this.classic = false});
  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>() ?? const AppPalette();
  @override
  AppPalette copyWith({bool? classic}) =>
      AppPalette(classic: classic ?? this.classic);
  @override
  AppPalette lerp(covariant AppPalette? other, double t) =>
      t < 0.5 ? this : other ?? this;
  Color get primary => classic ? Color(0xFF6543C5) : Color(0xFFB84009);
  Color get primaryDark => classic ? Color(0xFF4043C8) : Color(0xFF9F2D00);
  Color get primarySoft => classic ? Color(0xFFF1ECFF) : Color(0xFFFFF0E7);
  Color get secondary => classic ? Color(0xFF14B8A6) : Color(0xFF0F766E);
  Color get secondarySoft => Color(0xFFDDF8F4);
  Color get accent => Color(0xFFFF8A3D);
  Color get accentSoft => Color(0xFFFFEDD9);
  Color get danger => classic ? Color(0xFFF04F78) : Color(0xFFE7000B);
  Color get warning => Color(0xFFF59E0B);
  Color get background => Color(0xFFFFFFFF);
  Color get surface => Color(0xFFFFFFFF);
  Color get surfaceMuted => Color(0xFFF2F3F6);
  Color get textPrimary => Color(0xFF19212E);
  Color get textSecondary => Color(0xFF596273);
  Color get divider => classic ? Color(0xFFE3E8F4) : Color(0xFFE5E5E5);
  Color get stockSafe => Color(0xFF10B981);
  Color get stockLow => Color(0xFFF59E0B);
  Color get stockEmpty => classic ? Color(0xFFF04F78) : Color(0xFFE7000B);
  Color get summary => classic ? Color(0xFF282236) : Color(0xFF202835);
  double get controlRadius => 12;
}
