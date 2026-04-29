import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

abstract final class MoeenBrandAssets {
  static const full = 'assets/brand/moeen_logo_full.png';
  static const mark = 'assets/brand/moeen_logo_mark.png';
  static const icon = 'assets/brand/moeen_logo_icon.png';
}

class MoeenLogo extends StatelessWidget {
  const MoeenLogo({
    super.key,
    this.compact = false,
    this.onDark = false,
    this.centered = false,
  });

  final bool compact;
  final bool onDark;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final image = compact ? MoeenBrandAssets.mark : MoeenBrandAssets.full;
    final height = compact ? 64.0 : 118.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Image.asset(
          image,
          height: height,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) =>
              _FallbackLogo(compact: compact, onDark: onDark),
        ),
        if (!compact) ...[
          const SizedBox(height: 8),
          Text(
            'منصتك التعليمية في مكان واحد',
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: onDark
                  ? Colors.white.withValues(alpha: 0.82)
                  : AppColors.slate700,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );
  }
}

class _FallbackLogo extends StatelessWidget {
  const _FallbackLogo({required this.compact, required this.onDark});

  final bool compact;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 54 : 68,
          height: compact ? 54 : 68,
          decoration: BoxDecoration(
            gradient: AppColors.goldGradient,
            borderRadius: BorderRadius.circular(compact ? 18 : 22),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.28),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.favorite_rounded,
            color: AppColors.royalBlue,
            size: 30,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Moeen',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: onDark ? Colors.white : AppColors.royalBlueDark,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
