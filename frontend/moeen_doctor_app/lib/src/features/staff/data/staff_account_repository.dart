import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/offline/offline_cache_service.dart';
import '../../auth/data/staff_auth_session.dart';
import 'staff_account_models.dart';

class StaffAccountRepository {
  const StaffAccountRepository(this._api, {this.cache, this.cachePrefix});

  final ApiClient _api;
  final OfflineCacheService? cache;
  final String? cachePrefix;

  Future<StaffDashboardData> dashboard(StaffWorkspace workspace) async {
    final response = await _cachedGet('/${workspace.name}/dashboard');
    final cacheMeta = _cacheMeta(response);
    return StaffDashboardData(
      raw: _data(response),
      isAdministrative: workspace == StaffWorkspace.administrative,
      fromCache: cacheMeta != null,
      cachedAt: cacheMeta,
    );
  }

  Future<StaffSubscriptionOverview> subscription(
    StaffWorkspace workspace,
  ) async {
    final response = await _cachedGet('/${workspace.name}/subscription');
    return StaffSubscriptionOverview.fromJson(_data(response));
  }

  Future<String> redeem(StaffWorkspace workspace, String code) async {
    final response = await _api.post(
      '/${workspace.name}/subscription/redeem',
      data: {'code': code},
    );
    return (response['message'] ?? 'تم شحن الرصيد بنجاح.').toString();
  }

  Future<String> subscribe(StaffWorkspace workspace, int packageId) async {
    final response = await _api.post(
      '/${workspace.name}/subscription/subscribe',
      data: {'package_id': packageId},
    );
    return (response['message'] ?? 'تم تفعيل الاشتراك بنجاح.').toString();
  }

  Future<String> toggleAutoRenew(StaffWorkspace workspace, bool value) async {
    final response = await _api.post(
      '/${workspace.name}/subscription/auto-renew',
      data: {'auto_renew': value},
    );
    return (response['message'] ?? 'تم تحديث التجديد التلقائي.').toString();
  }

  Future<StaffFinancialLedger> ledger(
    StaffWorkspace workspace, {
    int page = 1,
  }) async {
    final response = await _cachedGet(
      '/${workspace.name}/ledger',
      query: {'page': page},
    );
    return StaffFinancialLedger.fromJson(_data(response));
  }

  Future<List<int>> exportLedger(StaffWorkspace workspace) {
    return _api.getBytes('/${workspace.name}/ledger/export');
  }

  Future<StaffProfile> profile(StaffWorkspace workspace) async {
    final response = await _cachedGet('/${workspace.name}/me');
    return StaffProfile.fromJson(_data(response));
  }

  Future<StaffAdministrativeSettings> administrativeSettings() async {
    final response = await _cachedGet('/administrative/settings');
    return StaffAdministrativeSettings.fromJson(_data(response));
  }

  Future<String> updateAdministrativeSettings({
    required int absenceDeprivationPercentage,
    required int excusesDeadlineDays,
    required String excuseReceiver,
    required int qrRotationSeconds,
  }) async {
    final response = await _api.put(
      '/administrative/settings',
      data: {
        'absence_deprivation_percentage': absenceDeprivationPercentage,
        'excuses_deadline_days': excusesDeadlineDays,
        'excuse_receiver': excuseReceiver,
        'qr_rotation_seconds': qrRotationSeconds,
      },
    );
    return (response['message'] ?? 'تم تحديث إعدادات الكلية بنجاح.').toString();
  }

  Future<String> changePassword({
    required StaffWorkspace workspace,
    required String currentPassword,
    required String password,
    required String confirmation,
  }) async {
    final response = await _api.post(
      '/${workspace.name}/change-password',
      data: {
        'current_password': currentPassword,
        'password': password,
        'password_confirmation': confirmation,
      },
    );
    return (response['message'] ?? 'تم تغيير كلمة المرور بنجاح.').toString();
  }

  Future<Map<String, dynamic>> updateEmail({
    required StaffWorkspace workspace,
    required String email,
    required String currentPassword,
  }) async {
    final response = await _api.patch(
      '/${workspace.name}/profile/email',
      data: {
        'email': email,
        'current_password': currentPassword,
      },
    );
    return _data(response);
  }

  Map<String, dynamic> _data(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
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
      cachePrefix ?? 'staff.account',
      'get',
      path,
      if (normalizedQuery.isNotEmpty) jsonEncode(normalizedQuery),
    ].join('|');
  }

  DateTime? _cacheMeta(Map<String, dynamic> response) {
    final meta = response['_offline_cache'];
    if (meta is! Map) return null;
    return DateTime.tryParse(meta['cached_at']?.toString() ?? '');
  }
}
