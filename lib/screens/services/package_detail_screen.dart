import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

// ─── Storage helper ───────────────────────────────────────────────────────────

const _supabaseProjectUrl = 'https://hjggxlmsuxbdagvzwtys.supabase.co';

String? storageUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http')) return path;
  return '$_supabaseProjectUrl/storage/v1/object/public/$path';
}

// ─── Model ────────────────────────────────────────────────────────────────────

class TravelPackage {
  final String id;
  final String title;
  final String description;
  final String category;
  final int nights;
  final int days;
  final double price;
  final String currency;
  final double rating;
  final int reviewCount;
  final String? heroImage;
  final List<String> images;
  final List<String> included;
  final List<String> excluded;
  final List<Map<String, dynamic>> itinerary;
  final int maxGroupSize;
  final String agencyName;
  final bool agencyVerified;
  final double agencyRating;

  TravelPackage.fromJson(Map<String, dynamic> j)
      : id          = j['id'] as String? ?? '',
        title       = j['title'] as String? ?? 'Untitled Package',
        description = j['description'] as String? ?? '',
        category    = j['category'] as String? ?? 'General',
        nights      = (j['nights'] as num?)?.toInt() ?? 0,
        days        = (j['days'] as num?)?.toInt() ?? 0,
        price       = (j['price'] as num?)?.toDouble() ?? 0.0,
        currency    = j['currency'] as String? ?? 'BDT',
        rating      = (j['rating'] as num?)?.toDouble() ?? 0.0,
        reviewCount = (j['review_count'] as num?)?.toInt() ?? 0,
        heroImage   = j['hero_image'] as String?,
        images      = _parseStringList(j['images']),
        included    = _parseStringList(j['included']),
        excluded    = _parseStringList(j['excluded']),
        itinerary   = _parseItinerary(j['itinerary']),
        maxGroupSize = (j['max_group_size'] as num?)?.toInt() ?? 0,
        agencyName     = _agencyName(j['agencies']),
        agencyVerified = _agencyVerified(j['agencies']),
        agencyRating   = _agencyRating(j['agencies']);

  static List<String> _parseStringList(dynamic raw) {
    if (raw is List) return raw.map((e) => e?.toString() ?? '').toList();
    return [];
  }

  static List<Map<String, dynamic>> _parseItinerary(dynamic raw) {
    if (raw is List) {
      return raw.map((e) {
        if (e is Map) return Map<String, dynamic>.from(e);
        return <String, dynamic>{};
      }).toList();
    }
    if (raw is Map) {
      return raw.entries.map((entry) {
        final val = entry.value;
        return (val is Map)
            ? Map<String, dynamic>.from(val)
            : <String, dynamic>{'title': entry.key.toString()};
      }).toList();
    }
    return [];
  }

  // ── Agency helpers — try multiple column-name spellings ──
  static String _agencyName(dynamic a) {
    if (a is! Map) return 'Unknown Agency';
    return (a['name'] ?? a['agency_name'] ?? a['title'] ?? 'Unknown Agency')
        .toString();
  }

  static bool _agencyVerified(dynamic a) {
    if (a is! Map) return false;
    final v = a['is_verified'] ?? a['verified'] ?? a['isVerified'] ?? false;
    if (v is bool) return v;
    return v.toString().toLowerCase() == 'true';
  }

  static double _agencyRating(dynamic a) {
    if (a is! Map) return 0.0;
    final r = a['rating'] ?? a['agency_rating'] ?? a['score'] ?? 0;
    return (r as num?)?.toDouble() ?? 0.0;
  }

  String? get heroUrl => storageUrl(heroImage);

  String get duration =>
      '$nights ${nights == 1 ? 'Night' : 'Nights'} / $days ${days == 1 ? 'Day' : 'Days'}';

