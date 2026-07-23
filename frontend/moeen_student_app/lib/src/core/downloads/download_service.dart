import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../network/api_exception.dart';

enum DownloadEventType { started, progress, completed, failed }

class DownloadEvent {
  const DownloadEvent({
    required this.type,
    required this.fileName,
    this.progress,
  });
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
    try {
      const android = AndroidInitializationSettings('ic_notification');
      const settings = InitializationSettings(android: android);
      await _notifications.initialize(settings);
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.requestNotificationsPermission();
    } catch (_) {
      // Downloads must remain available even if local notifications cannot start.
    } finally {
      _initialized = true;
    }
  }

  static Future<void> previewFile(String? url, String? fileName) async {
    if (url == null || url.isEmpty) return;
    await downloadUrl(url: url, fileName: fileName ?? 'file');
  }

  static Future<String?> downloadUrl({
    required String url,
    required String fileName,
    Map<String, dynamic>? headers,
  }) async {
    await initialize();
    final safeName = _safeFileName(fileName);
    final id = Random().nextInt(2147480000);
    final dio = Dio();
    var lastProgress = -1;

    try {
      _activeDownloads.add(id);
      // Emit in-app "started" event
      _eventController.add(
        DownloadEvent(type: DownloadEventType.started, fileName: safeName),
      );
      await _showProgress(id, safeName, null);

      final response = await dio.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          receiveTimeout: const Duration(minutes: 2),
          headers: headers,
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
      final finalPath = savedPath == null
          ? null
          : _ensureFileExtension(savedPath, safeName);

      if (finalPath != null) {
        final file = File(finalPath);
        await file.writeAsBytes(bytes);
      }

      _activeDownloads.remove(id);
      if (finalPath == null || finalPath.isEmpty) {
        await _notifications.cancel(id);
        return null;
      }

      await _showCompleted(id, safeName);
      // Emit in-app "completed" event
      _eventController.add(
        DownloadEvent(type: DownloadEventType.completed, fileName: safeName),
      );
      try {
        await OpenFilex.open(finalPath);
      } catch (_) {
        // The download is already complete; opening support varies by device.
      }
      return finalPath;
    } on DioException catch (error) {
      _activeDownloads.remove(id);
      await _showFailed(id, safeName);
      // Emit in-app "failed" event
      _eventController.add(
        DownloadEvent(type: DownloadEventType.failed, fileName: safeName),
      );
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
      _eventController.add(
        DownloadEvent(type: DownloadEventType.failed, fileName: safeName),
      );
      throw const ApiException('تعذر حفظ الملف في المسار المختار.');
    }
  }

  static Future<String?> downloadUrlToMoeenFolder({
    required String url,
    required String fileName,
    required String section,
    Map<String, dynamic>? headers,
    bool openAfterDownload = false,
  }) async {
    await initialize();
    final safeName = _safeFileName(fileName);
    final id = Random().nextInt(2147480000);
    final dio = Dio();
    var lastProgress = -1;

    try {
      final dir = await _moeenSectionDirectory(section);
      final file = await _uniqueFile(dir, safeName);

      _activeDownloads.add(id);
      _eventController.add(
        DownloadEvent(type: DownloadEventType.started, fileName: safeName),
      );
      await _showProgress(id, safeName, null);

      final response = await dio.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          receiveTimeout: const Duration(minutes: 2),
          headers: headers,
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

      await file.writeAsBytes(bytes, flush: true);
      _activeDownloads.remove(id);
      await _showCompleted(id, safeName);
      _eventController.add(
        DownloadEvent(type: DownloadEventType.completed, fileName: safeName),
      );
      if (openAfterDownload) {
        try {
          await OpenFilex.open(file.path);
        } catch (_) {
          // Saving succeeded; opening can fail if no compatible app exists.
        }
      }
      return file.path;
    } on DioException catch (error) {
      _activeDownloads.remove(id);
      await _showFailed(id, safeName);
      _eventController.add(
        DownloadEvent(type: DownloadEventType.failed, fileName: safeName),
      );
      throw ApiException(
        error.type == DioExceptionType.connectionError
            ? 'تعذر الاتصال أثناء تحميل الملف.'
            : 'حدث خطأ أثناء تحميل الملف.',
        statusCode: error.response?.statusCode,
      );
    } catch (_) {
      _activeDownloads.remove(id);
      await _showFailed(id, safeName);
      _eventController.add(
        DownloadEvent(type: DownloadEventType.failed, fileName: safeName),
      );
      throw const ApiException('تعذر حفظ الملف في مجلد تحميلات معين.');
    }
  }

  static Future<String?> saveBytesToMoeenFolder({
    required List<int> bytes,
    required String fileName,
    required String section,
    bool openAfterSave = false,
  }) async {
    if (bytes.isEmpty) {
      throw const ApiException('الملف المستلم فارغ.');
    }

    await initialize();
    final safeName = _safeFileName(fileName);
    final id = Random().nextInt(2147480000);

    try {
      final dir = await _moeenSectionDirectory(section);
      final file = await _uniqueFile(dir, safeName);

      _activeDownloads.add(id);
      _eventController.add(
        DownloadEvent(type: DownloadEventType.started, fileName: safeName),
      );
      await _showProgress(id, safeName, null);
      await file.writeAsBytes(bytes, flush: true);

      _activeDownloads.remove(id);
      await _showCompleted(id, safeName);
      _eventController.add(
        DownloadEvent(type: DownloadEventType.completed, fileName: safeName),
      );

      if (openAfterSave) {
        try {
          await OpenFilex.open(file.path);
        } catch (_) {
          // Saving succeeded; a compatible viewer may not be installed.
        }
      }
      return file.path;
    } catch (_) {
      _activeDownloads.remove(id);
      await _showFailed(id, safeName);
      _eventController.add(
        DownloadEvent(type: DownloadEventType.failed, fileName: safeName),
      );
      throw const ApiException('تعذر حفظ الملف في مجلد تحميلات معين.');
    }
  }

  static Future<String?> findMoeenFile({
    required String fileName,
    required String section,
  }) async {
    final dir = await _moeenSectionDirectory(section);
    final safeName = _safeFileName(fileName);
    final exact = File('${dir.path}${Platform.pathSeparator}$safeName');
    if (await exact.exists() && await exact.length() > 0) return exact.path;

    final dotIndex = safeName.lastIndexOf('.');
    final base = dotIndex > 0 ? safeName.substring(0, dotIndex) : safeName;
    final ext = dotIndex > 0 ? safeName.substring(dotIndex) : '';
    final files = await dir
        .list()
        .where((entity) => entity is File)
        .cast<File>()
        .toList();
    files.sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      final name = _baseName(file.path);
      if (name.startsWith('$base (') && name.endsWith(ext)) {
        if (await file.length() > 0) return file.path;
      }
    }
    return null;
  }

  static Future<String?> openMoeenFile({
    required String fileName,
    required String section,
  }) async {
    final path = await findMoeenFile(fileName: fileName, section: section);
    if (path == null) return null;
    try {
      final result = await OpenFilex.open(path);
      if (result.type != ResultType.done) return null;
      return path;
    } catch (_) {
      return null;
    }
  }

  static Future<void> openPath(String path) async {
    if (path.isEmpty) return;
    await OpenFilex.open(path);
  }

  static Future<String?> downloadUrlCached({
    required String url,
    required String fileName,
    required String cacheKey,
    Map<String, dynamic>? headers,
  }) async {
    await initialize();
    final safeName = _safeFileName(fileName);
    final safeKey = _safeFileName(cacheKey);
    final dir = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory(
      '${dir.path}${Platform.pathSeparator}moeen_downloads',
    );
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }

    final cachedPath =
        '${downloadsDir.path}${Platform.pathSeparator}${safeKey}_$safeName';
    final cachedFile = File(cachedPath);
    if (await cachedFile.exists() && await cachedFile.length() > 0) {
      await OpenFilex.open(cachedPath);
      return cachedPath;
    }

    final id = Random().nextInt(2147480000);
    final dio = Dio();
    var lastProgress = -1;

    try {
      _activeDownloads.add(id);
      _eventController.add(
        DownloadEvent(type: DownloadEventType.started, fileName: safeName),
      );
      await _showProgress(id, safeName, null);

      final response = await dio.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          receiveTimeout: const Duration(minutes: 2),
          headers: headers,
        ),
        onReceiveProgress: (received, total) {
          if (!_activeDownloads.contains(id)) return;
          if (total <= 0) return;
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

      await cachedFile.writeAsBytes(bytes, flush: true);
      _activeDownloads.remove(id);
      await _showCompleted(id, safeName);
      _eventController.add(
        DownloadEvent(type: DownloadEventType.completed, fileName: safeName),
      );
      await OpenFilex.open(cachedPath);
      return cachedPath;
    } on DioException catch (error) {
      _activeDownloads.remove(id);
      await _showFailed(id, safeName);
      _eventController.add(
        DownloadEvent(type: DownloadEventType.failed, fileName: safeName),
      );
      throw ApiException(
        error.type == DioExceptionType.connectionError
            ? 'تعذر الاتصال أثناء تحميل الملف.'
            : 'حدث خطأ أثناء تحميل الملف من الرابط المرسل.',
        statusCode: error.response?.statusCode,
      );
    } catch (_) {
      _activeDownloads.remove(id);
      await _showFailed(id, safeName);
      _eventController.add(
        DownloadEvent(type: DownloadEventType.failed, fileName: safeName),
      );
      throw const ApiException('تعذر حفظ الملف أو فتحه من التخزين المحلي.');
    }
  }

  static Future<void> _showProgress(
    int id,
    String fileName,
    int? progress,
  ) async {
    try {
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
        icon: 'ic_notification',
      );
      await _notifications.show(
        id,
        'جاري تحميل الملف',
        hasKnownProgress
            ? '$fileName - $progress%'
            : '$fileName - جاري التحميل',
        NotificationDetails(android: details),
      );
    } catch (_) {
      // Notifications are supplementary; they must not fail the download.
    }
  }

  static Future<void> _showCompleted(int id, String fileName) async {
    _activeDownloads.remove(id);
    try {
      await _notifications.cancel(id);
      const details = AndroidNotificationDetails(
        'moeen_downloads',
        'تحميل الملفات',
        channelDescription: 'إشعارات تقدم تحميل ملفات معين',
        importance: Importance.high,
        priority: Priority.high,
        ongoing: false,
        icon: 'ic_notification',
      );
      await _notifications.show(
        id,
        'اكتمل التحميل',
        fileName,
        const NotificationDetails(android: details),
      );
    } catch (_) {
      // Saving already succeeded; notification failures are non-fatal.
    }
  }

  static Future<void> _showFailed(int id, String fileName) async {
    try {
      const details = AndroidNotificationDetails(
        'moeen_downloads',
        'تحميل الملفات',
        channelDescription: 'إشعارات تقدم تحميل ملفات معين',
        importance: Importance.high,
        priority: Priority.high,
        ongoing: false,
        icon: 'ic_notification',
      );
      await _notifications.show(
        id,
        'فشل تحميل الملف',
        fileName,
        const NotificationDetails(android: details),
      );
    } catch (_) {
      // The original failure is more important than notification delivery.
    }
  }

  static String _safeFileName(String value) {
    final trimmed = value.trim().isEmpty ? 'moeen-file' : value.trim();
    return trimmed.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  static String _baseName(String path) {
    final normalized = path.replaceAll('\\', Platform.pathSeparator);
    return normalized.split(Platform.pathSeparator).last;
  }

  static String _ensureFileExtension(String path, String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex >= fileName.length - 1) return path;

    final extension = fileName.substring(dotIndex).toLowerCase();
    if (path.toLowerCase().endsWith(extension)) return path;

    return '$path$extension';
  }

  static Future<Directory> _moeenSectionDirectory(String section) async {
    final safeSection = _safeFileName(section).replaceAll('.', '_');
    final candidates = <Directory>[];
    if (Platform.isAndroid) {
      candidates.add(
        Directory('/storage/emulated/0/Download/Moeen/$safeSection'),
      );
    }
    try {
      final downloads = await getDownloadsDirectory();
      if (downloads != null) {
        candidates.add(
          Directory(
            '${downloads.path}${Platform.pathSeparator}Moeen${Platform.pathSeparator}$safeSection',
          ),
        );
      }
    } catch (_) {
      // Some Android versions do not expose a public downloads directory.
    }
    final docs = await getApplicationDocumentsDirectory();
    final fallback = Directory(
      '${docs.path}${Platform.pathSeparator}Download${Platform.pathSeparator}Moeen${Platform.pathSeparator}$safeSection',
    );
    candidates.add(fallback);

    for (final dir in candidates) {
      try {
        if (!await dir.exists()) await dir.create(recursive: true);
        final probe = File('${dir.path}${Platform.pathSeparator}.moeen_probe');
        await probe.writeAsString('ok', flush: true);
        await probe.delete();
        return dir;
      } catch (_) {
        continue;
      }
    }

    if (!await fallback.exists()) await fallback.create(recursive: true);
    return fallback;
  }

  static Future<File> _uniqueFile(Directory dir, String safeName) async {
    final dotIndex = safeName.lastIndexOf('.');
    final base = dotIndex > 0 ? safeName.substring(0, dotIndex) : safeName;
    final ext = dotIndex > 0 ? safeName.substring(dotIndex) : '';

    var candidate = File('${dir.path}${Platform.pathSeparator}$safeName');
    if (!await candidate.exists()) return candidate;

    for (var i = 2; i < 10000; i++) {
      candidate = File('${dir.path}${Platform.pathSeparator}$base ($i)$ext');
      if (!await candidate.exists()) return candidate;
    }
    return File(
      '${dir.path}${Platform.pathSeparator}$base (${DateTime.now().millisecondsSinceEpoch})$ext',
    );
  }
}
