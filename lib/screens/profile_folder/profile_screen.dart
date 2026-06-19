import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../login_screen.dart';
import 'profile_details_screen.dart';
import '../payment_folder/payment_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (mounted) setState(() { _profile = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _displayName {
    if (_profile != null) {
      final name = _profile!['full_name'] as String? ??
          _profile!['name'] as String? ??
          _profile!['username'] as String?;
      if (name != null && name.isNotEmpty) return name;
    }
    final meta = supabase.auth.currentUser?.userMetadata;
    return meta?['full_name'] as String? ??
        meta?['name'] as String? ??
        '';
  }

  String get _email => supabase.auth.currentUser?.email ?? '';

  String get _initials {
    if (_displayName.isNotEmpty) {
      final parts = _displayName.trim().split(' ').where((w) => w.isNotEmpty).toList();
      if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      return parts[0][0].toUpperCase();
    }
    if (_email.isNotEmpty) return _email[0].toUpperCase();
    return '?';
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Logout',
            style: AppTextStyles.h5.copyWith(color: AppColors.primary)),
        content: Text(
          'Are you sure you want to logout?',
          style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: AppTextStyles.btnSm.copyWith(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Logout', style: AppTextStyles.btnSm),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await supabase.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$feature — coming soon!'),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: AppColors.primary,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ColoredBox(
        color: AppColors.surfaceLight,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.secondary),
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    return ColoredBox(
      color: AppColors.surfaceLight,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _ProfileHeader(
              initials: _initials,
              name: _displayName,
              email: _email,
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Account section
                  _SectionLabel('Account'),
                  const SizedBox(height: 8),
                  _MenuCard(items: [
                    _MenuItem(
                      icon: Icons.person_outline_rounded,
                      label: 'Profile Details',
                      subtitle: 'Edit your personal info',
                      color: AppColors.secondary,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ProfileDetailsScreen())),
                    ),
                    _MenuItem(
                      icon: Icons.payment_rounded,
                      label: 'Payment History',
                      subtitle: 'View past transactions',
                      color: AppColors.success,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const PaymentHistoryScreen())),
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // Preferences section
                  _SectionLabel('Preferences'),
                  const SizedBox(height: 8),
                  _MenuCard(items: [
                    _MenuItem(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      subtitle: 'App preferences & notifications',
                      color: AppColors.primary,
                      onTap: () => _showComingSoon('Settings'),
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // Logout section
                  _MenuCard(items: [
                    _MenuItem(
                      icon: Icons.logout_rounded,
                      label: 'Logout',
                      color: AppColors.error,
                      textColor: AppColors.error,
                      showTrailing: false,
                      onTap: _logout,
                    ),
                  ]),

                  const SizedBox(height: 32),
                  Text('TravelMeta v1.0.0', style: AppTextStyles.caption),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Profile Header ───────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final String initials;
  final String name;
  final String email;
  const _ProfileHeader({
    required this.initials,
    required this.name,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: AppTextStyles.h3.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Name
          Text(
            name.isNotEmpty ? name : 'Traveler',
            style: AppTextStyles.h5.copyWith(color: Colors.white),
          ),

          const SizedBox(height: 4),

          // Email
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.email_outlined,
                  size: 13, color: Colors.white.withValues(alpha: 0.80)),
              const SizedBox(width: 5),
              Text(
                email.isNotEmpty ? email : '—',
                style: AppTextStyles.bodySm.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text.toUpperCase(),
          style: AppTextStyles.labelSm.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 1.0,
          ),
        ),
      );
}

// ─── Menu card ────────────────────────────────────────────────────────────────

class _MenuCard extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            items[i],
            if (i < items.length - 1)
              const Divider(height: 1, indent: 56, color: AppColors.borderLight),
          ],
        ],
      ),
    );
  }
}

// ─── Menu item ────────────────────────────────────────────────────────────────

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final Color? textColor;
  final VoidCallback onTap;
  final bool showTrailing;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.color,
    this.textColor,
    required this.onTap,
    this.showTrailing = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.label.copyWith(
                      color: textColor ?? AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: AppTextStyles.caption.copyWith(fontSize: 11)),
                  ],
                ],
              ),
            ),
            if (showTrailing)
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
