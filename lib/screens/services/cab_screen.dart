import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'service_widgets.dart';
import '../payment_folder/booking_payload.dart';
import '../payment_folder/checkout_screen.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class CabVehicleType {
  final String id;
  final String name;
  final double baseFare;
  final double perKm;
  final int capacity;
  final int etaMinutes;

  CabVehicleType.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        name = j['name'],
        baseFare = (j['base_fare'] as num).toDouble(),
        perKm = (j['per_km'] as num).toDouble(),
        capacity = (j['capacity'] as num).toInt(),
        etaMinutes = (j['eta_minutes'] as num).toInt();

  IconData get icon {
    switch (name.toLowerCase()) {
      case 'bike':
        return Icons.two_wheeler_rounded;
      case 'cng':
        return Icons.electric_rickshaw_rounded;
      case 'car':
        return Icons.directions_car_rounded;
      default:
        return Icons.airport_shuttle_rounded;
    }
  }

  String get fareLabel => '৳${baseFare.toStringAsFixed(0)} base · ৳${perKm.toStringAsFixed(0)}/km';
}

class CabDriver {
  final String id;
  final String fullName;
  final String vehicleModel;
  final String vehicleColor;
  final String vehiclePlate;
  final String city;
  final double rating;
  final int totalTrips;
  final bool isVerified;
  final CabVehicleType vehicleType;

  CabDriver.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        fullName = j['full_name'],
        vehicleModel = j['vehicle_model'] ?? '',
        vehicleColor = j['vehicle_color'] ?? '',
        vehiclePlate = j['vehicle_plate'] ?? '',
        city = j['city'] ?? '',
        rating = (j['rating'] as num).toDouble(),
        totalTrips = (j['total_trips'] as num).toInt(),
        isVerified = j['is_verified'] as bool? ?? false,
        vehicleType = CabVehicleType.fromJson(
            j['cab_vehicle_types'] as Map<String, dynamic>);
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class CabContent extends StatefulWidget {
  const CabContent({super.key});
  @override
  State<CabContent> createState() => _CabContentState();
}

class _CabContentState extends State<CabContent> {
  List<CabVehicleType> _vehicleTypes = [];
  CabVehicleType? _selectedType;

  String _pickupCity = 'Dhaka';
  final _destinationCtrl = TextEditingController();

  List<CabDriver> _results = [];
  bool _loadingTypes = true;
  bool _loading = false;
  bool _searched = false;
  String? _error;

  static const _cities = [
    'Dhaka', 'Chittagong', 'Sylhet', 'Rajshahi', 'Khulna',
    'Barisal', 'Rangpur', "Cox's Bazar", 'Comilla', 'Bogra',
    'Jessore', 'Mymensingh', 'Dinajpur',
  ];

  @override
  void initState() {
    super.initState();
    _loadVehicleTypes();
  }

  @override
  void dispose() {
    _destinationCtrl.dispose();
    super.dispose();
  }

  // ─── Data loading ────────────────────────────────────────────────────────────

  Future<void> _loadVehicleTypes() async {
    try {
      final data = await supabase
          .from('cab_vehicle_types')
          .select('id, name, base_fare, per_km, capacity, eta_minutes')
          .order('base_fare');
      final types = data
          .map((e) => CabVehicleType.fromJson(e))
          .toList();
      if (mounted) setState(() { _vehicleTypes = types; _loadingTypes = false; });
    } catch (e) {
      debugPrint('loadVehicleTypes: $e');
      if (mounted) setState(() => _loadingTypes = false);
    }
  }

  Future<void> _searchCabs() async {
    setState(() {
      _loading = true;
      _error = null;
      _searched = true;
      _results = [];
    });

    try {
      var query = supabase
          .from('cab_drivers')
          .select(
            'id, full_name, vehicle_model, vehicle_color, vehicle_plate, '
            'city, rating, total_trips, is_verified, '
            'cab_vehicle_types(id, name, base_fare, per_km, capacity, eta_minutes)',
          )
          .eq('is_available', true)
          .eq('city', _pickupCity);

      if (_selectedType != null) {
        query = query.eq('vehicle_type_id', _selectedType!.id);
      }

      final data = await query.order('rating', ascending: false);

      final drivers = data
          .map((e) => CabDriver.fromJson(e))
          .toList();

      if (mounted) setState(() => _results = drivers);
    } on PostgrestException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Failed to load cabs. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── City picker ─────────────────────────────────────────────────────────────

  Future<void> _pickCity() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CitySheet(cities: _cities, selected: _pickupCity),
    );
    if (picked != null) setState(() => _pickupCity = picked);
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
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Pickup + Destination
              SvField(
                label: 'Pickup City',
                value: _pickupCity,
                icon: Icons.my_location_rounded,
                onTap: _pickCity,
              ),
              const SizedBox(height: 10),
              _DestinationField(controller: _destinationCtrl),

