import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'service_widgets.dart';

class GuideContent extends StatefulWidget {
  const GuideContent({super.key});
  @override
  State<GuideContent> createState() => _GuideContentState();
}

class _GuideContentState extends State<GuideContent> {
  String _category = 'All';

  static const _categories = ['All', 'Beaches', 'Mountains', 'Heritage', 'Nature', 'Food'];

  static const _attractions = [
    (Icons.beach_access_rounded, "Cox's Bazar Beach", "Cox's Bazar", '4.9', 'Beaches', "World's longest natural sea beach."),
    (Icons.castle_rounded, 'Lalbagh Fort', 'Dhaka', '4.6', 'Heritage', '17th-century Mughal fort complex.'),
    (Icons.forest_rounded, 'Sundarbans', 'Khulna', '4.8', 'Nature', 'Largest mangrove forest in the world.'),
    (Icons.landscape_rounded, 'Nilgiri Hills', 'Bandarban', '4.7', 'Mountains', 'Highest peak accessible by road.'),
    (Icons.local_cafe_rounded, 'Srimangal Tea Estate', 'Sylhet', '4.5', 'Food', 'Tea capital of Bangladesh.'),
    (Icons.mosque_rounded, 'Sixty Dome Mosque', 'Bagerhat', '4.8', 'Heritage', 'UNESCO World Heritage Site.'),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _category == 'All'
        ? _attractions.toList()
        : _attractions.where((a) => a.$5 == _category).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvCard(
            child: Column(children: [
              SvField(label: 'Search Attractions', value: "Cox's Bazar", icon: Icons.search_rounded),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: SvField(label: 'Travel Date', value: 'Jun 15, 2026', icon: Icons.calendar_month_rounded)),
                const SizedBox(width: 10),
                Expanded(child: SvField(label: 'Group Size', value: '2 People', icon: Icons.people_rounded)),
              ]),
              const SizedBox(height: 14),
              SvButton(label: 'Find Attractions', onTap: () {}, color: AppColors.secondary),
            ]),
          ),
          const SizedBox(height: 24),
          const SvSectionTitle('Top Attractions'),
          const SizedBox(height: 10),
          SvChipRow(
            options: _categories,
            selected: _category,
            onChanged: (v) => setState(() => _category = v),
            accentColor: AppColors.secondary,
          ),
          const SizedBox(height: 14),
          if (filtered.isEmpty)
            _EmptyState(category: _category)
          else
            ...filtered.map(
              (a) => _AttractionCard(
                icon: a.$1,
                name: a.$2,
                location: a.$3,
                rating: a.$4,
                description: a.$6,
              ),
            ),
        ],
      ),
    );
  }
}

class _AttractionCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final String location;
  final String rating;
  final String description;
  const _AttractionCard({
    required this.icon,
    required this.name,
    required this.location,
    required this.rating,
    required this.description,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 3))],
        ),
        child: Row(children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.secondary, AppColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: AppTextStyles.label.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Row(children: [
                const Icon(Icons.location_on_rounded, size: 12, color: AppColors.textMuted),
                const SizedBox(width: 3),
                Text(location, style: AppTextStyles.caption),
              ]),
              const SizedBox(height: 4),
              Text(description, style: AppTextStyles.caption.copyWith(fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
            ]),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              const Icon(Icons.star_rounded, size: 12, color: AppColors.warning),
              const SizedBox(width: 3),
              Text(rating, style: AppTextStyles.labelSm.copyWith(color: AppColors.warning, fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
      );
}

class _EmptyState extends StatelessWidget {
  final String category;
  const _EmptyState({required this.category});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Center(
          child: Column(children: [
            const Icon(Icons.explore_off_rounded, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text('No $category attractions found', style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
          ]),
        ),
      );
}
