import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/notifications/push_notification_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/download_banner_overlay.dart';

class MoeenStudentApp extends ConsumerStatefulWidget {
  const MoeenStudentApp({super.key});

  @override
  ConsumerState<MoeenStudentApp> createState() => _MoeenStudentAppState();
}

class _MoeenStudentAppState extends ConsumerState<MoeenStudentApp> {
  StreamSubscription<String>? _notificationNavigationSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = ref.read(appRouterProvider);
      final pendingPath = PushNotificationService.takePendingNavigationPath();
      if (pendingPath != null) {
        router.go(pendingPath);
      }

      _notificationNavigationSubscription =
          PushNotificationService.navigationRequests.listen(router.go);
    });
  }

  @override
  void dispose() {
    unawaited(_notificationNavigationSubscription?.cancel());
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
          child: DownloadBannerOverlay(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
