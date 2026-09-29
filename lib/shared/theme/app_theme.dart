import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../widgets/app_icon.dart';
import 'package:forui/forui.dart';
import '../constants/app_colors.dart';

// Preset ajcbfc, adapted to Forui 0.21: Neutral / Orange / Noto Sans /
// Inter / Phosphor / medium radius. Both fonts are bundled for offline use.
final ownerTheme = FThemeData(
  colors: FColors.neutralLight.copyWith(
    primary: AppColors.primary,
    primaryForeground: AppColors.pageTopTint,
  ),
  touch: true,
  typography: _typography,
);

final _body = FTypography.inherit(colors: FColors.neutralLight, touch: true);
final _typography = _body.copyWith(
  lg: _body.lg.copyWith(fontFamily: 'Noto Sans'),
  xl: _body.xl.copyWith(fontFamily: 'Noto Sans'),
  xl2: _body.xl2.copyWith(fontFamily: 'Noto Sans'),
  xl3: _body.xl3.copyWith(fontFamily: 'Noto Sans'),
  xl4: _body.xl4.copyWith(fontFamily: 'Noto Sans'),
);

ThemeData buildAppTheme(bool classic) {
  final palette = AppPalette(classic: classic);
  final base = (classic
      ? ThemeData(
          colorScheme: ColorScheme.light(
            primary: palette.primary,
            secondary: palette.secondary,
            tertiary: palette.accent,
            error: palette.danger,
          ),
        )
      : ownerTheme.toApproximateMaterialTheme());
  // Material animates text internally even when the app theme changes instantly.
  // Resolve Material font sizes/baselines before disabling inheritance; otherwise
  // dense dropdowns cannot obtain titleMedium.fontSize.
  final material = ThemeData();
  return base.copyWith(
    textTheme: _materialText(
      material.typography.englishLike.merge(base.textTheme),
    ),
    primaryTextTheme: _materialText(
      material.typography.englishLike.merge(base.primaryTextTheme),
    ),
    typography: material.typography,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.surface,
      indicatorColor: palette.primarySoft,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    extensions: [palette],
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: palette.primary,
        textStyle: TextStyle(
          inherit: false,
          fontFamily: 'Noto Sans',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    actionIconTheme: ActionIconThemeData(
      backButtonIconBuilder: (context) =>
          AppIcon(PhosphorIconsRegular.arrowLeft),
    ),
    scaffoldBackgroundColor: palette.background,
    canvasColor: palette.background,
    dividerColor: palette.divider,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      centerTitle: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: palette.textPrimary,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontFamily: 'Noto Sans',
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: palette.textPrimary,
      ),
    ),
    cardTheme: CardThemeData(
      color: palette.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: palette.divider),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surface,
      hintStyle: TextStyle(color: palette.textSecondary),
      contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(palette.controlRadius),
        borderSide: BorderSide(color: palette.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(palette.controlRadius),
        borderSide: BorderSide(color: palette.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(palette.controlRadius),
        borderSide: BorderSide(color: palette.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(palette.controlRadius),
        borderSide: BorderSide(color: palette.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(palette.controlRadius),
        borderSide: BorderSide(color: palette.danger, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        minimumSize: Size.fromHeight(54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(palette.controlRadius),
        ),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: Size.fromHeight(52),
        backgroundColor: palette.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(palette.controlRadius),
        ),
        textStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: Size.fromHeight(52),
        foregroundColor: palette.primaryDark,
        side: BorderSide(color: palette.divider),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(palette.controlRadius),
        ),
        textStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 0,
      shape: StadiumBorder(),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: palette.surface,
      selectedColor: palette.primarySoft,
      side: BorderSide(color: palette.divider),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: TextStyle(
        color: palette.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.textPrimary,
      contentTextStyle: TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

final classicForuiTheme = FThemeData(
  colors: FColors.neutralLight.copyWith(primary: const Color(0xFF6543C5)),
  typography: FTypography(fontFamily: 'Noto Sans'),
  touch: true,
);

TextTheme _materialText(TextTheme text) => TextTheme(
  displayLarge: text.displayLarge?.copyWith(
    fontFamily: 'Noto Sans',
    inherit: false,
    textBaseline: TextBaseline.alphabetic,
  ),
  displayMedium: text.displayMedium?.copyWith(
    fontFamily: 'Noto Sans',
    inherit: false,
    textBaseline: TextBaseline.alphabetic,
  ),
  displaySmall: text.displaySmall?.copyWith(
    fontFamily: 'Noto Sans',
    inherit: false,
    textBaseline: TextBaseline.alphabetic,
  ),
  headlineLarge: text.headlineLarge?.copyWith(
    fontFamily: 'Noto Sans',
    inherit: false,
    textBaseline: TextBaseline.alphabetic,
  ),
  headlineMedium: text.headlineMedium?.copyWith(
    fontFamily: 'Noto Sans',
    inherit: false,
    textBaseline: TextBaseline.alphabetic,
  ),
  headlineSmall: text.headlineSmall?.copyWith(
    fontFamily: 'Noto Sans',
    inherit: false,
    textBaseline: TextBaseline.alphabetic,
  ),
  titleLarge: text.titleLarge?.copyWith(
    fontFamily: 'Noto Sans',
    inherit: false,
    textBaseline: TextBaseline.alphabetic,
  ),
  titleMedium: text.titleMedium?.copyWith(
    fontFamily: 'Noto Sans',
    inherit: false,
    textBaseline: TextBaseline.alphabetic,
  ),
  titleSmall: text.titleSmall?.copyWith(
    fontFamily: 'Noto Sans',
    inherit: false,
    textBaseline: TextBaseline.alphabetic,
  ),
  bodyLarge: text.bodyLarge?.copyWith(
    fontFamily: 'Noto Sans',
    inherit: false,
    textBaseline: TextBaseline.alphabetic,
  ),
  bodyMedium: text.bodyMedium?.copyWith(
    fontFamily: 'Noto Sans',
    inherit: false,
    textBaseline: TextBaseline.alphabetic,
  ),
  bodySmall: text.bodySmall?.copyWith(
    fontFamily: 'Noto Sans',
    inherit: false,
    textBaseline: TextBaseline.alphabetic,
  ),
  labelLarge: text.labelLarge?.copyWith(
    fontFamily: 'Noto Sans',
    inherit: false,
    textBaseline: TextBaseline.alphabetic,
  ),
  labelMedium: text.labelMedium?.copyWith(
    fontFamily: 'Noto Sans',
    inherit: false,
    textBaseline: TextBaseline.alphabetic,
  ),
  labelSmall: text.labelSmall?.copyWith(
    fontFamily: 'Noto Sans',
    inherit: false,
    textBaseline: TextBaseline.alphabetic,
  ),
);
