import 'dart:async';
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'explore_screen.dart';
import 'service_screens.dart';

// ─── Result model ─────────────────────────────────────────────────────────────

class _SearchResult {
  final String title;
  final String subtitle;
  final String category;
  final double? rating;
  final String? priceStr;
  final Map<String, dynamic> raw;

  const _SearchResult({
    required this.title,
    required this.subtitle,
    required this.category,
    this.rating,
    this.priceStr,
    required this.raw,
  });

  IconData get icon {
    switch (category) {
      case 'Places':   return Icons.landscape_rounded;
      case 'Packages': return Icons.card_travel_rounded;
      case 'Flights':  return Icons.flight_takeoff_rounded;
      case 'Bus':      return Icons.directions_bus_rounded;
      case 'Train':    return Icons.train_rounded;
      case 'Guides':   return Icons.person_pin_circle_rounded;
      default:         return Icons.search_rounded;
    }
  }

  Color get color {
    switch (category) {
      case 'Places':   return AppColors.secondary;
      case 'Packages': return const Color(0xFFEC4899);
      case 'Flights':  return AppColors.primary;
      case 'Bus':      return const Color(0xFF059669);
      case 'Train':    return const Color(0xFF7C3AED);
      case 'Guides':   return const Color(0xFFEF4444);
      default:         return AppColors.textMuted;
    }
  }
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
  int _minRating = 0;
  bool _filtersOpen = false;

  List<_SearchResult> _results = [];
  bool _loading = false;
  String? _searchError;
  Timer? _debounce;

  static const _categories = [
    'All', 'Places', 'Packages', 'Flights', 'Bus', 'Train', 'Guides',
  ];

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Search ────────────────────────────────────────────────────────────────

