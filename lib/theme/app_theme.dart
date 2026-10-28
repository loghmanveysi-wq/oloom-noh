// تعریف تم روشن و تاریک برنامه با پالت رنگی آبی علمی و نارنجی
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color accentOrange = Color(0xFFFF6F00);
  static const String fontFamily = 'Vazirmatn';

  static const PageTransitionsTheme _transitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    },
  );

  static final SnackBarThemeData _snackBar = SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );

  static InputDecorationTheme _inputs(bool dark) {
    OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecorationTheme(
      filled: true,
      fillColor: dark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.85),
      border: b(Colors.transparent),
      enabledBorder: b(dark ? Colors.white12 : const Color(0x221565C0)),
      focusedBorder: b(dark ? const Color(0xFF64B5F6) : primaryBlue, 2),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFEAF1FC),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        secondary: accentOrange,
        brightness: Brightness.light,
      ),
      pageTransitionsTheme: _transitions,
      snackBarTheme: _snackBar,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.white.withOpacity(0.86),
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shadowColor: primaryBlue.withOpacity(0.18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: Colors.white.withOpacity(0.8)),
        ),
      ),
      inputDecorationTheme: _inputs(false),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: primaryBlue),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentOrange,
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: accentOrange.withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F1720),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        secondary: accentOrange,
        brightness: Brightness.dark,
      ),
      pageTransitionsTheme: _transitions,
      snackBarTheme: _snackBar,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF16232E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF1B2733).withOpacity(0.82),
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shadowColor: Colors.black54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
      ),
      inputDecorationTheme: _inputs(true),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: Color(0xFF64B5F6)),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentOrange,
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: accentOrange.withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
