import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.surfaceLight,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_rounded, size: 56, color: AppColors.borderLight),
            SizedBox(height: 14),
            Text('Community', style: AppTextStyles.h5),
            SizedBox(height: 6),
            Text('Coming soon.', style: AppTextStyles.bodySm),
          ],
        ),
      ),
    );
  }
}
