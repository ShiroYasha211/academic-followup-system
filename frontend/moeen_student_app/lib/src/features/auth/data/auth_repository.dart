import '../../../core/device/device_identity_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/device_not_authorized_exception.dart';
import 'academic_option.dart';
import 'auth_session.dart';

class AuthRepository {
  AuthRepository(this._api, this._deviceIdentity);

  final ApiClient _api;
  final DeviceIdentityService _deviceIdentity;

  Future<AuthSession> login({
    required String login,
    required String password,
  }) async {
    try {
      final device = await _deviceIdentity.loginPayload();
      final response = await _api.post(
        '/student/login',
        data: {'login': login, 'password': password, 'device': device},
      );
      return _sessionFromStudentResponse(response);
    } on ApiException catch (error) {
      // Check for device-not-authorized before falling back to delegate login
      _maybeRethrowDeviceError(error);

      final canTryDelegate =
          login.contains('@') &&
          (error.statusCode == 401 || error.statusCode == 403);
      if (!canTryDelegate) rethrow;
      final response = await _api.post(
        '/delegate/login',
        data: {'email': login, 'password': password},
      );
      return _sessionFromDelegateResponse(response);
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String gender,
    required int universityId,
    required int collegeId,
    required int majorId,
    required int levelId,
    required String studentNumber,
  }) async {
    await _api.post(
      '/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
        'role': role,
        'gender': gender,
        'university_id': universityId,
        'college_id': collegeId,
        'major_id': majorId,
        'level_id': levelId,
        'student_number': studentNumber,
      },
    );
  }

  Future<List<AcademicOption>> universities() =>
      _options('/public/universities');

  Future<List<AcademicOption>> colleges(int universityId) {
    return _options('/public/colleges', query: {'university_id': universityId});
  }

  Future<List<AcademicOption>> majors(int collegeId) {
    return _options('/public/majors', query: {'college_id': collegeId});
  }

  Future<List<AcademicOption>> levels(int majorId) {
    return _options('/public/levels', query: {'major_id': majorId});
  }

  Future<List<AcademicOption>> _options(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final response = await _api.get(path, queryParameters: query);
    final data = response['data'];
    if (data is! List) {
      throw const ApiException('تعذر قراءة بيانات القائمة.');
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(AcademicOption.fromJson)
        .toList();
  }

  Future<Map<String, dynamic>> fetchPublicSupportSettings() async {
    final response = await _api.get('/public/support-settings');
    final data = response['data'];
    if (data is Map<String, dynamic>) return data;
    throw const ApiException('استجابة غير مكتملة من الخادم.');
  }

  AuthSession _sessionFromStudentResponse(Map<String, dynamic> response) {
    final data = response['data'] as Map<String, dynamic>;
    final user = data['user'] as Map<String, dynamic>;
    final device = data['device'];
    final deviceMap = device is Map ? device : const <String, dynamic>{};
    final major = user['major'];
    final role = _roleValue(user['role']);
    final isPracticalDelegate = user['is_practical_delegate'] == true;
    return AuthSession(
      token: data['token'].toString(),
      workspace: role == 'delegate' && !isPracticalDelegate
          ? AuthWorkspace.delegate
          : AuthWorkspace.student,
      role: role,
      name: user['name'].toString(),
      email: user['email']?.toString(),
      isPracticalDelegate: isPracticalDelegate,
      hasClinical: major is Map && major['has_clinical'] == true,
      deviceType: deviceMap['device_type']?.toString(),
      isPrimaryDevice: deviceMap['is_primary'] is bool
          ? deviceMap['is_primary'] as bool
          : null,
      permissions:
          (user['permissions'] as List?)?.map((e) => e.toString()).toList() ??
          [],
    );
  }

  AuthSession _sessionFromDelegateResponse(Map<String, dynamic> response) {
    final data = response['data'] as Map<String, dynamic>;
    final user = data['user'] as Map<String, dynamic>;
    return AuthSession(
      token: data['token'].toString(),
      workspace: AuthWorkspace.delegate,
      role: _roleValue(user['role']),
      name: user['name'].toString(),
      email: user['email']?.toString(),
      isPracticalDelegate: user['is_practical_delegate'] == true,
      hasClinical: user['is_clinical_delegate'] == true,
      permissions:
          (user['permissions'] as List?)?.map((e) => e.toString()).toList() ??
          [],
    );
  }

  String _roleValue(Object? value) {
    if (value is Map && value['value'] != null) {
      return value['value'].toString();
    }
    return (value ?? 'student').toString();
  }

  /// If the ApiException carries a device_not_authorized error code,
  /// throw a typed [DeviceNotAuthorizedException] so the UI can handle it.
  void _maybeRethrowDeviceError(ApiException error) {
    final errors = error.errors;
    if (errors is! Map) return;

    final code = errors['error_code']?.toString();
    if (code == 'device_not_authorized') {
      final whatsapp = errors['whatsapp_number']?.toString();
      throw DeviceNotAuthorizedException(
        whatsappNumber: (whatsapp != null && whatsapp.isNotEmpty)
            ? whatsapp
            : null,
      );
    }
  }
}
