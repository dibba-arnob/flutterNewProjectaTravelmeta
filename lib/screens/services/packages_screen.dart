import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'service_widgets.dart';

class PackagesContent extends StatefulWidget {
  const PackagesContent({super.key});
  @override
  State<PackagesContent> createState() => _PackagesContentState();
}

class _PackagesContentState extends State<PackagesContent> {
  String _duration = 'All';

  static const _durations = ['All', 'Weekend', '3-5 Days', '1 Week', '2 Weeks'];

  static const _packages = [
    ("Cox's Bazar Beach Escape", "Cox's Bazar", '3 Days / 2 Nights', '৳ 8,500', 0),
    ('Sundarbans Mangrove Tour', 'Khulna', '2 Days / 1 Night', '৳ 5,200', 1),
    ('Sylhet Tea Garden Retreat', 'Sylhet', '4 Days / 3 Nights', '৳ 12,000', 2),
    ('Bandarban Hill Trekking', 'Bandarban', '5 Days / 4 Nights', '৳ 15,500', 3),
  ];

  static const _colors = [AppColors.secondary, AppColors.success, AppColors.warning, AppColors.primary];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvCard(
            child: Column(children: [
              SvField(label: 'Destination / Interest', value: "Cox's Bazar, Bangladesh", icon: Icons.explore_rounded),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: SvField(label: 'Travel Date', value: 'Jun 15, 2026', icon: Icons.calendar_month_rounded)),
                const SizedBox(width: 10),
                Expanded(child: SvField(label: 'Travelers', value: '2 Adults', icon: Icons.people_rounded)),
              ]),
              const SizedBox(height: 14),
              SvButton(label: 'Search Packages', onTap: () {}, color: AppColors.success),
            ]),
          ),
          const SizedBox(height: 24),
          const SvSectionTitle('Popular Packages'),
          const SizedBox(height: 10),
          SvChipRow(
            options: _durations,
            selected: _duration,
            onChanged: (v) => setState(() => _duration = v),
            accentColor: AppColors.success,
          ),
          const SizedBox(height: 14),
          ..._packages.map(
            (p) => _PackageCard(
              title: p.$1,
              location: p.$2,
              duration: p.$3,
              price: p.$4,
              color: _colors[p.$5],
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final String title;
  final String location;
  final String duration;
  final String price;
  final Color color;
  const _PackageCard({
    required this.title,
    required this.location,
    required this.duration,
    required this.price,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 14, offset: Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 130,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.20), color.withValues(alpha: 0.07)],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Stack(children: [
                Center(child: Icon(Icons.luggage_rounded, size: 50, color: color.withValues(alpha: 0.55))),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      duration,
                      style: AppTextStyles.labelSm.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: AppTextStyles.h6.copyWith(color: AppColors.primary)),
                const SizedBox(height: 5),
                Row(children: [
                  const Icon(Icons.location_on_rounded, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 3),
                  Text(location, style: AppTextStyles.caption),
                ]),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Starting from', style: AppTextStyles.caption.copyWith(fontSize: 10)),
                    Text(price, style: AppTextStyles.priceSm.copyWith(color: color)),
                  ]),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                    child: Text('View Details', style: AppTextStyles.btnSm.copyWith(color: Colors.white)),
                  ),
                ]),
              ]),
            ),
          ],
        ),
      );
}
