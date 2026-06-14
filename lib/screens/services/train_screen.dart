import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'service_widgets.dart';

// ─── Helper ───────────────────────────────────────────────────────────────────

String _fmtDate(DateTime d) {
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

// ─── Models ───────────────────────────────────────────────────────────────────

class TrainStation {
  final String code;
  final String name;
  final String city;

  TrainStation.fromJson(Map<String, dynamic> j)
      : code = j['code'],
        name = j['name'],
        city = j['city'];

  String get displayName => '$city ($name)';
}

class TrainTrip {
  final String scheduleId;
  final String classId;
  final String fromCode;
  final String toCode;
  final String fromDisplay;
  final String toDisplay;
  final DateTime departsAt;
  final DateTime arrivesAt;
  final String trainName;
  final String trainNumber;
  final String className;
  final double fare;
  final int seatsAvailable;

  TrainTrip({
    required this.scheduleId,
    required this.classId,
    required this.fromCode,
    required this.toCode,
    required this.fromDisplay,
    required this.toDisplay,
    required this.departsAt,
    required this.arrivesAt,
    required this.trainName,
    required this.trainNumber,
    required this.className,
    required this.fare,
    required this.seatsAvailable,
  });

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

class TrainContent extends StatefulWidget {
  const TrainContent({super.key});
  @override
  State<TrainContent> createState() => _TrainContentState();
}

class _TrainContentState extends State<TrainContent> {
  List<TrainStation> _stations = [];
  String _fromCode = 'DHA';
  String _toCode = 'CTG';
  String _selectedClass = 'All';

  List<TrainTrip> _trips = [];
  bool _loading = false;
  String? _error;

  static const _classOptions = ['All', 'AC', 'Snigdha', 'S_CHAIR', 'SHOVAN'];

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  // ─── Data loading ────────────────────────────────────────────────────────────

  Future<void> _loadStations() async {
    try {
      final data = await supabase
          .from('stations')
          .select('code, name, city')
          .order('city');
      final stations = data
          .map((e) => TrainStation.fromJson(e))
          .toList();
      if (mounted) setState(() => _stations = stations);
    } catch (_) {}
    if (mounted) _searchTrains();
  }

  Future<void> _searchTrains() async {
    setState(() {
      _loading = true;
      _error = null;
      _trips = [];
    });

    final stationMap = {for (final s in _stations) s.code: s.displayName};

    try {
      final rawData = await supabase
          .from('train_schedules')
          .select(
            'id, from_station, to_station, departs_at, arrives_at, '
            'trains(name, number), '
            'train_classes(id, class_name, fare, seats_available)',
          )
          .eq('from_station', _fromCode)
          .eq('to_station', _toCode)
          .order('departs_at');

      final List<TrainTrip> trips = [];

      for (final schedule in rawData) {
        final train = (schedule['trains'] as Map<String, dynamic>?) ?? {};
        final classes = (schedule['train_classes'] as List?) ?? [];

        for (final cls in classes) {
          final c = cls as Map<String, dynamic>;
          if (_selectedClass != 'All' && c['class_name'] != _selectedClass) continue;

          trips.add(TrainTrip(
            scheduleId: schedule['id'] as String,
            classId: c['id'] as String,
            fromCode: schedule['from_station'] as String,
            toCode: schedule['to_station'] as String,
            fromDisplay: stationMap[schedule['from_station']] ?? schedule['from_station'] as String,
            toDisplay: stationMap[schedule['to_station']] ?? schedule['to_station'] as String,
            departsAt: DateTime.parse(schedule['departs_at'] as String).toLocal(),
            arrivesAt: DateTime.parse(schedule['arrives_at'] as String).toLocal(),
            trainName: train['name'] as String? ?? 'Unknown',
            trainNumber: train['number'] as String? ?? '',
            className: c['class_name'] as String? ?? '',
            fare: (c['fare'] as num).toDouble(),
            seatsAvailable: (c['seats_available'] as num).toInt(),
          ));
        }
      }

      trips.sort((a, b) => a.departsAt.compareTo(b.departsAt));
      if (mounted) setState(() => _trips = trips);
    } on PostgrestException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Failed to load trains. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── Station picker ──────────────────────────────────────────────────────────

  Future<void> _pickStation({required bool isFrom}) async {
    if (_stations.isEmpty) return;
    final picked = await showModalBottomSheet<TrainStation>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _StationSheet(
        stations: _stations,
        selectedCode: isFrom ? _fromCode : _toCode,
        title: isFrom ? 'From' : 'To',
      ),
    );
    if (picked == null) return;
    setState(() => isFrom ? _fromCode = picked.code : _toCode = picked.code);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  String _displayFor(String code) {
    for (final s in _stations) {
      if (s.code == code) return s.displayName;
    }
    return code;
  }

  void _showBookingDialog(TrainTrip trip) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _BookingDialog(trip: trip),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

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
                from: _displayFor(_fromCode),
                to: _displayFor(_toCode),
                fromIcon: Icons.train_rounded,
                toIcon: Icons.location_on_rounded,
                onTapFrom: () => _pickStation(isFrom: true),
                onTapTo: () => _pickStation(isFrom: false),
                onSwap: () => setState(() {
                  final t = _fromCode;
                  _fromCode = _toCode;
                  _toCode = t;
                }),
              ),
              const SizedBox(height: 12),
              SvChipRow(
                options: _classOptions,
                selected: _selectedClass,
                onChanged: (v) => setState(() => _selectedClass = v),
                accentColor: AppColors.primary,
              ),
              const SizedBox(height: 14),
              SvButton(
                label: 'Search Trains',
                onTap: _searchTrains,
                color: AppColors.primary,
              ),
            ]),
          ),

          const SizedBox(height: 24),

          // Results
          if (_loading)
            const _LoadingState()
          else if (_error != null)
            _ErrorState(message: _error!, onRetry: _searchTrains)
          else if (_trips.isEmpty)
            _EmptyState(from: _displayFor(_fromCode), to: _displayFor(_toCode))
          else ...[
            _ResultsHeader(
              count: _trips.length,
              from: _displayFor(_fromCode),
              to: _displayFor(_toCode),
            ),
            const SizedBox(height: 12),
            ..._trips.map(_buildTripCard),
          ],
        ],
      ),
    );
  }

  Widget _buildTripCard(TrainTrip trip) {
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
          // Train name + number + class badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  trip.trainName,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.confirmation_number_rounded, size: 11, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    'Train #${trip.trainNumber}',
                    style: AppTextStyles.caption.copyWith(fontSize: 11),
                  ),
                  const SizedBox(width: 10),
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
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  trip.className,
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.primary,
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
              Flexible(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(trip.departureTime,
                      style: AppTextStyles.h5.copyWith(color: AppColors.primary)),
                  Text(trip.fromDisplay,
                      style: AppTextStyles.caption,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1),
                ]),
              ),
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
                  const Icon(Icons.train_rounded, size: 14, color: AppColors.primary),
                ]),
              ),
              Flexible(
                child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(trip.arrivalTime,
                      style: AppTextStyles.h5.copyWith(color: AppColors.primary)),
                  Text(trip.toDisplay,
                      style: AppTextStyles.caption,
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1),
                ]),
              ),
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
                    style: AppTextStyles.price.copyWith(color: AppColors.primary)),
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
                    backgroundColor: AppColors.primary,
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
          Expanded(
            child: Text('$from → $to',
                style: AppTextStyles.h5.copyWith(color: AppColors.primary),
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Text(
            '$count ${count == 1 ? 'train' : 'trains'} found',
            style: AppTextStyles.caption.copyWith(
                color: AppColors.primary, fontWeight: FontWeight.w600),
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
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
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
          SvButton(label: 'Try Again', onTap: onRetry, color: AppColors.primary),
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
          Icon(Icons.train_rounded,
              size: 56, color: AppColors.primary.withValues(alpha: 0.25)),
          const SizedBox(height: 14),
          Text('No trains found',
              style: AppTextStyles.h5.copyWith(color: AppColors.primary)),
          const SizedBox(height: 6),
          Text(
            'No trains available from $from to $to.',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ]),
      );
}

