import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.surfaceLight,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_rounded, size: 56, color: AppColors.borderLight),
            SizedBox(height: 14),
            Text('Profile', style: AppTextStyles.h5),
            SizedBox(height: 6),
            Text('Coming soon.', style: AppTextStyles.bodySm),
          ],
        ),
      ),
    );
  }
}
