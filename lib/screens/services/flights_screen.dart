import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

class Airport {
  final String code;
  final String name;
  final String country;

  Airport.fromApi(Map<String, dynamic> j)
      : code = j['iata_code'] as String? ?? '',
        name = j['airport_name'] as String? ?? '',
        country = j['country_name'] as String? ?? '';

  String get displayName => '$name ($code)';
}

class Flight {
  final String id;
  final String fromCode;
  final String toCode;
  final String fromDisplay;
  final String toDisplay;
  final DateTime departsAt;
  final DateTime arrivesAt;
  final String airlineName;
  final String flightNumber;
  final String cabinClass;
  final double basePrice;
  final String currency;
  final int seatsAvailable;
  final String? aircraft;
  final int? baggageKg;
  final bool refundable;

  Flight({
    required this.id,
    required this.fromCode,
    required this.toCode,
    required this.fromDisplay,
    required this.toDisplay,
    required this.departsAt,
    required this.arrivesAt,
    required this.airlineName,
    required this.flightNumber,
    required this.cabinClass,
    required this.basePrice,
    required this.currency,
    required this.seatsAvailable,
    this.aircraft,
    this.baggageKg,
    required this.refundable,
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

  String get formattedFare => '৳ ${basePrice.toStringAsFixed(0)}';
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class FlightsContent extends StatefulWidget {
  const FlightsContent({super.key});
  @override
  State<FlightsContent> createState() => _FlightsContentState();
}

class _FlightsContentState extends State<FlightsContent> {
  List<Airport> _airports = [];
  String _fromCode = 'DAC';
  String _toCode = 'CXB';
  String _selectedClass = 'All';

  List<Flight> _flights = [];
  bool _loading = false;
  bool _showingAll = true;
  String? _error;

  static const _classOptions = ['All', 'Economy', 'Business', 'First'];

  @override
  void initState() {
    super.initState();
    _loadAirports();
  }

  // ─── Data loading ────────────────────────────────────────────────────────────

  Future<void> _loadAirports() async {
    try {
      final uri = Uri.parse(
        'http://api.aviationstack.com/v1/airports'
        '?access_key=97a9b32848e495da09f6a46cc408a83f'
        '&country_iso2=BD',
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = (json['data'] as List?) ?? [];
        final airports = data
            .map((e) => Airport.fromApi(e as Map<String, dynamic>))
            .where((a) => a.code.isNotEmpty)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        if (mounted) setState(() => _airports = airports);
      }
    } catch (_) {}
    if (mounted) _searchFlights(allFlights: true);
  }

  Future<void> _searchFlights({bool allFlights = false}) async {
    setState(() {
      _loading = true;
      _showingAll = allFlights;
      _error = null;
      _flights = [];
    });

    final airportMap = {for (final a in _airports) a.code: a.displayName};

    try {
      var query = supabase
          .from('flights')
          .select(
            'id, from_code, to_code, departs_at, arrives_at, '
            'cabin_class, base_price, currency, seats_available, flight_number, '
            'aircraft, baggage_kg, refundable, '
            'airlines(name)',
          );

      if (!allFlights) {
        query = query
            .eq('from_code', _fromCode)
            .eq('to_code', _toCode);
      }

      if (_selectedClass != 'All') {
        query = query.eq('cabin_class', _selectedClass);
      }

      final rawData = await query.order('departs_at');

      final List<Flight> flights = rawData.map((e) {
        final airline = (e['airlines'] as Map<String, dynamic>?) ?? {};
        return Flight(
          id: e['id'] as String,
          fromCode: e['from_code'] as String,
          toCode: e['to_code'] as String,
          fromDisplay: airportMap[e['from_code']] ?? e['from_code'] as String,
          toDisplay: airportMap[e['to_code']] ?? e['to_code'] as String,
          departsAt: DateTime.parse(e['departs_at'] as String).toLocal(),
          arrivesAt: DateTime.parse(e['arrives_at'] as String).toLocal(),
          airlineName: airline['name'] as String? ?? 'Unknown',
          flightNumber: e['flight_number'] as String? ?? '',
          cabinClass: e['cabin_class'] as String? ?? '',
          basePrice: (e['base_price'] as num).toDouble(),
          currency: e['currency'] as String? ?? 'BDT',
          seatsAvailable: (e['seats_available'] as num).toInt(),
          aircraft: e['aircraft'] as String?,
          baggageKg: e['baggage_kg'] as int?,
          refundable: e['refundable'] as bool? ?? false,
        );
      }).toList();

      if (mounted) setState(() => _flights = flights);
    } on PostgrestException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Failed to load flights. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── Airport picker ──────────────────────────────────────────────────────────

  Future<void> _pickAirport({required bool isFrom}) async {
    if (_airports.isEmpty) return;
    final picked = await showModalBottomSheet<Airport>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AirportSheet(
        airports: _airports,
        selectedCode: isFrom ? _fromCode : _toCode,
        title: isFrom ? 'From' : 'To',
      ),
    );
    if (picked == null) return;
    setState(() => isFrom ? _fromCode = picked.code : _toCode = picked.code);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  String _displayFor(String code) {
    for (final a in _airports) {
      if (a.code == code) return a.displayName;
    }
    return code;
  }

  void _showBookingDialog(Flight flight) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _BookingDialog(flight: flight),
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
                fromIcon: Icons.flight_takeoff_rounded,
                toIcon: Icons.flight_land_rounded,
                onTapFrom: () => _pickAirport(isFrom: true),
                onTapTo: () => _pickAirport(isFrom: false),
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
                accentColor: AppColors.secondary,
              ),
              const SizedBox(height: 14),
              SvButton(
                label: 'Search Flights',
                onTap: _searchFlights,
                color: AppColors.secondary,
              ),
            ]),
          ),