              const SizedBox(height: 14),
              const Divider(color: AppColors.borderLight),
              const SizedBox(height: 12),

              // Vehicle type selection
              Text(
                'Select Vehicle Type',
                style: AppTextStyles.label.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),

              if (_loadingTypes)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(AppColors.warning),
                      strokeWidth: 2,
                    ),
                  ),
                )
              else ...[
                // "All" chip + type grid
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TypeChip(
                      label: 'All',
                      icon: Icons.grid_view_rounded,
                      active: _selectedType == null,
                      onTap: () => setState(() => _selectedType = null),
                    ),
                    ..._vehicleTypes.map((t) => _TypeChip(
                          label: t.name,
                          icon: t.icon,
                          sublabel: t.fareLabel,
                          active: _selectedType?.id == t.id,
                          onTap: () => setState(() => _selectedType = t),
                        )),
                  ],
                ),
              ],

              const SizedBox(height: 14),
              SvButton(
                label: 'Search Cabs',
                onTap: _searchCabs,
                color: AppColors.warning,
              ),
            ]),
          ),

          const SizedBox(height: 24),

          // Results
          if (_loading)
            const _LoadingState()
          else if (_error != null)
            _ErrorState(message: _error!, onRetry: _searchCabs)
          else if (_searched && _results.isEmpty)
            _EmptyState(city: _pickupCity)
          else if (_searched) ...[
            _ResultsHeader(count: _results.length, city: _pickupCity),
            const SizedBox(height: 12),
            ..._results.map((d) => _buildDriverCard(d)),
          ],
        ],
      ),
    );
  }

  Widget _buildDriverCard(CabDriver driver) {
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
      child: Column(children: [
        // Driver info row
        Row(children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(driver.vehicleType.icon, size: 22, color: AppColors.warning),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text(
                    driver.fullName,
                    style: AppTextStyles.label.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (driver.isVerified) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.verified_rounded, size: 14, color: AppColors.secondary),
                ],
              ]),
              const SizedBox(height: 2),
              Text(
                '${driver.vehicleModel}  •  ${driver.vehicleColor}',
                style: AppTextStyles.caption.copyWith(fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ]),
          ),
          // Rating
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.star_rounded, size: 13, color: AppColors.warning),
              const SizedBox(width: 3),
              Text(driver.rating.toStringAsFixed(1),
                  style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.warning, fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),

        const SizedBox(height: 12),
        const Divider(height: 1, color: AppColors.borderLight),
        const SizedBox(height: 10),

        // Details row
        Row(children: [
          _DetailChip(
            icon: driver.vehicleType.icon,
            label: driver.vehicleType.name,
          ),
          const SizedBox(width: 8),
          _DetailChip(
            icon: Icons.people_outline_rounded,
            label: '${driver.vehicleType.capacity} seat${driver.vehicleType.capacity > 1 ? 's' : ''}',
          ),
          const SizedBox(width: 8),
          _DetailChip(
            icon: Icons.timer_outlined,
            label: '~${driver.vehicleType.etaMinutes} min',
          ),
          const Spacer(),
          Text(
            '৳${driver.vehicleType.baseFare.toStringAsFixed(0)}+',
            style: AppTextStyles.price.copyWith(color: AppColors.warning, fontSize: 16),
          ),
        ]),

        const SizedBox(height: 12),

        // Book button
        SvButton(
          label: 'Book Now',
          color: AppColors.warning,
          onTap: () => _showBookingDialog(driver),
        ),
      ]),
    );
  }

  Future<void> _showBookingDialog(CabDriver driver) async {
    final payload = await showDialog<BookingPayload>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _BookingDialog(
        driver: driver,
        pickup: _pickupCity,
        destination: _destinationCtrl.text.trim().isEmpty
            ? 'Not specified'
            : _destinationCtrl.text.trim(),
      ),
    );
    if (payload != null && mounted) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => CheckoutScreen(payload: payload)));
    }
  }
}

// ─── Small UI helpers ─────────────────────────────────────────────────────────

