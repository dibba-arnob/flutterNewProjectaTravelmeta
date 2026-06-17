import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/notifications_screen.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

// ─── App Bar ─────────────────────────────────────────────────────────────────

class TmAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Widget? leading;
  const TmAppBar({super.key, this.leading});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  State<TmAppBar> createState() => _TmAppBarState();
}

class _TmAppBarState extends State<TmAppBar> {
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _fetchUnread();
  }

  Future<void> _fetchUnread() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final data = await supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);
      if (mounted) setState(() => _unread = (data as List).length);
    } on PostgrestException {
      // silently ignore — badge just stays at 0
    } catch (_) {}
  }

  Future<void> _openNotifications(BuildContext ctx) async {
    await Navigator.of(ctx).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
    _fetchUnread();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.white,
      titleSpacing: 0,
      automaticallyImplyLeading: false,
      leading: widget.leading ??
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
        Builder(
          builder: (ctx) => Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => _openNotifications(ctx),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
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
                  if (_unread > 0)
                    Positioned(
                      top: 4,
                      right: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          _unread > 99 ? '99+' : '$_unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
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