// ─── Station picker bottom sheet ──────────────────────────────────────────────

class _StationSheet extends StatefulWidget {
  final List<TrainStation> stations;
  final String selectedCode;
  final String title;
  const _StationSheet({
    required this.stations,
    required this.selectedCode,
    required this.title,
  });

  @override
  State<_StationSheet> createState() => _StationSheetState();
}

class _StationSheetState extends State<_StationSheet> {
  final _search = TextEditingController();
  late List<TrainStation> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = List.of(widget.stations);
    _search.addListener(() {
      final q = _search.text.toLowerCase();
      setState(() {
        _filtered = q.isEmpty
            ? List.of(widget.stations)
            : widget.stations
                .where((s) =>
                    s.city.toLowerCase().contains(q) ||
                    s.name.toLowerCase().contains(q))
                .toList();
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
          Text('Select ${widget.title} Station',
              style: AppTextStyles.h5.copyWith(color: AppColors.primary)),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _search,
              style: AppTextStyles.body.copyWith(color: AppColors.primary),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: 'Search station or city...',
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
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final station = _filtered[i];
                final active = station.code == widget.selectedCode;
                return InkWell(
                  onTap: () => Navigator.pop(context, station),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    child: Row(children: [
                      Icon(Icons.train_rounded, size: 18,
                          color: active ? AppColors.primary : AppColors.textMuted),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(station.city,
                              style: AppTextStyles.label.copyWith(
                                color: active ? AppColors.primary : AppColors.primary,
                                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                              )),
                          Text(station.name,
                              style: AppTextStyles.caption.copyWith(fontSize: 11)),
                        ]),
                      ),
                      if (active)
                        const Icon(Icons.check_circle_rounded,
                            size: 18, color: AppColors.primary),
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
  final TrainTrip trip;
  const _BookingDialog({required this.trip});

  @override
  State<_BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends State<_BookingDialog> {
  int _passengers = 1;

  double get _total => widget.trip.fare * _passengers;

  bool _confirming = false;

  Future<void> _confirm() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    setState(() => _confirming = true);
    final trip = widget.trip;
    final ref = 'TM-TR-${DateTime.now().millisecondsSinceEpoch % 90000 + 10000}';
    try {
      await supabase.from('bookings').insert({
        'user_id': user.id,
        'service_type': 'train',
        'reference_code': ref,
        'status': 'confirmed',
        'total_amount': _total,
        'currency': 'BDT',
        'details': {
          'schedule_id': trip.scheduleId,
          'class_id': trip.classId,
          'train': trip.trainName,
          'train_number': trip.trainNumber,
          'from': trip.fromCode,
          'to': trip.toCode,
          'class': trip.className,
          'passengers': _passengers,
          'departs_at': trip.departsAt.toIso8601String(),
        },
        'starts_at': trip.departsAt.toIso8601String(),
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Train booked! Ref: $ref'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
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
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Booking Summary',
                    style: AppTextStyles.h5.copyWith(color: Colors.white)),
                const SizedBox(height: 4),
                Text(
                  '${trip.trainName}  •  #${trip.trainNumber}',
                  style: AppTextStyles.bodySm.copyWith(
                      color: Colors.white.withValues(alpha: 0.85)),
                ),
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
                        Text(trip.fromDisplay,
                            style: AppTextStyles.label.copyWith(
                                color: AppColors.primary, fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(children: [
                        const Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.primary),
                        Text(trip.duration,
                            style: AppTextStyles.caption.copyWith(fontSize: 10)),
                      ]),
                    ),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('TO', style: AppTextStyles.caption.copyWith(fontSize: 10, letterSpacing: 0.8)),
                        const SizedBox(height: 2),
                        Text(trip.toDisplay,
                            textAlign: TextAlign.end,
                            style: AppTextStyles.label.copyWith(
                                color: AppColors.primary, fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2),
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
                  _InfoTile(icon: Icons.airline_seat_recline_normal_rounded, label: 'Class', value: trip.className),
                  const SizedBox(width: 10),
                  _InfoTile(icon: Icons.calendar_today_rounded, label: 'Date', value: _fmtDate(trip.departsAt)),
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
                        color: AppColors.primary,
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
                        color: AppColors.primary,
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
                        style: AppTextStyles.price.copyWith(color: AppColors.primary)),
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
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _confirming ? null : _confirm,
                      child: _confirming
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text('Confirm Booking', style: AppTextStyles.btnSm),
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
            Icon(icon, size: 14, color: AppColors.primary),
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
  final Color color;
  const _CounterBtn({required this.icon, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: onTap != null
                ? color.withValues(alpha: 0.12)
                : AppColors.surfaceLight,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16,
            color: onTap != null ? color : AppColors.borderLight,
          ),
        ),
      );
}
