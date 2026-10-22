import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../../core/notifications/push_notification_service.dart';
import '../../../core/providers.dart';
import '../../../core/network/api_client.dart';
import '../data/auth_repository.dart';
import '../data/auth_session.dart';
import '../../student/logic/one_line_background_tasks.dart';
import '../../student/logic/one_line_notification_scheduler.dart';
import '../../student/logic/floating_review.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(deviceIdentityServiceProvider),
  );
});

final publicSupportSettingsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  return ref.watch(authRepositoryProvider).fetchPublicSupportSettings();
});

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession?>(AuthController.new);

class AuthController extends AsyncNotifier<AuthSession?> {
  Timer? _permissionSyncTimer;
  bool _permissionSyncRunning = false;
  int _sessionVersion = 0;

  @override
  Future<AuthSession?> build() async {
    ref.onDispose(() => _permissionSyncTimer?.cancel());
    var session = await ref.watch(sessionStorageProvider).read();
    if (session != null) {
      session = await _refreshPermissions(session);
      _startPermissionSync(session);
      unawaited(PushNotificationService.registerDevice(session));
    }
    return session;
  }

  Future<AuthSession> _refreshPermissions(AuthSession session) async {
    final version = _sessionVersion;
    try {
      final endpoint = session.workspace == AuthWorkspace.delegate
          ? '/delegate/me'
          : '/student/me';
      final response = await ApiClient(token: session.token).get(endpoint);
      final data = response['data'];
      final user = data is Map && data['user'] is Map ? data['user'] : data;
      final permissions = user is Map
          ? (user['permissions'] as List?)
                ?.map((permission) => permission.toString())
                .toList()
          : null;
      if (permissions == null) return session;
      if (version != _sessionVersion) return session;

      final updated = session.copyWith(permissions: permissions);
      await ref.read(sessionStorageProvider).save(updated);
      return updated;
    } catch (_) {
      return session;
    }
  }

  void _startPermissionSync(AuthSession session) {
    _permissionSyncTimer?.cancel();

    _permissionSyncTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => unawaited(refreshPermissionsNow()),
    );
  }

  Future<void> refreshPermissionsNow() async {
    if (_permissionSyncRunning) return;
    final session = state.valueOrNull;
    if (session == null) return;

    final version = _sessionVersion;
    _permissionSyncRunning = true;
    try {
      final updated = await _refreshPermissions(session);
      if (version == _sessionVersion &&
          state.valueOrNull?.token == session.token &&
          state.valueOrNull?.workspace == session.workspace &&
          !_samePermissions(session.permissions, updated.permissions)) {
        state = AsyncData(updated);
      }
    } finally {
      _permissionSyncRunning = false;
    }
  }

  bool _samePermissions(List<String> first, List<String> second) {
    if (first.length != second.length) return false;
    final normalizedFirst = {...first};
    final normalizedSecond = {...second};
    return normalizedFirst.length == normalizedSecond.length &&
        normalizedFirst.containsAll(normalizedSecond);
  }

  Future<void> login({required String login, required String password}) async {
    _sessionVersion++;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = await ref
          .read(authRepositoryProvider)
          .login(login: login, password: password);
      final refreshed = await _refreshPermissions(session);
      await ref.read(sessionStorageProvider).save(refreshed);
      _startPermissionSync(refreshed);
      unawaited(PushNotificationService.registerDevice(refreshed));
      return refreshed;
    });
  }

  Future<void> logout() async {
    _sessionVersion++;
    await FloatingReview.stop();
    _permissionSyncTimer?.cancel();
    _permissionSyncTimer = null;
    final session = state.valueOrNull;
    ref.read(oneLineNotificationSchedulerProvider).dispose();
    await ref.read(sessionStorageProvider).clear();
    state = const AsyncData(null);
    try {
      await OneLineBackgroundTasks.stop();
    } catch (error, stackTrace) {
      debugPrint('One Line session cleanup failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
    if (session != null) {
      await PushNotificationService.unregisterDevice(session);
    }
  }

  Future<void> updateEmail(String email) async {
    final session = state.valueOrNull;
    if (session == null) return;

    final updated = session.copyWith(email: email);
    await ref.read(sessionStorageProvider).save(updated);
    state = AsyncData(updated);
  }

  Future<AuthSession?> switchWorkspace(AuthWorkspace workspace) async {
    final session = state.valueOrNull;
    if (session == null || session.workspace == workspace) return session;

    if (workspace == AuthWorkspace.delegate &&
        !session.canAccessDelegateWorkspace) {
      return session;
    }
    if (workspace == AuthWorkspace.student &&
        !session.canAccessStudentWorkspace) {
      return session;
    }

    final updated = session.copyWith(workspace: workspace);
    _sessionVersion++;
    if (workspace == AuthWorkspace.delegate) {
      await FloatingReview.stop();
      ref.read(oneLineNotificationSchedulerProvider).dispose();
      await OneLineBackgroundTasks.stop();
    }
    await ref.read(sessionStorageProvider).save(updated);
    _startPermissionSync(updated);
    unawaited(PushNotificationService.registerDevice(updated));
    state = AsyncData(updated);
    unawaited(refreshPermissionsNow());
    return updated;
  }
}
