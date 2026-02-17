import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF007AFF);
  static const Color backgroundLight = Color(0xFFF2F2F7);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: backgroundLight,
    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      surface: Colors.white,
    ),

    // --- HAPA NDIPO REKEBISHO LIPO ---
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white, // Background ya box

      // Rangi ya neno "Email" au "Password" kabla ya kuandika (Hint)
      hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 22),

      // Rangi ya maandishi unayoandika (Input Text)
      labelStyle: const TextStyle(color: Colors.black87),

      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
    ),

    // Pia hakikisha TextTheme imewekwa rangi nyeusi
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black87),
    ),
  );t

  // DARK MODE (Usiku)
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1C1C1E),
      hintStyle: TextStyle(color: Colors.grey.shade500),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
  );
}