import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/logic/auth_controller.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'global_error_provider.dart';

final authenticatedApiClientProvider = Provider<ApiClient>((ref) {
  final session = ref.watch(authControllerProvider).valueOrNull;
  if (session == null) {
    throw const ApiException(
      'انتهت الجلسة. سجل الدخول مرة أخرى.',
      statusCode: 401,
    );
  }

  return ApiClient(
    token: session.token,
    onAuthError: (statusCode, message, errorCode) {
      if (statusCode == 401) {
        ref.read(globalDeviceErrorProvider.notifier).state = GlobalDeviceError(
          message: message,
        );
      }
    },
  );
});
