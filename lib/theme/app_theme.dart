import 'package:flutter/material.dart';

class AppTheme {
  // Volcano / Fire Colors
  static const Color fireBrick = Color(0xFFB22222);
  static const Color orangeRed = Color(0xFFFF4500);
  static const Color tomato = Color(0xFFFF6347);
  static const Color darkOrange = Color(0xFFFF8C00);
  static const Color gold = Color(0xFFFFD700);

  static const List<Color> volcanoColors = [
    orangeRed,
    tomato,
    darkOrange,
    gold,
  ];

  static const List<Color> darkVolcanoColors = [
    fireBrick,
    orangeRed,
    darkOrange,
    gold,
  ];

  static BoxDecoration get volcanoGradient => const BoxDecoration(
        gradient: LinearGradient(
          colors: volcanoColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static BoxDecoration get darkVolcanoGradient => const BoxDecoration(
        gradient: LinearGradient(
          colors: darkVolcanoColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static ThemeData get lightTheme => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: orangeRed,
          primary: orangeRed,
          secondary: tomato,
          surface: Colors.grey[100]!,
        ),
        useMaterial3: true,
      );
}