class _DestinationField extends StatelessWidget {
  final TextEditingController controller;
  const _DestinationField({required this.controller});

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        style: AppTextStyles.label.copyWith(color: AppColors.primary, fontSize: 12),
        cursorColor: AppColors.warning,
        decoration: InputDecoration(
          labelText: 'Destination',
          labelStyle: AppTextStyles.caption.copyWith(fontSize: 10),
          prefixIcon: const Icon(Icons.location_on_rounded,
              size: 15, color: AppColors.secondary),
          filled: true,
          fillColor: AppColors.surfaceLight,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.warning, width: 1.5),
          ),
        ),
      );
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? sublabel;
  final bool active;
  final VoidCallback onTap;
  const _TypeChip({
    required this.label,
    required this.icon,
    this.sublabel,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: active
                ? AppColors.warning.withValues(alpha: 0.10)
                : AppColors.surfaceLight,
            border: Border.all(
                color: active ? AppColors.warning : AppColors.borderLight,
                width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon,
                size: 16,
                color: active ? AppColors.warning : AppColors.textMuted),
            const SizedBox(width: 6),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: AppTextStyles.labelSm.copyWith(
                    color: active ? AppColors.primary : AppColors.textMuted,
                    fontWeight:
                        active ? FontWeight.w700 : FontWeight.w500,
                  )),
              if (sublabel != null)
                Text(sublabel!,
                    style: AppTextStyles.caption.copyWith(fontSize: 9)),
            ]),
          ]),
        ),
      );
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _DetailChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 3),
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 11)),
      ]);
}

// ─── Result state widgets ─────────────────────────────────────────────────────

class _ResultsHeader extends StatelessWidget {
  final int count;
  final String city;
  const _ResultsHeader({required this.count, required this.city});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Available in $city',
              style: AppTextStyles.h5.copyWith(color: AppColors.primary)),
          Text(
            '$count ${count == 1 ? 'cab' : 'cabs'} found',
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
  final String city;
  const _EmptyState({required this.city});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(children: [
          Icon(Icons.directions_car_rounded,
              size: 56, color: AppColors.warning.withValues(alpha: 0.30)),
          const SizedBox(height: 14),
          Text('No cabs available',
              style: AppTextStyles.h5.copyWith(color: AppColors.primary)),
          const SizedBox(height: 6),
          Text(
            'No available cabs found in $city.\nTry a different city or vehicle type.',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ]),
      );
}

// ─── City picker sheet ────────────────────────────────────────────────────────

class _CitySheet extends StatefulWidget {
  final List<String> cities;
  final String selected;
  const _CitySheet({required this.cities, required this.selected});

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
      height: MediaQuery.of(context).size.height * 0.60,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        const SizedBox(height: 12),
        Container(
          width: 36, height: 4,
          decoration: BoxDecoration(
            color: AppColors.borderLight, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 16),
        Text('Select Pickup City',
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
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppColors.textMuted, size: 20),
              filled: true,
              fillColor: AppColors.surfaceLight,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.warning, width: 1.5),
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
                            fontWeight:
                                active ? FontWeight.w700 : FontWeight.w400,
                          )),
                    ),
                    if (active)
                      const Icon(Icons.check_circle_rounded,
                          size: 18, color: AppColors.warning),
                  ]),
                ),
              );
            },
          ),
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
      ]),
    );
  }
}

// ─── Booking Dialog ───────────────────────────────────────────────────────────

class _BookingDialog extends StatefulWidget {
  final CabDriver driver;
  final String pickup;
  final String destination;
  const _BookingDialog({
    required this.driver,
    required this.pickup,
    required this.destination,
  });

