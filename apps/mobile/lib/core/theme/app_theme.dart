import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Design tokens (Clera brand identity) ────────────────────────────────────

abstract final class SSColors {
  // Brand — Clera forest-to-mint scale
  static const forest = Color(0xFF0D4A2E);      // Forest (primary)
  static const forestInk = Color(0xFF0A3320);   // Dark BG
  static const forestSoft = Color(0xFF0F6E56);  // Deep (secondary)
  static const forestDark = Color(0xFF4EE890);  // Mint (dark mode brand)

  // Surfaces (light)
  static const paper = Color(0xFFF7F4EC);
  static const paper2 = Color(0xFFEFEADD);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF12130F);
  static const ink2 = Color(0xFF2A2C26);
  static const muted = Color(0xFF6A6F64);
  static const line = Color(0xFFE4DFD1);

  // Surfaces (dark)
  static const bgDark = Color(0xFF0B0B0E);
  static const surfaceDark = Color(0xFF16161A);
  static const surface2Dark = Color(0xFF1D1E22);
  static const inkDark = Color(0xFFEDECE6);
  static const ink2Dark = Color(0xFFB9B7AD);
  static const mutedDark = Color(0xFF7A7D73);
  static const lineDark = Color(0xFF26272B);

  // Band colors (light)
  static const excellent = Color(0xFF0D4A2E);  // Forest
  static const good = Color(0xFF2ABF6A);       // Leaf
  static const caution = Color(0xFFD6A443);
  static const poor = Color(0xFFD9764A);
  static const avoid = Color(0xFFB5412F);

  // Band soft backgrounds (light)
  static const excellentSoft = Color(0xFFE6F0E8);
  static const goodSoft = Color(0xFFEDF2DD);
  static const cautionSoft = Color(0xFFF6EAD1);
  static const poorSoft = Color(0xFFF6E0CF);
  static const avoidSoft = Color(0xFFF1D6CD);

  // Band colors (dark)
  static const excellentDark = Color(0xFF6DB58A);
  static const goodDark = Color(0xFFA9C47A);
  static const cautionDark = Color(0xFFE2BF78);
  static const poorDark = Color(0xFFE39872);
  static const avoidDark = Color(0xFFD17563);

  // Band soft backgrounds (dark)
  static const excellentSoftDark = Color(0xFF1A2A21);
  static const goodSoftDark = Color(0xFF222A19);
  static const cautionSoftDark = Color(0xFF2D2619);
  static const poorSoftDark = Color(0xFF2D1F17);
  static const avoidSoftDark = Color(0xFF2A1814);

  // Accent
  static const accent = Color(0xFFC2410C);
  static const accentDark = Color(0xFFD97757);
}

abstract final class SSTypography {
  // Google Fonts names
  static const displayFamily = 'Instrument Sans';
  static const bodyFamily = 'Inter';
  static const monoFamily = 'JetBrains Mono';

  static TextStyle get display => GoogleFonts.instrumentSans(
    fontWeight: FontWeight.w600,
    fontSize: 36,
    height: 1.05,
    letterSpacing: -1.0,
  );
  static TextStyle get title => GoogleFonts.instrumentSans(
    fontWeight: FontWeight.w600,
    fontSize: 26,
    height: 1.1,
    letterSpacing: -0.6,
  );
  static TextStyle get headline => GoogleFonts.instrumentSans(
    fontWeight: FontWeight.w600,
    fontSize: 22,
    height: 1.2,
    letterSpacing: -0.4,
  );
  static TextStyle get body => GoogleFonts.inter(
    fontWeight: FontWeight.w400,
    fontSize: 15,
    height: 1.5,
  );
  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontWeight: FontWeight.w500,
    fontSize: 15,
    height: 1.5,
  );
  static TextStyle get bodySemibold => GoogleFonts.inter(
    fontWeight: FontWeight.w600,
    fontSize: 15,
    height: 1.5,
    letterSpacing: -0.1,
  );
  static TextStyle get label => GoogleFonts.inter(
    fontWeight: FontWeight.w600,
    fontSize: 13,
    height: 1.4,
  );
  static TextStyle get caption => GoogleFonts.inter(
    fontWeight: FontWeight.w400,
    fontSize: 11.5,
    height: 1.4,
  );
  static TextStyle get mono => GoogleFonts.jetBrainsMono(
    fontWeight: FontWeight.w400,
    fontSize: 10.5,
    letterSpacing: 1.8,
  );
}

abstract final class SSRadius {
  static const xs = Radius.circular(8);
  static const sm = Radius.circular(12);
  static const md = Radius.circular(16);
  static const lg = Radius.circular(20);
  static const xl = Radius.circular(24);
  static const full = Radius.circular(999);

