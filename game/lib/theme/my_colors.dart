import 'package:flutter/material.dart';

class AppColors {
  static const Color darkPrimary = Color(0xFF263238);
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color lightPrimary = Color(0xFF00BCD4); // Cyan
  static const Color lightSecondary = Color(0xFFFFC107); // Amber
}

class MyColors {
  static const Color lightGray = AppColors.darkPrimary;
  static const Color lightGraydark = Color.fromARGB(255, 9, 49, 54);
  static const Color white = Color.fromARGB(255, 255, 255, 255);
  static const Color black = Color(0xFF000000);
  static const Color mediumGray = Color(0xFF8AA5AB);
  static const Color tealGray = Color(0xFF51797F);
  static const Color darkBackground = AppColors.darkBackground;
  static const Color cardBackground = Color(0xFF404040);
  static const Color amber = Colors.amber;
  static const Color transparent = Colors.transparent;
  static const Color orange = Colors.orange;
  static const Color cyan = Colors.cyan;
  static const Color red = Color(0xFFFF0000);
  static const Color historyBackground = AppColors.darkSurface;
  static const Color background = AppColors.darkSurface;
  static const Color primary = AppColors.lightPrimary;
  static const Color accent = AppColors.lightSecondary;
}
