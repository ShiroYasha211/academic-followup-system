import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'network/api_client.dart';
import 'offline/offline_cache_service.dart';
import 'storage/session_storage.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
});

final sessionStorageProvider = Provider<SessionStorage>((ref) {
  return SessionStorage(ref.watch(secureStorageProvider));
});

final offlineCacheServiceProvider = Provider<OfflineCacheService>((ref) {
  return const OfflineCacheService();
});
