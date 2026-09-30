import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppColors {
  static const nightPage = Color(0xFF0D0F14);
  static const raisedInk = Color(0xFF1A1D26);
  static const hairline = Color(0xFF2A2F40);

  static const mastered = Color(0xFF7B2CBF);
  static const active = Color(0xFFF77F00);

  static const textPrimary = Color(0xFFF0F2F5);
  static const textMuted = Color(0xFF8E95A5);
  static const iconOff = Color(0xFF4A5063);
}

/// The Story-Voice Rule: [editorial] for content the learner reads,
/// [chrome] for everything that is interface.
abstract final class AppType {
  static TextStyle chrome({
    double size = 15,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.textPrimary,
    double? height,
    TextDecoration? decoration,
    Color? decorationColor,
    bool tabular = false,
  }) => GoogleFonts.figtree(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    decoration: decoration,
    decorationColor: decorationColor,
    decorationThickness: decoration == null ? null : 3,
    fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
  );

  /// Metadata / chip labels: level, reading time, topic.
  static TextStyle meta({Color color = AppColors.textMuted}) =>
      chrome(size: 13, weight: FontWeight.w600, color: color);

  static TextStyle editorial({
    double size = 24,
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.textPrimary,
    double height = 1.2,
    double letterSpacing = -0.2,
  }) => GoogleFonts.sourceSerif4(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  /// Long-form story text in the reader.
  static TextStyle storyBody() => editorial(
    size: 19,
    weight: FontWeight.w400,
    height: 1.6,
    letterSpacing: 0,
  );
}

ThemeData buildAppTheme() {
  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.nightPage,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.nightPage,
      onSurface: AppColors.textPrimary,
      // Neutral Chrome Rule: Material defaults (cursor, focus, indicators)
      // must never pick up a status ink.
      primary: AppColors.textPrimary,
      onPrimary: AppColors.nightPage,
      secondary: AppColors.textMuted,
      onSecondary: AppColors.nightPage,
      outline: AppColors.hairline,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    // Flat Ground Rule: sheets separate by tone and hairline, never shadow.
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.raisedInk,
      modalBackgroundColor: AppColors.raisedInk,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      modalElevation: 0,
      modalBarrierColor: AppColors.nightPage.withValues(alpha: 0.7),
      dragHandleColor: AppColors.iconOff,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: AppColors.hairline),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    cupertinoOverrideTheme: const CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.textPrimary,
      scaffoldBackgroundColor: AppColors.nightPage,
    ),
  );
}