  String get formattedPrice {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
}

// ─── Color / icon helpers ─────────────────────────────────────────────────────

Color _categoryColor(String category) {
  switch (category.toLowerCase()) {
    case 'beach':      return AppColors.secondary;
    case 'adventure':  return AppColors.error;
    case 'cultural':   return AppColors.warning;
    case 'wildlife':   return AppColors.success;
    case 'hill track': return AppColors.primary;
    default:           return AppColors.success;
  }
}

IconData _includedIcon(String item) {
  final s = item.toLowerCase();
  if (s.contains('transport') || s.contains('transfer') || s.contains('bus') ||
      s.contains('car') || s.contains('jeep')) {
    return Icons.directions_bus_rounded;
  }
  if (s.contains('flight') || s.contains('air')) { return Icons.flight_rounded; }
  if (s.contains('boat') || s.contains('cruise') || s.contains('ship')) {
    return Icons.directions_boat_rounded;
  }
  if (s.contains('stay') || s.contains('hotel') || s.contains('accommodation') ||
      s.contains('resort') || s.contains('floating') || s.contains('guest')) {
    return Icons.hotel_rounded;
  }
  if (s.contains('meal') || s.contains('breakfast') || s.contains('lunch') ||
      s.contains('dinner') || s.contains('food') || s.contains('board')) {
    return Icons.restaurant_rounded;
  }
  if (s.contains('guide') || s.contains('tour')) { return Icons.tour_rounded; }
  if (s.contains('permit') || s.contains('entry') || s.contains('ticket')) {
    return Icons.confirmation_number_rounded;
  }
  if (s.contains('equipment') || s.contains('gear') || s.contains('trekking')) {
    return Icons.backpack_rounded;
  }
  if (s.contains('access') || s.contains('beach')) { return Icons.beach_access_rounded; }
  return Icons.check_circle_rounded;
}

String? _mealBadge(List<String> activities) {
  final text = activities.join(' ').toLowerCase();
  if (text.contains('full board') ||
      (text.contains('breakfast') && text.contains('lunch') && text.contains('dinner'))) {
    return 'Full Board';
  }
  if (text.contains('half board') ||
      (text.contains('breakfast') && text.contains('dinner'))) {
    return 'Half Board';
  }
  if (text.contains('dinner')) return 'Dinner Included';
  if (text.contains('breakfast')) return 'Breakfast';
  if (text.contains('lunch')) return 'Lunch';
  if (text.contains('meal')) return 'Meals Included';
  return null;
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class PackageDetailScreen extends StatefulWidget {
  final TravelPackage package;
  const PackageDetailScreen({super.key, required this.package});

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> {
  bool _isFavorited = false;

  void _openBookingSheet() {
    final pkg   = widget.package;
    final color = _categoryColor(pkg.category);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookingSheet(package: pkg, accentColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pkg = widget.package;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _BottomBar(pkg: pkg, onBook: _openBookingSheet),
      body: CustomScrollView(
        slivers: [
          // ── App bar ──────────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 260,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0.5,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(color: AppColors.shadow, blurRadius: 8)
                  ],
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.primary, size: 20),
              ),
            ),
            actions: [
              _CircleIconBtn(
                icon: Icons.share_outlined,
                onTap: () {},
              ),
              _CircleIconBtn(
                icon: _isFavorited
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                iconColor:
                    _isFavorited ? Colors.red : AppColors.primary,
                onTap: () =>
                    setState(() => _isFavorited = !_isFavorited),
              ),
              const SizedBox(width: 4),
            ],
            title: Text(
              pkg.title,
              style: AppTextStyles.label
                  .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _HeroSection(pkg: pkg),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoChips(pkg: pkg),
                _TitleSection(pkg: pkg),
                const _Divider(),
                if (pkg.included.isNotEmpty) ...[
                  _WhatIsIncluded(pkg: pkg),
                  const _Divider(),
                ],
                if (pkg.itinerary.isNotEmpty) ...[
                  _TravelItinerary(pkg: pkg),
                  const _Divider(),
                ],
                const _ReviewsSection(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero section ─────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final TravelPackage pkg;
  const _HeroSection({required this.pkg});

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      if (pkg.heroUrl != null)
        Image.network(
          pkg.heroUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, e, s) =>
              _GradPlaceholder(category: pkg.category),
        )
      else
        _GradPlaceholder(category: pkg.category),

      // Subtle bottom scrim
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black26],
            stops: [0.5, 1.0],
          ),
        ),
      ),

