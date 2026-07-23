import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class DownloadSaveResult {
  const DownloadSaveResult({
    required this.path,
    required this.opened,
    this.cancelled = false,
  });

  final String path;
  final bool opened;
  final bool cancelled;
}

class DownloadService {
  DownloadService._();

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      const android = AndroidInitializationSettings('ic_notification');
      await _notifications.initialize(
        const InitializationSettings(android: android),
      );
      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } catch (_) {
      // Notifications are supplementary; downloads must still succeed.
    } finally {
      _initialized = true;
    }
  }

  static Future<DownloadSaveResult> saveBytes({
    required List<int> bytes,
    required String fileName,
    required String section,
    bool openAfterSave = true,
  }) async {
    await initialize();
    final id = Random().nextInt(2147480000);
    final safeName = _safeFileName(fileName);
    await _showProgress(id, safeName);

    final directory = await _sectionDirectory(section);
    final file = await _uniqueFile(directory, safeName);
    await file.writeAsBytes(Uint8List.fromList(bytes), flush: true);
    await _showCompleted(id, safeName);

    var opened = false;
    if (openAfterSave) {
      try {
        final result = await OpenFilex.open(file.path);
        opened = result.type == ResultType.done;
      } catch (_) {
        opened = false;
      }
    }

    return DownloadSaveResult(path: file.path, opened: opened);
  }

  static Future<DownloadSaveResult> downloadUrlToMoeenFolder({
    required String url,
    required String fileName,
    required String section,
    bool openAfterSave = true,
  }) async {
    final response = await Dio().get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    return saveBytes(
      bytes: response.data ?? const [],
      fileName: fileName,
      section: section,
      openAfterSave: openAfterSave,
    );
  }

  static Future<String?> openMoeenFile({
    required String fileName,
    required String section,
  }) async {
    final safeName = _safeFileName(fileName);
    for (final directory in await _sectionDirectoryCandidates(section)) {
      final file = File('${directory.path}${Platform.pathSeparator}$safeName');
      if (!await file.exists()) continue;
      try {
        final result = await OpenFilex.open(file.path);
        return result.type == ResultType.done ? file.path : null;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static Future<DownloadSaveResult> saveBytesWithPicker({
    required List<int> bytes,
    required String fileName,
    bool openAfterSave = true,
  }) async {
    await initialize();
    final id = Random().nextInt(2147480000);
    final safeName = _safeFileName(fileName);
    await _showProgress(id, safeName);

    final chosenPath = await FilePicker.platform.saveFile(
      dialogTitle: 'اختر مكان حفظ الملف',
      fileName: safeName,
      bytes: Uint8List.fromList(bytes),
    );
    if (chosenPath == null || chosenPath.isEmpty) {
      await _notifications.cancel(id);
      return const DownloadSaveResult(path: '', opened: false, cancelled: true);
    }

    final finalPath = _ensureExtension(chosenPath, safeName);
    final file = File(finalPath);
    if (!await file.exists()) {
      await file.writeAsBytes(Uint8List.fromList(bytes), flush: true);
    }
    await _showCompleted(id, safeName);

    var opened = false;
    if (openAfterSave) {
      try {
        final result = await OpenFilex.open(file.path);
        opened = result.type == ResultType.done;
      } catch (_) {
        opened = false;
      }
    }
    return DownloadSaveResult(path: file.path, opened: opened);
  }

  static Future<void> _showProgress(int id, String fileName) async {
    try {
      const details = AndroidNotificationDetails(
        'moeen_downloads',
        'تحميل الملفات',
        channelDescription: 'إشعارات تقدم تحميل ملفات معين',
        importance: Importance.low,
        priority: Priority.low,
        showProgress: true,
        indeterminate: true,
        ongoing: true,
        onlyAlertOnce: true,
        icon: 'ic_notification',
      );
      await _notifications.show(
        id,
        'جاري تحميل الملف',
        fileName,
        const NotificationDetails(android: details),
      );
    } catch (_) {}
  }

  static Future<void> _showCompleted(int id, String fileName) async {
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
    } catch (_) {}
  }

  static Future<Directory> _sectionDirectory(String section) async {
    final candidates = await _sectionDirectoryCandidates(section);
    final fallback = candidates.last;

    for (final candidate in candidates) {
      try {
        if (!await candidate.exists()) await candidate.create(recursive: true);
        final probe = File(
          '${candidate.path}${Platform.pathSeparator}.moeen_probe',
        );
        await probe.writeAsString('ok', flush: true);
        await probe.delete();
        return candidate;
      } catch (_) {}
    }

    if (!await fallback.exists()) await fallback.create(recursive: true);
    return fallback;
  }

  static Future<List<Directory>> _sectionDirectoryCandidates(
    String section,
  ) async {
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
    } catch (_) {}

    final documents = await getApplicationDocumentsDirectory();
    final fallback = Directory(
      '${documents.path}${Platform.pathSeparator}Download${Platform.pathSeparator}Moeen${Platform.pathSeparator}$safeSection',
    );
    candidates.add(fallback);
    return candidates;
  }

  static Future<File> _uniqueFile(Directory dir, String safeName) async {
    final dot = safeName.lastIndexOf('.');
    final base = dot > 0 ? safeName.substring(0, dot) : safeName;
    final ext = dot > 0 ? safeName.substring(dot) : '';
    var file = File('${dir.path}${Platform.pathSeparator}$safeName');
    if (!await file.exists()) return file;

    for (var i = 2; i < 10000; i++) {
      file = File('${dir.path}${Platform.pathSeparator}$base ($i)$ext');
      if (!await file.exists()) return file;
    }

    return File(
      '${dir.path}${Platform.pathSeparator}$base (${DateTime.now().millisecondsSinceEpoch})$ext',
    );
  }

  static String _safeFileName(String value) {
    final trimmed = value.trim().isEmpty ? 'moeen-file' : value.trim();
    return trimmed.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  static String _ensureExtension(String path, String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot <= 0 || dot >= fileName.length - 1) return path;
    final extension = fileName.substring(dot).toLowerCase();
    return path.toLowerCase().endsWith(extension) ? path : '$path$extension';
  }
}
