import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'booking_payload.dart';
import 'booking_confirmation_screen.dart';

enum _PayMethod { bkash, nagad, card, applePay }

String _methodToDb(_PayMethod m) {
  switch (m) {
    case _PayMethod.bkash:    return 'bkash';
    case _PayMethod.nagad:    return 'nagad';
    case _PayMethod.card:     return 'card';
    case _PayMethod.applePay: return 'apple_pay';
  }
}

String _methodName(_PayMethod m) {
  switch (m) {
    case _PayMethod.bkash:    return 'bKash';
    case _PayMethod.nagad:    return 'Nagad';
    case _PayMethod.card:     return 'Credit / Debit Card';
    case _PayMethod.applePay: return 'Apple Pay';
  }
}

String _currSym(String c) => c.toUpperCase() == 'BDT' ? '৳' : c;

// ─── Main Screen ──────────────────────────────────────────────────────────────

class CheckoutScreen extends StatefulWidget {
  final BookingPayload payload;
  const CheckoutScreen({super.key, required this.payload});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  _PayMethod _selected = _PayMethod.bkash;
  bool _paying = false;

  double get _tax => (widget.payload.baseAmount * 0.15).roundToDouble();
  double get _total => widget.payload.baseAmount + _tax;

  Future<void> _pay() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      _err('Please log in to continue.');
      return;
    }
    setState(() => _paying = true);
    String? bookingId;
    try {
      final p = widget.payload;

      final row = await supabase
          .from('bookings')
          .insert({
            'user_id': user.id,
            'service_type': p.serviceType,
            'status': 'confirmed',
            'total_amount': _total,
            'currency': p.currency,
            'details': p.details,
            if (p.startsAt != null) 'starts_at': p.startsAt!.toIso8601String(),
          })
          .select('id')
          .single();

      bookingId = row['id'] as String;

      await supabase.from('payments').insert({
        'booking_id': bookingId,
        'user_id': user.id,
        'amount': _total,
        'currency': p.currency,
        'method': _methodToDb(_selected),
        'status': 'completed',
        'gateway_ref': 'GW-${DateTime.now().millisecondsSinceEpoch}',
      });


      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BookingConfirmationScreen(
              payload: p,
              bookingId: bookingId!,
              grandTotal: _total,
              taxAmount: _tax,
              payMethodName: _methodName(_selected),
            ),
          ),
        );
      }
    } on PostgrestException catch (e) {
      await _rollback(bookingId);
      _err(e.message);
    } catch (_) {
      await _rollback(bookingId);
      _err('Payment failed. Please try again.');
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  Future<void> _rollback(String? id) async {
    if (id == null) return;
    try {
      await supabase.from('bookings').delete().eq('id', id);
    } catch (_) {}
  }

  void _err(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.payload;
    final sym = _currSym(p.currency);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: AppColors.shadow,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Checkout',
            style: AppTextStyles.h5.copyWith(color: AppColors.primary)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded, color: AppColors.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  children: [
                    _ServiceCard(payload: p),
                    const SizedBox(height: 14),
                    _PriceCard(payload: p, sym: sym, tax: _tax, total: _total),
                    const SizedBox(height: 14),
                    _PayMethodCard(
                      selected: _selected,
                      onChanged: _paying ? null : (m) => setState(() => _selected = m),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Trust(Icons.shield_outlined, 'Secure'),
                        const SizedBox(width: 36),
                        _Trust(Icons.lock_outline_rounded, 'Encrypted'),
                        const SizedBox(width: 36),
                        _Trust(Icons.verified_user_outlined, 'PCI DSS'),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),

              // ── Sticky pay button ────────────────────────────────────
              Container(
                padding: EdgeInsets.fromLTRB(
                    16, 12, 16, 16 + MediaQuery.of(context).padding.bottom),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 16,
                        offset: Offset(0, -4)),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _paying ? null : _pay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor:
                          AppColors.primary.withValues(alpha: 0.65),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _paying
                          ? const SizedBox(
                              key: ValueKey('spin'),
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white),
                            )
                          : Row(
                              key: const ValueKey('label'),
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.lock_rounded, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Pay Now  $sym ${_total.toStringAsFixed(0)}',
                                  style: AppTextStyles.btn,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Processing overlay ───────────────────────────────────────
          if (_paying)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.35),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 36, vertical: 28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 24,
                            offset: Offset(0, 8))
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 44,
                          height: 44,
                          child: CircularProgressIndicator(
                              color: AppColors.secondary, strokeWidth: 3),
                        ),
                        const SizedBox(height: 18),
                        Text('Processing Payment',
                            style: AppTextStyles.h6
                                .copyWith(color: AppColors.primary)),
                        const SizedBox(height: 6),
                        Text('Please do not close this screen.',
                            style: AppTextStyles.caption),
                      ],
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

