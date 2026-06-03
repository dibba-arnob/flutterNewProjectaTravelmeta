import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'service_widgets.dart';

class BusContent extends StatefulWidget {
  const BusContent({super.key});
  @override
  State<BusContent> createState() => _BusContentState();
}

class _BusContentState extends State<BusContent> {
  String _from = 'Dhaka';
  String _to = 'Chittagong';
  String _seatType = 'AC';

  static const _seatTypes = ['All', 'AC', 'Non-AC', 'Sleeper', 'Volvo'];

  static const _routes = [
    ('Dhaka', 'Chittagong', '5h 30m', '৳ 700'),
    ('Dhaka', 'Sylhet', '4h 00m', '৳ 650'),
    ('Dhaka', 'Rajshahi', '6h 00m', '৳ 750'),
    ("Cox's Bazar", 'Chittagong', '3h 00m', '৳ 450'),
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
              SvSwapRow(
                from: _from,
                to: _to,
                fromIcon: Icons.directions_bus_rounded,
                toIcon: Icons.location_on_rounded,
                onSwap: () => setState(() {
                  final t = _from;
                  _from = _to;
                  _to = t;
                }),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: SvField(label: 'Travel Date', value: 'Jun 15, 2026', icon: Icons.calendar_month_rounded)),
                const SizedBox(width: 10),
                Expanded(child: SvField(label: 'Passengers', value: '1 Seat', icon: Icons.person_outline_rounded)),
              ]),
              const SizedBox(height: 12),
              SvChipRow(
                options: _seatTypes,
                selected: _seatType,
                onChanged: (v) => setState(() => _seatType = v),
                accentColor: AppColors.warning,
              ),
              const SizedBox(height: 14),
              SvButton(label: 'Search Buses', onTap: () {}, color: AppColors.warning),
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
                icon: Icons.directions_bus_rounded,
                accentColor: AppColors.warning,
              )),
        ],
      ),
    );
  }
}
