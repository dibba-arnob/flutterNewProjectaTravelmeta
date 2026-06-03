import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class WalletContent extends StatelessWidget {
  const WalletContent({super.key});

  static const _transactions = [
    (Icons.flight_takeoff_rounded, 'Flight — Dhaka to CXB', 'Jun 10, 2026', '-৳ 4,500', false),
    (Icons.add_circle_rounded, 'Wallet Top-up', 'Jun 08, 2026', '+৳ 10,000', true),
    (Icons.hotel_rounded, 'Hotel — The Peninsula', 'Jun 05, 2026', '-৳ 8,500', false),
    (Icons.local_taxi_rounded, 'Cab — Gulshan to Airport', 'Jun 03, 2026', '-৳ 350', false),
    (Icons.add_circle_rounded, 'Wallet Top-up', 'May 30, 2026', '+৳ 5,000', true),
    (Icons.luggage_rounded, "Cox's Bazar Package", 'May 25, 2026', '-৳ 8,500', false),
  ];

  static const _actions = [
    (Icons.add_rounded, 'Add Money'),
    (Icons.send_rounded, 'Send'),
    (Icons.qr_code_rounded, 'Pay'),
    (Icons.history_rounded, 'History'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Balance card ──────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.28),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(
                    'TravelMeta Wallet',
                    style: AppTextStyles.labelSm.copyWith(color: Colors.white.withValues(alpha: 0.80)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'ACTIVE',
                      style: AppTextStyles.labelSm.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                ]),
                const SizedBox(height: 20),
                Text(
                  'Total Balance',
                  style: AppTextStyles.bodySm.copyWith(color: Colors.white.withValues(alpha: 0.70)),
                ),
                const SizedBox(height: 6),
                Text(
                  '৳ 12,650',
                  style: AppTextStyles.priceLg.copyWith(color: Colors.white, fontSize: 34),
                ),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      'Earned Points',
                      style: AppTextStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.70)),
                    ),
                    Text(
                      '2,340 pts',
                      style: AppTextStyles.label.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ]),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(
                      'This Month Spent',
                      style: AppTextStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.70)),
                    ),
                    Text(
                      '৳ 13,350',
                      style: AppTextStyles.label.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ]),
                ]),
              ],
            ),
          ),
          // ── Quick actions ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _actions.map((a) => _QuickAction(icon: a.$1, label: a.$2)).toList(),
            ),
          ),
          const SizedBox(height: 24),
          // ── Transactions ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Recent Transactions', style: AppTextStyles.h5.copyWith(color: AppColors.primary)),
              Text('See All', style: AppTextStyles.label.copyWith(color: AppColors.secondary)),
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 16, offset: Offset(0, 4))],
            ),
            child: Column(
              children: List.generate(_transactions.length, (i) {
                final t = _transactions[i];
                final isCredit = t.$5;
                return Column(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isCredit
                              ? AppColors.success.withValues(alpha: 0.10)
                              : AppColors.secondary.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(t.$1, size: 19, color: isCredit ? AppColors.success : AppColors.secondary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                            t.$2,
                            style: AppTextStyles.label.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(t.$3, style: AppTextStyles.caption),
                        ]),
                      ),
                      Text(
                        t.$4,
                        style: AppTextStyles.priceSm.copyWith(color: isCredit ? AppColors.success : AppColors.error),
                      ),
                    ]),
                  ),
                  if (i < _transactions.length - 1)
                    const Divider(height: 1, indent: 70, color: AppColors.borderLight),
                ]);
              }),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  const _QuickAction({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.secondary, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12),
        ),
      ]);
}