// ─── Service Card ─────────────────────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  final BookingPayload payload;
  const _ServiceCard({required this.payload});

  @override
  Widget build(BuildContext context) {
    final p = payload;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 16, offset: Offset(0, 4))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon thumbnail
          Container(
            width: 82,
            height: 82,
            margin: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [p.accentColor, p.accentColor.withValues(alpha: 0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(p.serviceIcon, size: 38, color: Colors.white),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: p.accentColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      p.serviceLabel,
                      style: AppTextStyles.labelSm.copyWith(
                          color: p.accentColor, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(p.title,
                      style:
                          AppTextStyles.h6.copyWith(color: AppColors.primary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(p.subtitle,
                      style: AppTextStyles.bodySm
                          .copyWith(color: p.accentColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Text(p.quantitySummary,
                      style: AppTextStyles.caption
                          .copyWith(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Price Card ───────────────────────────────────────────────────────────────

class _PriceCard extends StatelessWidget {
  final BookingPayload payload;
  final String sym;
  final double tax;
  final double total;
  const _PriceCard(
      {required this.payload,
      required this.sym,
      required this.tax,
      required this.total});

  @override
  Widget build(BuildContext context) {
    final p = payload;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 16, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Price Details',
              style: AppTextStyles.h6.copyWith(color: AppColors.primary)),
          const SizedBox(height: 16),
          _PR(
              label: 'Base rate (${p.quantitySummary})',
              value: '$sym ${p.baseAmount.toStringAsFixed(0)}'),
          const SizedBox(height: 10),
          _PR(
              label: 'Taxes & Fees',
              value: '$sym ${tax.toStringAsFixed(0)}'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: AppColors.borderLight),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Amount',
                  style: AppTextStyles.labelLg.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700)),
              Text('$sym ${total.toStringAsFixed(0)}',
                  style:
                      AppTextStyles.price.copyWith(color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PR extends StatelessWidget {
  final String label;
  final String value;
  const _PR({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
          Text(value,
              style: AppTextStyles.body.copyWith(color: AppColors.primary)),
        ],
      );
}

// ─── Payment Method Card ──────────────────────────────────────────────────────

class _PayMethodCard extends StatelessWidget {
  final _PayMethod selected;
  final ValueChanged<_PayMethod>? onChanged;
  const _PayMethodCard({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 16, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            child: Text('Payment Method',
                style: AppTextStyles.h6.copyWith(color: AppColors.primary)),
          ),
          _tile(_PayMethod.bkash, 'bKash', 'Fast & Secure Local Payment',
              const Color(0xFFE2136E), Icons.account_balance_wallet_rounded, isLast: false),
          _sep(),
          _tile(_PayMethod.nagad, 'Nagad', 'Local Mobile Wallet',
              const Color(0xFFED5C0D), Icons.wallet_rounded, isLast: false),
          _sep(),
          _tile(_PayMethod.card, 'Credit/Debit Card', 'Visa, Mastercard, AMEX',
              const Color(0xFF1A56DB), Icons.credit_card_rounded, isLast: false),
          _sep(),
          _tile(_PayMethod.applePay, 'Apple Pay', 'Instant Secure Checkout',
              const Color(0xFF1F2937), Icons.phone_iphone_rounded, isLast: true),
        ],
      ),
    );
  }

  Widget _sep() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Divider(height: 1, color: AppColors.borderLight),
      );

  Widget _tile(_PayMethod method, String name, String desc, Color color,
      IconData icon, {required bool isLast}) {
    final sel = selected == method;
    return InkWell(
      onTap: onChanged != null ? () => onChanged!(method) : null,
      borderRadius: isLast
          ? const BorderRadius.vertical(bottom: Radius.circular(16))
          : BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: AppTextStyles.label.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(desc,
                      style:
                          AppTextStyles.caption.copyWith(fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Radio indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: sel ? AppColors.secondary : AppColors.borderLight,
                  width: sel ? 2 : 1.5,
                ),
              ),
              child: sel
                  ? Center(
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.secondary,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Trust badge ──────────────────────────────────────────────────────────────

class _Trust extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Trust(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, size: 22, color: AppColors.textMuted),
          const SizedBox(height: 4),
          Text(label,
              style: AppTextStyles.caption.copyWith(
                  fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      );
}
