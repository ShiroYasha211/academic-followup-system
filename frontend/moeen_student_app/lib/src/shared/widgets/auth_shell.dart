import 'package:flutter/material.dart';

import '../../core/config/app_variant.dart';
import '../../core/theme/app_colors.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: StudentBrandColors.authGradient),
        child: Stack(
          children: [
            Positioned(
              top: -90,
              left: -70,
              child: _Glow(
                size: 240,
                color: StudentBrandColors.accent.withValues(alpha: 0.16),
              ),
            ),
            Positioned(
              bottom: -120,
              right: -60,
              child: _Glow(
                size: 300,
                color: StudentBrandColors.primary.withValues(alpha: 0.12),
              ),
            ),
            Positioned(
              top: 120,
              right: -90,
              child: _Glow(
                size: 190,
                color: AppColors.rose.withValues(alpha: 0.07),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
