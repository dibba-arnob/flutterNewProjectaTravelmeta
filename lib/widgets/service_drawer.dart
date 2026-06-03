import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

// ServiceDrawer is navigation-agnostic: the caller provides [onNavigate] so
// there is no circular import between this file and service_screens.dart.

class ServiceDrawer extends StatelessWidget {
  /// Index of the currently active service (0 = Flights … 7 = Wallet).
  final int currentIndex;

  /// Called with the target index when the user taps a different service item.
  /// The caller is responsible for executing the actual route push.
  final ValueChanged<int> onNavigate;

  const ServiceDrawer({
    super.key,
    required this.currentIndex,
    required this.onNavigate,
  });

  static const _items = [
    (Icons.flight_takeoff_rounded, 'Flights'),
    (Icons.hotel, 'Hotels'),
    (Icons.directions_bus_rounded, 'Bus'),
    (Icons.train_rounded, 'Train'),
    (Icons.local_taxi_rounded, 'Cab'),
    (Icons.luggage_rounded, 'Packages'),
    (Icons.explore_rounded, 'Guide'),
    (Icons.account_balance_wallet_rounded, 'Wallet'),
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.secondary, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo circle
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.flight_takeoff_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'TravelMeta',
                      style:
                          AppTextStyles.h5.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Services',
                      style: AppTextStyles.bodySm.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Navigation items ────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: _items.length,
              itemBuilder: (context, i) {
                final active = i == currentIndex;
                final (icon, label) = _items[i];
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  child: Material(
                    color: active
                        ? AppColors.secondary.withValues(alpha: 0.10)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      splashColor: AppColors.secondary.withValues(alpha: 0.12),
                      onTap: () {
                        Navigator.pop(context); // close drawer
                        if (i != currentIndex) onNavigate(i);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              icon,
                              size: 22,
                              color: active
                                  ? AppColors.secondary
                                  : AppColors.textMuted,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                label,
                                style: AppTextStyles.label.copyWith(
                                  color: active
                                      ? AppColors.primary
                                      : AppColors.textMuted,
                                  fontWeight: active
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            if (active)
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.secondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Back to Home ────────────────────────────────────────────────────
          const Divider(height: 1, color: AppColors.borderLight),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: SafeArea(
              top: false,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.pop(context); // close drawer
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.arrow_back_rounded,
                          size: 22,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'Back to Home',
                          style: AppTextStyles.label
                              .copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
