import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

abstract final class MoeenBrandAssets {
  static const full = 'assets/brand/logo.jpeg';
  static const mark = 'assets/brand/logo.jpeg';
  static const icon = 'assets/brand/logo.jpeg';
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
    final size = compact ? 42.0 : 80.0;

    final logoWidget = Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 14 : 22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: compact ? 0.06 : 0.1),
            blurRadius: compact ? 8 : 16,
            offset: Offset(0, compact ? 3 : 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(compact ? 11 : 19),
        child: Image.asset(
          image,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => _FallbackLogo(size: size),
        ),
      ),
    );

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment:
            centered ? MainAxisAlignment.center : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          logoWidget,
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'معين',
                style: TextStyle(
                  color: onDark ? Colors.white : AppColors.royalBlueDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 15.5,
                  fontFamily: 'Cairo',
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'المنصة التعليمية',
                style: TextStyle(
                  color: onDark
                      ? Colors.white.withValues(alpha: 0.7)
                      : AppColors.slate500,
                  fontWeight: FontWeight.w700,
                  fontSize: 9.5,
                  fontFamily: 'Cairo',
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        logoWidget,
        const SizedBox(height: 14),
        Text(
          'معين',
          style: TextStyle(
            color: onDark ? Colors.white : AppColors.royalBlueDark,
            fontWeight: FontWeight.w900,
            fontSize: 22,
            fontFamily: 'Cairo',
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'منصتك التعليمية في مكان واحد',
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: onDark
                ? Colors.white.withValues(alpha: 0.82)
                : AppColors.slate700,
            fontWeight: FontWeight.w800,
            fontSize: 12,
            fontFamily: 'Cairo',
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _FallbackLogo extends StatelessWidget {
  const _FallbackLogo({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: AppColors.goldGradient,
      ),
      child: Center(
        child: Icon(
          Icons.favorite_rounded,
          color: AppColors.royalBlue,
          size: size * 0.55,
        ),
      ),
    );
  }
}
