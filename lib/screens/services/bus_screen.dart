import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'service_widgets.dart';

// ─── Shared helper ────────────────────────────────────────────────────────────

String _fmtDate(DateTime d) {
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

// ─── Model ────────────────────────────────────────────────────────────────────

class BusTrip {
  final String id;
  final String fromCity;
  final String toCity;
  final DateTime departsAt;
  final DateTime arrivesAt;
  final String coachType;
  final double fare;
  final int seatsAvailable;
  final String operatorName;

  BusTrip.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        fromCity = j['from_city'],
        toCity = j['to_city'],
        departsAt = DateTime.parse(j['departs_at']).toLocal(),
        arrivesAt = DateTime.parse(j['arrives_at']).toLocal(),
        coachType = j['coach_type'] ?? '',
        fare = (j['fare'] as num).toDouble(),
        seatsAvailable = (j['seats_available'] as num).toInt(),
        operatorName = (j['bus_operators'] as Map?)?['name'] ?? 'Unknown';

  String get duration {
    final diff = arrivesAt.difference(departsAt);
    final h = diff.inHours;
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    return '${h}h ${m}m';
  }

  String get departureTime =>
      '${departsAt.hour.toString().padLeft(2, '0')}:${departsAt.minute.toString().padLeft(2, '0')}';

  String get arrivalTime =>
      '${arrivesAt.hour.toString().padLeft(2, '0')}:${arrivesAt.minute.toString().padLeft(2, '0')}';

  String get formattedFare => '৳ ${fare.toStringAsFixed(0)}';
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class BusContent extends StatefulWidget {
  const BusContent({super.key});
  @override
  State<BusContent> createState() => _BusContentState();
}

class _BusContentState extends State<BusContent> {
  String _from = 'Dhaka';
  String _to = 'Chittagong';
  String _seatType = 'All';

  List<BusTrip> _trips = [];
  bool _loading = false;
  String? _error;

  static const _seatTypes = ['All', 'AC', 'Non-AC', 'Sleeper', 'Volvo'];

  static const _cities = [
    'Dhaka', 'Chittagong', 'Sylhet', 'Rajshahi', 'Khulna',
    'Barisal', 'Rangpur', "Cox's Bazar", 'Comilla', 'Bogra',
    'Jessore', 'Mymensingh', 'Dinajpur',
  ];

  @override
  void initState() {
    super.initState();
    _searchBuses();
  }

  // ─── Supabase query ─────────────────────────────────────────────────────────

  Future<void> _searchBuses() async {
    setState(() {
      _loading = true;
      _error = null;
      _trips = [];
    });

    try {
      var query = supabase
          .from('bus_trips')
          .select(
            'id, from_city, to_city, departs_at, arrives_at, '
            'coach_type, fare, seats_available, bus_operators(name)',
          )
          .eq('from_city', _from)
          .eq('to_city', _to);

      if (_seatType != 'All') {
        query = query.eq('coach_type', _seatType);
      }

      final dynamic raw = await query.order('departs_at');

      final trips = (raw as List)
          .map((e) => BusTrip.fromJson(e as Map<String, dynamic>))
          .toList();

      if (mounted) setState(() => _trips = trips);
    } on PostgrestException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Failed to load buses. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── City picker ────────────────────────────────────────────────────────────

  Future<void> _pickCity({required bool isFrom}) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CitySheet(
        cities: _cities,
        selected: isFrom ? _from : _to,
        title: isFrom ? 'From' : 'To',
      ),
    );
    if (picked == null) return;
    setState(() => isFrom ? _from = picked : _to = picked);
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search form
          SvCard(
            child: Column(children: [
              SvSwapRow(
                from: _from,
                to: _to,
                fromIcon: Icons.directions_bus_rounded,
                toIcon: Icons.location_on_rounded,
                onTapFrom: () => _pickCity(isFrom: true),
                onTapTo: () => _pickCity(isFrom: false),
                onSwap: () => setState(() {
                  final t = _from;
                  _from = _to;
                  _to = t;
                }),
              ),
              const SizedBox(height: 12),
              SvChipRow(
                options: _seatTypes,
                selected: _seatType,
                onChanged: (v) => setState(() => _seatType = v),
                accentColor: AppColors.warning,
              ),
              const SizedBox(height: 14),
              SvButton(
                label: 'Search Buses',
                onTap: _searchBuses,
                color: AppColors.warning,
              ),
            ]),
          ),

          const SizedBox(height: 24),

          // Results
          if (_loading)
            const _LoadingState()
          else if (_error != null)
            _ErrorState(message: _error!, onRetry: _searchBuses)
          else if (_trips.isEmpty)
            _EmptyState(from: _from, to: _to)
          else ...[
            _ResultsHeader(count: _trips.length, from: _from, to: _to),
            const SizedBox(height: 12),
            ..._trips.map(_buildTripCard),
          ],
        ],
      ),
    );
  }

  Widget _buildTripCard(BusTrip trip) {
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
          // Operator + date + coach badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  trip.operatorName,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.calendar_today_rounded, size: 11, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    _fmtDate(trip.departsAt),
                    style: AppTextStyles.caption.copyWith(fontSize: 11),
                  ),
                ]),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  trip.coachType.isEmpty ? 'Standard' : trip.coachType,
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Departure → Arrival timeline
          Row(
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(trip.departureTime,
                    style: AppTextStyles.h5.copyWith(color: AppColors.primary)),
                Text(trip.fromCity, style: AppTextStyles.caption),
              ]),
              Expanded(
                child: Column(children: [
                  Row(children: [
                    Expanded(child: Divider(color: AppColors.borderLight, thickness: 1.5)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(trip.duration,
                          style: AppTextStyles.caption.copyWith(fontSize: 11)),
                    ),
                    Expanded(child: Divider(color: AppColors.borderLight, thickness: 1.5)),
                  ]),
                  const Icon(Icons.directions_bus_rounded, size: 14, color: AppColors.warning),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(trip.arrivalTime,
                    style: AppTextStyles.h5.copyWith(color: AppColors.primary)),
                Text(trip.toCity, style: AppTextStyles.caption),
              ]),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 12),

          // Fare + seats + Book Now
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(trip.formattedFare,
                    style: AppTextStyles.price.copyWith(color: AppColors.warning)),
                Text(
                  '${trip.seatsAvailable} seats left',
                  style: AppTextStyles.caption.copyWith(
                    color: trip.seatsAvailable < 5 ? AppColors.error : AppColors.textMuted,
                  ),
                ),
              ]),
              SizedBox(
                width: 110,
                height: 38,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _showBookingDialog(trip),
                  child: Text('Book Now', style: AppTextStyles.btnSm),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBookingDialog(BusTrip trip) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _BookingDialog(trip: trip),
    );
  }
}