          const SizedBox(height: 24),

          // Results
          if (_loading)
            const _LoadingState()
          else if (_error != null)
            _ErrorState(message: _error!, onRetry: _searchFlights)
          else if (_flights.isEmpty)
            _EmptyState(
              from: _showingAll ? 'All' : _displayFor(_fromCode),
              to: _showingAll ? 'routes' : _displayFor(_toCode),
            )
          else ...[
            _ResultsHeader(
              count: _flights.length,
              from: _showingAll ? 'All Routes' : _displayFor(_fromCode),
              to: _showingAll ? '' : _displayFor(_toCode),
            ),
            const SizedBox(height: 12),
            ..._flights.map(_buildFlightCard),
          ],
        ],
      ),
    );
  }

  Widget _buildFlightCard(Flight flight) {
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
          // Airline + flight number + cabin badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  flight.airlineName,
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
                    'Flight ${flight.flightNumber}',
                    style: AppTextStyles.caption.copyWith(fontSize: 11),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.calendar_today_rounded, size: 11, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    _fmtDate(flight.departsAt),
                    style: AppTextStyles.caption.copyWith(fontSize: 11),
                  ),
                ]),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  flight.cabinClass.isEmpty ? 'Economy' : flight.cabinClass,
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.secondary,
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
                  Text(flight.departureTime,
                      style: AppTextStyles.h5.copyWith(color: AppColors.primary)),
                  Text(flight.fromDisplay,
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
                      child: Text(flight.duration,
                          style: AppTextStyles.caption.copyWith(fontSize: 11)),
                    ),
                    Expanded(child: Divider(color: AppColors.borderLight, thickness: 1.5)),
                  ]),
                  const Icon(Icons.flight_rounded, size: 14, color: AppColors.secondary),
                ]),
              ),
              Flexible(
                child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(flight.arrivalTime,
                      style: AppTextStyles.h5.copyWith(color: AppColors.primary)),
                  Text(flight.toDisplay,
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
                Text(flight.formattedFare,
                    style: AppTextStyles.price.copyWith(color: AppColors.secondary)),
                Text(
                  '${flight.seatsAvailable} seats left',
                  style: AppTextStyles.caption.copyWith(
                    color: flight.seatsAvailable < 5 ? AppColors.error : AppColors.textMuted,
                  ),
                ),
              ]),
              SizedBox(
                width: 110,
                height: 38,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _showBookingDialog(flight),
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
            child: Text(to.isEmpty ? from : '$from → $to',
                style: AppTextStyles.h5.copyWith(color: AppColors.primary),
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Text(
            '$count ${count == 1 ? 'flight' : 'flights'} found',
            style: AppTextStyles.caption.copyWith(
                color: AppColors.secondary, fontWeight: FontWeight.w600),
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
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(message,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          SvButton(label: 'Try Again', onTap: onRetry, color: AppColors.secondary),
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
          Icon(Icons.flight_rounded,
              size: 56, color: AppColors.secondary.withValues(alpha: 0.25)),
          const SizedBox(height: 14),
          Text('No flights found',
              style: AppTextStyles.h5.copyWith(color: AppColors.primary)),
          const SizedBox(height: 6),
          Text(
            'No flights available from $from to $to.',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ]),
      );
}

// ─── Airport picker bottom sheet ──────────────────────────────────────────────

class _AirportSheet extends StatefulWidget {
  final List<Airport> airports;
  final String selectedCode;
  final String title;
  const _AirportSheet({
    required this.airports,
    required this.selectedCode,
    required this.title,
  });

  @override
  State<_AirportSheet> createState() => _AirportSheetState();
}

class _AirportSheetState extends State<_AirportSheet> {
  final _search = TextEditingController();
  late List<Airport> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = List.of(widget.airports);
    _search.addListener(() {
      final q = _search.text.toLowerCase();
      setState(() {
        _filtered = q.isEmpty
            ? List.of(widget.airports)
            : widget.airports
                .where((a) =>
                    a.name.toLowerCase().contains(q) ||
                    a.code.toLowerCase().contains(q) ||
                    a.country.toLowerCase().contains(q))
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
          Text('Select ${widget.title} Airport',
              style: AppTextStyles.h5.copyWith(color: AppColors.primary)),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _search,
              style: AppTextStyles.body.copyWith(color: AppColors.primary),
              cursorColor: AppColors.secondary,
              decoration: InputDecoration(
                hintText: 'Search airport or city...',
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
                  borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final airport = _filtered[i];
                final active = airport.code == widget.selectedCode;
                return InkWell(
                  onTap: () => Navigator.pop(context, airport),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    child: Row(children: [
                      Icon(Icons.flight_rounded, size: 18,
                          color: active ? AppColors.secondary : AppColors.textMuted),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(airport.name,
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.primary,
                                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2),
                          Text('${airport.code}  •  ${airport.country}',
                              style: AppTextStyles.caption.copyWith(fontSize: 11)),
                        ]),
                      ),
                      if (active)
                        const Icon(Icons.check_circle_rounded,
                            size: 18, color: AppColors.secondary),
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
  final Flight flight;
  const _BookingDialog({required this.flight});

  @override
  State<_BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends State<_BookingDialog> {
  int _passengers = 1;

  double get _total => widget.flight.basePrice * _passengers;

  bool _confirming = false;

  Future<void> _confirm() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    setState(() => _confirming = true);
    final flight = widget.flight;
    final ref = 'TM-FL-${DateTime.now().millisecondsSinceEpoch % 90000 + 10000}';
    try {
      await supabase.from('bookings').insert({
        'user_id': user.id,
        'service_type': 'flight',
        'reference_code': ref,
        'status': 'confirmed',
        'total_amount': _total,
        'currency': flight.currency,
        'details': {
          'flight_id': flight.id,
          'flight_number': flight.flightNumber,
          'airline': flight.airlineName,
          'from': flight.fromCode,
          'to': flight.toCode,
          'cabin_class': flight.cabinClass,
          'passengers': _passengers,
          'departs_at': flight.departsAt.toIso8601String(),
          'arrives_at': flight.arrivesAt.toIso8601String(),
        },
        'starts_at': flight.departsAt.toIso8601String(),
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Flight booked! Ref: $ref'),
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
    final flight = widget.flight;
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
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Booking Summary',
                      style: AppTextStyles.h5.copyWith(color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(
                    '${flight.airlineName}  •  ${flight.flightNumber}',
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
                            Text(flight.fromDisplay,
                                style: AppTextStyles.label.copyWith(
                                    color: AppColors.primary, fontWeight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2),
                          ]),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(children: [
                            const Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.secondary),
                            Text(flight.duration,
                                style: AppTextStyles.caption.copyWith(fontSize: 10)),
                          ]),
                        ),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text('TO', style: AppTextStyles.caption.copyWith(fontSize: 10, letterSpacing: 0.8)),
                            const SizedBox(height: 2),
                            Text(flight.toDisplay,
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
                      _InfoTile(icon: Icons.schedule_rounded, label: 'Departure', value: flight.departureTime),
                      const SizedBox(width: 10),
                      _InfoTile(icon: Icons.schedule_rounded, label: 'Arrival', value: flight.arrivalTime),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      _InfoTile(icon: Icons.airline_seat_recline_normal_rounded, label: 'Class', value: flight.cabinClass.isEmpty ? 'Economy' : flight.cabinClass),
                      const SizedBox(width: 10),
                      _InfoTile(icon: Icons.calendar_today_rounded, label: 'Date', value: _fmtDate(flight.departsAt)),
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
                          Text('Max ${flight.seatsAvailable} seats available',
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
                            onTap: _passengers < flight.seatsAvailable
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
                            style: AppTextStyles.price.copyWith(color: AppColors.secondary)),
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
                            backgroundColor: AppColors.secondary,
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
            Icon(icon, size: 14, color: AppColors.secondary),
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
                ? AppColors.secondary.withValues(alpha: 0.12)
                : AppColors.surfaceLight,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16,
            color: onTap != null ? AppColors.secondary : AppColors.borderLight,
          ),
        ),
      );
}