      // Rating badge
      Positioned(
        left: 14,
        bottom: 14,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
            const SizedBox(width: 4),
            Text(
              pkg.reviewCount > 0
                  ? '${pkg.rating.toStringAsFixed(1)} (${pkg.reviewCount} Reviews)'
                  : '${pkg.rating.toStringAsFixed(1)} Rating',
              style: AppTextStyles.labelSm.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ]),
        ),
      ),
    ]);
  }
}

class _GradPlaceholder extends StatelessWidget {
  final String category;
  const _GradPlaceholder({required this.category});

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(category);
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.30),
            color.withValues(alpha: 0.10),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Icon(Icons.landscape_rounded,
            size: 80, color: color.withValues(alpha: 0.40)),
      ),
    );
  }
}

// ─── Info chips ───────────────────────────────────────────────────────────────

class _InfoChips extends StatelessWidget {
  final TravelPackage pkg;
  const _InfoChips({required this.pkg});

  bool _hasAllMeals() {
    final text = pkg.included.join(' ').toLowerCase();
    return text.contains('meal') || text.contains('breakfast') ||
        text.contains('board');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _InfoChip(Icons.schedule_rounded, pkg.duration),
          if (_hasAllMeals())
            _InfoChip(Icons.all_inclusive_rounded, 'All-Inclusive'),
          if (pkg.maxGroupSize > 1)
            _InfoChip(Icons.group_rounded, 'Group Tour'),
          _InfoChip(Icons.explore_rounded, pkg.category),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.25)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: AppColors.secondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(
                color: AppColors.secondary, fontWeight: FontWeight.w600),
          ),
        ]),
      );
}

// ─── Title + description ──────────────────────────────────────────────────────

class _TitleSection extends StatelessWidget {
  final TravelPackage pkg;
  const _TitleSection({required this.pkg});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(pkg.title,
              style: AppTextStyles.h4.copyWith(color: AppColors.primary)),
          if (pkg.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              pkg.description,
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textMuted, height: 1.65),
            ),
          ],
        ]),
      );
}

// ─── What's Included ─────────────────────────────────────────────────────────

class _WhatIsIncluded extends StatelessWidget {
  final TravelPackage pkg;
  const _WhatIsIncluded({required this.pkg});

  @override
  Widget build(BuildContext context) {
    final items = pkg.included.take(8).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionHeader("What's Included"),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (_, i) => _IncludedCard(items[i]),
        ),
      ]),
    );
  }
}

class _IncludedCard extends StatelessWidget {
  final String item;
  const _IncludedCard(this.item);

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: const [
            BoxShadow(
                color: AppColors.shadow,
                blurRadius: 6,
                offset: Offset(0, 2))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_includedIcon(item),
                  size: 22, color: AppColors.secondary),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                item,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
}

// ─── Travel Itinerary ─────────────────────────────────────────────────────────

class _TravelItinerary extends StatefulWidget {
  final TravelPackage pkg;
  const _TravelItinerary({required this.pkg});

  @override
  State<_TravelItinerary> createState() => _TravelItineraryState();
}

class _TravelItineraryState extends State<_TravelItinerary> {
  bool _allExpanded = false;
  late Set<int> _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = {0};
  }

  void _toggleAll() {
    setState(() {
      _allExpanded = !_allExpanded;
      _expanded = _allExpanded
          ? Set.from(
              List.generate(widget.pkg.itinerary.length, (i) => i))
          : {};
    });
  }

  void _toggle(int i) => setState(() {
        if (_expanded.contains(i)) {
          _expanded.remove(i);
        } else {
          _expanded.add(i);
        }
      });

  @override
  Widget build(BuildContext context) {
    final items = widget.pkg.itinerary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _SectionHeader('Travel Itinerary'),
            GestureDetector(
              onTap: _toggleAll,
              child: Text(
                _allExpanded ? 'Collapse All' : 'Expand All',
                style: AppTextStyles.label
                    .copyWith(color: AppColors.secondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...items.asMap().entries.map((e) => _ItineraryItem(
              index: e.key,
              item: e.value,
              isExpanded: _expanded.contains(e.key),
              isLast: e.key == items.length - 1,
              onTap: () => _toggle(e.key),
            )),
      ]),
    );
  }
}

