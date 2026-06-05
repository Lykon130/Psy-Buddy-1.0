import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Dark Theme ────────────────────────────────────────────────────────────
  static const Color darkBg            = Color(0xFF0D0D12);
  static const Color darkSurface       = Color(0xFF16161F);
  static const Color darkSurfaceVar    = Color(0xFF1E1E2A);
  static const Color darkBorder        = Color(0xFF2A2A3A);
  static const Color darkTextPrimary   = Color(0xFFF0F0F8);
  static const Color darkTextSecondary = Color(0xFF8B8BA7);
  static const Color darkTextTertiary  = Color(0xFF5A5A72);

  // ── Light Theme ───────────────────────────────────────────────────────────
  static const Color lightBg            = Color(0xFFF8F8FD);
  static const Color lightSurface       = Color(0xFFFFFFFF);
  static const Color lightSurfaceVar    = Color(0xFFF0F0F8);
  static const Color lightBorder        = Color(0xFFE4E4EF);
  static const Color lightTextPrimary   = Color(0xFF0D0D12);
  static const Color lightTextSecondary = Color(0xFF6B6B85);
  static const Color lightTextTertiary  = Color(0xFF9898B0);

  // ── Primary (Indigo) ──────────────────────────────────────────────────────
  static const Color primaryDark           = Color(0xFF7C6EF8);
  static const Color primaryLight          = Color(0xFF6B5EE8);
  static const Color primaryContainerDark  = Color(0xFF2D2760);
  static const Color primaryContainerLight = Color(0xFFEDE9FF);

  // ── Brand Gradient ────────────────────────────────────────────────────────
  static const List<Color> brandGradient = [
    Color(0xFF7C6EF8),
    Color(0xFF5B8AF5),
    Color(0xFF4ECDC4),
  ];

  // ── Persona Colors ────────────────────────────────────────────────────────
  static const Color personaFriend = Color(0xFFF59E0B);
  static const Color personaCoach  = Color(0xFF10B981);
  static const Color personaEmpath = Color(0xFF7C6EF8);

  // Persona bg tints
  static const Color personaFriendBgDark  = Color(0xFF2D2200);
  static const Color personaCoachBgDark   = Color(0xFF00261A);
  static const Color personaEmpathBgDark  = Color(0xFF1A1740);
  static const Color personaFriendBgLight = Color(0xFFFEF3C7);
  static const Color personaCoachBgLight  = Color(0xFFD1FAE5);
  static const Color personaEmpathBgLight = Color(0xFFEDE9FE);

  // ── Emotion Accent Colors ─────────────────────────────────────────────────
  static const Color emotionJoy      = Color(0xFFF59E0B);
  static const Color emotionCalm     = Color(0xFF10B981);
  static const Color emotionSad      = Color(0xFF3B82F6);
  static const Color emotionAngry    = Color(0xFFEF4444);
  static const Color emotionFear     = Color(0xFF8B5CF6);
  static const Color emotionConfused = Color(0xFFF97316);
  static const Color emotionNeutral  = Color(0xFF6B7280);

  static Color getEmotionColor(String emotion, {bool isDark = true}) {
    switch (emotion.toLowerCase().trim()) {
      case 'joy':
      case 'amusement':
      case 'excitement':
      case 'optimism':
      case 'relief':
      case 'gratitude':
      case 'curiosity':
      case 'surprise':
        return emotionJoy;
      case 'admiration':
      case 'approval':
      case 'pride':
      case 'desire':
        return emotionCalm;
      case 'caring':
      case 'love':
      case 'sadness':
      case 'grief':
      case 'remorse':
        return emotionSad;
      case 'anger':
      case 'annoyance':
      case 'disapproval':
      case 'disgust':
        return emotionAngry;
      case 'confusion':
      case 'realization':
        return emotionConfused;
      case 'fear':
      case 'embarrassment':
      case 'nervousness':
        return emotionFear;
      default:
        return isDark ? primaryDark : primaryLight;
    }
  }
}
