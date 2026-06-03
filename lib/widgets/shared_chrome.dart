import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

// ─── App Bar ─────────────────────────────────────────────────────────────────
// Used by MainShell (leading = null → shows logo circle) and every
// service page (leading = hamburger Builder that opens the drawer).

class TmAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Override the leading widget.  When null the gradient logo circle is shown.
  final Widget? leading;

  const TmAppBar({super.key, this.leading});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.white,
      titleSpacing: 0,
      automaticallyImplyLeading: false,
      leading: leading ??
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 12, bottom: 12),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.secondary, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.flight_takeoff_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'TravelMeta',
            style: AppTextStyles.h6.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 11,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 2),
              Text(
                'DHAKA, BANGLADESH',
                style: AppTextStyles.labelSm.copyWith(
                  fontSize: 10,
                  color: AppColors.textMuted,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
              ),
              Positioned(
                top: 6,
                right: 5,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFF1F5F9)),
      ),
    );
  }
}

// ─── Bottom Nav ───────────────────────────────────────────────────────────────

class TmBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const TmBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    (Icons.home_rounded, Icons.home_outlined, 'Home'),
    (Icons.explore, Icons.explore_outlined, 'Explore'),
    (Icons.event_note, Icons.event_note_outlined, 'Bookings'),
    (Icons.people, Icons.people_outline, 'Community'),
    (Icons.person, Icons.person_outline, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(_items.length, (i) {
              final active = i == currentIndex;
              final (filledIcon, outlineIcon, label) = _items[i];
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        active ? filledIcon : outlineIcon,
                        size: 23,
                        color: active ? AppColors.primary : AppColors.textMuted,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        label,
                        style: AppTextStyles.labelSm.copyWith(
                          fontSize: 10,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w400,
                          color: active
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.secondary
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
