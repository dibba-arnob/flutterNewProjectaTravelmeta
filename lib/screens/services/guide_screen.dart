import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'service_widgets.dart';
import '../payment_folder/booking_payload.dart';
import '../payment_folder/checkout_screen.dart';

const _kAccent = AppColors.secondary;

String _pickStr(Map<String, dynamic> map, List<String> keys) {
  for (final k in keys) {
    final v = map[k];
    if (v != null && v.toString().isNotEmpty) return v.toString();
  }
  return '';
}

// ─── Model ────────────────────────────────────────────────────────────────────

class Guide {
  final String id;
  final String name;
  final String? bio;
  final String location;
  final double rating;
  final double hourlyRate;
  final double halfDayRate;
  final double fullDayRate;
  final List<String> specialties;
  final List<String> languages;
  final List<String> certifications;
  final List<String> availableDates;   // 'YYYY-MM-DD' strings where slots > 0
  final Map<String, int> slotsByDate;  // date string → slot count

  Guide.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        name = j['guide_name'] ?? 'Unknown',
        bio = j['about'],
        location = j['city'] ?? '',
        rating = (j['rating'] as num?)?.toDouble() ?? 0.0,
        hourlyRate = (j['hourly_rate'] as num?)?.toDouble() ?? 0.0,
        halfDayRate = (j['half_day_rate'] as num?)?.toDouble() ?? 0.0,
        fullDayRate = (j['full_day_rate'] as num?)?.toDouble() ?? 0.0,
        specialties = (j['guide_specialties'] as List?)
                ?.map((e) => _pickStr(e as Map<String, dynamic>, ['specialty', 'name', 'specialty_name']))
                .where((s) => s.isNotEmpty)
                .toList() ??
            [],
        languages = (j['guide_languages'] as List?)
                ?.map((e) => _pickStr(e as Map<String, dynamic>, ['language', 'name', 'language_name']))
                .where((s) => s.isNotEmpty)
                .toList() ??
            [],
        certifications = (j['guide_certifications'] as List?)
                ?.map((e) => _pickStr(e as Map<String, dynamic>, ['certification_name', 'name', 'cert_name', 'title']))
                .where((s) => s.isNotEmpty)
                .toList() ??
            [],
        availableDates = Guide._parseDates(j['guide_availability'] as List?),
        slotsByDate    = Guide._parseSlots(j['guide_availability'] as List?);

  static List<String> _parseDates(List? rows) {
    if (rows == null) return [];
    final dates = rows
        .where((e) => ((e as Map<String, dynamic>)['slots'] as num? ?? 0) > 0)
        .map((e) => (e as Map<String, dynamic>)['date']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    dates.sort();
    return dates;
  }

  static Map<String, int> _parseSlots(List? rows) {
    if (rows == null) return {};
    return {
      for (final e in rows)
        if ((e as Map<String, dynamic>)['date'] != null)
          e['date'].toString(): ((e['slots'] as num?) ?? 0).toInt(),
    };
  }

  String get initials {
    final parts = name.trim().split(' ').where((w) => w.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((w) => w[0]).join().toUpperCase();
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class GuideContent extends StatefulWidget {
  const GuideContent({super.key});
  @override
  State<GuideContent> createState() => _GuideContentState();
}

class _GuideContentState extends State<GuideContent> {
  String _location = '';
  String _specialty = 'All';
  final _locationCtrl = TextEditingController();

  List<Guide> _guides = [];
  bool _loading = false;
  String? _error;

  static const _specialties = [
    'All', 'Nature', 'Heritage', 'Beach', 'Mountain',
    'Food', 'City Tour', 'Adventure',
  ];

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() { _loading = true; _error = null; _guides = []; });
    try {
      var query = supabase.from('guides').select(
        '*, '
        'guide_specialties(*), '
        'guide_languages(*), '
        'guide_certifications(*), '
        'guide_availability(*)',
      );
      if (_location.isNotEmpty) query = query.ilike('city', '%$_location%');
      final data = await query.order('rating', ascending: false);

      var guides = data.map((g) => Guide.fromJson(g)).toList();

      if (_specialty != 'All') {
        guides = guides
            .where((g) =>
                g.specialties.isEmpty ||
                g.specialties.any(
                    (s) => s.toLowerCase().contains(_specialty.toLowerCase())))
            .toList();
      }

      if (mounted) setState(() => _guides = guides);
    } on PostgrestException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvCard(
            child: Column(children: [
              _SearchField(controller: _locationCtrl, onChanged: (v) => _location = v),
              const SizedBox(height: 14),
              SvButton(label: 'Find Guides', onTap: _search, color: _kAccent),
            ]),
          ),
          const SizedBox(height: 20),
          SvChipRow(
            options: _specialties,
            selected: _specialty,
            onChanged: (v) { setState(() => _specialty = v); _search(); },
            accentColor: _kAccent,
          ),
          const SizedBox(height: 20),
          if (_loading)
            const _LoadingState()
          else if (_error != null)
            _ErrorState(message: _error!, onRetry: _search)
          else if (_guides.isEmpty)
            _EmptyState(specialty: _specialty)
          else ...[
            _ResultsHeader(count: _guides.length, specialty: _specialty),
            const SizedBox(height: 12),
            ..._guides.map((g) => _GuideCard(guide: g, onBook: () => _showBooking(g))),
          ],
        ],
      ),
    );
  }

  Future<void> _showBooking(Guide guide) async {
    final payload = await showDialog<BookingPayload>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _BookingDialog(guide: guide),
    );
    if (payload != null && mounted) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => CheckoutScreen(payload: payload)));
    }
  }
}

