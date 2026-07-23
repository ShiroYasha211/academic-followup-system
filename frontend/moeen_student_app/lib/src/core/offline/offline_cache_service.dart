import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class OfflineCacheService {
  const OfflineCacheService();

  static const maxOfflineAge = Duration(hours: 72);
  static const staleAfter = Duration(hours: 24);

  Future<void> writeMap(String key, Map<String, dynamic> data) async {
    final file = await _fileForKey(key);
    await file.parent.create(recursive: true);
    final payload = {
      'cached_at': DateTime.now().toUtc().toIso8601String(),
      'data': data,
    };
    await file.writeAsString(jsonEncode(payload), flush: true);
  }

  Future<Map<String, dynamic>?> readMap(
    String key, {
    Duration maxAge = maxOfflineAge,
  }) async {
    final file = await _fileForKey(key);
    if (!await file.exists()) return null;

    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) return null;
      final cachedAtRaw = decoded['cached_at']?.toString();
      final data = decoded['data'];
      if (cachedAtRaw == null || data is! Map<String, dynamic>) return null;

      final cachedAt = DateTime.tryParse(cachedAtRaw)?.toUtc();
      if (cachedAt == null) return null;
      final age = DateTime.now().toUtc().difference(cachedAt);
      if (age > maxAge) return null;

      return {
        ...data,
        '_offline': true,
        '_cached_at': cachedAt.toIso8601String(),
        '_cache_age_hours': age.inHours,
        '_offline_stale': age > staleAfter,
      };
    } catch (_) {
      return null;
    }
  }

  Future<File> _fileForKey(String key) async {
    final dir = await getApplicationDocumentsDirectory();
    final safeKey = base64Url.encode(utf8.encode(key)).replaceAll('=', '');
    return File('${dir.path}/moeen_cache/$safeKey.json');
  }
}
