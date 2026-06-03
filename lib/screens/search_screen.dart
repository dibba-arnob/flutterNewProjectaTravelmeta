import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

// ─── Data model (swap _mockData list with real DB results later) ──────────────

class _SearchItem {
  final String name;
  final String subtitle;
  final String category;
  final double rating;
  final int price;
  final List<Color> gradientColors;
  final IconData icon;

  const _SearchItem({
    required this.name,
    required this.subtitle,
    required this.category,
    required this.rating,
    required this.price,
    required this.gradientColors,
    required this.icon,
  });
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();

  String _query = '';
  String _category = 'All';
  RangeValues _priceRange = const RangeValues(0, 2000);
  int _minRating = 0;
  bool _filtersOpen = false;

  static const _categories = [
    'All',
    'Places',
    'Hotels',
    'Flights',
    'Bus',
    'Packages',
  ];

  // Replace this list with a DB/API call in _loadResults()
  static const _mockData = [
    _SearchItem(
      name: 'Bali, Indonesia',
      subtitle: 'Tropical paradise with stunning rice terraces and beaches',
      category: 'Places',
      rating: 4.8,
      price: 240,
      gradientColors: [Color(0xFF166534), Color(0xFF4ADE80)],
      icon: Icons.beach_access_rounded,
    ),
    _SearchItem(
      name: 'Kyoto, Japan',
      subtitle: 'Ancient temples, cherry blossoms and serene gardens',
      category: 'Places',
      rating: 4.9,
      price: 310,
      gradientColors: [Color(0xFF831843), Color(0xFFF472B6)],
      icon: Icons.temple_buddhist_rounded,
    ),
    _SearchItem(
      name: 'Paris, France',
      subtitle: 'The city of love, art and the Eiffel Tower',
      category: 'Places',
      rating: 4.7,
      price: 420,
      gradientColors: [Color(0xFF1E3A5F), Color(0xFF93C5FD)],
      icon: Icons.location_city_rounded,
    ),
    _SearchItem(
      name: 'Swiss Alps Retreat',
      subtitle: 'Zermatt, Switzerland — alpine luxury',
      category: 'Hotels',
      rating: 4.6,
      price: 180,
      gradientColors: [Color(0xFF1E3A5F), Color(0xFF708090)],
      icon: Icons.landscape_rounded,
    ),
    _SearchItem(
      name: 'Marina Bay Suite',
      subtitle: 'Dubai, UAE — skyline views and world-class amenities',
      category: 'Hotels',
      rating: 4.7,
      price: 350,
      gradientColors: [Color(0xFF0C4A6E), Color(0xFF38BDF8)],
      icon: Icons.location_city_rounded,
    ),
    _SearchItem(
      name: 'Ubud Nature Villa',
      subtitle: 'Bali, Indonesia — jungle hideaway with private pool',
      category: 'Hotels',
      rating: 4.8,
      price: 240,
      gradientColors: [Color(0xFF166534), Color(0xFF86EFAC)],
      icon: Icons.forest_rounded,
    ),
    _SearchItem(
      name: 'Dhaka → Dubai',
      subtitle: 'Direct flight · ~6h · Economy from \$280',
      category: 'Flights',
      rating: 4.3,
      price: 280,
      gradientColors: [AppColors.primary, AppColors.secondary],
      icon: Icons.flight_takeoff_rounded,
    ),
    _SearchItem(
      name: 'Dhaka → London',
      subtitle: '1 stop · ~11h · Economy from \$620',
      category: 'Flights',
      rating: 4.1,
      price: 620,
      gradientColors: [Color(0xFF312E81), Color(0xFF818CF8)],
      icon: Icons.flight_rounded,
    ),
    _SearchItem(
      name: 'Dhaka City Bus Pass',
      subtitle: 'All-day metro bus pass · Unlimited rides',
      category: 'Bus',
      rating: 3.9,
      price: 5,
      gradientColors: [Color(0xFF92400E), Color(0xFFFBBF24)],
      icon: Icons.directions_bus_rounded,
    ),
    _SearchItem(
      name: 'Bali Explorer Package',
      subtitle: '7 nights · Hotel + flights + guided tours',
      category: 'Packages',
      rating: 4.8,
      price: 1299,
      gradientColors: [Color(0xFF065F46), Color(0xFF34D399)],
      icon: Icons.luggage_rounded,
    ),
    _SearchItem(
      name: 'Tokyo Adventure Pack',
      subtitle: '10 nights · Hotel + flights + JR Pass',
      category: 'Packages',
      rating: 4.9,
      price: 1850,
      gradientColors: [Color(0xFF831843), Color(0xFFFDA4AF)],
      icon: Icons.luggage_rounded,
    ),
    _SearchItem(
      name: 'Maldives Getaway',
      subtitle: 'Overwater bungalow · 5 nights all-inclusive',
      category: 'Packages',
      rating: 5.0,
      price: 2500,
      gradientColors: [Color(0xFF0C4A6E), Color(0xFF7DD3FC)],
      icon: Icons.water_rounded,
    ),
  ];

