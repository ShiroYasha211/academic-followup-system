import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF406AB4);
  static const primaryHover = Color(0xFF335591);
  static const royalBlue = Color(0xFF406AB4);
  static const royalBlueDark = Color(0xFF2D4B85);
  static const gold = Color(0xFFF1C63B);
  static const goldDeep = Color(0xFFD4AE34);
  static const cream = Color(0xFFEAF1F9);
  static const creamAlt = Color(0xFFD3E3F2);
  static const midnight = Color(0xFF172B4D);
  static const slate900 = Color(0xFF1E293B);
  static const slate800 = Color(0xFF1E293B);
  static const slate700 = Color(0xFF475569);
  static const slate600 = Color(0xFF475569);
  static const slate500 = Color(0xFF64748B);
  static const slate400 = Color(0xFF94A3B8);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate200 = Color(0xFFCBD5E1);
  static const slate100 = Color(0xFFEAF1F9);
  static const slate50 = Color(0xFFF8FAFE);
  static const surface = Color(0xFFFFFFFF);
  static const success = Color(0xFF10B981);
  static const danger = Color(0xFFF43F5E);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF3B82F6);
  static const teal = Color(0xFF0F766E);
  static const orange = Color(0xFFEA580C);
  static const rose = Color(0xFFBE123C);
  static const violet = Color(0xFF7C3AED);
  static const ghostWhite = Color(0xFFF8FAFE);

  static const authGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [cream, creamAlt, Color(0xFFC0D6EB)],
  );

  static const primaryGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [royalBlue, royalBlueDark],
  );

  static const goldGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [gold, goldDeep],
  );

  static const brandGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [royalBlue, royalBlueDark, gold],
  );
}
