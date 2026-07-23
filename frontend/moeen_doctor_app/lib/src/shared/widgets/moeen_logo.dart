import 'package:flutter/material.dart';

import '../../core/config/app_variant.dart';

abstract final class MoeenBrandAssets {
  static String get full => StaffAppBrand.logoAsset;
  static String get mark => StaffAppBrand.logoAsset;
  static String get icon => StaffAppBrand.logoAsset;
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
        child: StaffAppVariant.isDemo
            ? _DashboardLogoMark(size: size)
            : Image.asset(
                image,
                width: size,
                height: size,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => _DashboardLogoMark(size: size),
              ),
      ),
    );

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: centered
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          logoWidget,
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                StaffAppBrand.displayName,
                style: TextStyle(
                  color: onDark ? Colors.white : StaffBrandColors.primaryDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 15.5,
                  fontFamily: 'Cairo',
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                StaffAppBrand.compactTagline,
                style: TextStyle(
                  color: onDark
                      ? Colors.white.withValues(alpha: 0.7)
                      : StaffBrandColors.textSecondary,
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
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        logoWidget,
        const SizedBox(height: 14),
        Text(
          StaffAppBrand.displayName,
          style: TextStyle(
            color: onDark ? Colors.white : StaffBrandColors.primaryDark,
            fontWeight: FontWeight.w900,
            fontSize: 22,
            fontFamily: 'Cairo',
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          StaffAppBrand.tagline,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: onDark
                ? Colors.white.withValues(alpha: 0.82)
                : StaffBrandColors.textSecondary,
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

class _DashboardLogoMark extends StatelessWidget {
  const _DashboardLogoMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(gradient: StaffBrandColors.accentGradient),
      child: Center(
        child: Icon(
          Icons.school_rounded,
          color: Colors.white,
          size: size * 0.55,
        ),
      ),
    );
  }
}
