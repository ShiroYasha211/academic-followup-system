import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/push_notification_service.dart';
import '../../../core/providers.dart';
import '../data/auth_repository.dart';
import '../data/auth_session.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession?>(AuthController.new);

class AuthController extends AsyncNotifier<AuthSession?> {
  @override
  Future<AuthSession?> build() async {
    final session = await ref.watch(sessionStorageProvider).read();
    if (session != null) {
      unawaited(PushNotificationService.registerDevice(session));
    }
    return session;
  }

  Future<void> login({required String login, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = await ref
          .read(authRepositoryProvider)
          .login(login: login, password: password);
      await ref.read(sessionStorageProvider).save(session);
      await PushNotificationService.registerDevice(session);
      return session;
    });
  }

  Future<void> logout() async {
    final session = state.valueOrNull;
    if (session != null) {
      await PushNotificationService.unregisterDevice(session);
    }
    await ref.read(sessionStorageProvider).clear();
    state = const AsyncData(null);
  }
}
