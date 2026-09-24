import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// readygo-speak の CLAUDE.md 2章「書体」節に基づくテーマ定義をそのまま流用。
/// 欧文・数字・UI見出し: Outfit(500/700/800)
/// 和文・本文: Zen Kaku Gothic New(400/500/700)
class AppTheme {
  AppTheme._();

  static TextTheme _textTheme(Color color) {
    final base = GoogleFonts.zenKakuGothicNewTextTheme().apply(
      bodyColor: color,
      displayColor: color,
    );
    return base.copyWith(
      displayLarge: GoogleFonts.outfit(
        textStyle: base.displayLarge,
        fontWeight: FontWeight.w800,
      ),
      displayMedium: GoogleFonts.outfit(
        textStyle: base.displayMedium,
        fontWeight: FontWeight.w800,
      ),
      headlineLarge: GoogleFonts.outfit(
        textStyle: base.headlineLarge,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: GoogleFonts.outfit(
        textStyle: base.headlineMedium,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: GoogleFonts.outfit(
        textStyle: base.titleLarge,
        fontWeight: FontWeight.w700,
      ),
      labelLarge: GoogleFonts.outfit(
        textStyle: base.labelLarge,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandEnd,
      brightness: Brightness.light,
      primary: AppColors.brandEnd,
      secondary: AppColors.accent,
      surface: AppColors.paper,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.paper,
      textTheme: _textTheme(AppColors.ink),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
      ),
    );
  }
}
