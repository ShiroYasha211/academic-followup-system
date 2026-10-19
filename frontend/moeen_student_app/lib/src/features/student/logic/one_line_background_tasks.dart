import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:workmanager/workmanager.dart';

import '../../../core/config/app_variant.dart';
import '../../../core/network/api_client.dart';
import '../../../core/notifications/push_notification_service.dart';
import '../../../core/offline/offline_cache_service.dart';
import '../../../core/storage/session_storage.dart';
import '../data/flashcard_local_store.dart';
import '../data/student_repositories.dart';
import 'one_line_notification_scheduler.dart';

const _taskName = 'moeen.one_line.refresh';

@pragma('vm:entry-point')
void oneLineCallbackDispatcher() {
  Workmanager().executeTask((task, input) async {
    DartPluginRegistrant.ensureInitialized();
    if (task != _taskName || !StudentFeatureFlags.showOneLineShot) return true;
    const storage = SessionStorage(
      FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      ),
    );
    final session = await storage.read();
    if (session == null || session.isDelegate) return true;
    PushNotificationService.backgroundMode = true;
    final scheduler = OneLineNotificationScheduler(
      StudentContentRepository(
        ApiClient(token: session.token),
        const OfflineCacheService(),
        cacheScope: FlashcardLocalStore.keyFor(session),
      ),
      FlashcardLocalStore(accountKey: FlashcardLocalStore.keyFor(session)),
      isCurrentSession: () async =>
          (await storage.read())?.token == session.token,
    );
    try {
      await scheduler.sync();
      return true;
    } catch (error, stackTrace) {
      debugPrint('Background One Line refresh failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    } finally {
      scheduler.dispose();
    }
  });
}

class OneLineBackgroundTasks {
  static Future<void> register() async {
    if (!Platform.isAndroid || !StudentFeatureFlags.showOneLineShot) return;
    await Workmanager().initialize(oneLineCallbackDispatcher);
    await Workmanager().registerPeriodicTask(
      _taskName,
      _taskName,
      frequency: const Duration(hours: 6),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  static Future<void> stop() async {
    if (!Platform.isAndroid) return;
    try {
      await Workmanager().cancelByUniqueName(_taskName);
    } finally {
      await OneLineNotificationScheduler.runExclusive(
        () => const FlashcardLocalStore().withScheduleLock(() async {
          await PushNotificationService.cancelOneLineShotNotifications();
          await PushNotificationService.cancelFlashcardSmartReview();
        }),
      );
    }
  }
}
