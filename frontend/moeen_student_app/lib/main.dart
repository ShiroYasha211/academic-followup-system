import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';
import 'src/core/downloads/download_service.dart';
import 'src/core/notifications/push_notification_service.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await PushNotificationService.initialize();
    await DownloadService.initialize();
    await initializeDateFormatting('ar', null);
  } catch (e) {
    debugPrint('Initialization error: $e');
  }

  runApp(const ProviderScope(child: MoeenStudentApp()));
}
