import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

class OfflineCacheEntry {
  const OfflineCacheEntry({required this.data, required this.cachedAt});

  final Map<String, dynamic> data;
  final DateTime cachedAt;
}

class OfflineCacheService {
  const OfflineCacheService(FlutterSecureStorage storage);

  Future<void> saveJson(String key, Map<String, dynamic> data) async {
    final file = await _fileForKey(key);
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode({
        'cached_at': DateTime.now().toIso8601String(),
        'data': data,
      }),
      encoding: utf8,
      flush: true,
    );
  }

  Future<OfflineCacheEntry?> readJson(String key) async {
    final file = await _fileForKey(key);
    if (!await file.exists()) return null;
    final raw = await file.readAsString(encoding: utf8);
    if (raw.isEmpty) return null;

    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    final data = decoded['data'];
    if (data is! Map) return null;

    final cachedAt =
        DateTime.tryParse(decoded['cached_at']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return OfflineCacheEntry(
      data: Map<String, dynamic>.from(data),
      cachedAt: cachedAt,
    );
  }

  Future<void> clear(String key) async {
    final file = await _fileForKey(key);
    if (await file.exists()) await file.delete();
  }

  Future<File> _fileForKey(String key) async {
    final dir = await getApplicationSupportDirectory();
    final safeName = base64Url.encode(utf8.encode(key));
    return File('${dir.path}${Platform.pathSeparator}offline_cache'
        '${Platform.pathSeparator}$safeName.json');
  }
}
