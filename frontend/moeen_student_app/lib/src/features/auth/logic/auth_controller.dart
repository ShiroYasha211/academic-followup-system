import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/push_notification_service.dart';
import '../../../core/providers.dart';
import '../../../core/network/api_client.dart';
import '../data/auth_repository.dart';
import '../data/auth_session.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(deviceIdentityServiceProvider),
  );
});

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession?>(AuthController.new);

class AuthController extends AsyncNotifier<AuthSession?> {
  Timer? _permissionSyncTimer;
  bool _permissionSyncRunning = false;

  @override
  Future<AuthSession?> build() async {
    ref.onDispose(() => _permissionSyncTimer?.cancel());
    var session = await ref.watch(sessionStorageProvider).read();
    if (session != null) {
      session = await _refreshDelegatePermissions(session);
      _startDelegatePermissionSync(session);
      unawaited(PushNotificationService.registerDevice(session));
    }
    return session;
  }

  Future<AuthSession> _refreshDelegatePermissions(AuthSession session) async {
    if (!session.canAccessDelegateWorkspace) return session;

    try {
      final response = await ApiClient(
        token: session.token,
      ).get('/delegate/me');
      final data = response['data'];
      final user = data is Map ? data['user'] : null;
      final permissions = user is Map
          ? (user['permissions'] as List?)
                ?.map((permission) => permission.toString())
                .toList()
          : null;
      if (permissions == null) return session;

      final updated = session.copyWith(permissions: permissions);
      await ref.read(sessionStorageProvider).save(updated);
      return updated;
    } catch (_) {
      return session;
    }
  }

  void _startDelegatePermissionSync(AuthSession session) {
    _permissionSyncTimer?.cancel();
    if (!session.canAccessDelegateWorkspace) return;

    _permissionSyncTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => unawaited(refreshDelegatePermissionsNow()),
    );
  }

  Future<void> refreshDelegatePermissionsNow() async {
    if (_permissionSyncRunning) return;
    final session = state.valueOrNull;
    if (session == null || !session.canAccessDelegateWorkspace) return;

    _permissionSyncRunning = true;
    try {
      final updated = await _refreshDelegatePermissions(session);
      if (!_samePermissions(session.permissions, updated.permissions)) {
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
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = await ref
          .read(authRepositoryProvider)
          .login(login: login, password: password);
      final refreshed = await _refreshDelegatePermissions(session);
      await ref.read(sessionStorageProvider).save(refreshed);
      _startDelegatePermissionSync(refreshed);
      await PushNotificationService.registerDevice(refreshed);
      return refreshed;
    });
  }

  Future<void> logout() async {
    _permissionSyncTimer?.cancel();
    _permissionSyncTimer = null;
    final session = state.valueOrNull;
    if (session != null) {
      await PushNotificationService.unregisterDevice(session);
    }
    await ref.read(sessionStorageProvider).clear();
    state = const AsyncData(null);
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
    await ref.read(sessionStorageProvider).save(updated);
    _startDelegatePermissionSync(updated);
    await PushNotificationService.registerDevice(updated);
    state = AsyncData(updated);
    unawaited(refreshDelegatePermissionsNow());
    return updated;
  }
}