// ─── Search field ─────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTextStyles.body.copyWith(color: AppColors.primary),
        cursorColor: _kAccent,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: "Search by city (e.g. Dhaka, Cox's Bazar)...",
          hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _kAccent),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
}

// ─── Guide card ───────────────────────────────────────────────────────────────

class _GuideCard extends StatelessWidget {
  final Guide guide;
  final VoidCallback onBook;
  const _GuideCard({required this.guide, required this.onBook});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Avatar + name + badges
          Row(children: [
            _Avatar(initials: guide.initials),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(guide.name,
                    style: AppTextStyles.label.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.location_on_rounded, size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(guide.location.isEmpty ? 'Location N/A' : guide.location,
                        style: AppTextStyles.caption, overflow: TextOverflow.ellipsis),
                  ),
                ]),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              _RatingBadge(rating: guide.rating),
            ]),
          ]),

          // Bio
          if (guide.bio != null && guide.bio!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(guide.bio!,
                style: AppTextStyles.caption.copyWith(fontSize: 11),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ],

          // Specialties
          if (guide.specialties.isNotEmpty) ...[
            const SizedBox(height: 10),
            _TagRow(items: guide.specialties, color: _kAccent, icon: Icons.explore_rounded),
          ],

          // Languages
          if (guide.languages.isNotEmpty) ...[
            const SizedBox(height: 6),
            _TagRow(items: guide.languages, color: AppColors.success, icon: Icons.translate_rounded),
          ],

          // Certifications
          if (guide.certifications.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.verified_rounded, size: 12, color: AppColors.warning),
              const SizedBox(width: 4),
              Flexible(
                child: Text(guide.certifications.take(2).join(' • '),
                    style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.warning),
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
          ],

          // Availability
          const SizedBox(height: 6),
          Row(children: [
            Icon(
              guide.availableDates.isNotEmpty
                  ? Icons.event_available_rounded
                  : Icons.event_busy_rounded,
              size: 12,
              color: guide.availableDates.isNotEmpty ? AppColors.success : AppColors.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              guide.availableDates.isNotEmpty
                  ? '${guide.availableDates.length} date${guide.availableDates.length == 1 ? '' : 's'} available'
                  : 'No dates available',
              style: AppTextStyles.caption.copyWith(
                fontSize: 10,
                color: guide.availableDates.isNotEmpty ? AppColors.success : AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ]),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 12),

          // Rate tiles row
          Row(children: [
            _RateTile(label: 'Hourly', amount: guide.hourlyRate),
            const SizedBox(width: 8),
            _RateTile(label: 'Half Day', amount: guide.halfDayRate),
            const SizedBox(width: 8),
            _RateTile(label: 'Full Day', amount: guide.fullDayRate),
          ]),

          const SizedBox(height: 12),

          // Book Now button
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: onBook,
              child: Text(
                'Book Now',
                style: AppTextStyles.btnSm,
              ),
            ),
          ),
        ]),
      );
}

