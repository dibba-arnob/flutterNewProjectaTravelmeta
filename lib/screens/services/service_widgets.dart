import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

// ─── SvCard ───────────────────────────────────────────────────────────────────

class SvCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const SvCard({super.key, required this.child, this.padding = const EdgeInsets.all(20)});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: AppColors.shadow, blurRadius: 16, offset: Offset(0, 4)),
          ],
        ),
        child: child,
      );
}

// ─── SvToggleBar ──────────────────────────────────────────────────────────────

class SvToggleBar extends StatelessWidget {
  final List<String> options;
  final int selected;
  final ValueChanged<int> onChanged;
  final Color accentColor;
  const SvToggleBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.accentColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(options.length, (i) {
          final active = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: active ? accentColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(
                  options[i],
                  style: AppTextStyles.label.copyWith(
                    color: active ? Colors.white : AppColors.textMuted,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── SvSwapRow ────────────────────────────────────────────────────────────────

class SvSwapRow extends StatelessWidget {
  final String from;
  final String to;
  final IconData fromIcon;
  final IconData toIcon;
  final VoidCallback onSwap;
  const SvSwapRow({
    super.key,
    required this.from,
    required this.to,
    required this.fromIcon,
    required this.toIcon,
    required this.onSwap,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(fromIcon, size: 13, color: AppColors.secondary),
                      const SizedBox(width: 4),
                      Text('From', style: AppTextStyles.caption.copyWith(fontSize: 11)),
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      from,
                      style: AppTextStyles.label.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: onSwap,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.swap_horiz_rounded, size: 18, color: AppColors.secondary),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      Text('To', style: AppTextStyles.caption.copyWith(fontSize: 11)),
                      const SizedBox(width: 4),
                      Icon(toIcon, size: 13, color: AppColors.secondary),
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      to,
                      style: AppTextStyles.label.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

// ─── SvField ──────────────────────────────────────────────────────────────────

class SvField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const SvField({super.key, required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icon, size: 15, color: AppColors.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.label.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ]),
          ),
        ]),
      );
}

// ─── SvButton ─────────────────────────────────────────────────────────────────

class SvButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const SvButton({super.key, required this.label, required this.onTap, this.color = AppColors.secondary});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          onPressed: onTap,
          child: Text(label, style: AppTextStyles.btn),
        ),
      );
}

// ─── SvSectionTitle ───────────────────────────────────────────────────────────

class SvSectionTitle extends StatelessWidget {
  final String title;
  const SvSectionTitle(this.title, {super.key});
  @override
  Widget build(BuildContext context) =>
      Text(title, style: AppTextStyles.h5.copyWith(color: AppColors.primary));
}

// ─── SvRouteCard ──────────────────────────────────────────────────────────────

class SvRouteCard extends StatelessWidget {
  final String from;
  final String to;
  final String meta;
  final String price;
  final IconData icon;
  final Color accentColor;
  const SvRouteCard({
    super.key,
    required this.from,
    required this.to,
    required this.meta,
    required this.price,
    required this.icon,
    required this.accentColor,
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 19, color: accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(from, style: AppTextStyles.label.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_rounded, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Flexible(child: Text(to, style: AppTextStyles.label.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
              ]),
              const SizedBox(height: 3),
              Text(meta, style: AppTextStyles.caption),
            ]),
          ),
          const SizedBox(width: 8),
          Text(price, style: AppTextStyles.priceSm.copyWith(color: accentColor)),
        ]),
      );
}

// ─── SvChipRow ────────────────────────────────────────────────────────────────

class SvChipRow extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;
  final Color accentColor;
  const SvChipRow({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.accentColor = AppColors.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((opt) {
          final active = opt == selected;
          return GestureDetector(
            onTap: () => onChanged(opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: active ? accentColor : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: active ? accentColor : AppColors.borderLight),
              ),
              child: Text(
                opt,
                style: AppTextStyles.labelSm.copyWith(
                  color: active ? Colors.white : AppColors.textMuted,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
