import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppColors {
  static const nightPage = Color(0xFF0D0F14);
  static const raisedInk = Color(0xFF1A1D26);
  static const hairline = Color(0xFF2A2F40);

  static const mastered = Color(0xFF7B2CBF);
  static const active = Color(0xFFF77F00);

  /// Field Orange at 8% over Raised Ink: background of an active deck tile.
  static const activeTint = Color(0xFF2C2523);

  /// Feedback Rule: right/wrong in exercises only, never accents.
  static const success = Color(0xFF6FB38A);
  static const successTint = Color(0xFF273435);
  static const error = Color(0xFFD9726B);
  static const errorTint = Color(0xFF372A30);

  /// Memory Level Exception: the five dashes over a word in the Wortliste
  /// (Leitner box 1–5). Nowhere else.
  static const memoryLevel1 = active;
  static const memoryLevel2 = Color(0xFF7DB2E0); // Pale Sky
  static const memoryLevel3 = Color(0xFF6FCFB4); // Mint
  static const memoryLevel4 = Color(0xFF8BCF7A); // Light Green
  static const memoryLevel5 = Color(0xFF2FA65A); // Deep Green

  static Color memoryLevel(int level) => switch (level) {
    1 => memoryLevel1,
    2 => memoryLevel2,
    3 => memoryLevel3,
    4 => memoryLevel4,
    _ => memoryLevel5,
  };

  /// Audio Playback Exception: background behind a word or sentence while
  /// it is being read aloud (Wortliste, story narration). Never a status,
  /// never persistent.
  static const playback = Color(0xFF2A3A55);

  /// Newsprint Sand: the category kicker on news cards ("WIRTSCHAFT"). A
  /// warm, low-chroma neutral, the same for every category: no category
  /// colors (DESIGN.md). 8.2:1 on Raised Ink. Never a status, never a fill.
  static const newsKicker = Color(0xFFC2B49A);

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
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.raisedInk,
      contentTextStyle: AppType.chrome(),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(12),
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
