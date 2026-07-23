import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/authenticated_api_client.dart';

final practicalDelegateRepositoryProvider =
    Provider<PracticalDelegateRepository>(
      (ref) => PracticalDelegateRepository(
        ref.watch(authenticatedApiClientProvider),
      ),
    );

class PracticalDelegateRepository {
  const PracticalDelegateRepository(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> logbook() async {
    return _data(await _api.get('/student/clinical/logbook'));
  }

  Future<Map<String, dynamic>> evaluations() async {
    return _data(await _api.get('/student/clinical/evaluations'));
  }

  Future<Map<String, dynamic>> mockExams() async {
    return _data(await _api.get('/student/clinical/mock-exams'));
  }

  Future<Map<String, dynamic>> ownPendingCases() async {
    return _data(await _api.get('/student/clinical/cases/pending'));
  }

  Future<Map<String, dynamic>> reviewPendingCases() async {
    return _data(await _api.get('/delegate/clinical/cases/pending'));
  }

  Future<String> approveCase(int id) async {
    final response = await _api.post('/delegate/clinical/cases/$id/approve');
    return (response['message'] ?? 'تم اعتماد الحالة بنجاح.').toString();
  }

  Future<String> rejectCase({required int id, required String reason}) async {
    final response = await _api.post(
      '/delegate/clinical/cases/$id/reject',
      data: {'rejection_reason': reason},
    );
    return (response['message'] ?? 'تم رفض الحالة.').toString();
  }

  Future<Map<String, dynamic>> delegations() async {
    return _data(await _api.get('/delegate/clinical/delegations'));
  }

  Future<List<dynamic>> eligibleStudents() async {
    return _list(await _api.get('/delegate/clinical/delegations/students'));
  }

  Future<String> createDelegation({
    required int studentId,
    required int durationHours,
  }) async {
    final response = await _api.post(
      '/delegate/clinical/delegations',
      data: {'student_id': studentId, 'duration_hours': durationHours},
    );
    return (response['message'] ?? 'تم منح الصلاحية بنجاح.').toString();
  }

  Future<String> revokeDelegation(int id) async {
    final response = await _api.delete('/delegate/clinical/delegations/$id');
    return (response['message'] ?? 'تم سحب الصلاحية بنجاح.').toString();
  }
}

Map<String, dynamic> _data(Map<String, dynamic> response) {
  final data = response['data'];
  if (data is Map<String, dynamic>) return data;
  if (data is Map)
    return data.map((key, value) => MapEntry(key.toString(), value));
  throw const ApiException('استجابة غير مكتملة من الخادم.');
}

List<dynamic> _list(Map<String, dynamic> response) {
  final data = response['data'];
  if (data is List) return data;
  if (data is Map) {
    final nested = data['data'];
    if (nested is List) return nested;
    for (final value in data.values) {
      if (value is List) return value;
    }
  }
  throw const ApiException('استجابة غير مكتملة من الخادم.');
}
