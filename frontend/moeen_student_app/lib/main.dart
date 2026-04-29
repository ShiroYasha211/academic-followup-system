import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';
import 'src/core/downloads/download_service.dart';
import 'src/core/notifications/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushNotificationService.initialize();
  await DownloadService.initialize();
  runApp(const ProviderScope(child: MoeenStudentApp()));
}
