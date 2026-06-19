import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  List<Map<String, dynamic>> _payments = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() { _loading = false; _error = 'Not logged in.'; });
      return;
    }
    try {
      final data = await supabase
          .from('payments')
          .select('*, bookings(service_type, reference_code)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _payments = List<Map<String, dynamic>>.from(data as List);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = 'Failed to load payments.'; });
    }
  }

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
        title: Text('Payment History',
            style: AppTextStyles.h5.copyWith(color: AppColors.primary)),
        centerTitle: false,
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
              : _payments.isEmpty
                  ? const _EmptyView()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.secondary,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
                        itemCount: _payments.length,
                        separatorBuilder: (context, i) => const SizedBox(height: 12),
                        itemBuilder: (_, i) =>
                            _PaymentCard(payment: _payments[i]),
                      ),
                    ),
    );
  }
}

// ─── Payment Card ─────────────────────────────────────────────────────────────

class _PaymentCard extends StatelessWidget {
  final Map<String, dynamic> payment;
  const _PaymentCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    final booking = payment['bookings'] as Map<String, dynamic>?;
    final serviceType = booking?['service_type'] as String? ?? 'unknown';
    final refCode = booking?['reference_code'] as String? ?? '—';

    final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
    final currency = payment['currency'] as String? ?? 'BDT';
    final method = payment['method'] as String? ?? '';
    final status = payment['status'] as String? ?? '';
    final gatewayRef = payment['gateway_ref'] as String? ?? '';
    final createdAt = payment['created_at'] as String?;

    final sym = currency.toUpperCase() == 'BDT' ? '৳' : currency;
    final service = _serviceInfo(serviceType);
    final methodInfo = _methodInfo(method);
    final statusInfo = _statusInfo(status);
    final dateStr = _formatDate(createdAt);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          // ── Top row: icon + service + amount + status ──────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                // Service icon
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: service.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(service.icon, size: 22, color: service.color),
                ),
                const SizedBox(width: 12),

                // Service label + method
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.label,
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(methodInfo.icon,
                              size: 12, color: methodInfo.color),
                          const SizedBox(width: 4),
                          Text(
                            methodInfo.name,
                            style: AppTextStyles.caption
                                .copyWith(color: methodInfo.color, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Amount + status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$sym ${amount.toStringAsFixed(0)}',
                      style: AppTextStyles.priceSm
                          .copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(height: 4),
                    _StatusBadge(label: statusInfo.label, color: statusInfo.color),
                  ],
                ),
              ],
            ),
          ),

          // ── Divider ───────────────────────────────────────────────
          const Divider(height: 1, color: AppColors.borderLight),

          // ── Bottom row: date + refs ───────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 12, color: AppColors.textMuted),
                const SizedBox(width: 5),
                Text(dateStr, style: AppTextStyles.caption),
                const Spacer(),
                if (refCode != '—')
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: refCode));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Ref $refCode copied'),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        backgroundColor: AppColors.primary,
                      ));
                    },
                    child: Row(
                      children: [
                        Text(
                          refCode,
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.copy_rounded,
                            size: 12, color: AppColors.secondary),
                      ],
                    ),
                  )
                else if (gatewayRef.isNotEmpty)
                  Text(
                    gatewayRef,
                    style: AppTextStyles.caption
                        .copyWith(fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSm
              .copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      );
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long_rounded,
                    size: 42, color: AppColors.secondary),
              ),
              const SizedBox(height: 20),
              Text(
                'No payments yet',
                style: AppTextStyles.h5.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Text(
                'Your payment history will appear here once you complete a booking.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
}

// ─── Error state ──────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(message,
                style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _ServiceMeta {
  final IconData icon;
  final Color color;
  final String label;
  const _ServiceMeta(this.icon, this.color, this.label);
}

_ServiceMeta _serviceInfo(String type) {
  switch (type) {
    case 'flight':  return const _ServiceMeta(Icons.flight_rounded,               Color(0xFF0891B2), 'Flight');
    case 'bus':     return const _ServiceMeta(Icons.directions_bus_rounded,        Color(0xFF059669), 'Bus');
    case 'train':   return const _ServiceMeta(Icons.train_rounded,                 Color(0xFF7C3AED), 'Train');
    case 'cab':     return const _ServiceMeta(Icons.local_taxi_rounded,            Color(0xFFF59E0B), 'Cab');
    case 'hotel':   return const _ServiceMeta(Icons.hotel_rounded,                 Color(0xFF0284C7), 'Hotel');
    case 'package': return const _ServiceMeta(Icons.card_travel_rounded,           Color(0xFFEC4899), 'Package');
    case 'guide':   return const _ServiceMeta(Icons.person_pin_circle_rounded,     Color(0xFFEF4444), 'Tour Guide');
    default:        return const _ServiceMeta(Icons.confirmation_number_rounded,   AppColors.primary,  'Booking');
  }
}

class _MethodMeta {
  final IconData icon;
  final Color color;
  final String name;
  const _MethodMeta(this.icon, this.color, this.name);
}

_MethodMeta _methodInfo(String method) {
  switch (method) {
    case 'bkash':     return const _MethodMeta(Icons.account_balance_wallet_rounded, Color(0xFFE2136E), 'bKash');
    case 'nagad':     return const _MethodMeta(Icons.wallet_rounded,                 Color(0xFFED5C0D), 'Nagad');
    case 'card':      return const _MethodMeta(Icons.credit_card_rounded,            Color(0xFF1A56DB), 'Card');
    case 'apple_pay': return const _MethodMeta(Icons.phone_iphone_rounded,           Color(0xFF1F2937), 'Apple Pay');
    default:          return _MethodMeta(Icons.payment_rounded,                AppColors.textMuted, method);
  }
}

class _StatusMeta {
  final String label;
  final Color color;
  const _StatusMeta(this.label, this.color);
}

_StatusMeta _statusInfo(String status) {
  switch (status) {
    case 'completed': return const _StatusMeta('Paid',      AppColors.success);
    case 'pending':   return const _StatusMeta('Pending',   AppColors.warning);
    case 'failed':    return const _StatusMeta('Failed',    AppColors.error);
    case 'refunded':  return const _StatusMeta('Refunded',  Color(0xFF7C3AED));
    default:          return _StatusMeta(status,            AppColors.textMuted);
  }
}

String _formatDate(String? iso) {
  if (iso == null) return '—';
  try {
    final dt = DateTime.parse(iso).toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}  $h:$min $ampm';
  } catch (_) {
    return iso;
  }
}