  // ── Filtering logic — replace with DB query when ready ────────────────────
  List<_SearchItem> get _results {
    if (_query.trim().isEmpty) return [];
    final q = _query.toLowerCase();
    return _mockData.where((item) {
      final matchQuery = item.name.toLowerCase().contains(q) ||
          item.subtitle.toLowerCase().contains(q);
      final matchCat = _category == 'All' || item.category == _category;
      final matchPrice =
          item.price >= _priceRange.start && item.price <= _priceRange.end;
      final matchRating = item.rating >= _minRating;
      return matchQuery && matchCat && matchPrice && matchRating;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _ctrl.clear();
    setState(() => _query = '');
  }

  void _setQuery(String q) {
    _ctrl.text = q;
    _ctrl.selection = TextSelection.collapsed(offset: q.length);
    setState(() => _query = q);
  }

  String get _priceLabel =>
      '\$${_priceRange.start.toInt()} – \$${_priceRange.end.toInt()}';

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildCategoryChips(),
            // FIX: AnimatedSize needs mainAxisSize.min in the child Column
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeInOut,
              child: _filtersOpen
                  ? _buildFilterPanel()
                  : const SizedBox.shrink(),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ─── Top bar ──────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    // FIX: Theme override removes the global minHeight:52 constraint that
    // caused "RenderBox overflowed" inside our 50-px search field container.
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(4, 10, 12, 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: AppColors.primary,
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(
                inputDecorationTheme:
                    Theme.of(context).inputDecorationTheme.copyWith(
                          constraints: const BoxConstraints(),
                        ),
              ),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        focusNode: _focusNode,
                        onChanged: (v) => setState(() => _query = v),
                        textAlignVertical: TextAlignVertical.center,
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.textLight),
                        decoration: InputDecoration(
                          hintText: 'Search destinations, hotels...',
                          hintStyle: AppTextStyles.body
                              .copyWith(color: AppColors.textMuted),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 0),
                          filled: false,
                        ),
                        textInputAction: TextInputAction.search,
                        cursorColor: AppColors.secondary,
                      ),
                    ),
                    if (_query.isNotEmpty)
                      GestureDetector(
                        onTap: _clearSearch,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _filtersOpen = !_filtersOpen),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _filtersOpen
                    ? AppColors.secondary
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.tune_rounded,
                size: 20,
                color: _filtersOpen ? Colors.white : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Category chips ───────────────────────────────────────────────────────

  Widget _buildCategoryChips() {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.borderLight.withValues(alpha: 0.6),
          ),
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final active = _categories[i] == _category;
                return GestureDetector(
                  onTap: () => setState(() => _category = _categories[i]),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _categories[i],
                      style: AppTextStyles.labelSm.copyWith(
                        color: active ? Colors.white : AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Filter panel ─────────────────────────────────────────────────────────

  Widget _buildFilterPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        // FIX: MainAxisSize.min so AnimatedSize can measure the intrinsic height
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 16),
          // Price range
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Price Range',
                style: AppTextStyles.label
                    .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
              Text(
                _priceLabel,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.secondary,
              inactiveTrackColor: AppColors.borderLight,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.secondary.withValues(alpha: 0.12),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              rangeThumbShape:
                  const RoundRangeSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: RangeSlider(
              values: _priceRange,
              min: 0,
              max: 2000,
              divisions: 40,
              onChanged: (v) => setState(() => _priceRange = v),
            ),
          ),
          const SizedBox(height: 8),
          // Minimum rating
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Minimum Rating',
                style: AppTextStyles.label
                    .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
              if (_minRating > 0)
                GestureDetector(
                  onTap: () => setState(() => _minRating = 0),
                  child: Text(
                    'Clear',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (i) {
              final star = i + 1;
              final filled = star <= _minRating;
              return GestureDetector(
                onTap: () =>
                    setState(() => _minRating = _minRating == star ? 0 : star),
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 28,
                    color: filled
                        ? AppColors.warning
                        : AppColors.borderLight,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () => setState(() => _filtersOpen = false),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Apply Filters',
                style: AppTextStyles.btnSm.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Body ─────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_query.trim().isEmpty) return _buildIdleWatermark();
    final results = _results;
    if (results.isEmpty) return _buildNoResultsWatermark();
    return _buildResultsList(results);
  }

  Widget _buildIdleWatermark() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: Color(0xFFE0F2FE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.travel_explore_rounded,
                size: 48,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Explore TravelMeta',
              style: AppTextStyles.h4.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 10),
            Text(
              'Search for destinations, hotels, flights, bus routes and travel packages.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.textMuted,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _SuggestionChip('Bali', onTap: () => _setQuery('Bali')),
                _SuggestionChip('Kyoto', onTap: () => _setQuery('Kyoto')),
                _SuggestionChip('Dubai Hotel',
                    onTap: () => _setQuery('Dubai Hotel')),
                _SuggestionChip('Paris', onTap: () => _setQuery('Paris')),
                _SuggestionChip('Maldives',
                    onTap: () => _setQuery('Maldives')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsWatermark() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'No results found',
              style: AppTextStyles.h4.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 10),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.textMuted,
                  height: 1.6,
                ),
                children: [
                  const TextSpan(text: 'No matches for '),
                  TextSpan(
                    text: '"$_query"',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      fontFamily: AppTextStyles.bodySm.fontFamily,
                    ),
                  ),
                  const TextSpan(
                    text:
                        '.\nTry different keywords or adjust your filters.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                _clearSearch();
                setState(() {
                  _category = 'All';
                  _priceRange = const RangeValues(0, 2000);
                  _minRating = 0;
                });
              },
              child: Text(
                'Clear search & filters',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(List<_SearchItem> items) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _ResultCard(item: items[i]),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _SuggestionChip(this.label, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.north_west_rounded,
              size: 12,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.textLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final _SearchItem item;
  const _ResultCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(13),
                bottomLeft: Radius.circular(13),
              ),
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: item.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  item.icon,
                  size: 36,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.category,
                            style: AppTextStyles.labelSm.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          item.rating.toStringAsFixed(1),
                          style: AppTextStyles.captionMd
                              .copyWith(color: AppColors.primary),
                        ),
                        const Spacer(),
                        Text(
                          'from ',
                          style: AppTextStyles.caption,
                        ),
                        Text(
                          '\$${item.price}',
                          style: AppTextStyles.price
                              .copyWith(color: AppColors.secondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
