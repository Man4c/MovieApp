import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  scaffoldBackgroundColor: const Color(0xFF121212),
  colorScheme: ColorScheme.dark(
    primary: Colors.red,
    secondary: Colors.red,
    surface: const Color(0xFF1D1D1D),
    onSurface: Colors.white,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.red,
    elevation: 0,
    centerTitle: true,
  ),
  textTheme: const TextTheme(
    titleLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    bodyMedium: TextStyle(fontSize: 14, color: Colors.white70),
  ),
  cardTheme: CardTheme(
    color: const Color(0xFF1D1D1D),
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFF0B253F),
    selectedItemColor: Color(0xFF1F80E0),
    unselectedItemColor: Colors.white54,
  ),
);
