import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/offline/offline_cache_service.dart';

class StaffRepository {
  const StaffRepository(this._api, {this.cache, this.cachePrefix});

  final ApiClient _api;
  final OfflineCacheService? cache;
  final String? cachePrefix;

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) {
    return _cachedGet(path, query: query);
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> data) {
    return _api.post(path, data: data);
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> data) {
    return _api.put(path, data: data);
  }

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> data) {
    return _api.patch(path, data: data);
  }

  Future<Map<String, dynamic>> delete(String path) {
    return _api.delete(path);
  }

  Future<Map<String, dynamic>> upload(
    String path,
    Map<String, dynamic> fields,
  ) {
    return _api.post(path, data: FormData.fromMap(fields));
  }

  Future<Map<String, dynamic>> uploadPut(
    String path,
    Map<String, dynamic> fields,
  ) {
    return _api.post(path, data: FormData.fromMap({...fields, '_method': 'PUT'}));
  }

  Future<List<int>> download(String path, {Map<String, dynamic>? query}) {
    return _api.getBytes(path, queryParameters: query);
  }

  Future<Map<String, dynamic>> _cachedGet(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final cacheKey = _cacheKey(path, query);
    try {
      final response = await _api.get(path, queryParameters: query);
      await _saveCache(cacheKey, response);
      return response;
    } on ApiException catch (error) {
      if (!_canUseCache(error)) rethrow;
      final cached = await _readCache(cacheKey);
      if (cached == null) rethrow;
      return {
        ...cached.data,
        '_offline_cache': {
          'from_cache': true,
          'cached_at': cached.cachedAt.toIso8601String(),
        },
      };
    }
  }

  Future<void> _saveCache(String key, Map<String, dynamic> response) async {
    try {
      await cache?.saveJson(key, response);
    } catch (_) {}
  }

  Future<OfflineCacheEntry?> _readCache(String key) async {
    try {
      return await cache?.readJson(key);
    } catch (_) {
      return null;
    }
  }

  bool _canUseCache(ApiException error) {
    final status = error.statusCode;
    return status == null || status >= 500;
  }

  String _cacheKey(String path, Map<String, dynamic>? query) {
    final keys = query?.keys.toList() ?? <String>[];
    keys.sort();
    final normalizedQuery = <String, dynamic>{
      for (final key in keys)
        if (query![key] != null) key: query[key],
    };
    return [
      cachePrefix ?? 'staff',
      'get',
      path,
      if (normalizedQuery.isNotEmpty) jsonEncode(normalizedQuery),
    ].join('|');
  }
}
