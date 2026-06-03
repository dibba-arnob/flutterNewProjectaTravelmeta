import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> cardElevated = [
    BoxShadow(color: AppColors.shadow, blurRadius: 16, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> bottomNav = [
    BoxShadow(color: AppColors.shadow, blurRadius: 24, offset: Offset(0, -4)),
  ];

  static const List<BoxShadow> searchBar = [
    BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> fab = [
    BoxShadow(color: AppColors.shadow, blurRadius: 16, offset: Offset(0, 6)),
  ];

  static const List<BoxShadow> none = [];
}