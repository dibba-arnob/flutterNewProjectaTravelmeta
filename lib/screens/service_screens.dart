import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/shared_chrome.dart';
import 'services/flights_screen.dart';
import 'services/hotels_screen.dart';
import 'services/bus_screen.dart';
import 'services/train_screen.dart';
import 'services/cab_screen.dart';
import 'services/packages_screen.dart';
import 'services/guide_screen.dart';
import 'services/wallet_screen.dart';

// ─── Routing helper ───────────────────────────────────────────────────────────

class ServiceNav {
  ServiceNav._();

  static Widget _build(int index) => switch (index) {
        0 => const FlightsScreen(),
        1 => const HotelsScreen(),
        2 => const BusScreen(),
        3 => const TrainScreen(),
        4 => const CabScreen(),
        5 => const PackagesScreen(),
        6 => const GuideScreen(),
        _ => const WalletScreen(),
      };

  /// Push a new service page on top of the current route (from home grid).
  static void navigateTo(BuildContext context, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _build(index)),
    );
  }

  /// Replace the current service page (from the drawer).
  static void replaceTo(BuildContext context, int index) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => _build(index)),
    );
  }
}

// ─── Shared scaffold ──────────────────────────────────────────────────────────

class _ServicePage extends StatelessWidget {
  final int index;
  final Widget body;

  const _ServicePage({required this.index, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: TmAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _ServiceQuickNav(currentIndex: index),
          Container(height: 1, color: AppColors.borderLight),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: TmBottomNav(
        currentIndex: 0,
        onTap: (_) => Navigator.popUntil(context, (route) => route.isFirst),
      ),
    );
  }
}

// ─── Service quick-nav bar ────────────────────────────────────────────────────

class _ServiceQuickNav extends StatelessWidget {
  final int currentIndex;

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

  const _ServiceQuickNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: List.generate(_items.length, (i) {
            final active = i == currentIndex;
            final (icon, label) = _items[i];
            return GestureDetector(
              onTap: () {
                if (i != currentIndex) ServiceNav.replaceTo(context, i);
              },
              child: Container(
                width: 64,
                margin: const EdgeInsets.only(right: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.secondary
                            : AppColors.secondary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        icon,
                        size: 22,
                        color: active ? Colors.white : AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      label,
                      style: AppTextStyles.labelSm.copyWith(
                        fontSize: 10,
                        color: active ? AppColors.secondary : AppColors.textMuted,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ─── 8 Service screens ────────────────────────────────────────────────────────

class FlightsScreen extends StatelessWidget {
  const FlightsScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _ServicePage(index: 0, body: FlightsContent());
}

class HotelsScreen extends StatelessWidget {
  const HotelsScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _ServicePage(index: 1, body: HotelsContent());
}

class BusScreen extends StatelessWidget {
  const BusScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _ServicePage(index: 2, body: BusContent());
}

class TrainScreen extends StatelessWidget {
  const TrainScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _ServicePage(index: 3, body: TrainContent());
}

class CabScreen extends StatelessWidget {
  const CabScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _ServicePage(index: 4, body: CabContent());
}

class PackagesScreen extends StatelessWidget {
  const PackagesScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _ServicePage(index: 5, body: PackagesContent());
}

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _ServicePage(index: 6, body: GuideContent());
}

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _ServicePage(index: 7, body: WalletContent());
}
