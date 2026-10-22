import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/notifications/push_notification_service.dart';
import 'core/config/app_variant.dart';
import 'core/offline/connectivity_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/logic/auth_controller.dart';
import 'features/auth/data/auth_session.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/student/logic/one_line_notification_scheduler.dart';
import 'features/student/logic/one_line_background_tasks.dart';
import 'features/student/logic/floating_review.dart';
import 'features/student/data/student_repositories.dart';
import 'features/student/logic/student_controllers.dart';
import 'features/student/presentation/student_content_screens.dart';
import 'features/student/presentation/widgets/student_shell.dart';
import 'shared/widgets/download_banner_overlay.dart';
import 'shared/widgets/offline_banner.dart';
import 'core/network/global_error_provider.dart';
import 'core/theme/app_colors.dart';
import 'shared/widgets/moeen_dialogs.dart';

class MoeenStudentApp extends ConsumerStatefulWidget {
  const MoeenStudentApp({super.key});

  @override
  ConsumerState<MoeenStudentApp> createState() => _MoeenStudentAppState();
}

class _MoeenStudentAppState extends ConsumerState<MoeenStudentApp>
    with WidgetsBindingObserver {
  StreamSubscription<String>? _notificationNavigationSubscription;
  StreamSubscription<Map<String, dynamic>>? _notificationRefreshSubscription;
  ProviderSubscription<AsyncValue<bool>>? _onlineStatusSubscription;
  ProviderSubscription<AsyncValue<AuthSession?>>? _authSubscription;
  bool _dialogShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
      _authSubscription = ref.listenManual<AsyncValue<AuthSession?>>(
        authControllerProvider,
        (previous, next) {
          if (next.hasValue && next.valueOrNull == null) {
            unawaited(FloatingReview.stop());
          }
          if (StudentFeatureFlags.showOneLineShot && next.valueOrNull != null) {
            unawaited(_syncOneLineNotifications());
          }
        },
      );
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
          if (StudentFeatureFlags.showOneLineShot) {
            unawaited(_syncOneLineNotifications());
          }
        },
      );
      if (StudentFeatureFlags.showOneLineShot) {
        unawaited(_syncOneLineNotifications());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (StudentFeatureFlags.showOneLineShot) {
        unawaited(_syncOneLineNotifications());
      }
    }
  }

  Future<void> _syncOneLineNotifications({bool force = false}) async {
    try {
      final session = await ref.read(authControllerProvider.future);
      if (!mounted || session == null || session.isDelegate) return;
      try {
        await FloatingReview.configure(session);
        if (!mounted) return;
        await FloatingReview.synchronize(
          session,
          ref.read(studentContentRepositoryProvider),
        );
      } catch (error) {
        debugPrint('Floating review synchronization deferred: $error');
      }
      try {
        await OneLineBackgroundTasks.register();
      } catch (error, stackTrace) {
        debugPrint('One Line background task registration failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      if (!mounted) return;
      await scheduleStudentFlashcardSmartReviewNotification(ref);
      if (!mounted) return;
      await ref.read(oneLineNotificationSchedulerProvider).sync(force: force);
    } catch (error, stackTrace) {
      debugPrint('One Line refresh failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
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
      final uri = Uri.tryParse(path);
      if (uri?.path == StudentFlashcardsScreen.quickReviewRoute) {
        final navigatorContext = rootNavigatorKey.currentContext;
        final shown =
            navigatorContext != null &&
            await showStudentFlashcardSmartReviewPrompt(
              context: navigatorContext,
              ref: ref,
              force: true,
              reviewKey: uri?.queryParameters['review'],
              itemId: int.tryParse(uri?.queryParameters['item'] ?? ''),
            );
        if (shown) return;
        router.go(StudentFlashcardsScreen.route);
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
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_notificationNavigationSubscription?.cancel());
    unawaited(_notificationRefreshSubscription?.cancel());
    _authSubscription?.close();
    _onlineStatusSubscription?.close();
    super.dispose();
  }

  void _showCompulsoryErrorDialog(GlobalDeviceError error) {
    if (_dialogShowing) return;
    _dialogShowing = true;

    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      _dialogShowing = false;
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: MoeenDialog(
          title: 'صلاحية الجهاز',
          message: error.message,
          icon: Icons.warning_amber_rounded,
          color: AppColors.danger,
          actions: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  _dialogShowing = false;
                  Navigator.pop(context);
                  await ref.read(authControllerProvider.notifier).logout();
                  ref.read(globalDeviceErrorProvider.notifier).state = null;
                  ref.read(appRouterProvider).go(LoginScreen.route);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'العودة إلى صفحة تسجيل الدخول',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<GlobalDeviceError?>(globalDeviceErrorProvider, (previous, next) {
      if (next != null) {
        _showCompulsoryErrorDialog(next);
      }
    });

    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: StudentAppBrand.appTitle,
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
