import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/logic/auth_controller.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/auth/presentation/splash_screen.dart';
import 'features/staff/presentation/staff_screens.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: SplashScreen.route,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider).valueOrNull;
      final path = state.uri.path;
      final loggingIn =
          path == LoginScreen.route ||
          path == RegisterScreen.route ||
          path == SplashScreen.route;
      if (auth == null && !loggingIn) return LoginScreen.route;
      if (auth != null && loggingIn) return StaffDashboardScreen.route;
      return null;
    },
    routes: [
      GoRoute(
        path: SplashScreen.route,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: LoginScreen.route,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RegisterScreen.route,
        builder: (context, state) => const RegisterScreen(),
      ),
      ...staffRoutes,
    ],
  );
});

class MoeenStaffApp extends ConsumerWidget {
  const MoeenStaffApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Moeen Staff',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: ref.watch(appRouterProvider),
      locale: const Locale('ar'),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
