import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'service_widgets.dart';

class TrainContent extends StatefulWidget {
  const TrainContent({super.key});
  @override
  State<TrainContent> createState() => _TrainContentState();
}

class _TrainContentState extends State<TrainContent> {
  String _from = 'Dhaka (Kamalapur)';
  String _to = 'Chittagong';
  String _class = '1st Class';

  static const _classes = ['S_CHAIR', 'SHOVAN', 'AC_CHAIR', '1st Class', 'Snigdha'];

  static const _trains = [
    ('Dhaka', 'Chittagong', 'Subarna Express', '৳ 385'),
    ('Dhaka', 'Sylhet', 'Parabat Express', '৳ 275'),
    ('Dhaka', 'Rajshahi', 'Silk City Express', '৳ 390'),
    ('Dhaka', 'Khulna', 'Sundarban Express', '৳ 430'),
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
                fromIcon: Icons.train_rounded,
                toIcon: Icons.location_on_rounded,
                onSwap: () => setState(() {
                  final t = _from;
                  _from = _to;
                  _to = t;
                }),
              ),
              const SizedBox(height: 12),
              SvField(label: 'Date of Journey', value: 'Jun 15, 2026', icon: Icons.calendar_month_rounded),
              const SizedBox(height: 12),
              SvChipRow(
                options: _classes,
                selected: _class,
                onChanged: (v) => setState(() => _class = v),
                accentColor: AppColors.primary,
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: SvField(label: 'Adult', value: '1', icon: Icons.person_outline_rounded)),
                const SizedBox(width: 10),
                Expanded(child: SvField(label: 'Child (below 12)', value: '0', icon: Icons.child_care_rounded)),
              ]),
              const SizedBox(height: 14),
              SvButton(label: 'Search Trains', onTap: () {}, color: AppColors.primary),
            ]),
          ),
          const SizedBox(height: 24),
          const SvSectionTitle('Popular Trains'),
          const SizedBox(height: 12),
          ..._trains.map((r) => SvRouteCard(
                from: r.$1,
                to: r.$2,
                meta: r.$3,
                price: r.$4,
                icon: Icons.train_rounded,
                accentColor: AppColors.primary,
              )),
        ],
      ),
    );
  }
}
