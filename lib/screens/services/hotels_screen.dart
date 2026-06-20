import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../payment_folder/booking_payload.dart';
import '../payment_folder/checkout_screen.dart';
import 'service_widgets.dart';

// ─── Image URL helpers ────────────────────────────────────────────────────────

List<String> resolveImageUrls(dynamic rawImages) {
  if (rawImages == null) return const [];
  final List<String> raws;
  if (rawImages is List) {
    raws = rawImages
        .map((e) => e?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
  } else if (rawImages is String && rawImages.isNotEmpty) {
    raws = [rawImages];
  } else {
    return const [];
  }
  return raws.map(_resolveOne).where((u) => u.isNotEmpty).toList();
}

String _resolveOne(String raw) {
  if (raw.startsWith('http')) return raw;
  final slash = raw.indexOf('/');
  if (slash == -1) {
    return supabase.storage.from('hotels').getPublicUrl(raw);
  }
  final bucket = raw.substring(0, slash);
  final key = raw.substring(slash + 1);
  return supabase.storage.from(bucket).getPublicUrl(key);
}

String resolveImageUrl(dynamic rawImages) {
  final all = resolveImageUrls(rawImages);
  return all.isEmpty ? '' : all.first;
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _money(num value) {
  final s = value.toStringAsFixed(0);
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i != 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

String _fmtDate(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class HotelsContent extends StatefulWidget {
  const HotelsContent({super.key});
  @override
  State<HotelsContent> createState() => _HotelsContentState();
}

class _HotelsContentState extends State<HotelsContent> {
  String _type = 'All';
  List<Map<String, dynamic>> _hotels = [];
  bool _loading = false;
  String? _error;

  // Search state
  String _destination = "Cox's Bazar, Bangladesh";
  DateTime _checkIn = DateTime(2026, 6, 15);
  DateTime _checkOut = DateTime(2026, 6, 20);
  int _rooms = 1;
  int _guests = 2;
  String _activeSearch = '';

  static const _types = ['All', 'Hotel', 'Resort', 'Hostel', 'Apartment'];

  @override
  void initState() {
    super.initState();
    _fetchHotels();
  }

  Future<void> _fetchHotels() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await supabase
          .from('hotels')
          .select('*')
          .order('name', ascending: true);
      if (mounted) setState(() => _hotels = List<Map<String, dynamic>>.from(data));
    } on PostgrestException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to load hotels: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _hotels;
    if (_activeSearch.isNotEmpty) {
      final q = _activeSearch.toLowerCase();
      list = list.where((h) {
        final name = (h['name'] ?? h['hotel_name'] ?? '').toString().toLowerCase();
        final city = (h['city'] ?? '').toString().toLowerCase();
        final location = (h['location'] ?? '').toString().toLowerCase();
        return name.contains(q) || city.contains(q) || location.contains(q);
      }).toList();
    }
    if (_type != 'All') {
      final hasType = list.any((h) => (h['type'] ?? h['category']) != null);
      if (hasType) {
        list = list.where((h) {
          final t = (h['type'] ?? h['category'] ?? '').toString().toLowerCase();
          return t == _type.toLowerCase();
        }).toList();
      }
    }
    return list;
  }

  // ── Search field pickers ──────────────────────────────────────────────────

  Future<void> _pickDestination(BuildContext ctx) async {
    final ctrl = TextEditingController(text: _destination);
    final result = await showDialog<String>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Destination'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'City, country or hotel name',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && mounted) {
      setState(() => _destination = result);
    }
  }

  Future<void> _pickDate(BuildContext ctx, {required bool isCheckIn}) async {
    final initial = isCheckIn ? _checkIn : _checkOut;
    final first = isCheckIn
        ? DateTime.now()
        : _checkIn.add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: ctx,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.success),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isCheckIn) {
          _checkIn = picked;
          if (!_checkOut.isAfter(_checkIn)) {
            _checkOut = _checkIn.add(const Duration(days: 1));
          }
        } else {
          _checkOut = picked;
        }
      });
    }
  }

  Future<void> _pickRoomsGuests(BuildContext ctx) async {
    int tempRooms = _rooms;
    int tempGuests = _guests;
    await showDialog<void>(
      context: ctx,
      builder: (_) => StatefulBuilder(
        builder: (c, dlgSet) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Rooms & Guests'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CounterRow(
                label: 'Rooms',
                value: tempRooms,
                min: 1,
                max: 10,
                onChanged: (v) => dlgSet(() => tempRooms = v),
              ),
              const SizedBox(height: 16),
              _CounterRow(
                label: 'Adults',
                value: tempGuests,
                min: 1,
                max: 20,
                onChanged: (v) => dlgSet(() => tempGuests = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(c);
                if (mounted) setState(() { _rooms = tempRooms; _guests = tempGuests; });
              },
              child: const Text('Done', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Booking ───────────────────────────────────────────────────────────────

  void _bookHotel(Map<String, dynamic> hotel) {
    final nights = _checkOut.difference(_checkIn).inDays.clamp(1, 999);
    final priceNum =
        (hotel['price_from'] ?? hotel['price_per_night'] ?? hotel['price']) as num?;
    final pricePerNight = priceNum?.toDouble() ?? 0.0;
    final baseAmount = pricePerNight * nights * _rooms;
    final name =
        hotel['name']?.toString() ?? hotel['hotel_name']?.toString() ?? 'Hotel';
    final city =
        hotel['city']?.toString() ?? hotel['location']?.toString() ?? '';

    final payload = BookingPayload(
      serviceType: 'hotel',
      baseAmount: baseAmount,
      currency: 'BDT',
      details: {
        'hotel_id': hotel['id']?.toString() ?? '',
        'hotel_name': name,
        'city': city,
        'check_in': _checkIn.toIso8601String(),
        'check_out': _checkOut.toIso8601String(),
        'rooms': _rooms,
        'guests': _guests,
        'price_per_night': pricePerNight,
        'nights': nights,
      },
      startsAt: _checkIn,
      title: name,
      subtitle: city.isNotEmpty ? city : 'Hotel Booking',
      quantitySummary:
          '$_rooms room${_rooms > 1 ? 's' : ''} × $nights night${nights > 1 ? 's' : ''}',
      checkInLabel: 'Check-in',
      checkInValue: _fmtDate(_checkIn),
      guestsLabel: 'Guests',
      guestsValue: '$_guests Adult${_guests > 1 ? 's' : ''}',
      serviceIcon: Icons.hotel_rounded,
      serviceLabel: 'Hotel',
      accentColor: const Color(0xFF0284C7),
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CheckoutScreen(payload: payload)),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvCard(
            child: Column(children: [
              SvField(
                label: 'Destination / City',
                value: _destination.isEmpty ? 'Where are you going?' : _destination,
                icon: Icons.location_on_rounded,
                onTap: () => _pickDestination(context),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: SvField(
                    label: 'Check-in',
                    value: _fmtDate(_checkIn),
                    icon: Icons.calendar_month_rounded,
                    onTap: () => _pickDate(context, isCheckIn: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SvField(
                    label: 'Check-out',
                    value: _fmtDate(_checkOut),
                    icon: Icons.calendar_month_rounded,
                    onTap: () => _pickDate(context, isCheckIn: false),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: SvField(
                    label: 'Rooms',
                    value: '$_rooms Room${_rooms > 1 ? 's' : ''}',
                    icon: Icons.meeting_room_rounded,
                    onTap: () => _pickRoomsGuests(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SvField(
                    label: 'Guests',
                    value: '$_guests Adult${_guests > 1 ? 's' : ''}',
                    icon: Icons.people_rounded,
                    onTap: () => _pickRoomsGuests(context),
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              SvButton(
                label: 'Search Hotels',
                onTap: () => setState(() => _activeSearch = _destination),
                color: AppColors.success,
              ),
            ]),
          ),
          const SizedBox(height: 24),
          const SvSectionTitle('Featured Hotels'),
          const SizedBox(height: 10),
          SvChipRow(
            options: _types,
            selected: _type,
            onChanged: (v) => setState(() => _type = v),
            accentColor: AppColors.success,
          ),
          const SizedBox(height: 14),

          // ── Content states ────────────────────────────────────────────
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(AppColors.success),
                    strokeWidth: 2.5),
              ),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(children: [
                  const Icon(Icons.wifi_off_rounded,
                      size: 44, color: AppColors.textMuted),
                  const SizedBox(height: 10),
                  Text(_error!,
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.textMuted),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 14),
                  SvButton(
                      label: 'Try Again',
                      onTap: _fetchHotels,
                      color: AppColors.success),
                ]),
              ),
            )
          else if (_filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(
                  _activeSearch.isNotEmpty
                      ? 'No hotels found for "$_activeSearch".'
                      : 'No hotels found.',
                  style:
                      AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ..._filtered.map((h) => _HotelCard(
                  hotel: h,
                  onBook: () => _bookHotel(h),
                  onDetail: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _HotelDetailSheet(
                      hotel: h,
                      onBook: () => _bookHotel(h),
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}

// ─── Counter row widget (for rooms/guests dialog) ─────────────────────────────

class _CounterRow extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  const _CounterRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(label,
                style:
                    AppTextStyles.label.copyWith(color: AppColors.primary)),
          ),
          IconButton(
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline_rounded),
            color: AppColors.success,
            disabledColor: AppColors.borderLight,
          ),
          SizedBox(
            width: 32,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: AppTextStyles.h6.copyWith(color: AppColors.primary),
            ),
          ),
          IconButton(
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_circle_outline_rounded),
            color: AppColors.success,
            disabledColor: AppColors.borderLight,
          ),
        ],
      );
}

// ─── Hotel card ───────────────────────────────────────────────────────────────

class _HotelCard extends StatelessWidget {
  final Map<String, dynamic> hotel;
  final VoidCallback onBook;
  final VoidCallback onDetail;
  const _HotelCard({
    required this.hotel,
    required this.onBook,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveImageUrl(hotel['images']);
    final name =
        hotel['name']?.toString() ?? hotel['hotel_name']?.toString() ?? 'Unknown';
    final location =
        hotel['city']?.toString() ?? hotel['location']?.toString() ?? '';
    final rating = (hotel['rating'] as num?)?.toDouble() ?? 0.0;

    final starsRaw = hotel['stars'] ?? hotel['star_rating'] ?? hotel['star'];
    final stars = (starsRaw as num?)?.toInt() ?? rating.round();

    final priceNum =
        (hotel['price_from'] ?? hotel['price_per_night'] ?? hotel['price']) as num?;
    final price = priceNum != null ? '৳ ${_money(priceNum)} / night' : '';

    return GestureDetector(
      onTap: onDetail,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
                color: AppColors.shadow,
                blurRadius: 14,
                offset: Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (_, child, progress) =>
                                progress == null
                                    ? child
                                    : const _HotelImageFallback(),
                            errorBuilder: (_, __, e) =>
                                const _HotelImageFallback(),
                          )
                        : const _HotelImageFallback(),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(20)),
                        child: Row(children: [
                          const Icon(Icons.star_rounded,
                              color: Colors.white, size: 13),
                          const SizedBox(width: 3),
                          Text(
                            rating.toStringAsFixed(1),
                            style: AppTextStyles.labelSm.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (stars > 0)
                      Row(
                          children: List.generate(
                              stars,
                              (_) => const Icon(Icons.star_rounded,
                                  size: 13, color: AppColors.warning))),
                    const SizedBox(height: 5),
                    Text(name,
                        style:
                            AppTextStyles.h6.copyWith(color: AppColors.primary)),
                    const SizedBox(height: 4),
                    if (location.isNotEmpty)
                      Row(children: [
                        const Icon(Icons.location_on_rounded,
                            size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Text(location, style: AppTextStyles.caption),
                      ]),
                    const SizedBox(height: 10),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(price,
                              style: AppTextStyles.priceSm
                                  .copyWith(color: AppColors.success)),
                          // Inner GestureDetector takes priority over card's onDetail tap
                          GestureDetector(
                            onTap: onBook,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 8),
                              decoration: BoxDecoration(
                                  color: AppColors.success,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Text('Book Now',
                                  style: AppTextStyles.btnSm
                                      .copyWith(color: Colors.white)),
                            ),
                          ),
                        ]),
                  ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Image fallback ───────────────────────────────────────────────────────────

class _HotelImageFallback extends StatelessWidget {
  const _HotelImageFallback();

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.success.withValues(alpha: 0.18),
              AppColors.secondary.withValues(alpha: 0.12),
            ],
          ),
        ),
        child: const Center(
          child: Icon(Icons.hotel_rounded, size: 52, color: AppColors.success),
        ),
      );
}

// ─── Hotel detail bottom sheet ────────────────────────────────────────────────

class _HotelDetailSheet extends StatelessWidget {
  final Map<String, dynamic> hotel;
  final VoidCallback onBook;
  const _HotelDetailSheet({required this.hotel, required this.onBook});

  @override
  Widget build(BuildContext context) {
    final images = resolveImageUrls(hotel['images']);
    final name = hotel['name']?.toString() ?? 'Unknown';
    final city = hotel['city']?.toString() ?? '';
    final address = hotel['address']?.toString() ?? '';
    final description = hotel['description']?.toString() ?? '';
    final rating = (hotel['rating'] as num?)?.toDouble() ?? 0.0;
    final reviewCount = (hotel['review_count'] as num?)?.toInt();
    final stars = (hotel['stars'] as num?)?.toInt() ?? rating.round();
    final priceNum = (hotel['price_from'] ?? hotel['price']) as num?;
    final price = priceNum != null ? '৳ ${_money(priceNum)} / night' : '';
    final freeCancellation = hotel['free_cancellation'] == true;

    final amenitiesRaw = hotel['amenities'];
    final amenities = amenitiesRaw is List
        ? amenitiesRaw
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList()
        : <String>[];

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: scrollCtrl,
          padding: EdgeInsets.zero,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            _HotelGallery(images: images, height: 230),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (stars > 0)
                    Row(
                        children: List.generate(
                            stars,
                            (_) => const Icon(Icons.star_rounded,
                                size: 15, color: AppColors.warning))),
                  const SizedBox(height: 6),
                  Text(name,
                      style: AppTextStyles.h4.copyWith(color: AppColors.primary)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(children: [
                        const Icon(Icons.star_rounded,
                            color: Colors.white, size: 13),
                        const SizedBox(width: 3),
                        Text(rating.toStringAsFixed(1),
                            style: AppTextStyles.labelSm.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ]),
                    ),
                    if (reviewCount != null) ...[
                      const SizedBox(width: 8),
                      Text('${_money(reviewCount)} reviews',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textMuted)),
                    ],
                  ]),
                  if (address.isNotEmpty || city.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.location_on_rounded,
                          size: 15, color: AppColors.secondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(address.isNotEmpty ? address : city,
                            style: AppTextStyles.bodySm
                                .copyWith(color: AppColors.textMuted)),
                      ),
                    ]),
                  ],
                  if (freeCancellation) ...[
                    const SizedBox(height: 10),
                    Row(children: [
                      const Icon(Icons.verified_rounded,
                          size: 15, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text('Free cancellation',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ],
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const Divider(color: AppColors.borderLight),
                    const SizedBox(height: 14),
                    Text('About',
                        style:
                            AppTextStyles.h6.copyWith(color: AppColors.primary)),
                    const SizedBox(height: 8),
                    Text(description,
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.textMuted, height: 1.6)),
                  ],
                  if (amenities.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text('Amenities',
                        style:
                            AppTextStyles.h6.copyWith(color: AppColors.primary)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: amenities
                          .map((a) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.success
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(a,
                                    style: AppTextStyles.caption
                                        .copyWith(color: AppColors.primary)),
                              ))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 22),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('From',
                                  style: AppTextStyles.caption
                                      .copyWith(color: AppColors.textMuted)),
                              Text(price,
                                  style: AppTextStyles.priceSm
                                      .copyWith(color: AppColors.success)),
                            ]),
                        // Book Now — closes sheet then goes to checkout
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context); // close sheet
                            onBook();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 26, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('Book Now',
                                style: AppTextStyles.btnSm
                                    .copyWith(color: Colors.white)),
                          ),
                        ),
                      ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Swipeable gallery ────────────────────────────────────────────────────────

class _HotelGallery extends StatefulWidget {
  final List<String> images;
  final double height;
  const _HotelGallery({required this.images, this.height = 230});

  @override
  State<_HotelGallery> createState() => _HotelGalleryState();
}

class _HotelGalleryState extends State<_HotelGallery> {
  final _controller = PageController();
  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return SizedBox(
          height: widget.height, child: const _HotelImageFallback());
    }

    final multiple = widget.images.length > 1;

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => Image.network(
              widget.images[i],
              height: widget.height,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : const _HotelImageFallback(),
              errorBuilder: (_, __, ___) => const _HotelImageFallback(),
            ),
          ),
          if (multiple)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${_current + 1}/${widget.images.length}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          if (multiple)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.images.length, (i) {
                  final active = i == _current;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}