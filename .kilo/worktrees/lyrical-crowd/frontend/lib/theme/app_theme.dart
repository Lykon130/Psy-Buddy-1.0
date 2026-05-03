import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData getTheme(String emotion) {
    Color primaryColor;
    Color backgroundColor;
    Color surfaceColor;

    switch (emotion.toLowerCase()) {
      case 'happy':
        primaryColor = Colors.orangeAccent;
        backgroundColor = const Color(0xFFFFF8E1); // Light warm yellow
        surfaceColor = Colors.white;
        break;
      case 'sad':
        primaryColor = Colors.blueGrey;
        backgroundColor = const Color(0xFFECEFF1);
        surfaceColor = Colors.white;
        break;
      case 'angry':
        primaryColor = Colors.redAccent;
        backgroundColor = const Color(0xFFFFEBEE);
        surfaceColor = Colors.white;
        break;
      case 'anxious':
        primaryColor = Colors.deepPurpleAccent;
        backgroundColor = const Color(0xFFF3E5F5);
        surfaceColor = Colors.white;
        break;
      case 'neutral':
      default:
        primaryColor = Colors.teal;
        backgroundColor = const Color(0xFFFAFAFA);
        surfaceColor = Colors.white;
        break;
    }

    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
      cardColor: surfaceColor,
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryColor),
        titleTextStyle: GoogleFonts.inter(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(),
      useMaterial3: true,
    );
  }

  // A specific text theme for Journal/Dreams (diary aesthetic)
  static TextTheme diaryTextTheme = GoogleFonts.loraTextTheme();
}