// ─── Rate tile ────────────────────────────────────────────────────────────────

class _RateTile extends StatelessWidget {
  final String label;
  final double amount;
  const _RateTile({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: _kAccent.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(children: [
            Text(label,
                style: AppTextStyles.caption.copyWith(fontSize: 10),
                textAlign: TextAlign.center),
            const SizedBox(height: 3),
            Text(
              '৳${amount.toStringAsFixed(0)}',
              style: AppTextStyles.priceSm.copyWith(color: _kAccent),
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      );
}

// ─── Small reusable widgets ───────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String initials;
  const _Avatar({required this.initials});

  @override
  Widget build(BuildContext context) => Container(
        width: 54, height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.secondary, AppColors.accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(initials,
            style: AppTextStyles.h5.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
      );
}

class _RatingBadge extends StatelessWidget {
  final double rating;
  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.star_rounded, size: 12, color: AppColors.warning),
          const SizedBox(width: 3),
          Text(rating.toStringAsFixed(1),
              style: AppTextStyles.labelSm
                  .copyWith(color: AppColors.warning, fontWeight: FontWeight.w700)),
        ]),
      );
}


class _TagRow extends StatelessWidget {
  final List<String> items;
  final Color color;
  final IconData icon;
  const _TagRow({required this.items, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 6, runSpacing: 4,
        children: items.take(4).map((item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 10, color: color),
                const SizedBox(width: 3),
                Text(item,
                    style: AppTextStyles.caption.copyWith(
                        fontSize: 10, color: color, fontWeight: FontWeight.w600)),
              ]),
            )).toList(),
      );
}

// ─── Result state widgets ─────────────────────────────────────────────────────

class _ResultsHeader extends StatelessWidget {
  final int count;
  final String specialty;
  const _ResultsHeader({required this.count, required this.specialty});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(specialty == 'All' ? 'All Guides' : '$specialty Guides',
              style: AppTextStyles.h5.copyWith(color: AppColors.primary)),
          Text('$count ${count == 1 ? 'guide' : 'guides'} found',
              style: AppTextStyles.caption
                  .copyWith(color: _kAccent, fontWeight: FontWeight.w600)),
        ],
      );
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(_kAccent), strokeWidth: 2.5),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(message,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          SvButton(label: 'Try Again', onTap: onRetry, color: _kAccent),
        ]),
      );
}

class _EmptyState extends StatelessWidget {
  final String specialty;
  const _EmptyState({required this.specialty});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(children: [
          Icon(Icons.person_search_rounded,
              size: 56, color: _kAccent.withValues(alpha: 0.35)),
          const SizedBox(height: 14),
          Text('No guides found',
              style: AppTextStyles.h5.copyWith(color: AppColors.primary)),
          const SizedBox(height: 6),
          Text(
            specialty == 'All'
                ? 'No guides available. Try a different city.'
                : 'No $specialty guides available.',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ]),
      );
}

// ─── Booking Dialog ───────────────────────────────────────────────────────────

enum _BookingType { hourly, halfDay, fullDay }

class _BookingDialog extends StatefulWidget {
  final Guide guide;
  const _BookingDialog({required this.guide});

