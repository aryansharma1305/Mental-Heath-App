import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Pastel Color Palette (Inspired by modern learning apps)
  static const Color primaryPink = Color(0xFFFFC1E3);
  static const Color softPink = Color(0xFFFFF0F5);
  static const Color mintGreen = Color(0xFFD4F1D4);
  static const Color softGreen = Color(0xFFE8F5E9);
  static const Color creamBeige = Color(0xFFFFF4E6);
  static const Color softBeige = Color(0xFFFFF9F0);
  static const Color lavender = Color(0xFFE6D9F5);
  static const Color softPurple = Color(0xFFF3E5F5);
  static const Color softYellow = Color(0xFFFFFDE7);
  static const Color skyBlue = Color(0xFFE3F2FD);
  
  // Main colors
  static const Color primaryColor = Color(0xFFFF9EC7);  // Soft pink
  static const Color secondaryColor = Color(0xFFA0D8B3);  // Mint green
  static const Color accentColor = Color(0xFFFFD89C);  // Warm peach
  static const Color backgroundColor = Color(0xFFFAF7F9);  // Very soft pink-white
  
  // Dark shades for text
  static const Color textDark = Color(0xFF2D3748);
  static const Color textMedium = Color(0xFF4A5568);
  static const Color textGrey = Color(0xFF718096);
  static const Color textLight = Color(0xFFA0AEC0);
  
  // Status colors (pastel versions)
  static const Color successGreen = Color(0xFF81C995);
  static const Color warningOrange = Color(0xFFFFB84D);
  static const Color errorRed = Color(0xFFFF8A8A);
  static const Color infoBlue = Color(0xFF8AB4F8);
  
  // Surface colors
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color cardWhite = Color(0xFFFFFBFD);
  static const Color dividerColor = Color(0xFFEEE5EA);
  
  // Gradient Collections
  static const LinearGradient pinkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFC1E3), Color(0xFFFFE5F0)],
  );
  
  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFA0D8B3), Color(0xFFD4F1D4)],
  );
  
  static const LinearGradient beigeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFE4C4), Color(0xFFFFF4E6)],
  );
  
  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD6BCFA), Color(0xFFE6D9F5)],
  );
  
  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF93C5FD), Color(0xFFDCEEFF)],
  );
  
  // Background gradient
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF0F5), Color(0xFFFAF7F9), Color(0xFFFFFFFF)],
  );

  // ========================================
  // BACKWARD COMPATIBILITY ALIASES
  // ========================================
  // These maintain compatibility with existing code
  static const Color primaryBlue = Color(0xFFFF9EC7);  // Maps to primaryColor (soft pink)
  static const Color lightBlue = Color(0xFFA0D8B3);  // Maps to secondaryColor (mint green)
  static const Color accentGreen = successGreen;  // Maps to successGreen
  static const Color warningYellow = warningOrange;  // Maps to warningOrange
  // infoBlue already defined above
  
  // Gradient alias
  static const LinearGradient primaryGradient = pinkGradient;

  // Text Styles
  static TextStyle get displayLarge => GoogleFonts.poppins(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: textDark,
        letterSpacing: -0.5,
      );

  static TextStyle get headingLarge => GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textDark,
        letterSpacing: -0.5,
      );

  static TextStyle get headingMedium => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textDark,
        letterSpacing: -0.3,
      );

  static TextStyle get headingSmall => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textDark,
      );

  static TextStyle get titleLarge => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textDark,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: textMedium,
        height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: textMedium,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: textGrey,
        height: 1.5,
      );

  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textDark,
        letterSpacing: 0.1,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textDark,
        letterSpacing: 0.1,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: textGrey,
        letterSpacing: 0.1,
      );

  // Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        surface: backgroundColor,
        background: backgroundColor,
        error: errorRed,
      ),
      scaffoldBackgroundColor: backgroundColor,
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceWhite,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        iconTheme: const IconThemeData(color: textDark),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: textDark,
          foregroundColor: surfaceWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textDark,
          side: const BorderSide(color: dividerColor, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textDark,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: dividerColor, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: dividerColor, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorRed, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          color: textGrey,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: textLight,
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: softPink,
        selectedColor: primaryColor,
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceWhite,
        selectedItemColor: primaryColor,
        unselectedItemColor: textLight,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: textDark,
        foregroundColor: surfaceWhite,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: dividerColor,
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return textLight;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor.withOpacity(0.5);
          }
          return dividerColor;
        }),
      ),
    );
  }

  // Custom Shadows
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 20,
          offset: const Offset(0, 4),
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get mediumShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 24,
          offset: const Offset(0, 6),
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: textDark.withOpacity(0.15),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  // Custom Decorations
  static BoxDecoration pinkCardDecoration = BoxDecoration(
    gradient: pinkGradient,
    borderRadius: BorderRadius.circular(24),
    boxShadow: softShadow,
  );

  static BoxDecoration greenCardDecoration = BoxDecoration(
    gradient: greenGradient,
    borderRadius: BorderRadius.circular(24),
    boxShadow: softShadow,
  );

  static BoxDecoration beigeCardDecoration = BoxDecoration(
    gradient: beigeGradient,
    borderRadius: BorderRadius.circular(24),
    boxShadow: softShadow,
  );

  static BoxDecoration purpleCardDecoration = BoxDecoration(
    gradient: purpleGradient,
    borderRadius: BorderRadius.circular(24),
    boxShadow: softShadow,
  );

  static BoxDecoration whiteCardDecoration = BoxDecoration(
    color: surfaceWhite,
    borderRadius: BorderRadius.circular(24),
    boxShadow: softShadow,
  );

  // Helper method to get subject color
  static Color getSubjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'writing':
        return const Color(0xFFFFF9C4);
      case 'math':
        return const Color(0xFFE1BEE7);
      case 'chemistry':
        return const Color(0xFFFFC1E3);
      case 'developing':
      case 'development':
        return const Color(0xFFFFCCBC);
      case 'geographic':
      case 'geography':
        return const Color(0xFF8AB4F8);
      default:
        return softPink;
    }
  }

  // Helper method to get subject gradient
  static LinearGradient getSubjectGradient(String subject) {
    switch (subject.toLowerCase()) {
      case 'writing':
        return const LinearGradient(
          colors: [Color(0xFFFFF9C4), Color(0xFFFFFDE7)],
        );
      case 'math':
        return purpleGradient;
      case 'chemistry':
        return pinkGradient;
      case 'developing':
      case 'development':
        return const LinearGradient(
          colors: [Color(0xFFFFCCBC), Color(0xFFFFE0B2)],
        );
      case 'geographic':
      case 'geography':
        return blueGradient;
      default:
        return pinkGradient;
    }
  }
}
