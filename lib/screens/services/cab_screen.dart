import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'service_widgets.dart';

class CabContent extends StatefulWidget {
  const CabContent({super.key});
  @override
  State<CabContent> createState() => _CabContentState();
}

class _CabContentState extends State<CabContent> {
  String _cabType = 'Economy';
  bool _schedule = false;

  static const _cabTypes = [
    (Icons.directions_car_rounded, 'Economy', '৳ 50/km', '4 seats'),
    (Icons.car_rental_rounded, 'Comfort', '৳ 80/km', '4 seats'),
    (Icons.airport_shuttle_rounded, 'XL', '৳ 100/km', '7 seats'),
    (Icons.electric_rickshaw_rounded, 'Auto', '৳ 30/km', '3 seats'),
  ];

  static const _features = [
    (Icons.verified_rounded, 'Verified Drivers', 'All drivers are background-verified and trained.'),
    (Icons.security_rounded, 'Safe Rides', 'Real-time tracking and SOS button available.'),
    (Icons.price_check_rounded, 'Fixed Prices', 'No surge pricing — transparent fares always.'),
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
                options: const ['Ride Now', 'Schedule'],
                selected: _schedule ? 1 : 0,
                onChanged: (i) => setState(() => _schedule = i == 1),
                accentColor: AppColors.warning,
              ),
              const SizedBox(height: 14),
              SvField(label: 'Pickup Location', value: 'Gulshan 1, Dhaka', icon: Icons.my_location_rounded),
              const SizedBox(height: 10),
              SvField(label: 'Destination', value: 'Hazrat Shahjalal International Airport', icon: Icons.location_on_rounded),
              if (_schedule) ...[
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: SvField(label: 'Date', value: 'Jun 15, 2026', icon: Icons.calendar_month_rounded)),
                  const SizedBox(width: 10),
                  Expanded(child: SvField(label: 'Time', value: '10:30 AM', icon: Icons.access_time_rounded)),
                ]),
              ],
              const SizedBox(height: 14),
              const Divider(color: AppColors.borderLight),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select Cab Type',
                  style: AppTextStyles.label.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.3,
                children: _cabTypes.map((c) {
                  final active = _cabType == c.$2;
                  return GestureDetector(
                    onTap: () => setState(() => _cabType = c.$2),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: active ? AppColors.warning.withValues(alpha: 0.10) : AppColors.surfaceLight,
                        border: Border.all(color: active ? AppColors.warning : AppColors.borderLight, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        Icon(c.$1, size: 20, color: active ? AppColors.warning : AppColors.textMuted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                c.$2,
                                style: AppTextStyles.label.copyWith(
                                  color: active ? AppColors.primary : AppColors.textMuted,
                                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                              Text(c.$3, style: AppTextStyles.caption.copyWith(fontSize: 10)),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              SvButton(label: 'Book Cab', onTap: () {}, color: AppColors.warning),
            ]),
          ),
          const SizedBox(height: 24),
          const SvSectionTitle('Why TravelMeta Cabs?'),
          const SizedBox(height: 12),
          ..._features.map((f) => _FeatureRow(icon: f.$1, title: f.$2, description: f.$3)),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  const _FeatureRow({required this.icon, required this.title, required this.description});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 3))],
        ),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: AppColors.warning),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: AppTextStyles.label.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(description, style: AppTextStyles.caption),
            ]),
          ),
        ]),
      );
}