// ─── Result state widgets ─────────────────────────────────────────────────────

class _ResultsHeader extends StatelessWidget {
  final int count;
  final String from;
  final String to;
  const _ResultsHeader({required this.count, required this.from, required this.to});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$from → $to',
              style: AppTextStyles.h5.copyWith(color: AppColors.primary)),
          Text(
            '$count ${count == 1 ? 'bus' : 'buses'} found',
            style: AppTextStyles.caption.copyWith(
                color: AppColors.warning, fontWeight: FontWeight.w600),
          ),
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
            valueColor: AlwaysStoppedAnimation(AppColors.warning),
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
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(message,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          SvButton(label: 'Try Again', onTap: onRetry, color: AppColors.warning),
        ]),
      );
}

class _EmptyState extends StatelessWidget {
  final String from;
  final String to;
  const _EmptyState({required this.from, required this.to});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(children: [
          Icon(Icons.directions_bus_rounded,
              size: 56, color: AppColors.warning.withValues(alpha: 0.35)),
          const SizedBox(height: 14),
          Text('No buses found',
              style: AppTextStyles.h5.copyWith(color: AppColors.primary)),
          const SizedBox(height: 6),
          Text(
            'No buses available from $from to $to.',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ]),
      );
}

// ─── City picker bottom sheet ─────────────────────────────────────────────────

class _CitySheet extends StatefulWidget {
  final List<String> cities;
  final String selected;
  final String title;
  const _CitySheet({required this.cities, required this.selected, required this.title});

  @override
  State<_CitySheet> createState() => _CitySheetState();
}

