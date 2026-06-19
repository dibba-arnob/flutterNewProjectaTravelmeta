import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'service_widgets.dart';

// ─── Image URL resolver ───────────────────────────────────────────────────────
// NOTE: this is the same logic used in explore_screen.dart. If you'd rather not
// duplicate it, move these two functions into supabase_service.dart and import
// them in both screens.

/// Resolves every entry in an `images` jsonb value into a list of public URLs.
/// Handles full URLs, prefixed paths ("hotels/sonargaon/1.jpg") and bare paths.
List<String> resolveImageUrls(dynamic rawImages) {
  if (rawImages == null) return const [];

  final List<String> raws;
  if (rawImages is List) {
    raws = rawImages
        .map((e) => e?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
  } else if (rawImages is String && rawImages.isNotEmpty) {
    raws = [rawImages];
  } else {
    return const [];
  }
  return raws.map(_resolveOne).where((u) => u.isNotEmpty).toList();
}

String _resolveOne(String raw) {
  if (raw.startsWith('http')) return raw;
  final slash = raw.indexOf('/');
  if (slash == -1) {
    // Bare filename with no folder — assume the hotels bucket.
    return supabase.storage.from('hotels').getPublicUrl(raw);
  }
  final bucket = raw.substring(0, slash); // "hotels"
  final key = raw.substring(slash + 1);   // "sonargaon/1.jpg"
  return supabase.storage.from(bucket).getPublicUrl(key);
}

/// First image only (used for the card hero).
String resolveImageUrl(dynamic rawImages) {
  final all = resolveImageUrls(rawImages);
  return all.isEmpty ? '' : all.first;
}

/// Adds thousands separators: 12000 -> "12,000".
String _money(num value) {
  final s = value.toStringAsFixed(0);
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i != 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class HotelsContent extends StatefulWidget {
  const HotelsContent({super.key});
  @override
  State<HotelsContent> createState() => _HotelsContentState();
}

class _HotelsContentState extends State<HotelsContent> {
  String _type = 'All';
  List<Map<String, dynamic>> _hotels = [];
  bool _loading = false;
  String? _error;

  static const _types = ['All', 'Hotel', 'Resort', 'Hostel', 'Apartment'];

  @override
  void initState() {
    super.initState();
    _fetchHotels();
  }

  Future<void> _fetchHotels() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data =
          await supabase.from('hotels').select('*').order('name', ascending: true);
      if (mounted) setState(() => _hotels = List<Map<String, dynamic>>.from(data));
    } on PostgrestException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to load hotels: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_type == 'All') return _hotels;
    // The hotels table has no `type`/`category` column yet, so if none of the
    // rows carry one, don't filter (otherwise every chip would show nothing).
    final hasType = _hotels.any((h) => (h['type'] ?? h['category']) != null);
    if (!hasType) return _hotels;
    return _hotels.where((h) {
      final t = (h['type'] ?? h['category'] ?? '').toString().toLowerCase();
      return t == _type.toLowerCase();
    }).toList();
  }

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

          // ── Content states ──────────────────────────────────
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(AppColors.success),
                    strokeWidth: 2.5),
              ),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(children: [
                  const Icon(Icons.wifi_off_rounded, size: 44, color: AppColors.textMuted),
                  const SizedBox(height: 10),
                  Text(_error!,
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 14),
                  SvButton(label: 'Try Again', onTap: _fetchHotels, color: AppColors.success),
                ]),
              ),
            )
          else if (_filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text('No hotels found.',
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted)),
              ),
            )
          else
            ..._filtered.map((h) => _HotelCard(hotel: h)),
        ],
      ),
    );
  }
}

// ─── Hotel card ───────────────────────────────────────────────────────────────

class _HotelCard extends StatelessWidget {
  final Map<String, dynamic> hotel;
  const _HotelCard({required this.hotel});

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveImageUrl(hotel['images']);
    final name = hotel['name']?.toString() ?? hotel['hotel_name']?.toString() ?? 'Unknown';
    final location = hotel['city']?.toString() ?? hotel['location']?.toString() ?? '';
    final rating = (hotel['rating'] as num?)?.toDouble() ?? 0.0;

    // stars: prefer an explicit column, else fall back to the rounded rating.
    final starsRaw = hotel['stars'] ?? hotel['star_rating'] ?? hotel['star'];
    final stars = (starsRaw as num?)?.toInt() ?? rating.round();

    // price: numeric column -> "৳ 12,000 / night"
    final priceNum =
        (hotel['price_from'] ?? hotel['price_per_night'] ?? hotel['price']) as num?;
    final price = priceNum != null ? '৳ ${_money(priceNum)} / night' : '';

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _HotelDetailSheet(hotel: hotel),
      ),
      child: Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 14, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image (real photo, with rating badge overlay)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: SizedBox(
              height: 140,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, progress) =>
                              progress == null ? child : const _HotelImageFallback(),
                          errorBuilder: (_, __, ___) => const _HotelImageFallback(),
                        )
                      : const _HotelImageFallback(),
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
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (stars > 0)
                Row(children: List.generate(stars, (_) => const Icon(Icons.star_rounded, size: 13, color: AppColors.warning))),
              const SizedBox(height: 5),
              Text(name, style: AppTextStyles.h6.copyWith(color: AppColors.primary)),
              const SizedBox(height: 4),
              if (location.isNotEmpty)
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
      ),
    );
  }
}

