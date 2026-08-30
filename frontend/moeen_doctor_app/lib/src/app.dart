import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/config/app_config.dart';
import 'core/config/app_variant.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/refresh/staff_refresh_coordinator.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/moeen_dialogs.dart';
import 'features/auth/logic/auth_controller.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/auth/presentation/splash_screen.dart';
import 'features/staff/presentation/staff_screens.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
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

class MoeenStaffApp extends ConsumerStatefulWidget {
  const MoeenStaffApp({super.key});

  @override
  ConsumerState<MoeenStaffApp> createState() => _MoeenStaffAppState();
}

class _MoeenStaffAppState extends ConsumerState<MoeenStaffApp>
    with WidgetsBindingObserver {
  StreamSubscription<String>? _notificationNavigationSubscription;
  StreamSubscription<Map<String, dynamic>>? _notificationRefreshSubscription;
  StreamSubscription<dynamic>? _connectivitySubscription;
  DateTime? _lastResumedAt;
  int _connectivityProbeId = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notificationNavigationSubscription = StaffPushNotificationService
        .navigationRequests
        .listen((path) => unawaited(_openNotificationPath(path)));
    _notificationRefreshSubscription = StaffPushNotificationService
        .refreshRequests
        .listen((data) {
          ref
              .read(staffRefreshCoordinatorProvider.notifier)
              .triggerRefresh(force: true);
          if (data['type']?.toString() == 'administrative_access' ||
              data['refresh_session']?.toString() == 'true') {
            unawaited(
              ref.read(authControllerProvider.notifier).refreshSession(),
            );
          }
        });
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _handleConnectivityChange,
    );
    unawaited(_checkInitialConnectivity());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pendingPath =
          StaffPushNotificationService.takePendingNavigationPath();
      if (pendingPath != null && pendingPath.isNotEmpty) {
        unawaited(_openNotificationPath(pendingPath));
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationNavigationSubscription?.cancel();
    _notificationRefreshSubscription?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(ref.read(authControllerProvider.notifier).refreshSession());
    final now = DateTime.now();
    if (_lastResumedAt == null ||
        now.difference(_lastResumedAt!) > const Duration(seconds: 45)) {
      ref.read(staffRefreshCoordinatorProvider.notifier).triggerRefresh();
    }
    _lastResumedAt = now;
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      _handleConnectivityChange(await Connectivity().checkConnectivity());
    } catch (_) {}
  }

  void _handleConnectivityChange(dynamic result) {
    if (_hasNetworkTransport(result)) {
      _connectivityProbeId++;
      ref.read(staffRefreshCoordinatorProvider.notifier).setOnline(true);
      return;
    }
    unawaited(_verifyOfflineBeforeMarking());
  }

  bool _hasNetworkTransport(dynamic result) {
    if (result is List<ConnectivityResult>) {
      return result.any((item) => item != ConnectivityResult.none);
    }
    if (result is ConnectivityResult) return result != ConnectivityResult.none;
    return true;
  }

  Future<void> _verifyOfflineBeforeMarking() async {
    final probeId = ++_connectivityProbeId;
    final online = await _canReachBackend();
    if (!mounted || probeId != _connectivityProbeId) return;
    ref.read(staffRefreshCoordinatorProvider.notifier).setOnline(online);
  }

  Future<bool> _canReachBackend() async {
    try {
      final uri = Uri.parse(AppConfig.apiBaseUrl);
      final host = uri.host;
      if (host.isEmpty) return true;
      final port = uri.hasPort ? uri.port : (uri.scheme == 'http' ? 80 : 443);
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 3),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _openNotificationPath(String path) async {
    try {
      final session = await ref.read(authControllerProvider.future);
      if (session == null) {
        StaffPushNotificationService.storePendingNavigationPath(path);
        ref.read(appRouterProvider).go(LoginScreen.route);
        return;
      }
      ref.read(appRouterProvider).go(path);
    } catch (_) {
      StaffPushNotificationService.storePendingNavigationPath(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (previous, next) {
      if (previous?.valueOrNull == null || next.valueOrNull != null) return;

      final message = ref
          .read(authControllerProvider.notifier)
          .takeSessionExpiredMessage();
      if (message == null) return;

      ref.read(appRouterProvider).go(LoginScreen.route);
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final dialogContext = rootNavigatorKey.currentContext;
        if (dialogContext == null) return;
        await showMoeenInfoDialog(
          context: dialogContext,
          title: 'انتهت جلسة تسجيل الدخول',
          message: message,
          buttonLabel: 'تسجيل الدخول',
          icon: Icons.lock_clock_rounded,
          color: AppColors.warning,
        );
      });
    });

    final refreshState = ref.watch(staffRefreshCoordinatorProvider);
    return MaterialApp.router(
      title: StaffAppBrand.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: ref.watch(appRouterProvider),
      locale: const Locale('ar'),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            child ?? const SizedBox.shrink(),
            _StaffGlobalConnectivityBanner(state: refreshState),
          ],
        ),
      ),
    );
  }
}

class _StaffGlobalConnectivityBanner extends StatelessWidget {
  const _StaffGlobalConnectivityBanner({required this.state});

  final StaffRefreshState state;

  @override
  Widget build(BuildContext context) {
    final visible = !state.online || state.refreshing;
    final offline = !state.online;
    final background = offline
        ? const Color(0xFF2F2418)
        : StaffBrandColors.primary;
    final icon = offline ? Icons.wifi_off_rounded : Icons.sync_rounded;
    final message = offline
        ? 'لا يوجد اتصال بالإنترنت. يتم عرض البيانات المحفوظة عند توفرها.'
        : 'تم استعادة الاتصال، جاري تحديث البيانات...';

    return PositionedDirectional(
      top: 0,
      start: 12,
      end: 12,
      child: SafeArea(
        bottom: false,
        child: IgnorePointer(
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            offset: visible ? Offset.zero : const Offset(0, -1.4),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: visible ? 1 : 0,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.16),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                height: 1.35,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
