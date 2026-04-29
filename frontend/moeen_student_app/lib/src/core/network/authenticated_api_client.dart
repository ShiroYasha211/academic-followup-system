import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/logic/auth_controller.dart';
import 'api_client.dart';
import 'api_exception.dart';

final authenticatedApiClientProvider = Provider<ApiClient>((ref) {
  final session = ref.watch(authControllerProvider).valueOrNull;
  if (session == null) {
    throw const ApiException(
      'انتهت الجلسة. سجل الدخول مرة أخرى.',
      statusCode: 401,
    );
  }

  return ApiClient(token: session.token);
});
