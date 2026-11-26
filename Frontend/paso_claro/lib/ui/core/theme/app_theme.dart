import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// PasoClaro ThemeData builder following DESIGN.md:
/// - Outfit (Headings) + Geist (Body) + JetBrains Mono (Official codes/metadata)
/// - Standard Mode & Senior High-Contrast Mode (Adultos Mayores)
abstract final class AppTheme {
  static TextStyle heading(
    double size, {
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.charcoalInk,
    double height = 1.2,
    double letterSpacing = -0.02,
  }) {
    return GoogleFonts.outfit(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: size * letterSpacing,
    );
  }

  static TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.slateCharcoal,
    double height = 1.5,
  }) {
    return GoogleFonts.getFont(
      'Geist',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  static TextStyle mono(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.charcoalInk,
    double height = 1.35,
    double letterSpacing = 0.3,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static ThemeData build({required bool seniorMode}) {
    final primary = seniorMode ? AppColors.agaveDeep : AppColors.agaveJade;
    final bodySize = seniorMode ? 20.0 : 16.0;
    final borderColor =
        seniorMode ? AppColors.charcoalInk : AppColors.whisperBorder;
    final borderWidth = seniorMode ? 2.0 : 1.0;

    final colorScheme = ColorScheme.light(
      primary: primary,
      onPrimary: AppColors.purePaper,
      primaryContainer: AppColors.agaveMist,
      onPrimaryContainer: AppColors.agaveDeep,
      secondary: AppColors.slateCharcoal,
      onSecondary: AppColors.purePaper,
      surface: AppColors.purePaper,
      onSurface: AppColors.charcoalInk,
      error: AppColors.brickAlert,
      onError: AppColors.purePaper,
      outline: borderColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.canvasAlabaster,
      dividerColor: AppColors.whisperBorder,
      textTheme: TextTheme(
        headlineLarge: heading(seniorMode ? 32 : 26),
        headlineMedium: heading(seniorMode ? 26 : 22, weight: FontWeight.w600),
        titleLarge: heading(seniorMode ? 22 : 18, weight: FontWeight.w600),
        titleMedium: heading(seniorMode ? 20 : 16, weight: FontWeight.w600),
        bodyLarge: body(bodySize, color: AppColors.charcoalInk),
        bodyMedium: body(
          seniorMode ? 18 : 15,
          color: AppColors.slateCharcoal,
        ),
        bodySmall: body(
          seniorMode ? 16 : 13,
          color: AppColors.graphiteSecondary,
        ),
        labelLarge: body(
          seniorMode ? 18 : 16,
          weight: FontWeight.w600,
          color: AppColors.purePaper,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.purePaper,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(seniorMode ? 20 : 24),
          side: BorderSide(color: borderColor, width: borderWidth),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: AppColors.purePaper,
          elevation: 0,
          minimumSize: Size.fromHeight(seniorMode ? 60 : 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: heading(
            seniorMode ? 19 : 16,
            weight: FontWeight.w600,
            color: AppColors.purePaper,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.purePaper,
          foregroundColor: AppColors.charcoalInk,
          minimumSize: Size.fromHeight(seniorMode ? 56 : 50),
          side: BorderSide(
            color: seniorMode ? AppColors.charcoalInk : AppColors.strongBorder,
            width: seniorMode ? 2.0 : 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: body(
            seniorMode ? 18 : 15,
            weight: FontWeight.w600,
            color: AppColors.charcoalInk,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.softStone,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor, width: borderWidth),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor, width: borderWidth),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
    );
  }
}
