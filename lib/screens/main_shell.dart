import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/shared_chrome.dart';
import 'home_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _idx = 0;

  static const List<Widget> _pages = [
    HomeScreen(),
    _PlaceholderPage('Explore', Icons.explore_rounded),
    _PlaceholderPage('Bookings', Icons.event_note_rounded),
    _PlaceholderPage('Community', Icons.people_rounded),
    _PlaceholderPage('Profile', Icons.person_rounded),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      // No leading override → shows the gradient logo circle
      appBar: const TmAppBar(),
      body: IndexedStack(index: _idx, children: _pages),
      bottomNavigationBar: TmBottomNav(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
      ),
    );
  }
}

// ─── Placeholder pages (Explore, Bookings, Community, Profile) ────────────────

class _PlaceholderPage extends StatelessWidget {
  final String name;
  final IconData icon;

  const _PlaceholderPage(this.name, this.icon);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 34, color: AppColors.secondary),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: AppTextStyles.h4.copyWith(
              color: AppColors.primary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Coming soon',
            style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
