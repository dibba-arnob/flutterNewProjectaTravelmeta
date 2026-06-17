import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class AppNotification {
  final String id;
  final String category;
  final String title;
  final String? body;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.category,
    required this.title,
    this.body,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as String,
        category: j['category'] as String? ?? 'system',
        title: j['title'] as String,
        body: j['body'] as String?,
        data: j['data'] as Map<String, dynamic>?,
        isRead: j['is_read'] as bool? ?? false,
        createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
      );
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

(IconData, Color, String) _categoryMeta(String cat) => switch (cat) {
      'booking'  => (Icons.confirmation_number_rounded, AppColors.secondary,    'Booking'),
      'reminder' => (Icons.alarm_rounded,               AppColors.warning,       'Reminder'),
      'alert'    => (Icons.warning_amber_rounded,        AppColors.error,         'Alert'),
      'promo'    => (Icons.local_offer_rounded,          AppColors.success,       'Promo'),
      'payment'  => (Icons.receipt_long_rounded,         const Color(0xFF7C3AED), 'Payment'),
      'deadline' => (Icons.timer_rounded,                AppColors.error,         'Deadline'),
      _          => (Icons.notifications_rounded,        AppColors.textMuted,     'Info'),
    };

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60)  return 'Just now';
  if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
  if (diff.inHours < 24)    return '${diff.inHours}h ago';
  if (diff.inDays < 7)      return '${diff.inDays}d ago';
  const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return '${m[dt.month - 1]} ${dt.day}';
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() { _loading = false; _error = 'Not signed in.'; });
      return;
    }
    try {
      final data = await supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _notifs = (data as List)
              .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      }
    } on PostgrestException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Failed to load notifications.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markRead(AppNotification n) async {
    if (n.isRead) return;
    try {
      await supabase.from('notifications').update({'is_read': true}).eq('id', n.id);
      if (mounted) {
        setState(() {
          final idx = _notifs.indexWhere((e) => e.id == n.id);
          if (idx != -1) {
            _notifs[idx] = AppNotification(
              id: n.id, category: n.category, title: n.title,
              body: n.body, data: n.data, isRead: true, createdAt: n.createdAt,
            );
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
      if (mounted) {
        setState(() {
          _notifs = _notifs.map((n) => AppNotification(
            id: n.id, category: n.category, title: n.title,
            body: n.body, data: n.data, isRead: true, createdAt: n.createdAt,
          )).toList();
        });
      }
    } catch (_) {}
  }

  int get _unreadCount => _notifs.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: AppColors.shadow,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Notifications',
            style: AppTextStyles.h5.copyWith(color: AppColors.primary)),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Mark all read',
                style: AppTextStyles.labelSm.copyWith(color: AppColors.secondary),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFF1F5F9)),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.secondary),
                strokeWidth: 2.5,
              ),
            )
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : _notifs.isEmpty
                  ? const _EmptyView()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.secondary,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _notifs.length,
                        itemBuilder: (_, i) => _NotifTile(
                          notif: _notifs[i],
                          onTap: () => _markRead(_notifs[i]),
                        ),
                      ),
                    ),
    );
  }
}

// ─── Notification tile ────────────────────────────────────────────────────────

class _NotifTile extends StatelessWidget {
  final AppNotification notif;
  final VoidCallback onTap;
  const _NotifTile({required this.notif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = _categoryMeta(notif.category);
    final unread = !notif.isRead;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: unread ? AppColors.secondary.withValues(alpha: 0.04) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          label,
                          style: AppTextStyles.labelSm.copyWith(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _timeAgo(notif.createdAt),
                        style: AppTextStyles.caption.copyWith(fontSize: 11),
                      ),
                      if (unread) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    notif.title,
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.primary,
                      fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (notif.body != null && notif.body!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      notif.body!,
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty / Error ────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.borderLight.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_off_outlined,
                  size: 36, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            Text('No notifications yet', style: AppTextStyles.h5),
            const SizedBox(height: 6),
            Text(
              'Booking confirmations, reminders,\nand alerts will appear here.',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(message,
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: onRetry,
                child: Text('Try Again', style: AppTextStyles.btnSm),
              ),
            ],
          ),
        ),
      );
}
