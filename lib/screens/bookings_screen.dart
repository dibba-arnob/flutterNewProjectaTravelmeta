import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

enum ServiceType { flight, bus, train, cab, hotel, package, guide }

enum BookingStatus { pending, confirmed, cancelled, completed, refunded }

class Booking {
  final String id;
  final String userId;
  final ServiceType serviceType;
  final String referenceCode;
  final BookingStatus status;
  final double totalAmount;
  final String currency;
  final Map<String, dynamic> details;
  final DateTime? startsAt;
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.userId,
    required this.serviceType,
    required this.referenceCode,
    required this.status,
    required this.totalAmount,
    required this.currency,
    required this.details,
    this.startsAt,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
        id: j['id'] as String,
        userId: j['user_id'] as String,
        serviceType: ServiceType.values.firstWhere(
          (e) => e.name == (j['service_type'] as String),
          orElse: () => ServiceType.flight,
        ),
        referenceCode: j['reference_code'] as String,
        status: BookingStatus.values.firstWhere(
          (e) => e.name == (j['status'] as String),
          orElse: () => BookingStatus.pending,
        ),
        totalAmount: (j['total_amount'] as num).toDouble(),
        currency: j['currency'] as String? ?? 'BDT',
        details: (j['details'] as Map<String, dynamic>?) ?? {},
        startsAt: j['starts_at'] != null
            ? DateTime.parse(j['starts_at'] as String).toLocal()
            : null,
        createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
      );

  String get formattedAmount {
    final symbol = currency == 'BDT' ? '৳' : currency;
    return '$symbol ${totalAmount.toStringAsFixed(0)}';
  }
}

// ─── Helper ───────────────────────────────────────────────────────────────────

String _fmtDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  List<Booking> _bookings = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Not signed in.';
        });
      }
      return;
    }

    try {
      final data = await supabase
          .from('bookings')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final bookings = (data as List)
          .map((e) => Booking.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) setState(() => _bookings = bookings);
    } on PostgrestException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Failed to load bookings. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _LoadingState();
    if (_error != null) return _ErrorState(message: _error!, onRetry: _loadBookings);
    if (_bookings.isEmpty) return const _EmptyState();

    return ColoredBox(
      color: AppColors.surfaceLight,
      child: RefreshIndicator(
        onRefresh: _loadBookings,
        color: AppColors.secondary,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: _bookings.length,
          itemBuilder: (_, i) => _BookingCard(booking: _bookings[i]),
        ),
      ),
    );
  }
}

// ─── Booking card ─────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final Booking booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _serviceIcon(booking.serviceType),
                    size: 18,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    _serviceLabel(booking.serviceType),
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    booking.referenceCode,
                    style: AppTextStyles.caption.copyWith(fontSize: 11),
                  ),
                ]),
              ]),
              _StatusBadge(status: booking.status),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  'TOTAL',
                  style: AppTextStyles.caption.copyWith(fontSize: 10, letterSpacing: 0.8),
                ),
                const SizedBox(height: 2),
                Text(
                  booking.formattedAmount,
                  style: AppTextStyles.price.copyWith(color: AppColors.secondary),
                ),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(
                  booking.startsAt != null ? 'SERVICE DATE' : 'BOOKED ON',
                  style: AppTextStyles.caption.copyWith(fontSize: 10, letterSpacing: 0.8),
                ),
                const SizedBox(height: 2),
                Text(
                  _fmtDate(booking.startsAt ?? booking.createdAt),
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  IconData _serviceIcon(ServiceType type) => switch (type) {
        ServiceType.flight  => Icons.flight_rounded,
        ServiceType.bus     => Icons.directions_bus_rounded,
        ServiceType.train   => Icons.train_rounded,
        ServiceType.cab     => Icons.local_taxi_rounded,
        ServiceType.hotel   => Icons.hotel_rounded,
        ServiceType.package => Icons.card_travel_rounded,
        ServiceType.guide   => Icons.tour_rounded,
      };

  String _serviceLabel(ServiceType type) => switch (type) {
        ServiceType.flight  => 'Flight',
        ServiceType.bus     => 'Bus',
        ServiceType.train   => 'Train',
        ServiceType.cab     => 'Cab',
        ServiceType.hotel   => 'Hotel',
        ServiceType.package => 'Package',
        ServiceType.guide   => 'Guide',
      };
}

// ─── Status badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final BookingStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      BookingStatus.pending   => ('Pending', AppColors.warning),
      BookingStatus.confirmed => ('Confirmed', AppColors.success),
      BookingStatus.cancelled => ('Cancelled', AppColors.error),
      BookingStatus.completed => ('Completed', AppColors.secondary),
      BookingStatus.refunded  => ('Refunded', AppColors.textMuted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSm.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── State widgets ────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: AppColors.surfaceLight,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.secondary),
            strokeWidth: 2.5,
          ),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: AppColors.surfaceLight,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textMuted),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
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
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: AppColors.surfaceLight,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_note_rounded, size: 56, color: AppColors.borderLight),
              SizedBox(height: 14),
              Text('No bookings yet', style: AppTextStyles.h5),
              SizedBox(height: 6),
              Text(
                'Your confirmed bookings will appear here.',
                style: AppTextStyles.bodySm,
              ),
            ],
          ),
        ),
      );
}
