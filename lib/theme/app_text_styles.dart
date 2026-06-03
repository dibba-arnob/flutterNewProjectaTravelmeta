import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract class AppTextStyles {
  static const String _heading = 'PlusJakartaSans';
  static const String _body    = 'Inter';
  static const String _bangla  = 'HindSiliguri';

  // ─── Headings ───────────────────────────────────────────
  static const TextStyle h1 = TextStyle(fontFamily: _heading, fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.2);
  static const TextStyle h2 = TextStyle(fontFamily: _heading, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.3, height: 1.25);
  static const TextStyle h3 = TextStyle(fontFamily: _heading, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.2, height: 1.3);
  static const TextStyle h4 = TextStyle(fontFamily: _heading, fontSize: 20, fontWeight: FontWeight.w700, height: 1.3);
  static const TextStyle h5 = TextStyle(fontFamily: _heading, fontSize: 18, fontWeight: FontWeight.w600, height: 1.4);
  static const TextStyle h6 = TextStyle(fontFamily: _heading, fontSize: 16, fontWeight: FontWeight.w600, height: 1.4);

  // ─── Body ───────────────────────────────────────────────
  static const TextStyle bodyLg = TextStyle(fontFamily: _body, fontSize: 16, fontWeight: FontWeight.w400, height: 1.6);
  static const TextStyle body   = TextStyle(fontFamily: _body, fontSize: 14, fontWeight: FontWeight.w400, height: 1.57);
  static const TextStyle bodySm = TextStyle(fontFamily: _body, fontSize: 13, fontWeight: FontWeight.w400, height: 1.5);

  // ─── Label ──────────────────────────────────────────────
  static const TextStyle labelLg = TextStyle(fontFamily: _body, fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: 0.1);
  static const TextStyle label   = TextStyle(fontFamily: _body, fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.1);
  static const TextStyle labelSm = TextStyle(fontFamily: _body, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.2);

  // ─── Caption ────────────────────────────────────────────
  static const TextStyle caption   = TextStyle(fontFamily: _body, fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textMuted, height: 1.4);
  static const TextStyle captionMd = TextStyle(fontFamily: _body, fontSize: 12, fontWeight: FontWeight.w600, height: 1.4);

  // ─── Price ──────────────────────────────────────────────
  static const _tabular = [FontFeature.tabularFigures()];
  static const TextStyle priceLg = TextStyle(fontFamily: _body, fontSize: 24, fontWeight: FontWeight.w700, fontFeatures: _tabular, letterSpacing: -0.3);
  static const TextStyle price   = TextStyle(fontFamily: _body, fontSize: 18, fontWeight: FontWeight.w600, fontFeatures: _tabular);
  static const TextStyle priceSm = TextStyle(fontFamily: _body, fontSize: 14, fontWeight: FontWeight.w600, fontFeatures: _tabular);

  // ─── Button ─────────────────────────────────────────────
  static const TextStyle btn   = TextStyle(fontFamily: _body, fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.1);
  static const TextStyle btnSm = TextStyle(fontFamily: _body, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.1);

  // ─── Bangla ─────────────────────────────────────────────
  static const TextStyle bodyBn = TextStyle(fontFamily: _bangla, fontSize: 14, fontWeight: FontWeight.w400, height: 1.7);
  static const TextStyle h3Bn   = TextStyle(fontFamily: _bangla, fontSize: 24, fontWeight: FontWeight.w700, height: 1.4);
}