import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_variant.dart';
import '../../../core/notifications/push_notification_service.dart';
import '../../../core/router/landing_route.dart';
import '../../../shared/widgets/moeen_logo.dart';
import '../data/auth_session.dart';
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
    final session = await _readSessionSafely();
    if (!mounted) return;
    await _initializeNotificationsSafely();
    if (!mounted) return;

    final pendingPath = PushNotificationService.takePendingNavigationPath();
    if (pendingPath != null) {
      if (session == null) {
        PushNotificationService.storePendingNavigationPath(pendingPath);
        context.go(LoginScreen.route);
      } else {
        context.go(pendingPath);
      }
      return;
    }

    context.go(session == null ? LoginScreen.route : landingRouteFor(session));
  }

  Future<void> _initializeNotificationsSafely() async {
    try {
      await PushNotificationService.initialize().timeout(
        const Duration(seconds: 8),
      );
    } catch (error, stackTrace) {
      debugPrint('Splash notification initialization skipped: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<AuthSession?> _readSessionSafely() async {
    try {
      return await ref
          .read(authControllerProvider.future)
          .timeout(const Duration(seconds: 8));
    } catch (error, stackTrace) {
      debugPrint('Splash auth session read failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
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
        decoration: BoxDecoration(
          gradient: AppVariant.isDemo
              ? StudentBrandColors.authGradient
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFFBF2),
                    Color(0xFFFFF7E6),
                    Color(0xFFF8FAFC),
                  ],
                ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -90,
              child: _Orb(
                size: 280,
                color: StudentBrandColors.accent.withValues(alpha: 0.14),
              ),
            ),
            Positioned(
              bottom: -90,
              left: -80,
              child: _Orb(
                size: 250,
                color: StudentBrandColors.primary.withValues(alpha: 0.08),
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
                          color: StudentBrandColors.surface,
                          borderRadius: BorderRadius.circular(36),
                          border: Border.all(
                            color: StudentBrandColors.border.withValues(
                              alpha: 0.8,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: StudentBrandColors.primary.withValues(
                                alpha: 0.08,
                              ),
                              blurRadius: 34,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: const MoeenLogo(centered: true),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'مساحتك التعليمية في مكان واحد',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: StudentBrandColors.primaryDark,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: 34,
                        height: 34,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: StudentBrandColors.primary,
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
