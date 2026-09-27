import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFCA3500);
  static const Color primaryDark = Color(0xFF9F2D00);
  static const Color primarySoft = Color(0xFFFFEDD5);
  static const Color secondary = Color(0xFF0F766E);
  static const Color secondarySoft = Color(0xFFDDF8F4);
  static const Color accent = Color(0xFFFF8A3D);
  static const Color accentSoft = Color(0xFFFFEDD9);
  static const Color danger = Color(0xFFE7000B);
  static const Color warning = Color(0xFFF59E0B);

  static const Color background = Color(0xFFFFFFFF);
  static const Color pageTopTint = Color(0xFFFFF7ED);
  static const Color pageBottomTint = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF5F5F5);
  static const Color textPrimary = Color(0xFF0A0A0A);
  static const Color textSecondary = Color(0xFF737373);
  static const Color divider = Color(0xFFE5E5E5);

  static const Color stockSafe = Color(0xFF10B981);
  static const Color stockLow = Color(0xFFF59E0B);
  static const Color stockEmpty = Color(0xFFE7000B);
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
  Color get primary => classic ? Color(0xFF5B5CE2) : Color(0xFFCA3500);
  Color get primaryDark => classic ? Color(0xFF4043C8) : Color(0xFF9F2D00);
  Color get primarySoft => classic ? Color(0xFFE9E9FF) : Color(0xFFFFEDD5);
  Color get secondary => classic ? Color(0xFF14B8A6) : Color(0xFF0F766E);
  Color get secondarySoft => Color(0xFFDDF8F4);
  Color get accent => Color(0xFFFF8A3D);
  Color get accentSoft => Color(0xFFFFEDD9);
  Color get danger => classic ? Color(0xFFF04F78) : Color(0xFFE7000B);
  Color get warning => Color(0xFFF59E0B);
  Color get background => classic ? Color(0xFFF6F7FB) : Color(0xFFFFFFFF);
  Color get pageTopTint => classic ? Color(0xFFF3E8FF) : Color(0xFFFFF7ED);
  Color get pageBottomTint => classic ? Color(0xFFE0F2FE) : Color(0xFFFAFAFA);
  Color get surface => Color(0xFFFFFFFF);
  Color get surfaceMuted => classic ? Color(0xFFF9FAFF) : Color(0xFFF5F5F5);
  Color get textPrimary => classic ? Color(0xFF1F2937) : Color(0xFF0A0A0A);
  Color get textSecondary => classic ? Color(0xFF6B7280) : Color(0xFF737373);
  Color get divider => classic ? Color(0xFFE3E8F4) : Color(0xFFE5E5E5);
  Color get stockSafe => Color(0xFF10B981);
  Color get stockLow => Color(0xFFF59E0B);
  Color get stockEmpty => classic ? Color(0xFFF04F78) : Color(0xFFE7000B);
  double get controlRadius => classic ? 18 : 10;
}
