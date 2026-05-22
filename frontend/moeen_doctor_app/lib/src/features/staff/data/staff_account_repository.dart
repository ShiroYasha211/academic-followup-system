import '../../../core/network/api_client.dart';
import '../../auth/data/staff_auth_session.dart';
import 'staff_account_models.dart';

class StaffAccountRepository {
  const StaffAccountRepository(this._api);

  final ApiClient _api;

  Future<StaffDashboardData> dashboard(StaffWorkspace workspace) async {
    final response = await _api.get('/${workspace.name}/dashboard');
    return StaffDashboardData(
      raw: _data(response),
      isAdministrative: workspace == StaffWorkspace.administrative,
    );
  }

  Future<StaffSubscriptionOverview> subscription(
    StaffWorkspace workspace,
  ) async {
    final response = await _api.get('/${workspace.name}/subscription');
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
    final response = await _api.get(
      '/${workspace.name}/ledger',
      queryParameters: {'page': page},
    );
    return StaffFinancialLedger.fromJson(_data(response));
  }

  Future<List<int>> exportLedger(StaffWorkspace workspace) {
    return _api.getBytes('/${workspace.name}/ledger/export');
  }

  Future<StaffProfile> profile(StaffWorkspace workspace) async {
    final response = await _api.get('/${workspace.name}/me');
    return StaffProfile.fromJson(_data(response));
  }

  Future<StaffAdministrativeSettings> administrativeSettings() async {
    final response = await _api.get('/administrative/settings');
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
}
