import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.white,
      colorScheme: const ColorScheme.light(
        primary: AppColors.black,
        onPrimary: AppColors.white,
        surface: AppColors.white,
        onSurface: AppColors.black,
        error: AppColors.error,
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  static TextStyle get logoLiving => GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w500,
        height: 1,
        letterSpacing: -0.5,
      );

  static TextStyle get logoGrace => GoogleFonts.playfairDisplay(
        fontSize: 56,
        fontWeight: FontWeight.w600,
        height: 0.9,
        letterSpacing: -1.5,
      );
}
