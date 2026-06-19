import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

String resolveSpotImage(dynamic rawImages) {
  if (rawImages == null) return '';

  // `images` is a jsonb array — grab the first entry.
  String? first;
  if (rawImages is List && rawImages.isNotEmpty) {
    first = rawImages.first?.toString();
  } else if (rawImages is String && rawImages.isNotEmpty) {
    first = rawImages; // fallback if it ever arrives as a plain string
  }
  if (first == null || first.isEmpty) return '';

  // Already a full URL? Use it directly.
  if (first.startsWith('http')) return first;

  // Otherwise it's a storage path. The first segment is the bucket,
  // everything after it is the object key.
  final slash = first.indexOf('/');
  if (slash == -1) {
    // No folder prefix (e.g. "boga-lake-1.jpg") -> assume tourist-spots bucket.
    return supabase.storage.from('tourist-spots').getPublicUrl(first);
  }
  final bucket = first.substring(0, slash); // "tourist-spots"
  final key = first.substring(slash + 1);   // "nilgiri-1.jpeg"
  return supabase.storage.from(bucket).getPublicUrl(key);
}

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchCtrl = TextEditingController();
  String _city = '';
  List<Map<String, dynamic>> _spots = [];
  bool _loading = false;
  String? _error;

  static const _popularCities = [
    "Cox's Bazar", 'Dhaka', 'Sylhet', 'Chittagong',
    'Bandarban', 'Rangamati', 'Sundarbans', 'Sreemangal',
  ];

  @override
  void initState() {
    super.initState();
    _fetchSpots();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchSpots() async {
    setState(() { _loading = true; _error = null; });
    try {
      var query = supabase.from('tourist_spots').select('*');
      if (_city.isNotEmpty) query = query.ilike('city', '%$_city%');
      final data = await query.order('name', ascending: true);
      if (mounted) setState(() => _spots = List<Map<String, dynamic>>.from(data));
    } on PostgrestException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to load spots: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _selectCity(String city) {
    final next = _city.toLowerCase() == city.toLowerCase() ? '' : city;
    setState(() {
      _city = next;
      _searchCtrl.text = next;
    });
    _fetchSpots();
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() => _city = '');
    _fetchSpots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: CustomScrollView(
        slivers: [
          // ── Header ───────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 190,
            pinned: true,
            backgroundColor: AppColors.primary,
            automaticallyImplyLeading: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Explore',
                            style: AppTextStyles.h3.copyWith(color: Colors.white)),
                        Text('Discover tourist spots across Bangladesh',
                            style: AppTextStyles.bodySm
                                .copyWith(color: Colors.white.withValues(alpha: 0.75))),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _searchCtrl,
                          onChanged: (v) => setState(() => _city = v),
                          onSubmitted: (_) => _fetchSpots(),
                          style: AppTextStyles.body.copyWith(color: AppColors.primary),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'Search by city...',
                            hintStyle: AppTextStyles.body
                                .copyWith(color: AppColors.textMuted, fontSize: 13),
                            prefixIcon: const Icon(Icons.search_rounded,
                                color: AppColors.textMuted, size: 20),
                            suffixIcon: _city.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded,
                                        size: 18, color: AppColors.textMuted),
                                    onPressed: _clearSearch,
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Popular cities chips ──────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Popular Cities',
                      style: AppTextStyles.label.copyWith(
                          color: AppColors.primary, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _popularCities.map((city) {
                        final active = _city.toLowerCase() == city.toLowerCase();
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => _selectCity(city),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: active ? AppColors.secondary : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: active
                                      ? AppColors.secondary
                                      : AppColors.borderLight,
                                ),
                                boxShadow: active
                                    ? const [
                                        BoxShadow(
                                            color: AppColors.shadow,
                                            blurRadius: 6,
                                            offset: Offset(0, 2))
                                      ]
                                    : null,
                              ),
                              child: Text(
                                city,
                                style: AppTextStyles.labelSm.copyWith(
                                  color: active ? Colors.white : AppColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Results header ────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _city.isEmpty ? 'All Spots' : 'Spots in $_city',
                    style: AppTextStyles.h5.copyWith(color: AppColors.primary),
                  ),
                  if (!_loading && _spots.isNotEmpty)
                    Text(
                      '${_spots.length} found',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.secondary, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────────
          if (_loading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(AppColors.secondary),
                    strokeWidth: 2.5),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(
                child: _ErrorView(message: _error!, onRetry: _fetchSpots))
          else if (_spots.isEmpty)
            SliverFillRemaining(child: _EmptyView(city: _city))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _SpotCard(spot: _spots[i]),
                  childCount: _spots.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.72,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Spot card ────────────────────────────────────────────────────────────────

class _SpotCard extends StatelessWidget {
  final Map<String, dynamic> spot;
  const _SpotCard({required this.spot});

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveSpotImage(spot['images']);
    final name = spot['name']?.toString() ?? spot['spot_name']?.toString() ?? 'Unknown';
    final city = spot['city']?.toString() ?? spot['location']?.toString() ?? '';
    final category = spot['category']?.toString() ?? '';
    final rating = (spot['rating'] as num?)?.toDouble();

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _SpotDetailSheet(spot: spot),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (_, child, progress) =>
                            progress == null ? child : _PlaceholderImage(),
                        errorBuilder: (context, error, stack) => _PlaceholderImage(),
                      )
                    : _PlaceholderImage(),
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: AppTextStyles.label.copyWith(
                          color: AppColors.primary, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (city.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(children: [
                      const Icon(Icons.location_on_rounded,
                          size: 11, color: AppColors.textMuted),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(city,
                            style: AppTextStyles.caption.copyWith(fontSize: 10),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (category.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(category,
                              style: AppTextStyles.caption.copyWith(
                                  fontSize: 9,
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w600)),
                        )
                      else
                        const SizedBox.shrink(),
                      if (rating != null)
                        Row(children: [
                          const Icon(Icons.star_rounded,
                              size: 11, color: AppColors.warning),
                          const SizedBox(width: 2),
                          Text(rating.toStringAsFixed(1),
                              style: AppTextStyles.caption.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary)),
                        ]),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Spot detail bottom sheet ─────────────────────────────────────────────────

class _SpotDetailSheet extends StatelessWidget {
  final Map<String, dynamic> spot;
  const _SpotDetailSheet({required this.spot});

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveSpotImage(spot['images']);
    final name = spot['name']?.toString() ?? spot['spot_name']?.toString() ?? 'Unknown';
    final city = spot['city']?.toString() ?? spot['location']?.toString() ?? '';
    final description =
        spot['description']?.toString() ?? spot['about']?.toString() ?? '';
    final category = spot['category']?.toString() ?? '';
    final rating = (spot['rating'] as num?)?.toDouble();

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      maxChildSize: 0.95,
      minChildSize: 0.45,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: scrollCtrl,
          padding: EdgeInsets.zero,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Image
            if (imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => _PlaceholderImage(height: 220),
              )
            else
              _PlaceholderImage(height: 220),

            // Details
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: AppTextStyles.h4.copyWith(color: AppColors.primary)),
                  const SizedBox(height: 8),
                  Row(children: [
                    if (city.isNotEmpty) ...[
                      const Icon(Icons.location_on_rounded,
                          size: 14, color: AppColors.secondary),
                      const SizedBox(width: 4),
                      Text(city,
                          style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(width: 12),
                    ],
                    if (rating != null) ...[
                      const Icon(Icons.star_rounded,
                          size: 14, color: AppColors.warning),
                      const SizedBox(width: 3),
                      Text(rating.toStringAsFixed(1),
                          style: AppTextStyles.bodySm.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary)),
                    ],
                    const Spacer(),
                    if (category.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(category,
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w600)),
                      ),
                  ]),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const Divider(color: AppColors.borderLight),
                    const SizedBox(height: 14),
                    Text('About',
                        style:
                            AppTextStyles.h6.copyWith(color: AppColors.primary)),
                    const SizedBox(height: 8),
                    Text(description,
                        style: AppTextStyles.body.copyWith(
                            color: AppColors.textMuted, height: 1.65)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _PlaceholderImage extends StatelessWidget {
  final double? height;
  const _PlaceholderImage({this.height});

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        width: double.infinity,
        color: AppColors.surfaceLight,
        child: const Center(
          child: Icon(Icons.image_rounded, size: 40, color: AppColors.borderLight),
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(message,
                style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              onPressed: onRetry,
              child: const Text('Try Again'),
            ),
          ]),
        ),
      );
}

class _EmptyView extends StatelessWidget {
  final String city;
  const _EmptyView({required this.city});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.explore_off_rounded,
                size: 64,
                color: AppColors.secondary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('No spots found',
                style: AppTextStyles.h5.copyWith(color: AppColors.primary)),
            const SizedBox(height: 8),
            Text(
              city.isEmpty
                  ? 'No tourist spots available.'
                  : 'No tourist spots found in $city.\nTry a different city.',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      );
}