  @override
  State<_BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends State<_BookingDialog> {
  final _kmCtrl = TextEditingController();
  double _km = 0;

  @override
  void dispose() {
    _kmCtrl.dispose();
    super.dispose();
  }

  double get _totalFare {
    final vt = widget.driver.vehicleType;
    return vt.baseFare + (_km * vt.perKm);
  }

  void _proceed() {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    final driver = widget.driver;
    final vt = driver.vehicleType;
    Navigator.pop(
      context,
      BookingPayload(
        serviceType: 'cab',
        baseAmount: _totalFare,
        currency: 'BDT',
        details: {
          'driver_id': driver.id,
          'driver_name': driver.fullName,
          'vehicle_type': vt.name,
          'vehicle_model': driver.vehicleModel,
          'vehicle_plate': driver.vehiclePlate,
          'pickup': widget.pickup,
          'destination': widget.destination,
          'base_fare': vt.baseFare,
          'per_km': vt.perKm,
          'distance_km': _km,
          'estimated_total': _totalFare,
        },
        title: driver.fullName,
        subtitle: '${widget.pickup} → ${widget.destination}',
        quantitySummary: _km > 0 ? '${_km.toStringAsFixed(1)} km · ${vt.name}' : vt.name,
        checkInLabel: 'PICKUP',
        checkInValue: widget.pickup,
        guestsLabel: 'CAPACITY',
        guestsValue: '${vt.capacity} Seat${vt.capacity > 1 ? 's' : ''}',
        serviceIcon: Icons.local_taxi_rounded,
        serviceLabel: 'Cab',
        accentColor: AppColors.warning,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final driver = widget.driver;
    final vt = driver.vehicleType;
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
                child: Row(children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(vt.icon, size: 24, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(driver.fullName,
                          style: AppTextStyles.h5.copyWith(color: Colors.white)),
                      const SizedBox(height: 2),
                      Row(children: [
                        Text(
                          '${driver.vehicleModel}  •  ${driver.vehicleColor}',
                          style: AppTextStyles.bodySm.copyWith(
                              color: Colors.white.withValues(alpha: 0.85)),
                        ),
                        if (driver.isVerified) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.verified_rounded,
                              size: 13,
                              color: Colors.white.withValues(alpha: 0.90)),
                        ],
                      ]),
                    ]),
                  ),
                  // Rating
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.star_rounded, size: 13, color: Colors.white),
                      const SizedBox(width: 3),
                      Text(driver.rating.toStringAsFixed(1),
                          style: AppTextStyles.labelSm.copyWith(
                              color: Colors.white, fontWeight: FontWeight.w700)),
                    ]),
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
                      child: Column(children: [
                        Row(children: [
                          const Icon(Icons.my_location_rounded,
                              size: 14, color: AppColors.warning),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('PICKUP', style: AppTextStyles.caption.copyWith(fontSize: 9, letterSpacing: 0.8)),
                              Text(widget.pickup,
                                  style: AppTextStyles.label.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ]),
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Column(
                            children: List.generate(3, (_) => Container(
                              width: 2, height: 5, margin: const EdgeInsets.symmetric(vertical: 2),
                              color: AppColors.borderLight,
                            )),
                          ),
                        ),
                        Row(children: [
                          const Icon(Icons.location_on_rounded,
                              size: 14, color: AppColors.error),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('DESTINATION', style: AppTextStyles.caption.copyWith(fontSize: 9, letterSpacing: 0.8)),
                              Text(widget.destination,
                                  style: AppTextStyles.label.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ]),
                      ]),
                    ),

                    const SizedBox(height: 12),

                    // Info tiles
                    Row(children: [
                      _InfoTile(icon: vt.icon, label: 'Type', value: vt.name),
                      const SizedBox(width: 10),
                      _InfoTile(
                          icon: Icons.people_outline_rounded,
                          label: 'Capacity',
                          value: '${vt.capacity} seat${vt.capacity > 1 ? 's' : ''}'),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      _InfoTile(
                          icon: Icons.timer_outlined,
                          label: 'ETA',
                          value: '~${vt.etaMinutes} min'),
                      const SizedBox(width: 10),
                      _InfoTile(
                          icon: Icons.route_rounded,
                          label: 'Per km',
                          value: '৳${vt.perKm.toStringAsFixed(0)}'),
                    ]),

                    const SizedBox(height: 18),
                    const Divider(height: 1, color: AppColors.borderLight),
                    const SizedBox(height: 16),

                    // ── Distance input ───────────────────────────────────
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Distance',
                        style: AppTextStyles.label.copyWith(
                            color: AppColors.primary, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _kmCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      cursorColor: AppColors.warning,
                      style: AppTextStyles.body.copyWith(color: AppColors.primary),
                      decoration: InputDecoration(
                        hintText: 'Enter distance in km',
                        hintStyle: AppTextStyles.caption,
                        prefixIcon: const Icon(Icons.route_rounded,
                            size: 18, color: AppColors.warning),
                        suffixText: 'km',
                        suffixStyle: AppTextStyles.label.copyWith(
                            color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.borderLight),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.warning, width: 1.5),
                        ),
                      ),
                      onChanged: (v) {
                        setState(() => _km = double.tryParse(v) ?? 0);
                      },
                    ),

                    const SizedBox(height: 16),

                    // ── Fare breakdown ───────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.25)),
                      ),
                      child: Column(children: [
                        _FareRow(
                          label: 'Base fare',
                          value: '৳ ${vt.baseFare.toStringAsFixed(0)}',
                        ),
                        const SizedBox(height: 8),
                        _FareRow(
                          label: '${_km > 0 ? _km.toStringAsFixed(1) : '0'} km × ৳${vt.perKm.toStringAsFixed(0)}/km',
                          value: '৳ ${(_km * vt.perKm).toStringAsFixed(0)}',
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(height: 1, color: AppColors.borderLight),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Estimated Total',
                              style: AppTextStyles.label.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '৳ ${_totalFare.toStringAsFixed(0)}',
                              style: AppTextStyles.price
                                  .copyWith(color: AppColors.warning),
                            ),
                          ],
                        ),
                      ]),
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
                            backgroundColor: AppColors.warning,
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
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Dialog helper ────────────────────────────────────────────────────────────

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

class _FareRow extends StatelessWidget {
  final String label;
  final String value;
  const _FareRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.caption.copyWith(
                  fontSize: 12, color: AppColors.textMuted)),
          Text(value,
              style: AppTextStyles.label.copyWith(color: AppColors.primary)),
        ],
      );
}
