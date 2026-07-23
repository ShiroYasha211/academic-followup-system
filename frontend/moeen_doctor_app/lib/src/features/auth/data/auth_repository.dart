import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'academic_option.dart';
import 'staff_auth_session.dart';

class AuthRepository {
  const AuthRepository(this._api);

  final ApiClient _api;

  Future<StaffAuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      '/doctor/login',
      data: {'email': email, 'password': password},
    );
    return _sessionFromResponse(response);
  }

  Future<void> registerDoctor({
    required String name,
    required String email,
    required String password,
    required int universityId,
    required int collegeId,
  }) async {
    await _api.post(
      '/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
        'role': 'doctor',
        'university_id': universityId,
        'college_id': collegeId,
      },
    );
  }

  Future<List<AcademicOption>> universities() =>
      _options('/public/universities');

  Future<List<AcademicOption>> colleges(int universityId) {
    return _options('/public/colleges', query: {'university_id': universityId});
  }

  Future<void> logout(String token, StaffWorkspace workspace) async {
    await ApiClient(token: token).post('/${workspace.name}/logout');
  }

  Future<StaffAuthSession> refresh(StaffAuthSession session) async {
    Map<String, dynamic> response;
    try {
      response = await ApiClient(
        token: session.token,
      ).get('/${session.workspace.name}/me');
    } on ApiException catch (error) {
      if (session.workspace != StaffWorkspace.administrative ||
          error.statusCode != 403) {
        rethrow;
      }
      response = await ApiClient(token: session.token).get('/doctor/me');
    }
    final data = response['data'];
    if (data is! Map) return session;
    final availableWorkspaces = _parseWorkspaces(data['available_workspaces']);
    final workspace = availableWorkspaces.contains(session.workspace)
        ? session.workspace
        : availableWorkspaces.contains(StaffWorkspace.doctor)
        ? StaffWorkspace.doctor
        : availableWorkspaces.first;
    return session.copyWith(
      workspace: workspace,
      name: (data['name'] ?? session.name).toString(),
      email: (data['email'] ?? session.email).toString(),
      role: (data['role'] ?? session.role).toString(),
      university: data['university']?.toString(),
      college: data['college']?.toString(),
      major: data['major']?.toString(),
      availableWorkspaces: availableWorkspaces,
    );
  }

  StaffAuthSession _sessionFromResponse(Map<String, dynamic> response) {
    final data = response['data'];
    final user = data is Map ? data['user'] : null;
    if (data is! Map || user is! Map) {
      throw StateError('استجابة الدخول غير مكتملة.');
    }
    final workspaces = _parseWorkspaces(user['available_workspaces']);
    final workspace = workspaces.contains(StaffWorkspace.doctor)
        ? StaffWorkspace.doctor
        : workspaces.first;
    return StaffAuthSession(
      token: data['token'].toString(),
      workspace: workspace,
      availableWorkspaces: workspaces,
      name: (user['name'] ?? '').toString(),
      email: (user['email'] ?? '').toString(),
      role: (user['role'] ?? 'doctor').toString(),
    );
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

  List<StaffWorkspace> _parseWorkspaces(Object? raw) {
    if (raw is List) {
      final parsed = raw
          .map((item) => item.toString())
          .map(_workspaceFromString)
          .whereType<StaffWorkspace>()
          .toSet()
          .toList();
      return parsed.isEmpty ? const [StaffWorkspace.doctor] : parsed;
    }
    return const [StaffWorkspace.doctor];
  }

  StaffWorkspace? _workspaceFromString(String value) {
    return switch (value) {
      'doctor' => StaffWorkspace.doctor,
      'administrative' => StaffWorkspace.administrative,
      _ => null,
    };
  }
}
