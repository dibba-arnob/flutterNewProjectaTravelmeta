import 'package:flutter/material.dart';

abstract class AppColors {
  // ─── Brand ──────────────────────────────────────────────
  static const Color primary   = Color(0xFF0A2540); // deep navy
  static const Color secondary = Color(0xFF0891B2); // cyan
  static const Color accent    = Color(0xFF06B6D4); // light cyan

  // ─── Gradient ───────────────────────────────────────────
  static const LinearGradient brandGradient = LinearGradient(
    colors: [primary, secondary, accent],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ─── Backgrounds ────────────────────────────────────────
  static const Color bgLight   = Color(0xFFFFFFFF);
  static const Color bgDark    = Color(0xFF0A0F1E);

  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color surfaceDark  = Color(0xFF1E2535);

  // ─── Text ───────────────────────────────────────────────
  static const Color textLight = Color(0xFF0F172A);
  static const Color textDark  = Color(0xFFF1F5F9);
  static const Color textMuted = Color(0xFF64748B);

  // ─── Button ─────────────────────────────────────────────
  static const Color buttonPrimary = primary;
  static const Color buttonText    = Color(0xFFFFFFFF);

  // ─── Border ─────────────────────────────────────────────
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark  = Color(0x14FFFFFF);

  // ─── Semantic ───────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error   = Color(0xFFEF4444);

  // ─── Shadow ─────────────────────────────────────────────
  static const Color shadow = Color(0x140A2540);
}