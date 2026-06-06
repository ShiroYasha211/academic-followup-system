import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/notifications/push_notification_service.dart';
import '../../../core/providers.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/staff_auth_session.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(publicApiClientProvider));
});

final authControllerProvider =
    AsyncNotifierProvider<AuthController, StaffAuthSession?>(
      AuthController.new,
    );

class AuthController extends AsyncNotifier<StaffAuthSession?> {
  bool _handlingUnauthorized = false;
  String? _sessionExpiredMessage;

  @override
  Future<StaffAuthSession?> build() async {
    final session = await ref.watch(sessionStorageProvider).read();
    if (session == null) return null;
    try {
      final refreshed = await ref.read(authRepositoryProvider).refresh(session);
      await ref.read(sessionStorageProvider).save(refreshed);
      await StaffPushNotificationService.registerDevice(refreshed);
      return refreshed;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await ref.read(sessionStorageProvider).clear();
        _sessionExpiredMessage =
            'انتهت جلسة تسجيل الدخول أو تم تسجيل الحساب من جهاز آخر. يرجى تسجيل الدخول مجددًا.';
        return null;
      }
      await StaffPushNotificationService.registerDevice(session);
      return session;
    } catch (_) {
      await StaffPushNotificationService.registerDevice(session);
      return session;
    }
  }

  Future<void> login({required String email, required String password}) async {
    _sessionExpiredMessage = null;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);
      await ref.read(sessionStorageProvider).save(session);
      await StaffPushNotificationService.registerDevice(session);
      return session;
    });
  }

  Future<void> switchWorkspace(StaffWorkspace workspace) async {
    final session = state.valueOrNull;
    if (session == null || !session.availableWorkspaces.contains(workspace)) {
      return;
    }
    final updated = session.copyWith(workspace: workspace);
    await ref.read(sessionStorageProvider).save(updated);
    state = AsyncData(updated);
  }

  Future<void> updateEmail(String email) async {
    final session = state.valueOrNull;
    if (session == null) return;
    final updated = session.copyWith(email: email);
    await ref.read(sessionStorageProvider).save(updated);
    state = AsyncData(updated);
  }

  Future<void> logout() async {
    _sessionExpiredMessage = null;
    final session = state.valueOrNull;
    if (session != null) {
      await StaffPushNotificationService.unregisterDevice(session);
      try {
        await ref
            .read(authRepositoryProvider)
            .logout(session.token, session.workspace);
      } catch (_) {}
    }
    await ref.read(sessionStorageProvider).clear();
    state = const AsyncData(null);
  }

  Future<void> handleUnauthorized() async {
    if (_handlingUnauthorized || state.valueOrNull == null) return;
    _handlingUnauthorized = true;
    try {
      _sessionExpiredMessage =
          'انتهت جلسة تسجيل الدخول أو تم تسجيل الحساب من جهاز آخر. يرجى تسجيل الدخول مجددًا.';
      await ref.read(sessionStorageProvider).clear();
      state = const AsyncData(null);
    } finally {
      _handlingUnauthorized = false;
    }
  }

  String? takeSessionExpiredMessage() {
    final message = _sessionExpiredMessage;
    _sessionExpiredMessage = null;
    return message;
  }
}
