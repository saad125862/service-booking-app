import 'package:flutter/material.dart';

/// Seba brand colours and the Material 3 theme shared by every screen.
///
/// The look is "dark premium": warm charcoal surfaces, one orange accent and a touch of gold.
/// A light theme (warm cream) is kept for people who prefer it.
class AppColors {
  const AppColors._();
  static const brand = Color(0xFFE8590C); // Seba orange (logo)
  static const accentDark = Color(0xFFFF8A3D); // the accent on dark surfaces
  static const gold = Color(0xFFE5B96A);
  static const success = Color(0xFF3FB36B);
  static const warning = Color(0xFFF0A020);
  static const info = Color(0xFF5C7CFA);
}

/// Motion values used across the app, so everything moves with the same feel.
class AppMotion {
  const AppMotion._();
  static const fast = Duration(milliseconds: 160);
  static const base = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 480);
  static const curve = Curves.easeOutCubic;
  static const emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(_lightScheme(), Brightness.light);
  static ThemeData dark() => _build(_darkScheme(), Brightness.dark);

  static ColorScheme _darkScheme() =>
      ColorScheme.fromSeed(seedColor: AppColors.brand, brightness: Brightness.dark).copyWith(
        primary: AppColors.accentDark,
        onPrimary: const Color(0xFF1A0F06),
        primaryContainer: const Color(0xFF3A2412),
        onPrimaryContainer: const Color(0xFFFFD9BD),
        secondary: const Color(0xFFD9B79C),
        onSecondary: const Color(0xFF2A1A0E),
        secondaryContainer: const Color(0xFF2E2219),
        onSecondaryContainer: const Color(0xFFF4EAE2),
        tertiary: AppColors.gold,
        onTertiary: const Color(0xFF2A1E05),
        tertiaryContainer: const Color(0xFF3A2F18),
        onTertiaryContainer: const Color(0xFFFFE7B0),
        surface: const Color(0xFF15110E),
        onSurface: const Color(0xFFF4EAE2),
        onSurfaceVariant: const Color(0xFFA8998D),
        surfaceContainerLowest: const Color(0xFF100C09),
        surfaceContainerLow: const Color(0xFF1B1511),
        surfaceContainer: const Color(0xFF221A14),
        surfaceContainerHigh: const Color(0xFF2A2019),
        surfaceContainerHighest: const Color(0xFF33271E),
        outline: const Color(0xFF5A4636),
        outlineVariant: const Color(0xFF38291D),
        error: const Color(0xFFFF7A7A),
        onError: const Color(0xFF3A0A0A),
        errorContainer: const Color(0xFF4A1F1F),
        onErrorContainer: const Color(0xFFFFD6D6),
        inverseSurface: const Color(0xFFF4EAE2),
        onInverseSurface: const Color(0xFF15110E),
        inversePrimary: AppColors.brand,
        surfaceTint: Colors.transparent,
      );

  static ColorScheme _lightScheme() =>
      ColorScheme.fromSeed(seedColor: AppColors.brand, brightness: Brightness.light).copyWith(
        primary: const Color(0xFFD9480F),
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFFFFE3D0),
        onPrimaryContainer: const Color(0xFF5C2200),
        tertiary: const Color(0xFF9A6B14),
        tertiaryContainer: const Color(0xFFFBEBC8),
        onTertiaryContainer: const Color(0xFF3F2B00),
        surface: const Color(0xFFFFF8F3),
        onSurface: const Color(0xFF2B2118),
        onSurfaceVariant: const Color(0xFF7A6656),
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: Colors.white,
        surfaceContainer: const Color(0xFFFDF1E8),
        surfaceContainerHigh: const Color(0xFFF7E6D9),
        surfaceContainerHighest: const Color(0xFFF1DCCB),
        outline: const Color(0xFFB89A85),
        outlineVariant: const Color(0xFFEADBCF),
        surfaceTint: Colors.transparent,
      );

  static ThemeData _build(ColorScheme scheme, Brightness brightness) {
    final radius = BorderRadius.circular(14);
    final dark = brightness == Brightness.dark;

    OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: color, width: width),
    );

    const titleStyle = TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.2);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PremiumPageTransitionsBuilder(),
          TargetPlatform.iOS: PremiumPageTransitionsBuilder(),
          TargetPlatform.macOS: PremiumPageTransitionsBuilder(),
          TargetPlatform.windows: PremiumPageTransitionsBuilder(),
          TargetPlatform.linux: PremiumPageTransitionsBuilder(),
          TargetPlatform.fuchsia: PremiumPageTransitionsBuilder(),
        },
      ),
      textTheme: ThemeData(brightness: brightness).textTheme.copyWith(
        headlineSmall: titleStyle.copyWith(fontWeight: FontWeight.w700),
        titleLarge: titleStyle,
        titleMedium: titleStyle,
        titleSmall: titleStyle.copyWith(letterSpacing: 0),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? scheme.surfaceContainer : scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: border(scheme.outlineVariant),
        enabledBorder: border(scheme.outlineVariant),
        focusedBorder: border(scheme.primary, 1.6),
        errorBorder: border(scheme.error),
        focusedErrorBorder: border(scheme.error, 1.6),
        disabledBorder: border(scheme.outlineVariant.withValues(alpha: 0.5)),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.8)),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.1),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: radius),
          side: BorderSide(color: scheme.outline.withValues(alpha: dark ? 0.7 : 1)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.1),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: dark ? scheme.surfaceContainer : scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        elevation: 0,
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary,
        indicatorShape: const StadiumBorder(),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? scheme.onPrimary : scheme.onSurfaceVariant,
            size: 24,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            color: states.contains(WidgetState.selected) ? scheme.onSurface : scheme.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: scheme.primary,
        selectedIconTheme: IconThemeData(color: scheme.onPrimary),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: dark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: dark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? scheme.surfaceContainerHighest : scheme.inverseSurface,
        contentTextStyle: TextStyle(color: dark ? scheme.onSurface : scheme.onInverseSurface),
        actionTextColor: scheme.primary,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: dark ? scheme.surfaceContainer : scheme.surfaceContainerLow,
        selectedColor: scheme.primary,
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w500),
        secondaryLabelStyle: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.w600),
        checkmarkColor: scheme.onPrimary,
        showCheckmark: false,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: scheme.primary,
          selectedForegroundColor: scheme.onPrimary,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? scheme.onPrimary : scheme.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? scheme.primary : scheme.surfaceContainerHighest,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.transparent : scheme.outline,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: dark ? scheme.surfaceContainerHighest : scheme.inverseSurface,
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: TextStyle(color: dark ? scheme.onSurface : scheme.onInverseSurface, fontSize: 12),
      ),
    );
  }
}

/// Page transition used on every platform: the new page fades in while sliding a few pixels from
/// the right, and the page underneath eases back. Quick, quiet and the same everywhere.
class PremiumPageTransitionsBuilder extends PageTransitionsBuilder {
  const PremiumPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;

    final incoming = CurvedAnimation(parent: animation, curve: AppMotion.emphasized, reverseCurve: Curves.easeInCubic);
    final outgoing = CurvedAnimation(
      parent: secondaryAnimation,
      curve: AppMotion.emphasized,
      reverseCurve: Curves.easeInCubic,
    );

    return SlideTransition(
      position: Tween<Offset>(begin: Offset.zero, end: const Offset(-0.06, 0)).animate(outgoing),
      child: FadeTransition(
        opacity: Tween<double>(begin: 1, end: 0.6).animate(outgoing),
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero).animate(incoming),
          child: FadeTransition(opacity: incoming, child: child),
        ),
      ),
    );
  }
}