// Gradient + icon fallback, shown while loading or if an image fails.
class _HotelImageFallback extends StatelessWidget {
  const _HotelImageFallback();

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.success.withValues(alpha: 0.18),
              AppColors.secondary.withValues(alpha: 0.12),
            ],
          ),
        ),
        child: const Center(
          child: Icon(Icons.hotel_rounded, size: 52, color: AppColors.success),
        ),
      );
}

// ─── Hotel detail bottom sheet ────────────────────────────────────────────────

class _HotelDetailSheet extends StatelessWidget {
  final Map<String, dynamic> hotel;
  const _HotelDetailSheet({required this.hotel});

  @override
  Widget build(BuildContext context) {
    final images = resolveImageUrls(hotel['images']); // ALL images
    final name = hotel['name']?.toString() ?? 'Unknown';
    final city = hotel['city']?.toString() ?? '';
    final address = hotel['address']?.toString() ?? '';
    final description = hotel['description']?.toString() ?? '';
    final rating = (hotel['rating'] as num?)?.toDouble() ?? 0.0;
    final reviewCount = (hotel['review_count'] as num?)?.toInt();
    final stars = (hotel['stars'] as num?)?.toInt() ?? rating.round();
    final priceNum = (hotel['price_from'] ?? hotel['price']) as num?;
    final price = priceNum != null ? '৳ ${_money(priceNum)} / night' : '';
    final freeCancellation = hotel['free_cancellation'] == true;

    final amenitiesRaw = hotel['amenities'];
    final amenities = amenitiesRaw is List
        ? amenitiesRaw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : <String>[];

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      maxChildSize: 0.95,
      minChildSize: 0.5,
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

            // Swipeable gallery (all images)
            _HotelGallery(images: images, height: 230),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (stars > 0)
                    Row(
                        children: List.generate(
                            stars,
                            (_) => const Icon(Icons.star_rounded,
                                size: 15, color: AppColors.warning))),
                  const SizedBox(height: 6),
                  Text(name, style: AppTextStyles.h4.copyWith(color: AppColors.primary)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(children: [
                        const Icon(Icons.star_rounded, color: Colors.white, size: 13),
                        const SizedBox(width: 3),
                        Text(rating.toStringAsFixed(1),
                            style: AppTextStyles.labelSm.copyWith(
                                color: Colors.white, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                    if (reviewCount != null) ...[
                      const SizedBox(width: 8),
                      Text('${_money(reviewCount)} reviews',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textMuted)),
                    ],
                  ]),
                  if (address.isNotEmpty || city.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.location_on_rounded,
                          size: 15, color: AppColors.secondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(address.isNotEmpty ? address : city,
                            style: AppTextStyles.bodySm
                                .copyWith(color: AppColors.textMuted)),
                      ),
                    ]),
                  ],
                  if (freeCancellation) ...[
                    const SizedBox(height: 10),
                    Row(children: [
                      const Icon(Icons.verified_rounded,
                          size: 15, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text('Free cancellation',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ],
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const Divider(color: AppColors.borderLight),
                    const SizedBox(height: 14),
                    Text('About',
                        style: AppTextStyles.h6.copyWith(color: AppColors.primary)),
                    const SizedBox(height: 8),
                    Text(description,
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.textMuted, height: 1.6)),
                  ],
                  if (amenities.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text('Amenities',
                        style: AppTextStyles.h6.copyWith(color: AppColors.primary)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: amenities
                          .map((a) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(a,
                                    style: AppTextStyles.caption
                                        .copyWith(color: AppColors.primary)),
                              ))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 22),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('From',
                                  style: AppTextStyles.caption
                                      .copyWith(color: AppColors.textMuted)),
                              Text(price,
                                  style: AppTextStyles.priceSm
                                      .copyWith(color: AppColors.success)),
                            ]),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 26, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('Book Now',
                              style: AppTextStyles.btnSm
                                  .copyWith(color: Colors.white)),
                        ),
                      ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Swipeable hotel gallery ──────────────────────────────────────────────────

class _HotelGallery extends StatefulWidget {
  final List<String> images;
  final double height;
  const _HotelGallery({required this.images, this.height = 230});

  @override
  State<_HotelGallery> createState() => _HotelGalleryState();
}

class _HotelGalleryState extends State<_HotelGallery> {
  final _controller = PageController();
  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return SizedBox(height: widget.height, child: const _HotelImageFallback());
    }

    final multiple = widget.images.length > 1;

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => Image.network(
              widget.images[i],
              height: widget.height,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : const _HotelImageFallback(),
              errorBuilder: (_, __, ___) => const _HotelImageFallback(),
            ),
          ),
          if (multiple)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${_current + 1}/${widget.images.length}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          if (multiple)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.images.length, (i) {
                  final active = i == _current;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}