  static const borderXs = BorderRadius.all(xs);
  static const borderSm = BorderRadius.all(sm);
  static const borderMd = BorderRadius.all(md);
  static const borderLg = BorderRadius.all(lg);
  static const borderXl = BorderRadius.all(xl);
  static const borderFull = BorderRadius.all(full);
}

// ─── Band helpers ─────────────────────────────────────────────────────────────

enum ScoreBand { excellent, good, caution, poor, avoid }

extension ScoreBandX on ScoreBand {
  String get label => switch (this) {
    ScoreBand.excellent => 'Excellent',
    ScoreBand.good => 'Good',
    ScoreBand.caution => 'Caution',
    ScoreBand.poor => 'Poor',
    ScoreBand.avoid => 'Avoid',
  };

  String get letter => switch (this) {
    ScoreBand.excellent => 'A',
    ScoreBand.good => 'B',
    ScoreBand.caution => 'C',
    ScoreBand.poor => 'D',
    ScoreBand.avoid => 'F',
  };

  Color color(bool dark) => switch (this) {
    ScoreBand.excellent => dark ? SSColors.excellentDark : SSColors.excellent,
    ScoreBand.good => dark ? SSColors.goodDark : SSColors.good,
    ScoreBand.caution => dark ? SSColors.cautionDark : SSColors.caution,
    ScoreBand.poor => dark ? SSColors.poorDark : SSColors.poor,
    ScoreBand.avoid => dark ? SSColors.avoidDark : SSColors.avoid,
  };

  Color softColor(bool dark) => switch (this) {
    ScoreBand.excellent => dark ? SSColors.excellentSoftDark : SSColors.excellentSoft,
    ScoreBand.good => dark ? SSColors.goodSoftDark : SSColors.goodSoft,
    ScoreBand.caution => dark ? SSColors.cautionSoftDark : SSColors.cautionSoft,
    ScoreBand.poor => dark ? SSColors.poorSoftDark : SSColors.poorSoft,
    ScoreBand.avoid => dark ? SSColors.avoidSoftDark : SSColors.avoidSoft,
  };
}

ScoreBand bandFromScore(int score) {
  if (score >= 85) return ScoreBand.excellent;
  if (score >= 70) return ScoreBand.good;
  if (score >= 40) return ScoreBand.caution;
  if (score >= 20) return ScoreBand.poor;
  return ScoreBand.avoid;
}

// ─── App theme ────────────────────────────────────────────────────────────────

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: isDark ? SSColors.bgDark : SSColors.paper,
      colorScheme: isDark
          ? const ColorScheme.dark(
              primary: SSColors.forestDark,
              onPrimary: Colors.black,
              secondary: SSColors.forestSoft,
              surface: SSColors.surfaceDark,
              onSurface: SSColors.inkDark,
              outline: SSColors.lineDark,
            )
          : const ColorScheme.light(
              primary: SSColors.forest,
              onPrimary: Colors.white,
              secondary: SSColors.forestSoft,
              surface: SSColors.surface,
              onSurface: SSColors.ink,
              outline: SSColors.line,
            ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? SSColors.bgDark : SSColors.paper,
        foregroundColor: isDark ? SSColors.inkDark : SSColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: isDark
            ? const SystemUiOverlayStyle(
                statusBarBrightness: Brightness.dark,
                statusBarIconBrightness: Brightness.light,
              )
            : const SystemUiOverlayStyle(
                statusBarBrightness: Brightness.light,
                statusBarIconBrightness: Brightness.dark,
              ),
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData(brightness: brightness).textTheme,
      ),
      dividerColor: isDark ? SSColors.lineDark : SSColors.line,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF0E0F11) : const Color(0xFFF2ECDC),
        border: OutlineInputBorder(
          borderRadius: SSRadius.borderMd,
          borderSide: BorderSide(color: isDark ? SSColors.lineDark : SSColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: SSRadius.borderMd,
          borderSide: BorderSide(color: isDark ? SSColors.lineDark : SSColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: SSRadius.borderMd,
          borderSide: BorderSide(
            color: isDark ? SSColors.forestDark : SSColors.forest,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? SSColors.forestDark : SSColors.forest,
          foregroundColor: isDark ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: SSRadius.borderMd),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? SSColors.inkDark : SSColors.ink,
          side: BorderSide(color: isDark ? SSColors.lineDark : SSColors.line),
          shape: RoundedRectangleBorder(borderRadius: SSRadius.borderMd),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xD90B0B0E) : const Color(0xD9FFFFFF),
        selectedItemColor: isDark ? SSColors.forestDark : SSColors.forest,
        unselectedItemColor: isDark ? SSColors.mutedDark : SSColors.muted,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? SSColors.surfaceDark : SSColors.surface,
        side: BorderSide(color: isDark ? SSColors.lineDark : SSColors.line),
        shape: RoundedRectangleBorder(borderRadius: SSRadius.borderFull),
        padding: const EdgeInsets.symmetric(horizontal: 6),
      ),
    );
  }
}
