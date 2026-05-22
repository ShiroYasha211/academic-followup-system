import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/moeen_logo.dart';
import '../../staff/presentation/staff_screens.dart';
import '../logic/auth_controller.dart';
import 'login_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  static const route = '/';

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
    _goNext();
  }

  Future<void> _goNext() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    final session = await ref.read(authControllerProvider.future);
    if (!mounted) return;
    context.go(
      session == null ? LoginScreen.route : StaffDashboardScreen.route,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFBF2), Color(0xFFFFF7E6), Color(0xFFF8FAFC)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -90,
              child: _Orb(
                size: 280,
                color: AppColors.gold.withValues(alpha: 0.16),
              ),
            ),
            Positioned(
              bottom: -90,
              left: -80,
              child: _Orb(
                size: 250,
                color: AppColors.royalBlue.withValues(alpha: 0.08),
              ),
            ),
            Center(
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFCF5),
                          borderRadius: BorderRadius.circular(36),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.royalBlue.withValues(
                                alpha: 0.08,
                              ),
                              blurRadius: 34,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: const MoeenLogo(centered: true),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.school_rounded,
                              color: AppColors.royalBlue,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'بوابة عضو هيئة التدريس',
                              style: TextStyle(
                                color: AppColors.royalBlueDark,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'مساحتك الأكاديمية في مكان واحد',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.midnight,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 36),
                      const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
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

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});

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