class _CitySheetState extends State<_CitySheet> {
  final _search = TextEditingController();
  late List<String> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = List.of(widget.cities);
    _search.addListener(() {
      final q = _search.text.toLowerCase();
      setState(() {
        _filtered = q.isEmpty
            ? List.of(widget.cities)
            : widget.cities.where((c) => c.toLowerCase().contains(q)).toList();
      });
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text('Select ${widget.title} City',
              style: AppTextStyles.h5.copyWith(color: AppColors.primary)),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _search,
              style: AppTextStyles.body.copyWith(color: AppColors.primary),
              cursorColor: AppColors.warning,
              decoration: InputDecoration(
                hintText: 'Search city...',
                hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                filled: true,
                fillColor: AppColors.surfaceLight,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.warning, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final city = _filtered[i];
                final active = city == widget.selected;
                return InkWell(
                  onTap: () => Navigator.pop(context, city),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    child: Row(children: [
                      Icon(Icons.location_city_rounded, size: 18,
                          color: active ? AppColors.warning : AppColors.textMuted),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(city,
                            style: AppTextStyles.body.copyWith(
                              color: active ? AppColors.warning : AppColors.primary,
                              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                            )),
                      ),
                      if (active)
                        const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.warning),
                    ]),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

// ─── Booking Dialog ───────────────────────────────────────────────────────────

class _BookingDialog extends StatefulWidget {
  final BusTrip trip;
  const _BookingDialog({required this.trip});

  @override
  State<_BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends State<_BookingDialog> {
  int _passengers = 1;

  double get _total => widget.trip.fare * _passengers;

  void _confirm() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Booking confirmed for $_passengers passenger${_passengers > 1 ? 's' : ''}!',
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(color: AppColors.shadow, blurRadius: 24, offset: Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Booking Summary',
                      style: AppTextStyles.h5.copyWith(color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(trip.operatorName,
                      style: AppTextStyles.bodySm.copyWith(
                          color: Colors.white.withValues(alpha: 0.85))),
                ]),
              ),

              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [

                // Route
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('FROM', style: AppTextStyles.caption.copyWith(fontSize: 10, letterSpacing: 0.8)),
                        const SizedBox(height: 2),
                        Text(trip.fromCity,
                            style: AppTextStyles.label.copyWith(
                                color: AppColors.primary, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                    Column(children: [
                      const Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.warning),
                      Text(trip.duration,
                          style: AppTextStyles.caption.copyWith(fontSize: 10)),
                    ]),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('TO', style: AppTextStyles.caption.copyWith(fontSize: 10, letterSpacing: 0.8)),
                        const SizedBox(height: 2),
                        Text(trip.toCity,
                            textAlign: TextAlign.end,
                            style: AppTextStyles.label.copyWith(
                                color: AppColors.primary, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ]),
                ),

                const SizedBox(height: 12),

                // Info tiles
                Row(children: [
                  _InfoTile(icon: Icons.schedule_rounded, label: 'Departure', value: trip.departureTime),
                  const SizedBox(width: 10),
                  _InfoTile(icon: Icons.schedule_rounded, label: 'Arrival', value: trip.arrivalTime),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  _InfoTile(
                    icon: Icons.directions_bus_rounded,
                    label: 'Bus Type',
                    value: trip.coachType.isEmpty ? 'Standard' : trip.coachType,
                  ),
                  const SizedBox(width: 10),
                  _InfoTile(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: _fmtDate(trip.departsAt),
                  ),
                ]),

                const SizedBox(height: 18),
                const Divider(height: 1, color: AppColors.borderLight),
                const SizedBox(height: 18),

                // Passenger selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Passengers',
                          style: AppTextStyles.label.copyWith(
                              color: AppColors.primary, fontWeight: FontWeight.w600)),
                      Text('Max ${trip.seatsAvailable} seats available',
                          style: AppTextStyles.caption.copyWith(fontSize: 11)),
                    ]),
                    Row(children: [
                      _CounterBtn(
                        icon: Icons.remove,
                        onTap: _passengers > 1 ? () => setState(() => _passengers--) : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('$_passengers',
                            style: AppTextStyles.h5.copyWith(color: AppColors.primary)),
                      ),
                      _CounterBtn(
                        icon: Icons.add,
                        onTap: _passengers < trip.seatsAvailable
                            ? () => setState(() => _passengers++)
                            : null,
                      ),
                    ]),
                  ],
                ),

                const SizedBox(height: 18),
                const Divider(height: 1, color: AppColors.borderLight),
                const SizedBox(height: 14),

                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Fare',
                        style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
                    Text('৳ ${_total.toStringAsFixed(0)}',
                        style: AppTextStyles.price.copyWith(color: AppColors.warning)),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        backgroundColor: AppColors.warning,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _confirm,
                      child: Text('Confirm Booking', style: AppTextStyles.btnSm),
                    ),
                  ),
                ]),
              ]),
            ),
          ),
        ],
      ),
    ),
  ),
);
  }
}

// ─── Dialog helpers ───────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Icon(icon, size: 14, color: AppColors.warning),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
                const SizedBox(height: 2),
                Text(value,
                    style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
              ]),
            ),
          ]),
        ),
      );
}

class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _CounterBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: onTap != null
                ? AppColors.warning.withValues(alpha: 0.12)
                : AppColors.surfaceLight,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16,
            color: onTap != null ? AppColors.warning : AppColors.borderLight,
          ),
        ),
      );
}