class _ItineraryItem extends StatelessWidget {
  final int index;
  final Map<String, dynamic> item;
  final bool isExpanded;
  final bool isLast;
  final VoidCallback onTap;

  const _ItineraryItem({
    required this.index,
    required this.item,
    required this.isExpanded,
    required this.isLast,
    required this.onTap,
  });

  List<String> get _acts {
    final raw = item['activities'];
    if (raw is List) return raw.map((e) => e?.toString() ?? '').toList();
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final title = item['title'] as String? ?? 'Day ${index + 1}';
    final acts  = _acts;
    final desc  = acts.join('. ');
    final meal  = _mealBadge(acts);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Timeline ──
          SizedBox(
            width: 32,
            child: Column(children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
                child: Center(
                  child: Text('${index + 1}',
                      style: AppTextStyles.labelSm.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppColors.borderLight,
                  ),
                ),
            ]),
          ),
          const SizedBox(width: 12),

          // ── Card ──
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                margin: EdgeInsets.only(bottom: isLast ? 0 : 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: const [
                    BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 4,
                        offset: Offset(0, 2))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: AppTextStyles.label.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),

                    // Expanded content
                    if (isExpanded) ...[
                      const Divider(height: 1, color: AppColors.borderLight),
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(14, 10, 14, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (desc.isNotEmpty) ...[
                              Text(
                                desc,
                                style: AppTextStyles.bodySm.copyWith(
                                    color: AppColors.textMuted,
                                    height: 1.55),
                              ),
                              const SizedBox(height: 10),
                            ],
                            Wrap(spacing: 6, runSpacing: 6, children: [
                              if (acts.isNotEmpty)
                                _Badge(
                                  '${acts.length} ${acts.length == 1 ? 'activity' : 'activities'}',
                                  AppColors.secondary
                                      .withValues(alpha: 0.10),
                                  AppColors.secondary,
                                ),
                              if (meal != null)
                                _Badge(
                                  meal,
                                  AppColors.warning
                                      .withValues(alpha: 0.10),
                                  AppColors.warning,
                                ),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  const _Badge(this.text, this.bg, this.fg);

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Text(text,
            style: AppTextStyles.caption.copyWith(
                color: fg, fontWeight: FontWeight.w600, fontSize: 11)),
      );
}

// ─── Reviews ──────────────────────────────────────────────────────────────────

const _mockReviews = [
  {
    'name': 'Ankur Rahman',
    'initials': 'AR',
    'rating': 5,
    'text':
        '"Unforgettable experience! The resort was top-notch and waking up above the clouds was magical. Highly recommended for couples."',
    'color': 0xFF10B981,
  },
  {
    'name': 'Fatema Khatun',
    'initials': 'FK',
    'rating': 4,
    'text':
        '"Very beautiful destination. The guides were professional and the food was excellent. Will visit again!"',
    'color': 0xFF0891B2,
  },
  {
    'name': 'Rahim Uddin',
    'initials': 'RU',
    'rating': 5,
    'text':
        '"The itinerary was perfectly planned. Every activity was a highlight. Bumpy jeep ride was worth it for the view!"',
    'color': 0xFFF59E0B,
  },
];

class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 0, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: _SectionHeader('Traveler Reviews'),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 165,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: 16),
                itemCount: _mockReviews.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _ReviewCard(_mockReviews[i]),
              ),
            ),
          ],
        ),
      );
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  const _ReviewCard(this.review);

  @override
  Widget build(BuildContext context) {
    final color = Color(review['color'] as int);
    final rating = review['rating'] as int;
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow,
              blurRadius: 6,
              offset: Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Reviewer header
        Row(children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Text(
              review['initials'] as String,
              style: AppTextStyles.label.copyWith(
                  color: color, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  review['name'] as String,
                  style: AppTextStyles.label.copyWith(
                      color: AppColors.primary, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 12,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Expanded(
          child: Text(
            review['text'] as String,
            style: AppTextStyles.caption.copyWith(height: 1.45),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
  }
}

// ─── Bottom bar ───────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final TravelPackage pkg;
  final VoidCallback onBook;
  const _BottomBar({required this.pkg, required this.onBook});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 16,
                offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(children: [
            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Per Person',
                    style:
                        AppTextStyles.caption.copyWith(fontSize: 10)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${pkg.currency} ',
                      style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700),
                    ),
                    Text(
                      pkg.formattedPrice,
                      style: AppTextStyles.priceLg
                          .copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 16),

            // Book Now button
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: onBook,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Book Now', style: AppTextStyles.btn),
                ),
              ),
            ),
          ]),
        ),
      );
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTextStyles.h5.copyWith(color: AppColors.primary));
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, color: AppColors.borderLight);
}

