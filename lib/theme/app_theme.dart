import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

extension AppPaletteContext on BuildContext {
  AppPalette get appColors => AppPalette(Theme.of(this).brightness);
}

/// Semantic palette resolved at the view, so changing a theme never remounts
/// navigation or destroys the current exercise/editor state.
class AppPalette {
  const AppPalette(this.brightness);
  final Brightness brightness;
  bool get light => brightness == Brightness.light;
  Color get nightPage => light ? const Color(0xFFF6F5F2) : AppColors.nightPage;
  Color get raisedInk => light ? const Color(0xFFFFFFFF) : AppColors.raisedInk;
  Color get hairline => light ? const Color(0xFFD8DCE2) : AppColors.hairline;
  Color get textPrimary =>
      light ? const Color(0xFF202632) : AppColors.textPrimary;
  Color get textMuted => light ? const Color(0xFF596477) : AppColors.textMuted;
  Color get iconOff => light ? const Color(0xFF8992A1) : AppColors.iconOff;
  Color get active => AppColors.active;
  Color get mastered => AppColors.mastered;
  Color get activeTint =>
      light ? const Color(0xFFFFF0E2) : AppColors.activeTint;
  Color get success => light ? const Color(0xFF347A51) : AppColors.success;
  Color get successTint =>
      light ? const Color(0xFFE4F1E9) : AppColors.successTint;
  Color get error => light ? const Color(0xFFAD3F38) : AppColors.error;
  Color get errorTint => light ? const Color(0xFFFBE8E6) : AppColors.errorTint;
  Color get memoryLevel1 => AppColors.memoryLevel1;
  Color get memoryLevel2 =>
      light ? const Color(0xFF256C99) : AppColors.memoryLevel2;
  Color get memoryLevel3 => AppColors.memoryLevel3;
  Color get memoryLevel4 => AppColors.memoryLevel4;
  Color get memoryLevel5 => AppColors.memoryLevel5;
  Color memoryLevel(int level) =>
      level == 2 ? memoryLevel2 : AppColors.memoryLevel(level);
  Color get playback => light ? const Color(0xFFE6EFF8) : AppColors.playback;
  Color get newsKicker =>
      light ? const Color(0xFF78653F) : AppColors.newsKicker;
}

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
    Color? color,
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
  static TextStyle meta({Color? color}) =>
      chrome(size: 13, weight: FontWeight.w600, color: color);

  static TextStyle editorial({
    double size = 24,
    FontWeight weight = FontWeight.w600,
    Color? color,
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

ThemeData buildAppTheme({Brightness brightness = Brightness.dark}) {
  final colors = AppPalette(brightness);
  final base = ThemeData(brightness: brightness, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: colors.nightPage,
    dividerColor: colors.hairline,
    disabledColor: colors.textMuted,
    dividerTheme: DividerThemeData(color: colors.hairline, thickness: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: colors.nightPage,
      foregroundColor: colors.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    colorScheme: ColorScheme(
      brightness: brightness,
      error: colors.error,
      onError: colors.nightPage,
      surface: colors.nightPage,
      surfaceContainer: colors.raisedInk,
      surfaceContainerHigh: colors.raisedInk,
      surfaceContainerHighest: colors.raisedInk,
      surfaceContainerLow: colors.raisedInk,
      surfaceContainerLowest: colors.nightPage,
      onSurface: colors.textPrimary,
      // Neutral Chrome Rule: Material defaults (cursor, focus, indicators)
      // must never pick up a status ink.
      primary: colors.textPrimary,
      onPrimary: colors.nightPage,
      secondary: colors.textMuted,
      onSecondary: colors.nightPage,
      outline: colors.hairline,
    ),
    textTheme: base.textTheme.apply(
      fontFamily: AppType.chrome().fontFamily,
      bodyColor: colors.textPrimary,
      displayColor: colors.textPrimary,
    ),
    // Flat Ground Rule: sheets separate by tone and hairline, never shadow.
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.raisedInk,
      modalBackgroundColor: colors.raisedInk,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      modalElevation: 0,
      modalBarrierColor: colors.nightPage.withValues(alpha: 0.7),
      dragHandleColor: colors.iconOff,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.hairline),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colors.raisedInk,
      contentTextStyle: AppType.chrome(),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.hairline),
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    cupertinoOverrideTheme: CupertinoThemeData(
      brightness: brightness,
      primaryColor: colors.textPrimary,
      scaffoldBackgroundColor: colors.nightPage,
    ),
  );
}