  void _onQueryChanged(String q) {
    setState(() { _query = q; _searchError = null; });
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() { _results = []; _loading = false; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 420), _search);
  }

  Future<void> _search() async {
    final q = _query.trim();
    if (q.isEmpty) return;
    setState(() { _loading = true; _searchError = null; });

    try {
      final futures = <Future<List<_SearchResult>>>[];
      final cat = _category;

      if (cat == 'All' || cat == 'Places')   futures.add(_searchSpots(q));
      if (cat == 'All' || cat == 'Packages') futures.add(_searchPackages(q));
      if (cat == 'All' || cat == 'Flights')  futures.add(_searchFlights(q));
      if (cat == 'All' || cat == 'Bus')      futures.add(_searchBus(q));
      if (cat == 'All' || cat == 'Train')    futures.add(_searchTrain(q));
      if (cat == 'All' || cat == 'Guides')   futures.add(_searchGuides(q));

      final lists = await Future.wait(futures);
      var all = lists.expand((l) => l).toList();

      if (_minRating > 0) {
        all = all
            .where((r) => r.rating != null && r.rating! >= _minRating)
            .toList();
      }

      if (mounted) setState(() { _results = all; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _searchError = 'Search failed. Try again.'; });
    }
  }

  // ── Per-table queries ─────────────────────────────────────────────────────

  Future<List<_SearchResult>> _searchSpots(String q) async {
    try {
      final data = await supabase
          .from('tourist_spots')
          .select('id, name, city, category, rating')
          .or('name.ilike.%$q%,city.ilike.%$q%')
          .limit(6);
      return (data as List).map((row) {
        final name = row['name']?.toString() ?? 'Unknown';
        final city = row['city']?.toString() ?? '';
        final cat  = row['category']?.toString() ?? '';
        return _SearchResult(
          title: name,
          subtitle: [city, cat].where((s) => s.isNotEmpty).join(' · '),
          category: 'Places',
          rating: (row['rating'] as num?)?.toDouble(),
          raw: Map<String, dynamic>.from(row as Map),
        );
      }).toList();
    } catch (_) { return []; }
  }

  Future<List<_SearchResult>> _searchPackages(String q) async {
    try {
      final data = await supabase
          .from('packages')
          .select('id, title, category, price, currency, rating')
          .ilike('title', '%$q%')
          .limit(6);
      return (data as List).map((row) {
        final currency = row['currency']?.toString() ?? 'BDT';
        final price    = (row['price'] as num?)?.toDouble();
        final sym      = currency == 'BDT' ? '৳' : currency;
        return _SearchResult(
          title:    row['title']?.toString() ?? 'Package',
          subtitle: row['category']?.toString() ?? '',
          category: 'Packages',
          rating:   (row['rating'] as num?)?.toDouble(),
          priceStr: price != null ? '$sym ${price.toStringAsFixed(0)}' : null,
          raw: Map<String, dynamic>.from(row as Map),
        );
      }).toList();
    } catch (_) { return []; }
  }

  Future<List<_SearchResult>> _searchFlights(String q) async {
    try {
      final data = await supabase
          .from('flights')
          .select('id, from_code, to_code, airline_name, base_price, currency, cabin_class')
          .or('from_code.ilike.%$q%,to_code.ilike.%$q%,airline_name.ilike.%$q%')
          .limit(6);
      return (data as List).map((row) {
        final from     = row['from_code']?.toString() ?? '';
        final to       = row['to_code']?.toString() ?? '';
        final airline  = row['airline_name']?.toString() ?? '';
        final cabin    = row['cabin_class']?.toString() ?? '';
        final price    = (row['base_price'] as num?)?.toDouble();
        final currency = row['currency']?.toString() ?? 'BDT';
        final sym      = currency == 'BDT' ? '৳' : '\$';
        return _SearchResult(
          title:    '$from → $to',
          subtitle: [airline, cabin].where((s) => s.isNotEmpty).join(' · '),
          category: 'Flights',
          priceStr: price != null ? '$sym ${price.toStringAsFixed(0)}' : null,
          raw: Map<String, dynamic>.from(row as Map),
        );
      }).toList();
    } catch (_) { return []; }
  }

  Future<List<_SearchResult>> _searchBus(String q) async {
    try {
      final data = await supabase
          .from('bus_trips')
          .select('id, from_city, to_city, fare, bus_operators(name)')
          .or('from_city.ilike.%$q%,to_city.ilike.%$q%')
          .limit(6);
      return (data as List).map((row) {
        final from     = row['from_city']?.toString() ?? '';
        final to       = row['to_city']?.toString() ?? '';
        final operator = (row['bus_operators'] as Map?)?['name']?.toString() ?? '';
        final fare     = (row['fare'] as num?)?.toDouble();
        return _SearchResult(
          title:    '$from → $to',
          subtitle: operator,
          category: 'Bus',
          priceStr: fare != null ? '৳ ${fare.toStringAsFixed(0)}' : null,
          raw: Map<String, dynamic>.from(row as Map),
        );
      }).toList();
    } catch (_) { return []; }
  }

  Future<List<_SearchResult>> _searchTrain(String q) async {
    try {
      final data = await supabase
          .from('train_schedules')
          .select('id, from_station, to_station, trains(name, number)')
          .or('from_station.ilike.%$q%,to_station.ilike.%$q%')
          .limit(6);
      return (data as List).map((row) {
        final from   = row['from_station']?.toString() ?? '';
        final to     = row['to_station']?.toString() ?? '';
        final trains = row['trains'] as Map?;
        final name   = trains?['name']?.toString() ?? '';
        final num    = trains?['number']?.toString() ?? '';
        return _SearchResult(
          title:    '$from → $to',
          subtitle: [name, num].where((s) => s.isNotEmpty).join(' · '),
          category: 'Train',
          raw: Map<String, dynamic>.from(row as Map),
        );
      }).toList();
    } catch (_) { return []; }
  }

  Future<List<_SearchResult>> _searchGuides(String q) async {
    try {
      final data = await supabase
          .from('guides')
          .select('id, name, city, rating, about')
          .or('name.ilike.%$q%,city.ilike.%$q%')
          .limit(6);
      return (data as List).map((row) {
        final name   = row['name']?.toString() ?? 'Guide';
        final city   = row['city']?.toString() ?? '';
        final about  = row['about']?.toString() ?? '';
        final teaser = about.length > 60 ? '${about.substring(0, 60)}…' : about;
        return _SearchResult(
          title:    name,
          subtitle: city.isNotEmpty ? city : teaser,
          category: 'Guides',
          rating:   (row['rating'] as num?)?.toDouble(),
          raw: Map<String, dynamic>.from(row as Map),
        );
      }).toList();
    } catch (_) { return []; }
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _onResultTap(_SearchResult r) {
    switch (r.category) {
      case 'Places':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ExploreScreen()));
      case 'Packages':
        ServiceNav.navigateTo(context, 5);
      case 'Flights':
        ServiceNav.navigateTo(context, 0);
      case 'Bus':
        ServiceNav.navigateTo(context, 2);
      case 'Train':
        ServiceNav.navigateTo(context, 3);
      case 'Guides':
        ServiceNav.navigateTo(context, 6);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _clearSearch() {
    _ctrl.clear();
    _debounce?.cancel();
    setState(() { _query = ''; _results = []; _loading = false; _searchError = null; });
  }

  void _setQuery(String q) {
    _ctrl.text = q;
    _ctrl.selection = TextSelection.collapsed(offset: q.length);
    _onQueryChanged(q);
  }

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
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeInOut,
              child: _filtersOpen ? _buildFilterPanel() : const SizedBox.shrink(),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ─── Top bar ──────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
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
                      child: Icon(Icons.search_rounded,
                          size: 20, color: AppColors.textMuted),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        focusNode: _focusNode,
                        onChanged: _onQueryChanged,
                        textAlignVertical: TextAlignVertical.center,
                        style: AppTextStyles.body.copyWith(color: AppColors.textLight),
                        decoration: InputDecoration(
                          hintText: 'Search places, flights, guides…',
                          hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          filled: false,
                        ),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _search(),
                        cursorColor: AppColors.secondary,
                      ),
                    ),
                    if (_query.isNotEmpty)
                      GestureDetector(
                        onTap: _clearSearch,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(Icons.close_rounded,
                              size: 18, color: AppColors.textMuted),
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
              child: Icon(Icons.tune_rounded,
                  size: 20,
                  color: _filtersOpen ? Colors.white : AppColors.textMuted),
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
          Divider(height: 1, thickness: 1,
              color: AppColors.borderLight.withValues(alpha: 0.6)),
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
                  onTap: () {
                    setState(() => _category = _categories[i]);
                    if (_query.trim().isNotEmpty) _search();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Minimum Rating',
                  style: AppTextStyles.label.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w700)),
              if (_minRating > 0)
                GestureDetector(
                  onTap: () { setState(() => _minRating = 0); if (_query.trim().isNotEmpty) _search(); },
                  child: Text('Clear',
                      style: AppTextStyles.label.copyWith(
                          color: AppColors.secondary, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (i) {
              final star   = i + 1;
              final filled = star <= _minRating;
              return GestureDetector(
                onTap: () {
                  setState(() => _minRating = _minRating == star ? 0 : star);
                  if (_query.trim().isNotEmpty) _search();
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 28,
                    color: filled ? AppColors.warning : AppColors.borderLight,
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
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Apply Filters',
                  style: AppTextStyles.btnSm.copyWith(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Body ─────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_query.trim().isEmpty) return _buildIdleView();
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.secondary),
            strokeWidth: 2.5),
      );
    }
    if (_searchError != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(_searchError!,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _search,
            child: Text('Retry',
                style: AppTextStyles.label.copyWith(
                    color: AppColors.secondary, fontWeight: FontWeight.w700)),
          ),
        ]),
      );
    }
    if (_results.isEmpty) return _buildNoResultsView();
    return _buildResultsList();
  }

  Widget _buildIdleView() {
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
              child: const Icon(Icons.travel_explore_rounded,
                  size: 48, color: AppColors.secondary),
            ),
            const SizedBox(height: 22),
            Text('Explore TravelMeta',
                style: AppTextStyles.h4.copyWith(color: AppColors.primary)),
            const SizedBox(height: 10),
            Text(
              'Search places, packages, flights,\nbus, train routes and tour guides.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySm
                  .copyWith(color: AppColors.textMuted, height: 1.6),
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _SuggestionChip('Cox\'s Bazar', onTap: () => _setQuery("Cox's Bazar")),
                _SuggestionChip('Sylhet',       onTap: () => _setQuery('Sylhet')),
                _SuggestionChip('Dhaka',        onTap: () => _setQuery('Dhaka')),
                _SuggestionChip('Bandarban',    onTap: () => _setQuery('Bandarban')),
                _SuggestionChip('Sundarbans',   onTap: () => _setQuery('Sundarbans')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsView() {
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
              child: const Icon(Icons.search_off_rounded,
                  size: 48, color: AppColors.error),
            ),
            const SizedBox(height: 22),
            Text('No results found',
                style: AppTextStyles.h4.copyWith(color: AppColors.primary)),
            const SizedBox(height: 10),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: AppTextStyles.bodySm
                    .copyWith(color: AppColors.textMuted, height: 1.6),
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
                  const TextSpan(text: '.\nTry different keywords or another category.'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                _clearSearch();
                setState(() { _category = 'All'; _minRating = 0; });
              },
              child: Text('Clear search & filters',
                  style: AppTextStyles.label.copyWith(
                      color: AppColors.secondary, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      itemCount: _results.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _ResultCard(
        result: _results[i],
        onTap: () => _onResultTap(_results[i]),
      ),
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
            BoxShadow(color: AppColors.shadow, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.north_west_rounded, size: 12, color: AppColors.textMuted),
            const SizedBox(width: 5),
            Text(label,
                style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.textLight, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final _SearchResult result;
  final VoidCallback onTap;
  const _ResultCard({required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = result;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: const [
            BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            // Icon thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(13),
                bottomLeft: Radius.circular(13),
              ),
              child: Container(
                width: 84,
                height: 84,
                color: r.color.withValues(alpha: 0.12),
                child: Icon(r.icon, size: 34, color: r.color),
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
                            r.title,
                            style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: r.color.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            r.category,
                            style: AppTextStyles.labelSm.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: r.color,
                                letterSpacing: 0.3),
                          ),
                        ),
                      ],
                    ),
                    if (r.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        r.subtitle,
                        style: AppTextStyles.labelSm
                            .copyWith(color: AppColors.textMuted, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (r.rating != null) ...[
                          const Icon(Icons.star_rounded,
                              size: 13, color: AppColors.warning),
                          const SizedBox(width: 3),
                          Text(
                            r.rating!.toStringAsFixed(1),
                            style: AppTextStyles.captionMd
                                .copyWith(color: AppColors.primary),
                          ),
                          const SizedBox(width: 8),
                        ],
                        const Spacer(),
                        if (r.priceStr != null)
                          Text(
                            r.priceStr!,
                            style: AppTextStyles.priceSm
                                .copyWith(color: r.color),
                          ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 12, color: AppColors.textMuted),
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
