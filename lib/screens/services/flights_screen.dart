import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'service_widgets.dart';

class FlightsContent extends StatefulWidget {
  const FlightsContent({super.key});
  @override
  State<FlightsContent> createState() => _FlightsContentState();
}

class _FlightsContentState extends State<FlightsContent> {
  bool _roundTrip = false;
  String _from = 'Dhaka (DAC)';
  String _to = "Cox's Bazar (CXB)";

  static const _routes = [
    ("Dhaka", "Cox's Bazar", '1h 05m', '৳ 4,500'),
    ('Dhaka', 'Chittagong', '45m', '৳ 3,800'),
    ('Dhaka', 'Sylhet', '40m', '৳ 3,200'),
    ('Chittagong', "Cox's Bazar", '35m', '৳ 2,900'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvCard(
            child: Column(children: [
              SvToggleBar(
                options: const ['One Way', 'Round Trip'],
                selected: _roundTrip ? 1 : 0,
                onChanged: (i) => setState(() => _roundTrip = i == 1),
              ),
              const SizedBox(height: 14),
              SvSwapRow(
                from: _from,
                to: _to,
                fromIcon: Icons.flight_takeoff_rounded,
                toIcon: Icons.flight_land_rounded,
                onSwap: () => setState(() {
                  final t = _from;
                  _from = _to;
                  _to = t;
                }),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: SvField(label: 'Departure', value: 'Jun 15, 2026', icon: Icons.calendar_month_rounded)),
                if (_roundTrip) ...[
                  const SizedBox(width: 10),
                  Expanded(child: SvField(label: 'Return', value: 'Jun 20, 2026', icon: Icons.calendar_month_rounded)),
                ],
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: SvField(label: 'Passengers', value: '1 Adult', icon: Icons.person_outline_rounded)),
                const SizedBox(width: 10),
                Expanded(child: SvField(label: 'Class', value: 'Economy', icon: Icons.airline_seat_recline_normal_rounded)),
              ]),
              const SizedBox(height: 14),
              SvButton(label: 'Search Flights', onTap: () {}, color: AppColors.secondary),
            ]),
          ),
          const SizedBox(height: 24),
          const SvSectionTitle('Popular Routes'),
          const SizedBox(height: 12),
          ..._routes.map((r) => SvRouteCard(
                from: r.$1,
                to: r.$2,
                meta: r.$3,
                price: r.$4,
                icon: Icons.flight_takeoff_rounded,
                accentColor: AppColors.secondary,
              )),
        ],
      ),
    );
  }
}
