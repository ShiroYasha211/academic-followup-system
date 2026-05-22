import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/notifications/push_notification_service.dart';
import 'core/offline/connectivity_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/logic/auth_controller.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/student/logic/student_controllers.dart';
import 'features/student/presentation/widgets/student_shell.dart';
import 'shared/widgets/download_banner_overlay.dart';
import 'shared/widgets/offline_banner.dart';

class MoeenStudentApp extends ConsumerStatefulWidget {
  const MoeenStudentApp({super.key});

  @override
  ConsumerState<MoeenStudentApp> createState() => _MoeenStudentAppState();
}

class _MoeenStudentAppState extends ConsumerState<MoeenStudentApp> {
  StreamSubscription<String>? _notificationNavigationSubscription;
  StreamSubscription<Map<String, dynamic>>? _notificationRefreshSubscription;
  ProviderSubscription<AsyncValue<bool>>? _onlineStatusSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pendingPath = PushNotificationService.takePendingNavigationPath();
      if (pendingPath != null) {
        unawaited(_openNotificationPath(pendingPath));
      }

      _notificationNavigationSubscription = PushNotificationService
          .navigationRequests
          .listen((path) => unawaited(_openNotificationPath(path)));
      _notificationRefreshSubscription = PushNotificationService.refreshRequests
          .listen((_) {
            ref.invalidate(studentUnreadNotificationsCountProvider);
            ref.invalidate(studentUnreadScreenCountsProvider);
            ref.invalidate(studentUnreadMessagesCountProvider);
          });
      _onlineStatusSubscription = ref.listenManual<AsyncValue<bool>>(
        onlineStatusProvider,
        (previous, next) {
          final wasOffline = previous?.valueOrNull == false;
          final isOnline = next.valueOrNull == true;
          if (!wasOffline || !isOnline) return;
          ref.invalidate(authControllerProvider);
          ref.invalidate(studentDashboardControllerProvider);
          ref.invalidate(subscriptionControllerProvider);
          ref.invalidate(studentUnreadNotificationsCountProvider);
          ref.invalidate(studentUnreadScreenCountsProvider);
          ref.invalidate(studentUnreadMessagesCountProvider);
        },
      );
    });
  }

  Future<void> _openNotificationPath(String path) async {
    final router = ref.read(appRouterProvider);
    try {
      final session = await ref.read(authControllerProvider.future);
      if (!mounted) return;
      if (session == null) {
        PushNotificationService.storePendingNavigationPath(path);
        router.go(LoginScreen.route);
        return;
      }
      router.go(path);
    } catch (_) {
      PushNotificationService.storePendingNavigationPath(path);
      router.go(LoginScreen.route);
    }
  }

  @override
  void dispose() {
    unawaited(_notificationNavigationSubscription?.cancel());
    unawaited(_notificationRefreshSubscription?.cancel());
    _onlineStatusSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Moeen Student',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      locale: const Locale('ar'),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: OfflineBannerOverlay(
            child: DownloadBannerOverlay(
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}
