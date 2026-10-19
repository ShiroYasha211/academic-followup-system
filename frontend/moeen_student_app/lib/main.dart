import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';
import 'src/core/downloads/download_service.dart';
import 'src/core/notifications/push_notification_service.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('ar', null);
  runApp(const ProviderScope(child: MoeenStudentApp()));
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_initializeServices());
  });
}

Future<void> _initializeServices() async {
  await _initializeService(
    'push notifications',
    PushNotificationService.initialize,
  );
  await _initializeService('downloads', DownloadService.initialize);
}

Future<void> _initializeService(
  String name,
  Future<void> Function() initialize,
) async {
  try {
    await initialize().timeout(const Duration(seconds: 8));
  } catch (error, stackTrace) {
    debugPrint('Failed to initialize $name: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
