import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'service_widgets.dart';

class HotelsContent extends StatefulWidget {
  const HotelsContent({super.key});
  @override
  State<HotelsContent> createState() => _HotelsContentState();
}

class _HotelsContentState extends State<HotelsContent> {
  String _type = 'All';

  static const _types = ['All', 'Hotel', 'Resort', 'Hostel', 'Apartment'];

  static const _hotels = [
    ('The Peninsula', "Cox's Bazar", 4.8, '৳ 8,500 / night', 5),
    ('Hotel Agrabad', 'Chittagong', 4.5, '৳ 5,200 / night', 4),
    ('Pan Pacific Sonargaon', 'Dhaka', 4.7, '৳ 12,000 / night', 5),
    ('Sayeman Beach Resort', "Cox's Bazar", 4.3, '৳ 6,800 / night', 4),
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
              SvField(label: 'Destination / City', value: "Cox's Bazar, Bangladesh", icon: Icons.location_on_rounded),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: SvField(label: 'Check-in', value: 'Jun 15, 2026', icon: Icons.calendar_month_rounded)),
                const SizedBox(width: 10),
                Expanded(child: SvField(label: 'Check-out', value: 'Jun 20, 2026', icon: Icons.calendar_month_rounded)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: SvField(label: 'Rooms', value: '1 Room', icon: Icons.meeting_room_rounded)),
                const SizedBox(width: 10),
                Expanded(child: SvField(label: 'Guests', value: '2 Adults', icon: Icons.people_rounded)),
              ]),
              const SizedBox(height: 14),
              SvButton(label: 'Search Hotels', onTap: () {}, color: AppColors.success),
            ]),
          ),
          const SizedBox(height: 24),
          const SvSectionTitle('Featured Hotels'),
          const SizedBox(height: 10),
          SvChipRow(
            options: _types,
            selected: _type,
            onChanged: (v) => setState(() => _type = v),
            accentColor: AppColors.success,
          ),
          const SizedBox(height: 14),
          ..._hotels.map(
            (h) => _HotelCard(name: h.$1, location: h.$2, rating: h.$3, price: h.$4, stars: h.$5),
          ),
        ],
      ),
    );
  }
}

class _HotelCard extends StatelessWidget {
  final String name;
  final String location;
  final double rating;
  final String price;
  final int stars;
  const _HotelCard({
    required this.name,
    required this.location,
    required this.rating,
    required this.price,
    required this.stars,
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
            // Image placeholder
            Container(
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.success.withValues(alpha: 0.18), AppColors.secondary.withValues(alpha: 0.12)],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Stack(children: [
                const Center(child: Icon(Icons.hotel_rounded, size: 52, color: AppColors.success)),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(20)),
                    child: Row(children: [
                      const Icon(Icons.star_rounded, color: Colors.white, size: 13),
                      const SizedBox(width: 3),
                      Text(
                        rating.toStringAsFixed(1),
                        style: AppTextStyles.labelSm.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ]),
                  ),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: List.generate(stars, (_) => const Icon(Icons.star_rounded, size: 13, color: AppColors.warning))),
                const SizedBox(height: 5),
                Text(name, style: AppTextStyles.h6.copyWith(color: AppColors.primary)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on_rounded, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 3),
                  Text(location, style: AppTextStyles.caption),
                ]),
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(price, style: AppTextStyles.priceSm.copyWith(color: AppColors.success)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(10)),
                    child: Text('Book Now', style: AppTextStyles.btnSm.copyWith(color: Colors.white)),
                  ),
                ]),
              ]),
            ),
          ],
        ),
      );
}
