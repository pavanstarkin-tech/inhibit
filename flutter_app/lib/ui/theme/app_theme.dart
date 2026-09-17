import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Neobrutalist Canvas & Neutrals (70% neutral, 20% black, 10% accents)
  static const bgMain = Color(0xFFFFF8E7); // Warm off-white
  static const bgCard = Color(0xFFFFFFFF); // Crisp white
  static const textMain = Color(0xFF000000); // Solid black
  static const textMuted = Color(0xFF555555); // Dark muted grey
  static const borderBlack = Color(0xFF000000); // 3px / 4px solid black

  // Strong Curated Neobrutalist Accents
  static const accentYellow = Color(0xFFFFD93D);
  static const accentPink = Color(0xFFFF6B9D);
  static const accentBlue = Color(0xFF5B8DEF);
  static const accentGreen = Color(0xFF7ED957);
  static const accentOrange = Color(0xFFFF8A3D);
  static const accentPurple = Color(0xFF9B7EDE);
  static const accentRed = Color(0xFFFF453A);

  // Life Band Colors in Neobrutalist Palette
  static const bandPast = Color(0xFF94A3B8);
  static const bandSleep = Color(0xFF5B8DEF);
  static const bandWork = Color(0xFF9B7EDE);
  static const bandHygiene = Color(0xFFFFD93D);
  static const bandScrolling = Color(0xFFFF6B9D);
  static const bandFree = Color(0xFF7ED957);

  // Border Widths
  static const double borderStandard = 3.0;
  static const double borderHeavy = 4.0;

  // Hard Offset Shadows
  static const Offset shadowSmall = Offset(3, 3);
  static const Offset shadowStandard = Offset(5, 5);
  static const Offset shadowLarge = Offset(7, 7);

  static List<BoxShadow> hardShadow({
    Offset offset = shadowStandard,
    Color color = borderBlack,
  }) {
    return [
      BoxShadow(
        color: color,
        offset: offset,
        blurRadius: 0,
        spreadRadius: 0,
      ),
    ];
  }

  static ThemeData get neobrutalistTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgMain,
      primaryColor: accentYellow,
      cardColor: bgCard,
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: textMain,
          letterSpacing: -0.8,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: textMain,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: textMain,
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textMain,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textMain,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textMuted,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgMain,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textMain),
        titleTextStyle: TextStyle(
          color: textMain,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderBlack,
        thickness: 2,
        space: 1,
      ),
    );
  }
}
