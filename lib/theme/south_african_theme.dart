import 'package:flutter/material.dart';

/// South African-inspired color theme for the Gauteng Wellbeing Mapper app.
/// Colors are inspired by the South African flag but optimized for readability and accessibility.
class SouthAfricanTheme {
  // Primary colors inspired by South African flag
  static const Color primaryGreen = Color(0xFF007749);     // Deep green for primary actions
  static const Color primaryBlue = Color(0xFF002868);      // Deep blue for app bars and accents
  static const Color accentYellow = Color(0xFFFFB612);     // Bright yellow for highlights
  static const Color accentRed = Color(0xFFDE3831);        // Red for warnings/errors
  static const Color neutralBlack = Color(0xFF000000);     // Pure black for text
  static const Color pureWhite = Color(0xFFFFFFFF);        // Pure white for backgrounds
  
  // Extended palette for better UI design
  static const Color lightGreen = Color(0xFF4CAF50);       // Lighter green for success states
  static const Color darkGreen = Color(0xFF2E7D32);        // Darker green for pressed states
  static const Color lightBlue = Color(0xFF1976D2);        // Lighter blue for info
  static const Color darkBlue = Color(0xFF0D47A1);         // Darker blue for pressed states
  static const Color softYellow = Color(0xFFFFF8E1);       // Very light yellow for backgrounds
  static const Color softRed = Color(0xFFFFEBEE);          // Very light red for error backgrounds
  static const Color lightGrey = Color(0xFFF5F5F5);        // Light grey for cards
  static const Color mediumGrey = Color(0xFF757575);       // Medium grey for secondary text
  static const Color darkGrey = Color(0xFF424242);         // Dark grey for primary text
  
  // Semantic colors
  static const Color success = lightGreen;
  static const Color warning = accentYellow;
  static const Color error = accentRed;
  static const Color info = lightBlue;
  
  // Private mode colors (warmer, yellow-based)
  static const Color privateMode = Color(0xFFFF9800);      // Orange for private mode
  static const Color privateModeLight = Color(0xFFFFF3E0); // Light orange background
  static const Color privateModeDark = Color(0xFFE65100);  // Dark orange for text
  
  // Research mode colors (green-based)
  static const Color researchMode = primaryGreen;
  static const Color researchModeLight = Color(0xFFE8F5E8); // Light green background
  static const Color researchModeDark = Color(0xFF1B5E20);  // Dark green for text
  
  /// Creates a Material Theme using South African colors
  static ThemeData get materialTheme {
    return ThemeData(
      // Use colorScheme as the primary way to define colors
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: primaryGreen,
        tertiary: accentYellow,
        surface: pureWhite,
        error: accentRed,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      
      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: pureWhite,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: pureWhite,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: pureWhite,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentYellow,
        foregroundColor: neutralBlack,
        elevation: 4,
      ),
      
      // Card theme
      cardTheme: CardTheme(
        color: pureWhite,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      
      // Text theme
      textTheme: TextTheme(
        headlineLarge: TextStyle(color: neutralBlack, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: neutralBlack, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: darkGrey, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: darkGrey),
        bodyMedium: TextStyle(color: darkGrey),
        bodySmall: TextStyle(color: mediumGrey),
        labelLarge: TextStyle(color: pureWhite, fontWeight: FontWeight.w600),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: mediumGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accentRed, width: 2),
        ),
      ),
      
      // Bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: pureWhite,
        selectedItemColor: primaryBlue,
        unselectedItemColor: mediumGrey,
        elevation: 8,
      ),
      
      // Drawer theme
      drawerTheme: DrawerThemeData(
        backgroundColor: pureWhite,
        elevation: 8,
      ),
      
      // Progress indicator theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryGreen,
        linearTrackColor: lightGrey,
        circularTrackColor: lightGrey,
      ),
      
      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: lightGrey,
        selectedColor: primaryGreen,
        labelStyle: TextStyle(color: darkGrey),
      ),
      
      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryGreen;
          }
          return mediumGrey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryGreen.withValues(alpha: 0.5);
          }
          return lightGrey;
        }),
      ),
    );
  }
  
  /// Gets the appropriate icon color for a given background
  static Color getIconColor(Color backgroundColor) {
    // Calculate luminance to determine if we need light or dark icons
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? neutralBlack : pureWhite;
  }
  
  /// Gets the appropriate text color for a given background
  static Color getTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? neutralBlack : pureWhite;
  }
}