class _CircleIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;
  const _CircleIconBtn({
    required this.icon,
    required this.onTap,
    this.iconColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(color: AppColors.shadow, blurRadius: 6)
            ],
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
      );
}

// ─── Booking sheet ────────────────────────────────────────────────────────────

class _BookingSheet extends StatefulWidget {
  final TravelPackage package;
  final Color accentColor;
  const _BookingSheet({required this.package, required this.accentColor});

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();

  int       _travelers  = 1;
  DateTime? _travelDate;
  bool      _submitting = false;

  double get _totalPrice => widget.package.price * _travelers;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now  = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _travelDate = date);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_travelDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a travel date.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final ref = 'TM-PK-${DateTime.now().millisecondsSinceEpoch % 90000 + 10000}';
      await supabase.from('bookings').insert({
        'user_id': supabase.auth.currentUser?.id ?? '',
        'service_type': 'package',
        'reference_code': ref,
        'status': 'pending',
        'total_amount': _totalPrice,
        'currency': widget.package.currency,
        'details': {
          'package_id': widget.package.id,
          'package_title': widget.package.title,
          'travelers': _travelers,
          'contact_name': _nameCtrl.text.trim(),
          'contact_phone': _phoneCtrl.text.trim(),
          'category': widget.package.category,
        },
        'starts_at': _travelDate!.toIso8601String(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking confirmed! We\'ll contact you soon.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.message),
              backgroundColor: AppColors.error),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit booking.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.accentColor;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 16),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('Book Package',
                    style: AppTextStyles.h5
                        .copyWith(color: AppColors.primary)),
                Text(widget.package.title,
                    style: AppTextStyles.bodySm
                        .copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _nameCtrl,
                  decoration: _decor('Full Name',
                      Icons.person_rounded, color),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _phoneCtrl,
                  decoration: _decor(
                      'Phone Number', Icons.phone_rounded, color),
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),

                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: AppColors.borderLight),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 18, color: color),
                      const SizedBox(width: 10),
                      Text(
                        _travelDate == null
                            ? 'Select Travel Date'
                            : '${_travelDate!.day}/${_travelDate!.month}/${_travelDate!.year}',
                        style: AppTextStyles.body.copyWith(
                          color: _travelDate == null
                              ? AppColors.textMuted
                              : AppColors.textLight,
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),

                Row(children: [
                  Text('Travelers', style: AppTextStyles.label),
                  const Spacer(),
                  IconButton(
                    onPressed: _travelers > 1
                        ? () => setState(() => _travelers--)
                        : null,
                    icon: const Icon(Icons.remove_circle_rounded),
                    color: color,
                  ),
                  Text('$_travelers',
                      style: AppTextStyles.h6
                          .copyWith(color: AppColors.primary)),
                  IconButton(
                    onPressed: _travelers <
                            (widget.package.maxGroupSize > 0
                                ? widget.package.maxGroupSize
                                : 20)
                        ? () => setState(() => _travelers++)
                        : null,
                    icon: const Icon(Icons.add_circle_rounded),
                    color: color,
                  ),
                ]),
                const SizedBox(height: 4),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Price',
                          style: AppTextStyles.label),
                      Text(
                        '${widget.package.currency} ${_totalPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                        style: AppTextStyles.price
                            .copyWith(color: color),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text('Confirm Booking',
                            style: AppTextStyles.btn),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decor(String label, IconData icon, Color color) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: color),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 14),
      );
}
