import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'package_detail_screen.dart';
import 'service_widgets.dart';

class PackagesContent extends StatefulWidget {
  const PackagesContent({super.key});
  @override
  State<PackagesContent> createState() => _PackagesContentState();
}

class _PackagesContentState extends State<PackagesContent> {
  static const _categories = [
    'All', 'Beach', 'Adventure', 'Cultural',
    'Wildlife', 'Hill Track', 'City Tour',
  ];

  String _selectedCategory = 'All';
  List<TravelPackage> _packages = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;

    List<TravelPackage> newPackages = [];
    String? newError;

    try {
      var query = supabase.from('packages').select('*');
      if (_selectedCategory != 'All') {
        query = query.eq('category', _selectedCategory);
      }
      final rawData = await query;
      debugPrint('PACKAGES ROWS: ${rawData.length}');
      for (final row in rawData) {
        try {
          newPackages.add(TravelPackage.fromJson(Map<String, dynamic>.from(row as Map)));
        } catch (e) {
          debugPrint('Parse error: $e');
        }
      }
    } on PostgrestException catch (e) {
      debugPrint('PG ERROR: ${e.message}');
      newError = e.message;
    } catch (e) {
      debugPrint('LOAD ERROR: $e');
      newError = e.toString();
    }

    if (mounted) {
      setState(() {
        _packages = newPackages;
        _error = newError;
        _loading = false;
      });
    }
  }

  void _onCategoryChanged(String cat) {
    if (_selectedCategory == cat) return;
    setState(() {
      _selectedCategory = cat;
      _loading = true;
      _error = null;
      _packages = [];
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Category filter ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SvCard(
            child: SvChipRow(
              options: _categories,
              selected: _selectedCategory,
              onChanged: _onCategoryChanged,
              accentColor: AppColors.secondary,
            ),
          ),
        ),

        // ── Body ─────────────────────────────────────────────────────────
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.secondary),
      );
    }
    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _load);
    }
    if (_packages.isEmpty) {
      return _EmptyState(category: _selectedCategory);
    }

    return RefreshIndicator(
      color: AppColors.secondary,
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedCategory == 'All'
                        ? 'All Packages'
                        : '$_selectedCategory Packages',
                    style: AppTextStyles.h5.copyWith(color: AppColors.primary),
                  ),
                  Text(
                    '${_packages.length} found',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            // Cards
            ..._packages.map((pkg) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _PackageCard(
                package: pkg,
                onViewDetails: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PackageDetailScreen(package: pkg),
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

// ─── Package card ─────────────────────────────────────────────────────────────

Color _catColor(String cat) {
  switch (cat.toLowerCase()) {
    case 'beach':      return AppColors.secondary;
    case 'adventure':  return AppColors.error;
    case 'cultural':   return AppColors.warning;
    case 'wildlife':   return AppColors.success;
    case 'hill track': return AppColors.primary;
    default:           return AppColors.success;
  }
}

class _PackageCard extends StatelessWidget {
  final TravelPackage package;
  final VoidCallback onViewDetails;
  const _PackageCard({required this.package, required this.onViewDetails});

  @override
  Widget build(BuildContext context) {
    final pkg   = package;
    final color = _catColor(pkg.category);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow,
              blurRadius: 14,
              offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Hero image ─────────────────────────────────────────────────
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(18)),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: Stack(fit: StackFit.expand, children: [
                // Background: image or gradient
                if (pkg.heroUrl != null)
                  Image.network(
                    pkg.heroUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (ctx, child, progress) {
                      if (progress == null) return child;
                      return _GradBg(color: color);
                    },
                    errorBuilder: (ctx, e, s) => _GradBg(color: color),
                  )
                else
                  _GradBg(color: color),

                // Duration badge
                Positioned(
                  top: 10,
                  left: 10,
                  child: _HeroBadge(pkg.duration),
                ),

                // Rating badge
                Positioned(
                  top: 10,
                  right: 10,
                  child: _HeroBadge(
                    '★ ${pkg.rating.toStringAsFixed(1)}',
                  ),
                ),
              ]),
            ),
          ),

          // ── Info ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Category chip
                _CategoryBadge(label: pkg.category, color: color),
                const SizedBox(height: 6),

                // Title
                Text(
                  pkg.title,
                  style: AppTextStyles.h6
                      .copyWith(color: AppColors.primary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Agency
                Row(children: [
                  const Icon(Icons.business_rounded,
                      size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      pkg.agencyName,
                      style: AppTextStyles.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (pkg.agencyVerified) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified_rounded,
                        size: 13, color: AppColors.success),
                  ],
                ]),

                const SizedBox(height: 14),

                // Price row + button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Starting from',
                            style: AppTextStyles.caption
                                .copyWith(fontSize: 10)),
                        Text(
                          '${pkg.currency} ${pkg.formattedPrice}',
                          style: AppTextStyles.priceSm
                              .copyWith(color: color),
                        ),
                        Text('per person',
                            style: AppTextStyles.caption
                                .copyWith(fontSize: 10)),
                      ],
                    ),
                    GestureDetector(
                      onTap: onViewDetails,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'View Details',
                          style: AppTextStyles.btnSm
                              .copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Small sub-widgets ────────────────────────────────────────────────────────

class _GradBg extends StatelessWidget {
  final Color color;
  const _GradBg({required this.color});

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.22),
              color.withValues(alpha: 0.08),
            ],
          ),
        ),
        child: Center(
          child: Icon(Icons.luggage_rounded,
              size: 52, color: color.withValues(alpha: 0.40)),
        ),
      );
}

class _HeroBadge extends StatelessWidget {
  final String text;
  const _HeroBadge(this.text);

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: AppTextStyles.labelSm.copyWith(
              color: Colors.white, fontWeight: FontWeight.w700),
        ),
      );
}

class _CategoryBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _CategoryBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11),
        ),
      );
}

// ─── State screens ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String category;
  const _EmptyState({required this.category});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.luggage_rounded,
                size: 56,
                color: AppColors.secondary.withValues(alpha: 0.25)),
            const SizedBox(height: 14),
            Text('No packages found',
                style: AppTextStyles.h5
                    .copyWith(color: AppColors.primary)),
            const SizedBox(height: 6),
            Text(
              category == 'All'
                  ? 'No packages available right now.'
                  : 'No "$category" packages yet.',
              style: AppTextStyles.bodySm
                  .copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.wifi_off_rounded,
                size: 56, color: AppColors.textMuted),
            const SizedBox(height: 14),
            Text('Could not load packages',
                style: AppTextStyles.h5
                    .copyWith(color: AppColors.primary)),
            const SizedBox(height: 6),
            Text(
              message,
              style: AppTextStyles.bodySm
                  .copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
            ),
          ]),
        ),
      );
}
