import 'package:flutter/material.dart';

import '../../core/config/app_variant.dart';

class MoeenCard extends StatelessWidget {
  const MoeenCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: StudentBrandColors.textPrimary.withValues(alpha: 0.12),
            blurRadius: 34,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: child,
    );
  }
}
