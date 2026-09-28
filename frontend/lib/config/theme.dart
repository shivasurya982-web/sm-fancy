import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Sparkle Platinum Design System ─────────────────────────────────────────
  
  // Platinum & Silvers
  static const Color platinum = Color(0xFFE5E4E2);
  static const Color brightPlatinum = Color(0xFFF5F5F3);
  static const Color polishedSilver = Color(0xFFC8C8C8);
  static const Color metallicSilver = Color(0xFFAFAFAF);
  static const Color darkSilver = Color(0xFF777777);
  static const Color brushedPlatinum = Color(0xFFE5E5E5);
  
  // Darks
  static const Color deepCharcoal = Color(0xFF111111);
  static const Color luxuryBlack = Color(0xFF080808);
  static const Color softCharcoal = Color(0xFF1A1A1A);
  static const Color matteBlack = Color(0xFF080808);
  static const Color deepBlack = Color(0xFF080808);
  static const Color luxuryCharcoal = Color(0xFF1A1A1A);
  
  // Accents
  static const Color sapphireBlue = Color(0xFF002D62);
  static const Color champagneGold = Color(0xFFC9A96E);
  static const Color softGold = Color(0xFFD8C28F);
  static const Color antiqueGold = Color(0xFF9C7A43);
  
  // Rules & Borders
  static const Color platinumBorder = Color(0xFFD7D7D2);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color platinumHighlight = Color(0x66FFFFFF);
  static const Color softBeige = Color(0xFFD7D7D2);

  // Status
  static const Color success = Color(0xFF4A6741);
  static const Color error = Color(0xFF8B0000);

  // ── Aliases ───────────────────────────────────────────────────────────────
  static const Color blackPrimary = deepCharcoal;
  static const Color surfaceSecondary = softCharcoal;
  static const Color blackSurface = luxuryBlack;
  static const Color darkSurface = luxuryBlack;
  static const Color darkCard = softCharcoal;
  static const Color surfaceLight = Color(0xFF222222);
  static const Color goldPrimary = platinum;
  static const Color goldLight = brightPlatinum;
  static const Color goldDeep = polishedSilver;
  static const Color metallicGold = platinum;
  static const Color pearlWhite = Color(0xFFFFFFFF);
  static const Color marbleWhite = Color(0xFFF5F2EC);
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFA7A7A7);
  static const Color coolGrey = Color(0xFFA7A7A7);
  static const Color warmGray = Color(0xFFA7A7A7);
  static const Color muted = Color(0xFF777777);

  // ── Gradients ──────────────────────────────────────────────────────────────
  static const LinearGradient luxuryGradient = LinearGradient(
    colors: [polishedSilver, platinum, brightPlatinum, platinum, polishedSilver],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient velvetBackgroundGradient = LinearGradient(
    colors: [luxuryBlack, deepCharcoal],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Platinum Glass Decoration (Floating 3D Effect) ────────────────────────
  
  static BoxDecoration premiumCard({double radius = 30, bool isDark = true}) => BoxDecoration(
    color: luxuryBlack.withOpacity(0.7),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: glassBorder, width: 1.2),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.5),
        blurRadius: 15,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: Colors.white.withOpacity(0.05),
        blurRadius: 1,
        offset: const Offset(0, -1),
      ),
    ],
  );

  static BoxDecoration glassDecoration({required bool isDark, double radius = 30}) {
    return BoxDecoration(
      color: (isDark ? Colors.black : Colors.white).withOpacity(0.15),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: glassBorder, width: 0.8),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  static BoxDecoration capsuleDecoration() => BoxDecoration(
    color: Colors.white.withOpacity(0.05),
    borderRadius: BorderRadius.circular(100),
    border: Border.all(color: glassBorder, width: 0.8),
  );

  static BoxDecoration filigreeBackground() => const BoxDecoration(
    color: deepCharcoal,
  );

  static List<BoxShadow> sapphireGlow() => [
    BoxShadow(color: sapphireBlue.withOpacity(0.5), blurRadius: 20, spreadRadius: 2)
  ];

  // ── Theme Definitions ──────────────────────────────────────────────────────

  static ThemeData get darkTheme => _buildTheme(Brightness.dark);
  static ThemeData get lightTheme => _buildTheme(Brightness.dark); 

  static ThemeData _buildTheme(Brightness brightness) {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: deepCharcoal,
      primaryColor: platinum,
      colorScheme: const ColorScheme.dark(
        primary: platinum,
        onPrimary: luxuryBlack,
        secondary: sapphireBlue,
        surface: luxuryBlack,
        onSurface: platinum,
        outline: glassBorder,
        error: error,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: brushedPlatinum,
        refreshBackgroundColor: luxuryBlack,
      ),

      textTheme: TextTheme(
        displayLarge: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.w900, color: brightPlatinum),
        headlineLarge: GoogleFonts.playfairDisplay(fontSize: 26, fontWeight: FontWeight.bold, color: brightPlatinum, letterSpacing: 0.5),
        labelSmall: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: platinum, letterSpacing: 2.0),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: luxuryBlack.withOpacity(0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(100), borderSide: const BorderSide(color: glassBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(100), borderSide: const BorderSide(color: glassBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(100), borderSide: const BorderSide(color: platinum, width: 1)),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: platinum,
          foregroundColor: luxuryBlack,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
      ),

      appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
      
      cardTheme: CardThemeData(
        color: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}
