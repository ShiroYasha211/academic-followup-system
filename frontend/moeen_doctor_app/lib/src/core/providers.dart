import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'network/api_client.dart';
import 'offline/offline_cache_service.dart';
import 'storage/session_storage.dart';
import '../features/auth/logic/auth_controller.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final sessionStorageProvider = Provider<SessionStorage>((ref) {
  return SessionStorage(ref.watch(secureStorageProvider));
});

final offlineCacheProvider = Provider<OfflineCacheService>((ref) {
  return OfflineCacheService(ref.watch(secureStorageProvider));
});

final publicApiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authenticatedApiClientProvider = Provider<ApiClient>((ref) {
  final token = ref.watch(authControllerProvider).valueOrNull?.token;
  return ApiClient(token: token);
});