  @override
  State<_BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends State<_BookingDialog> {
  _BookingType _type = _BookingType.fullDay;
  int _qty = 1;
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  @override
  void initState() {
    super.initState();
    if (widget.guide.availableDates.isNotEmpty) {
      try {
        final first = DateTime.parse(widget.guide.availableDates.first);
        if (first.isAfter(DateTime.now())) _startDate = first;
      } catch (_) {}
    }
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool _isDateAvailable(DateTime d) {
    if (widget.guide.availableDates.isEmpty) return true;
    return widget.guide.availableDates.contains(_dateKey(d));
  }

  int _slotsForDate(DateTime d) => widget.guide.slotsByDate[_dateKey(d)] ?? 0;

  double get _unitRate {
    switch (_type) {
      case _BookingType.hourly:   return widget.guide.hourlyRate;
      case _BookingType.halfDay:  return widget.guide.halfDayRate;
      case _BookingType.fullDay:  return widget.guide.fullDayRate;
    }
  }

  String get _unitLabel {
    switch (_type) {
      case _BookingType.hourly:   return _qty == 1 ? 'hour' : 'hours';
      case _BookingType.halfDay:  return _qty == 1 ? 'half-day' : 'half-days';
      case _BookingType.fullDay:  return _qty == 1 ? 'day' : 'days';
    }
  }

  int get _maxQty {
    switch (_type) {
      case _BookingType.hourly:   return 12;
      case _BookingType.halfDay:  return 10;
      case _BookingType.fullDay:  return 30;
    }
  }

  double get _total => _unitRate * _qty;

  String _fmtDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }

  Future<void> _pickDate() async {
    final hasSlots = widget.guide.availableDates.isNotEmpty;
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      selectableDayPredicate: hasSlots ? _isDateAvailable : null,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: _kAccent)),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _startDate = picked);
  }

  void _proceed() {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    final guide = widget.guide;
    Navigator.pop(
      context,
      BookingPayload(
        serviceType: 'guide',
        baseAmount: _total,
        currency: 'BDT',
        details: {
          'guide_id': guide.id,
          'guide_name': guide.name,
          'location': guide.location,
          'booking_type': _type.name,
          'quantity': _qty,
          'date': _dateKey(_startDate),
        },
        startsAt: _startDate,
        title: guide.name,
        subtitle: '${guide.location} · ${_type.name} booking',
        quantitySummary: '$_qty $_unitLabel',
        checkInLabel: 'BOOKING DATE',
        checkInValue: _fmtDate(_startDate),
        guestsLabel: 'SESSIONS',
        guestsValue: '$_qty $_unitLabel',
        serviceIcon: Icons.person_pin_rounded,
        serviceLabel: 'Guide',
        accentColor: _kAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final guide = widget.guide;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(color: AppColors.shadow, blurRadius: 24, offset: Offset(0, 8)),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: _kAccent,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(children: [
                _Avatar(initials: guide.initials),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Book a Guide',
                        style: AppTextStyles.h5.copyWith(color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(guide.name,
                        style: AppTextStyles.bodySm
                            .copyWith(color: Colors.white.withValues(alpha: 0.85))),
                  ]),
                ),
              ]),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(children: [

                  // Location + exp tile
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('City', style: AppTextStyles.caption.copyWith(fontSize: 10)),
                        const SizedBox(height: 2),
                        Text(guide.location.isEmpty ? '—' : guide.location,
                            style: AppTextStyles.label.copyWith(
                                color: AppColors.primary, fontWeight: FontWeight.w700)),
                      ])),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('Rating', style: AppTextStyles.caption.copyWith(fontSize: 10)),
                        const SizedBox(height: 2),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.star_rounded, size: 13, color: AppColors.warning),
                          const SizedBox(width: 3),
                          Text(guide.rating.toStringAsFixed(1),
                              style: AppTextStyles.label.copyWith(
                                  color: AppColors.primary, fontWeight: FontWeight.w700)),
                        ]),
                      ])),
                    ]),
                  ),

                  const SizedBox(height: 16),

                  // Booking type selector
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Select Booking Type',
                        style: AppTextStyles.label.copyWith(
                            color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    _TypeTile(
                      label: 'Hourly',
                      rate: guide.hourlyRate,
                      icon: Icons.schedule_rounded,
                      selected: _type == _BookingType.hourly,
                      onTap: () => setState(() { _type = _BookingType.hourly; _qty = 1; }),
                    ),
                    const SizedBox(width: 8),
                    _TypeTile(
                      label: 'Half Day',
                      rate: guide.halfDayRate,
                      icon: Icons.wb_twilight_rounded,
                      selected: _type == _BookingType.halfDay,
                      onTap: () => setState(() { _type = _BookingType.halfDay; _qty = 1; }),
                    ),
                    const SizedBox(width: 8),
                    _TypeTile(
                      label: 'Full Day',
                      rate: guide.fullDayRate,
                      icon: Icons.wb_sunny_rounded,
                      selected: _type == _BookingType.fullDay,
                      onTap: () => setState(() { _type = _BookingType.fullDay; _qty = 1; }),
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // Date picker
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderLight),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        const Icon(Icons.calendar_month_rounded, size: 18, color: _kAccent),
                        const SizedBox(width: 10),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Date', style: AppTextStyles.caption.copyWith(fontSize: 10)),
                          const SizedBox(height: 2),
                          Text(_fmtDate(_startDate),
                              style: AppTextStyles.label.copyWith(
                                  color: AppColors.primary, fontWeight: FontWeight.w600)),
                          if (widget.guide.availableDates.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              '${_slotsForDate(_startDate)} slot${_slotsForDate(_startDate) == 1 ? '' : 's'} available',
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 10,
                                color: _slotsForDate(_startDate) > 0
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                          ],
                        ]),
                        const Spacer(),
                        const Icon(Icons.chevron_right_rounded,
                            size: 18, color: AppColors.textMuted),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 14),
                  const Divider(height: 1, color: AppColors.borderLight),
                  const SizedBox(height: 14),

                  // Quantity counter
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Quantity',
                            style: AppTextStyles.label.copyWith(
                                color: AppColors.primary, fontWeight: FontWeight.w600)),
                        Text('৳${_unitRate.toStringAsFixed(0)} per $_unitLabel',
                            style: AppTextStyles.caption.copyWith(fontSize: 11)),
                      ]),
                      Row(children: [
                        _CounterBtn(
                          icon: Icons.remove,
                          onTap: _qty > 1 ? () => setState(() => _qty--) : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('$_qty',
                              style: AppTextStyles.h5.copyWith(color: AppColors.primary)),
                        ),
                        _CounterBtn(
                          icon: Icons.add,
                          onTap: _qty < _maxQty ? () => setState(() => _qty++) : null,
                        ),
                      ]),
                    ],
                  ),

                  const SizedBox(height: 14),
                  const Divider(height: 1, color: AppColors.borderLight),
                  const SizedBox(height: 14),

                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Price',
                          style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
                      Text('৳ ${_total.toStringAsFixed(0)}',
                          style: AppTextStyles.price.copyWith(color: _kAccent)),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Buttons
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textMuted,
                          side: const BorderSide(color: AppColors.borderLight),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel', style: AppTextStyles.btnSm),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _proceed,
                        child: Text('Proceed to Payment', style: AppTextStyles.btnSm),
                      ),
                    ),
                  ]),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── Booking type tile ────────────────────────────────────────────────────────

class _TypeTile extends StatelessWidget {
  final String label;
  final double rate;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _TypeTile({
    required this.label, required this.rate, required this.icon,
    required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              color: selected ? _kAccent : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: selected ? _kAccent : AppColors.borderLight, width: 1.5),
            ),
            child: Column(children: [
              Icon(icon, size: 18,
                  color: selected ? Colors.white : AppColors.textMuted),
              const SizedBox(height: 4),
              Text(label,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11,
                    color: selected ? Colors.white : AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: 2),
              Text('৳${rate.toStringAsFixed(0)}',
                  style: AppTextStyles.labelSm.copyWith(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.9)
                        : _kAccent,
                    fontWeight: FontWeight.w700,
                  )),
            ]),
          ),
        ),
      );
}

// ─── Counter button ───────────────────────────────────────────────────────────

class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _CounterBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: onTap != null
                ? _kAccent.withValues(alpha: 0.12)
                : AppColors.surfaceLight,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16,
              color: onTap != null ? _kAccent : AppColors.borderLight),
        ),
      );
}
