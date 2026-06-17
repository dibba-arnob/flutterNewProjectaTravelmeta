import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'booking_payload.dart';

String _currSym(String c) => c.toUpperCase() == 'BDT' ? '৳' : c;

// ─── Screen ───────────────────────────────────────────────────────────────────

class BookingConfirmationScreen extends StatelessWidget {
  final BookingPayload payload;
  final String bookingId;
  final double grandTotal;
  final double taxAmount;
  final String payMethodName;

  const BookingConfirmationScreen({
    super.key,
    required this.payload,
    required this.bookingId,
    required this.grandTotal,
    required this.taxAmount,
    required this.payMethodName,
  });

  // Format UUID into a human-readable booking reference
  String get _displayRef =>
      'TM-${bookingId.replaceAll('-', '').substring(0, 8).toUpperCase()}';

  void _copy(BuildContext ctx) {
    Clipboard.setData(ClipboardData(text: _displayRef));
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: const Text('Booking ID copied to clipboard'),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _receipt(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _EReceiptSheet(
        payload: payload,
        grandTotal: grandTotal,
        taxAmount: taxAmount,
        payMethodName: payMethodName,
        displayRef: _displayRef,
      ),
    );
  }

  void _goBookings(BuildContext ctx) {
    Navigator.pushNamedAndRemoveUntil(ctx, '/home', (_) => false);
  }

  String _serviceDesc() {
    switch (payload.serviceType) {
      case 'flight':  return 'flight';
      case 'bus':     return 'bus trip';
      case 'train':   return 'train trip';
      case 'cab':     return 'cab booking';
      case 'hotel':   return 'hotel booking';
      case 'guide':   return 'guide booking';
      case 'package': return 'travel package';
      default:        return 'booking';
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = payload;

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.primary),
          onPressed: () => _goBookings(context),
        ),
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                gradient: AppColors.brandGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.flight_takeoff_rounded,
                  size: 14, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text('TravelMeta',
                style: AppTextStyles.h6.copyWith(color: AppColors.primary)),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded, color: AppColors.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 40),

            // ── Animated check circle ─────────────────────────────────
            _CheckCircle(accentColor: p.accentColor),

            const SizedBox(height: 24),

            Text('Booking Confirmed!',
                style: AppTextStyles.h3.copyWith(color: AppColors.primary)),

            const SizedBox(height: 10),

            Text(
              'Your ${_serviceDesc()} is all set.\nWe\'ve sent the receipt to your email.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textMuted, height: 1.6),
            ),

            const SizedBox(height: 32),

            // ── Booking ID card ───────────────────────────────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 16,
                      offset: Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  // Reference code row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('BOOKING ID',
                                  style: AppTextStyles.caption.copyWith(
                                      fontSize: 10,
                                      letterSpacing: 1.2,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textMuted)),
                              const SizedBox(height: 6),
                              Text(_displayRef,
                                  style: AppTextStyles.h4.copyWith(
                                      color: AppColors.primary,
                                      letterSpacing: 0.5)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _copy(context),
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          color: AppColors.secondary,
                          style: IconButton.styleFrom(
                            backgroundColor:
                                AppColors.secondary.withValues(alpha: 0.08),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Divider(height: 1, color: AppColors.borderLight),
                  ),

                  // Check-in + guests columns
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 16, 0, 20),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            child: _InfoCol(
                              icon: Icons.calendar_today_rounded,
                              label: p.checkInLabel,
                              value: p.checkInValue,
                            ),
                          ),
                          const VerticalDivider(
                              width: 1,
                              thickness: 1,
                              color: AppColors.borderLight),
                          Expanded(
                            child: _InfoCol(
                              icon: Icons.people_outline_rounded,
                              label: p.guestsLabel,
                              value: p.guestsValue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── E-Receipt button ──────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => _receipt(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('View E-Receipt',
                    style: AppTextStyles.btn
                        .copyWith(color: AppColors.primary)),
              ),
            ),

            const SizedBox(height: 12),

            // ── Go to bookings button ─────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _goBookings(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Go to My Bookings', style: AppTextStyles.btn),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ─── Animated check circle ────────────────────────────────────────────────────

class _CheckCircle extends StatelessWidget {
  final Color accentColor;
  const _CheckCircle({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (_, v, child) => Transform.scale(scale: v, child: child),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow ring
          Container(
            width: 126,
            height: 126,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.12),
            ),
          ),
          // Main circle
          Container(
            width: 106,
            height: 106,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, accentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.40),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.check_rounded,
                size: 52, color: Colors.white),
          ),
          // Top-right badge
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  size: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info column ──────────────────────────────────────────────────────────────

class _InfoCol extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoCol(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, size: 18, color: AppColors.secondary),
          const SizedBox(height: 6),
          Text(label,
              style: AppTextStyles.caption.copyWith(
                  fontSize: 10,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value,
              style: AppTextStyles.label
                  .copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
        ],
      );
}

// ─── E-Receipt sheet ──────────────────────────────────────────────────────────

class _EReceiptSheet extends StatelessWidget {
  final BookingPayload payload;
  final double grandTotal;
  final double taxAmount;
  final String payMethodName;
  final String displayRef;
  const _EReceiptSheet({
    required this.payload,
    required this.grandTotal,
    required this.taxAmount,
    required this.payMethodName,
    required this.displayRef,
  });

  @override
  Widget build(BuildContext context) {
    final p = payload;
    final sym = _currSym(p.currency);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 18),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('E-Receipt',
                    style:
                        AppTextStyles.h5.copyWith(color: AppColors.primary)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('PAID',
                      style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0)),
                ),
              ],
            ),

            const SizedBox(height: 20),

            _RRow('Booking ID', displayRef),
            _RRow(p.checkInLabel, p.checkInValue),
            _RRow(p.guestsLabel, p.guestsValue),
            _RRow('Service', p.serviceLabel),
            _RRow('Payment Method', payMethodName),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: AppColors.borderLight),
            ),

            _RRow('Base Amount', '$sym ${p.baseAmount.toStringAsFixed(0)}'),
            _RRow('Taxes & Fees', '$sym ${taxAmount.toStringAsFixed(0)}'),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: AppColors.borderLight),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Paid',
                    style: AppTextStyles.labelLg.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w700)),
                Text('$sym ${grandTotal.toStringAsFixed(0)}',
                    style: AppTextStyles.price
                        .copyWith(color: AppColors.secondary)),
              ],
            ),

            const SizedBox(height: 22),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.borderLight),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text('Close', style: AppTextStyles.btnSm),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RRow extends StatelessWidget {
  final String label;
  final String value;
  const _RRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style:
                    AppTextStyles.body.copyWith(color: AppColors.textMuted)),
            Flexible(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: AppTextStyles.body.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );
}
