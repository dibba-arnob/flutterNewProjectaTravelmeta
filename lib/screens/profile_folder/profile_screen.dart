import 'dart:io' show File, Platform;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  bool _uploading = false;
  String? _avatarUrl;
  Uint8List? _avatarBytes; // actual image bytes — bypasses all URL/browser caching
  int _avatarKey = 0;

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
      final url = _resolveAvatarUrl(data?['avatar_url'] as String?);
      final bytes = await _fetchBytes(url);
      if (mounted) {
        setState(() {
          _profile = data;
          _loading = false;
          _uploading = false;
          _avatarUrl = url;
          _avatarBytes = bytes;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; _uploading = false; });
    }
  }

  String? _resolveAvatarUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return supabase.storage.from('avatars').getPublicUrl(path);
  }

  // Fetch raw bytes from a URL — no cache involved
  Future<Uint8List?> _fetchBytes(String? url) async {
    if (url == null) return null;
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) return res.bodyBytes;
    } catch (_) {}
    return null;
  }

  bool get _isMobile =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  // Shows sheet on every platform — returns 'change', 'remove', or null
  Future<String?> _showAvatarActionSheet() {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text('Profile Picture',
                style: AppTextStyles.h5.copyWith(color: AppColors.primary)),
            const SizedBox(height: 20),
            _SourceTile(
              icon: Icons.photo_library_rounded,
              label: 'Choose from Gallery',
              color: AppColors.secondary,
              onTap: () => Navigator.pop(ctx, 'change'),
            ),
            if (_isMobile) ...[
              const SizedBox(height: 12),
              _SourceTile(
                icon: Icons.camera_alt_rounded,
                label: 'Take a Photo',
                color: AppColors.primary,
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
            ],
            if (_avatarUrl != null) ...[
              const SizedBox(height: 12),
              _SourceTile(
                icon: Icons.delete_outline_rounded,
                label: 'Remove Photo',
                color: AppColors.error,
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_uploading) return;

    final action = await _showAvatarActionSheet();
    if (action == null) return;

    if (action == 'remove') {
      await _removeAvatar();
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) return;

    Uint8List? bytes;
    String ext = 'jpg';

    try {
      if (_isMobile && action == 'camera') {
        final xfile = await ImagePicker().pickImage(
          source: ImageSource.camera,
          maxWidth: 800, maxHeight: 800, imageQuality: 85,
        );
        if (xfile == null) return;
        bytes = await xfile.readAsBytes();
        ext = xfile.name.split('.').last.toLowerCase();
      } else if (_isDesktop) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image, allowMultiple: false, withData: false,
        );
        if (result == null || result.files.isEmpty) return;
        final picked = result.files.first;
        if (picked.path == null) return;
        ext = (picked.extension ?? 'jpg').toLowerCase();
        bytes = await File(picked.path!).readAsBytes();
      } else {
        // Mobile gallery or web
        final source = _isMobile ? ImageSource.gallery : ImageSource.gallery;
        final xfile = await ImagePicker().pickImage(
          source: source,
          maxWidth: 800, maxHeight: 800, imageQuality: 85,
        );
        if (xfile == null) return;
        bytes = await xfile.readAsBytes();
        ext = xfile.name.split('.').last.toLowerCase();
      }
    } catch (e) {
      if (mounted) _showError('Could not open image: $e');
      return;
    }

    setState(() => _uploading = true);
    try {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final mime = ext == 'jpg' ? 'image/jpeg' : 'image/$ext';
      final storagePath = '${user.id}/avatar_$ts.$ext';

      // 1. Upload file to storage
      await supabase.storage.from('avatars').uploadBinary(
        storagePath, bytes,
        fileOptions: FileOptions(contentType: mime, upsert: false),
      );

      // 2. Update profiles table — use .select() so we can detect silent RLS failures
      final updated = await supabase.from('profiles').update({
        'avatar_url': storagePath,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', user.id).select();

      if (updated.isEmpty) {
        throw Exception('Profile row not updated — check RLS policies on the profiles table');
      }

      // 3. Fetch the uploaded image as raw bytes — bypasses all URL/browser caching
      final newUrl = _resolveAvatarUrl(storagePath);
      final newBytes = await _fetchBytes(newUrl);
      if (mounted) {
        setState(() {
          _avatarUrl = newUrl;
          _avatarBytes = newBytes;
          _avatarKey++;
          _uploading = false;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile picture updated'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        _showError('Upload failed: $e');
      }
    }
  }

  Future<void> _removeAvatar() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    setState(() => _uploading = true);
    try {
      await supabase.from('profiles').update({
        'avatar_url': null,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', user.id);
      if (mounted) {
        setState(() {
          _avatarUrl = null;
          _avatarBytes = null;
          _avatarKey++;
          _uploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        _showError('Could not remove photo: $e');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.error,
    ));
  }

  // ── Display helpers ───────────────────────────────────────────────────────

  String get _displayName {
    if (_profile != null) {
      final name = _profile!['full_name'] as String? ??
          _profile!['name'] as String? ??
          _profile!['username'] as String?;
      if (name != null && name.isNotEmpty) return name;
    }
    final meta = supabase.auth.currentUser?.userMetadata;
    return meta?['full_name'] as String? ?? meta?['name'] as String? ?? '';
  }

  String get _email => supabase.auth.currentUser?.email ?? '';

  String get _initials {
    if (_displayName.isNotEmpty) {
      final parts =
          _displayName.trim().split(' ').where((w) => w.isNotEmpty).toList();
      if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      return parts[0][0].toUpperCase();
    }
    if (_email.isNotEmpty) return _email[0].toUpperCase();
    return '?';
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:
            Text('Logout', style: AppTextStyles.h5.copyWith(color: AppColors.primary)),
        content: Text('Are you sure you want to logout?',
            style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
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

  // ── Build ─────────────────────────────────────────────────────────────────

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
              key: ValueKey(_avatarKey),
              initials: _initials,
              name: _displayName,
              email: _email,
              avatarBytes: _avatarBytes,
              uploading: _uploading,
              onPickAvatar: _pickAndUploadAvatar,
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _SectionLabel('Account'),
                  const SizedBox(height: 8),
                  _MenuCard(items: [
                    _MenuItem(
                      icon: Icons.person_outline_rounded,
                      label: 'Profile Details',
                      subtitle: 'Edit your personal info',
                      color: AppColors.secondary,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const ProfileDetailsScreen()))
                          .then((_) => _loadProfile()),
                    ),
                    _MenuItem(
                      icon: Icons.payment_rounded,
                      label: 'Payment History',
                      subtitle: 'View past transactions',
                      color: AppColors.success,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const PaymentHistoryScreen())),
                    ),
                  ]),

                  const SizedBox(height: 16),

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
  final Uint8List? avatarBytes;
  final bool uploading;
  final VoidCallback onPickAvatar;

  const _ProfileHeader({
    super.key,
    required this.initials,
    required this.name,
    required this.email,
    required this.avatarBytes,
    required this.uploading,
    required this.onPickAvatar,
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
          // ── Avatar with camera overlay ──────────────────────────────
          GestureDetector(
            onTap: onPickAvatar,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Circle border
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    color: Colors.white.withValues(alpha: 0.20),
                  ),
                  child: ClipOval(
                    child: uploading
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation(Colors.white),
                              strokeWidth: 2.5,
                            ),
                          )
                        : avatarBytes != null
                            ? Image.memory(
                                avatarBytes!,
                                fit: BoxFit.cover,
                                width: 90,
                                height: 90,
                                errorBuilder: (context, err, stack) =>
                                    _InitialsAvatar(initials: initials),
                              )
                            : _InitialsAvatar(initials: initials),
                  ),
                ),

                // Camera badge (bottom-right)
                if (!uploading)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          size: 13, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Text(
            name.isNotEmpty ? name : 'Traveler',
            style: AppTextStyles.h5.copyWith(color: Colors.white),
          ),

          const SizedBox(height: 4),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.email_outlined,
                  size: 13, color: Colors.white.withValues(alpha: 0.80)),
              const SizedBox(width: 5),
              Text(
                email.isNotEmpty ? email : '—',
                style: AppTextStyles.bodySm.copyWith(
                    color: Colors.white.withValues(alpha: 0.85)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String initials;
  const _InitialsAvatar({required this.initials});

  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          initials,
          style: AppTextStyles.h3.copyWith(
              color: Colors.white, fontWeight: FontWeight.w700),
        ),
      );
}

// ─── Bottom sheet source tile ─────────────────────────────────────────────────

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SourceTile(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 14),
              Text(label,
                  style: AppTextStyles.label.copyWith(
                      color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
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
              color: AppColors.textMuted, letterSpacing: 1.0),
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
                  Text(label,
                      style: AppTextStyles.label.copyWith(
                          color: textColor ?? AppColors.primary,
                          fontWeight: FontWeight.w600)),
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
