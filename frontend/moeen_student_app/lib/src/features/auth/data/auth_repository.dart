import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'academic_option.dart';
import 'auth_session.dart';

class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  Future<AuthSession> login({
    required String login,
    required String password,
  }) async {
    try {
      final response = await _api.post(
        '/student/login',
        data: {'login': login, 'password': password},
      );
      return _sessionFromStudentResponse(response);
    } on ApiException catch (error) {
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

  AuthSession _sessionFromStudentResponse(Map<String, dynamic> response) {
    final data = response['data'] as Map<String, dynamic>;
    final user = data['user'] as Map<String, dynamic>;
    return AuthSession(
      token: data['token'].toString(),
      workspace: AuthWorkspace.student,
      role: _roleValue(user['role']),
      name: user['name'].toString(),
      email: user['email']?.toString(),
      isPracticalDelegate: user['is_practical_delegate'] == true,
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
    );
  }

  String _roleValue(Object? value) {
    if (value is Map && value['value'] != null) {
      return value['value'].toString();
    }
    return (value ?? 'student').toString();
  }
}
