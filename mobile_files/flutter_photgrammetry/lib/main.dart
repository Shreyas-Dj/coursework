import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
 
void main() {
  runApp(const PhotogrammetryApp());
}
 
class PhotogrammetryApp extends StatelessWidget {
  const PhotogrammetryApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photogrammetry',
      debugShowCheckedModeBanner: false,
 
      // ── Dark theme ───────────────────────────────────────────────────────
      // Sets up the global dark colour scheme so every screen is dark by default.
      // Individual screens and widgets can still override specific colours.
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF111111),
        colorScheme: const ColorScheme.dark(
          surface: Color(0xFF111111),
          primary: Color(0xFF5a8fd4),
        ),
 
        // Bottom navigation bar styling applied globally
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF161614),
          selectedItemColor: Color(0xFFf0f0ee),
          unselectedItemColor: Color(0xFF555555),
          elevation: 0,
        ),
 
        // SnackBar styling for the temporary toast messages
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF2a2a28),
          contentTextStyle: TextStyle(color: Color(0xFFf0f0ee)),
          behavior: SnackBarBehavior.floating,
        ),
 
        // Makes the refresh indicator match the app accent colour
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Color(0xFF5a8fd4),
        ),
 
        useMaterial3: true,
      ),
 
      // Start on the home screen
      home: const HomeScreen(),
    );
  }
}
 