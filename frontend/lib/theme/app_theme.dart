import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData getTheme(String emotion) {
    Color primaryColor;
    Color backgroundColor;
    Color surfaceColor = Colors.white;

    final lowerEmotion = emotion.toLowerCase();

    // Group 1: Base - #FCDE99
    final group1 = ['joy', 'amusement', 'excitement', 'optimism', 'relief', 'gratitude', 'curiosity', 'surprise'];
    
    // Group 2: Soft mint green - #BBF7D0
    final group2 = ['admiration', 'approval', 'pride', 'desire'];
    
    // Group 3: Light sky blue - #BAE6FD
    final group3 = ['caring', 'love', 'sadness', 'grief', 'remorse'];
    
    // Group 4: Soft red - #FCA5A5
    final group4 = ['anger', 'annoyance', 'disapproval', 'disgust'];
    
    // Group 5: Soft peach orange - #FDBA74
    final group5 = ['confusion', 'realization'];
    
    // Group 6: Soft lavender - #DDD6FE (Nervousness is commonly fear-adjacent and added here to complete 28)
    final group6 = ['fear', 'embarrassment', 'nervousness']; 
    
    // Group 7: Light gray - #F3F4F6
    final group7 = ['disappointment', 'neutral'];

    if (group1.contains(lowerEmotion)) {
      backgroundColor = const Color(0xFFFCDE99);
      primaryColor = const Color(0xFFD6A010); // Darker tone for text/icons
    } else if (group2.contains(lowerEmotion)) {
      backgroundColor = const Color(0xFFBBF7D0);
      primaryColor = const Color(0xFF16A34A);
    } else if (group3.contains(lowerEmotion)) {
      backgroundColor = const Color(0xFFBAE6FD);
      primaryColor = const Color(0xFF0284C7);
    } else if (group4.contains(lowerEmotion)) {
      backgroundColor = const Color(0xFFFCA5A5);
      primaryColor = const Color(0xFFDC2626);
    } else if (group5.contains(lowerEmotion)) {
      backgroundColor = const Color(0xFFFDBA74);
      primaryColor = const Color(0xFFEA580C);
    } else if (group6.contains(lowerEmotion)) {
      backgroundColor = const Color(0xFFDDD6FE);
      primaryColor = const Color(0xFF7C3AED);
    } else if (group7.contains(lowerEmotion)) {
      backgroundColor = const Color(0xFFF3F4F6);
      primaryColor = const Color(0xFF4B5563);
    } else {
      // Default / fallback
      backgroundColor = const Color(0xFFF3F4F6);
      primaryColor = const Color(0xFF4B5563);
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
