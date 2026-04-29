import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_filex/open_filex.dart';

import '../network/api_exception.dart';

enum DownloadEventType { started, progress, completed, failed }

class DownloadEvent {
  const DownloadEvent({required this.type, required this.fileName, this.progress});
  final DownloadEventType type;
  final String fileName;
  final int? progress;
}

class DownloadService {
  DownloadService._();

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static final Set<int> _activeDownloads = <int>{};
  static bool _initialized = false;

  /// Broadcast stream for in-app download event banners.
  static final StreamController<DownloadEvent> _eventController =
      StreamController<DownloadEvent>.broadcast();
  static Stream<DownloadEvent> get events => _eventController.stream;

  static Future<void> initialize() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _notifications.initialize(settings);
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();
    _initialized = true;
  }

  static Future<String?> downloadUrl({
    required String url,
    required String fileName,
  }) async {
    await initialize();
    final safeName = _safeFileName(fileName);
    final id = Random().nextInt(2147480000);
    final dio = Dio();
    var lastProgress = -1;

    try {
      _activeDownloads.add(id);
      // Emit in-app "started" event
      _eventController.add(DownloadEvent(type: DownloadEventType.started, fileName: safeName));
      await _showProgress(id, safeName, null);

      final response = await dio.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          receiveTimeout: const Duration(minutes: 2),
        ),
        onReceiveProgress: (received, total) {
          if (!_activeDownloads.contains(id)) return;
          if (total <= 0) {
            if (lastProgress != -2) {
              lastProgress = -2;
              _showProgress(id, safeName, null);
            }
            return;
          }
          final progress = ((received / total) * 100).clamp(0, 100).toInt();
          if (progress != lastProgress) {
            lastProgress = progress;
            _showProgress(id, safeName, progress);
          }
        },
      );

      final bytes = response.data ?? const <int>[];
      if (bytes.isEmpty) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }

      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'اختر مكان حفظ الملف',
        fileName: safeName,
        bytes: Uint8List.fromList(bytes),
      );

      _activeDownloads.remove(id);
      if (savedPath == null || savedPath.isEmpty) {
        await _notifications.cancel(id);
        return null;
      }

      await _showProgress(id, safeName, 100);
      await _showCompleted(id, safeName);
      // Emit in-app "completed" event
      _eventController.add(DownloadEvent(type: DownloadEventType.completed, fileName: safeName));
      await OpenFilex.open(savedPath);
      return savedPath;
    } on DioException catch (error) {
      _activeDownloads.remove(id);
      await _showFailed(id, safeName);
      // Emit in-app "failed" event
      _eventController.add(DownloadEvent(type: DownloadEventType.failed, fileName: safeName));
      throw ApiException(
        error.type == DioExceptionType.connectionError
            ? 'تعذر الاتصال أثناء تحميل الملف.'
            : 'حدث خطأ أثناء تحميل الملف.',
        statusCode: error.response?.statusCode,
      );
    } catch (_) {
      _activeDownloads.remove(id);
      await _showFailed(id, safeName);
      // Emit in-app "failed" event
      _eventController.add(DownloadEvent(type: DownloadEventType.failed, fileName: safeName));
      throw const ApiException('تعذر حفظ الملف في المسار المختار.');
    }
  }

  static Future<void> _showProgress(
    int id,
    String fileName,
    int? progress,
  ) async {
    if (!_activeDownloads.contains(id) && progress != 100) return;
    final hasKnownProgress = progress != null;
    final details = AndroidNotificationDetails(
      'moeen_downloads',
      'تحميل الملفات',
      channelDescription: 'إشعارات تقدم تحميل ملفات معين',
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: 100,
      progress: progress ?? 0,
      indeterminate: !hasKnownProgress,
      onlyAlertOnce: true,
      ongoing: true,
    );
    await _notifications.show(
      id,
      'جاري تحميل الملف',
      hasKnownProgress ? '$fileName - $progress%' : '$fileName - جاري التحميل',
      NotificationDetails(android: details),
    );
  }

  static Future<void> _showCompleted(int id, String fileName) async {
    _activeDownloads.remove(id);
    const details = AndroidNotificationDetails(
      'moeen_downloads',
      'تحميل الملفات',
      channelDescription: 'إشعارات تقدم تحميل ملفات معين',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: false,
    );
    await _notifications.show(
      id,
      'اكتمل التحميل',
      fileName,
      const NotificationDetails(android: details),
    );
  }

  static Future<void> _showFailed(int id, String fileName) async {
    const details = AndroidNotificationDetails(
      'moeen_downloads',
      'تحميل الملفات',
      channelDescription: 'إشعارات تقدم تحميل ملفات معين',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: false,
    );
    await _notifications.show(
      id,
      'فشل تحميل الملف',
      fileName,
      const NotificationDetails(android: details),
    );
  }

  static String _safeFileName(String value) {
    final trimmed = value.trim().isEmpty ? 'moeen-file' : value.trim();
    return trimmed.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }
}
