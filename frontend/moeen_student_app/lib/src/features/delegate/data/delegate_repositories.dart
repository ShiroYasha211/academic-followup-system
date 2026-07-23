import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/authenticated_api_client.dart';
import '../../student/data/models/financial_ledger.dart';
import '../../student/data/models/subscription_models.dart';

final delegateRepositoryProvider = Provider<DelegateRepository>((ref) {
  return DelegateRepository(ref.watch(authenticatedApiClientProvider));
});

final delegateSubscriptionRepositoryProvider =
    Provider<DelegateSubscriptionRepository>((ref) {
      return DelegateSubscriptionRepository(
        ref.watch(authenticatedApiClientProvider),
      );
    });

final delegateLedgerRepositoryProvider = Provider<DelegateLedgerRepository>((
  ref,
) {
  return DelegateLedgerRepository(ref.watch(authenticatedApiClientProvider));
});

class DelegateRepository {
  const DelegateRepository(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> dashboard() async =>
      _data(await _api.get('/delegate/dashboard'));

  Future<Map<String, dynamic>> me() async =>
      _data(await _api.get('/delegate/me'));

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmation,
  }) async {
    final response = await _api.post(
      '/delegate/change-password',
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': confirmation,
      },
    );
    return (response['message'] ?? 'تم تغيير كلمة المرور بنجاح.').toString();
  }

  Future<Map<String, dynamic>> notifications() async =>
      _data(await _api.get('/delegate/notifications'));

  Future<String> markNotificationRead(int id) async {
    final response = await _api.post('/delegate/notifications/$id/read');
    return (response['message'] ?? 'تم تحديد التنبيه كمقروء.').toString();
  }

  Future<String> markAllNotificationsRead() async {
    final response = await _api.post('/delegate/notifications/mark-all-read');
    return (response['message'] ?? 'تم تحديد جميع التنبيهات كمقروءة.')
        .toString();
  }

  Future<Map<String, dynamic>> news() async =>
      _data(await _api.get('/delegate/news'));

  Future<Map<String, dynamic>> newsDetails(String batchId) async =>
      _data(await _api.get('/delegate/news/$batchId'));

  Future<String> voteNews({
    required String batchId,
    required int optionId,
  }) async {
    final response = await _api.post(
      '/delegate/news/$batchId/vote',
      data: {'option_id': optionId},
    );
    return (response['message'] ?? 'تم تسجيل التصويت.').toString();
  }

  Future<String> markAllNewsAsRead() async {
    final response = await _api.post('/delegate/news/mark-all-as-read');
    return (response['message'] ?? 'تم تحديد الكل كمقروء.').toString();
  }

  Future<Map<String, dynamic>> students({
    int page = 1,
    String? query,
    bool all = false,
  }) async => _data(
    await _api.get(
      '/delegate/students',
      queryParameters: {
        'page': page,
        if (query != null) 'query': query,
        if (all) 'all': 1,
      },
    ),
  );

  Future<List<int>> downloadTemplate() async =>
      await _api.getBytes('/delegate/students/template');

  Future<Map<String, dynamic>> importStudents(String filePath) async {
    final formData = FormData.fromMap({
      'csv_file': await MultipartFile.fromFile(
        filePath,
        filename: 'students.csv',
      ),
    });
    return _data(await _api.post('/delegate/students/import', data: formData));
  }

  Future<String> createStudent(Map<String, dynamic> data) async {
    final response = await _api.post('/delegate/students', data: data);
    return (response['message'] ?? 'تمت إضافة الطالب.').toString();
  }

  Future<String> updateStudent(int id, Map<String, dynamic> data) async {
    final response = await _api.put('/delegate/students/$id', data: data);
    return (response['message'] ?? 'تم تحديث الطالب.').toString();
  }

  Future<String> deleteStudent(int id) async {
    final response = await _api.delete('/delegate/students/$id');
    return (response['message'] ?? 'تم حذف الطالب.').toString();
  }

  Future<Map<String, dynamic>> studentPermissions(int id) async =>
      _data(await _api.get('/delegate/students/$id/permissions'));

  Future<String> updateStudentPermissions({
    required int id,
    required bool canUploadLibrary,
  }) async {
    final response = await _api.post(
      '/delegate/students/$id/permissions',
      data: {
        'permissions': canUploadLibrary
            ? ['upload_shared_library']
            : <String>[],
      },
    );
    return (response['message'] ?? 'تم تحديث الصلاحيات.').toString();
  }

  Future<List<dynamic>> subjects() async =>
      _list(await _api.get('/delegate/subjects'));

  Future<List<dynamic>> doctors() async =>
      _list(await _api.get('/delegate/subjects/doctors'));

  Future<Map<String, dynamic>> subjectTermOptions() async {
    final response = await _api.get('/delegate/subjects/terms');
    final data = response['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return data.cast<String, dynamic>();
    return {'terms': _list(response)};
  }

  Future<List<dynamic>> terms() async {
    final options = await subjectTermOptions();
    final terms = options['terms'];
    return terms is List ? terms : const <dynamic>[];
  }

  Future<Map<String, dynamic>> subjectDetails(int id) async =>
      _data(await _api.get('/delegate/subjects/$id'));

  Future<String> saveSubject({
    int? id,
    required Map<String, dynamic> data,
  }) async {
    final response = id == null
        ? await _api.post('/delegate/subjects', data: data)
        : await _api.put('/delegate/subjects/$id', data: data);
    return (response['message'] ?? 'تم حفظ المادة.').toString();
  }

  Future<String> deleteSubject(int id) async {
    final response = await _api.delete('/delegate/subjects/$id');
    return (response['message'] ?? 'تم حذف المادة.').toString();
  }

  Future<List<dynamic>> schedules() async =>
      _list(await _api.get('/delegate/schedules'));

  Future<String> saveSchedule({
    int? id,
    required Map<String, dynamic> data,
  }) async {
    final response = id == null
        ? await _api.post('/delegate/schedules', data: data)
        : await _api.put('/delegate/schedules/$id', data: data);
    return (response['message'] ?? 'تم حفظ المحاضرة.').toString();
  }

  Future<String> deleteSchedule(int id) async {
    final response = await _api.delete('/delegate/schedules/$id');
    return (response['message'] ?? 'تم حذف المحاضرة.').toString();
  }

  Future<List<dynamic>> examSchedules() async =>
      _list(await _api.get('/delegate/exam-schedules'));

  Future<String> saveExamSchedule({
    int? id,
    required Map<String, dynamic> data,
  }) async {
    final response = id == null
        ? await _api.post('/delegate/exam-schedules', data: data)
        : await _api.put('/delegate/exam-schedules/$id', data: data);
    return (response['message'] ?? 'تم حفظ جدول الاختبارات.').toString();
  }

  Future<String> deleteExamSchedule(int id) async {
    final response = await _api.delete('/delegate/exam-schedules/$id');
    return (response['message'] ?? 'تم حذف جدول الاختبارات.').toString();
  }

  Future<List<dynamic>> assignments() async =>
      _list(await _api.get('/delegate/assignments'));

  Future<Map<String, dynamic>> assignmentPermissions() async =>
      _data(await _api.get('/delegate/assignments/permissions'));

  Future<String> saveAssignment({
    int? id,
    required Map<String, dynamic> data,
  }) async {
    final response = id == null
        ? await _api.post('/delegate/assignments', data: data)
        : await _api.put('/delegate/assignments/$id', data: data);
    return (response['message'] ?? 'تم حفظ التكليف.').toString();
  }

  Future<String> deleteAssignment(int id) async {
    final response = await _api.delete('/delegate/assignments/$id');
    return (response['message'] ?? 'تم حذف التكليف.').toString();
  }

  Future<Map<String, dynamic>> resources({
    String? search,
    int? subjectId,
    String? category,
  }) async {
    return _data(
      await _api.get(
        '/delegate/resources',
        queryParameters: {
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
          if (subjectId != null && subjectId > 0) 'subject_id': subjectId,
          if (category != null && category != 'all') 'category': category,
        },
      ),
    );
  }

  Future<String> uploadResource({
    required int subjectId,
    required String title,
    required String category,
    required String filePath,
    required String fileName,
    String? description,
  }) async {
    final form = FormData.fromMap({
      'subject_id': subjectId,
      'title': title,
      'category': category,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final response = await _api.post('/delegate/resources', data: form);
    return (response['message'] ?? 'تم رفع الملف.').toString();
  }

  Future<String> updateResource({
    required int id,
    required int subjectId,
    required String title,
    required String category,
    String? description,
  }) async {
    final response = await _api.put(
      '/delegate/resources/$id',
      data: {
        'subject_id': subjectId,
        'title': title,
        'category': category,
        if (description != null) 'description': description,
      },
    );
    return (response['message'] ?? 'تم تحديث بيانات الملف.').toString();
  }

  Future<String> deleteResource(int id) async {
    final response = await _api.delete('/delegate/resources/$id');
    return (response['message'] ?? 'تم حذف الملف.').toString();
  }

  Future<List<dynamic>> searchLibrary({
    String? query,
    String? category,
    int? subjectId,
  }) async {
    final response = await _api.get(
      '/delegate/resources/library/search',
      queryParameters: {
        if (query != null && query.isNotEmpty) 'q': query,
        if (category != null && category != 'all') 'category': category,
        if (subjectId != null && subjectId > 0) 'subject_id': subjectId,
      },
    );
    return _list(response);
  }

  Future<String> importResource({
    required int resourceId,
    required int subjectId,
  }) async {
    final response = await _api.post(
      '/delegate/resources/import',
      data: {'resource_id': resourceId, 'subject_id': subjectId},
    );
    return (response['message'] ?? 'تم استيراد الملف.').toString();
  }

  Future<Map<String, dynamic>> reminders({String filter = 'upcoming'}) async =>
      _data(
        await _api.get(
          '/delegate/reminders',
          queryParameters: {'filter': filter},
        ),
      );

  Future<Map<String, dynamic>> announcements({
    String? query,
    String? category,
  }) async => _data(
    await _api.get(
      '/delegate/announcements',
      queryParameters: {
        if (query != null && query.isNotEmpty) 'q': query,
        if (category != null && category != 'all') 'category': category,
      },
    ),
  );

  Future<String> saveReminder({
    int? id,
    required Map<String, dynamic> data,
  }) async {
    final response = id == null
        ? await _api.post('/delegate/reminders', data: data)
        : await _api.put('/delegate/reminders/$id', data: data);
    return (response['message'] ?? 'تم حفظ التذكير.').toString();
  }

  Future<String> deleteReminder(int id) async {
    final response = await _api.delete('/delegate/reminders/$id');
    return (response['message'] ?? 'تم حذف التذكير.').toString();
  }

  Future<String> saveAnnouncement({
    int? id,
    required Map<String, dynamic> data,
  }) async {
    Object? finalData = data;

    // Check if we have a file (attachment)
    if (data['attachment'] != null) {
      finalData = FormData.fromMap({...data, if (id != null) '_method': 'PUT'});
    }

    final response = id == null
        ? await _api.post('/delegate/announcements', data: finalData)
        : (data['attachment'] != null
              ? await _api.post('/delegate/announcements/$id', data: finalData)
              : await _api.put('/delegate/announcements/$id', data: finalData));

    return (response['message'] ?? 'تم نشر الإعلان.').toString();
  }

  Future<String> toggleAnnouncementPin(int id) async {
    final response = await _api.patch('/delegate/announcements/$id/toggle-pin');
    return (response['message'] ?? 'تم تحديث حالة التثبيت.').toString();
  }

  Future<String> deleteAnnouncement(int id) async {
    final response = await _api.delete('/delegate/announcements/$id');
    return (response['message'] ?? 'تم حذف الإعلان.').toString();
  }

  Future<Map<String, dynamic>> attendance({
    String? search,
    String? date,
  }) async => _data(
    await _api.get(
      '/delegate/attendances',
      queryParameters: {
        if (search != null) 'search': search,
        if (date != null) 'date': date,
      },
    ),
  );

  Future<Map<String, dynamic>> attendanceCreate({
    required int subjectId,
    String? date,
    int? qrSessionId,
    int? lectureId,
  }) async {
    return _data(
      await _api.get(
        '/delegate/attendances/$subjectId/create',
        queryParameters: {
          if (date != null) 'date': date,
          if (qrSessionId != null) 'qr_session_id': qrSessionId,
          if (lectureId != null) 'lecture_id': lectureId,
        },
      ),
    );
  }

  Future<String> saveAttendance(Map<String, dynamic> data) async {
    final response = await _api.post('/delegate/attendances', data: data);
    return (response['message'] ?? 'تم حفظ الحضور.').toString();
  }

  Future<String> requestAttendanceEdit(Map<String, dynamic> data) async {
    final response = await _api.post(
      '/delegate/attendance-edit-requests',
      data: data,
    );
    return (response['message'] ?? 'تم إرسال طلب فتح تعديل الحضور.').toString();
  }

  Future<Map<String, dynamic>> issuePairingCode({
    required int subjectId,
    required String date,
    required String title,
    String? lectureNumber,
    String? deviceName,
  }) async {
    return _data(
      await _api.post(
        '/delegate/desktop/pairing-code',
        data: {
          'subject_id': subjectId,
          'date': date,
          'title': title,
          if (lectureNumber != null && lectureNumber.isNotEmpty)
            'lecture_number': lectureNumber,
          if (deviceName != null) 'device_name': deviceName,
        },
      ),
    );
  }

  Future<Map<String, dynamic>> attendanceAlerts() async =>
      _data(await _api.get('/delegate/attendances/alerts'));

  Future<Map<String, dynamic>> startQrAttendance(
    Map<String, dynamic> data,
  ) async =>
      _data(await _api.post('/delegate/qr-attendance/start', data: data));

  Future<Map<String, dynamic>> qrToken(int sessionId) async =>
      _data(await _api.get('/delegate/qr-attendance/$sessionId/token'));

  Future<Map<String, dynamic>> qrStatus(int sessionId) async =>
      _data(await _api.get('/delegate/qr-attendance/$sessionId/status'));

  Future<Map<String, dynamic>> finalizeQr(int sessionId) async =>
      _data(await _api.post('/delegate/qr-attendance/$sessionId/finalize'));

  Future<Map<String, dynamic>> cancelQr(int sessionId) async =>
      _data(await _api.post('/delegate/qr-attendance/$sessionId/cancel'));

  Future<Map<String, dynamic>> activeQrAttendance({
    required int subjectId,
    required String date,
    required String title,
  }) async => _data(
    await _api.get(
      '/delegate/qr-attendance/active',
      queryParameters: {'subject_id': subjectId, 'date': date, 'title': title},
    ),
  );

  Future<Map<String, dynamic>> attendanceReport({
    required int subjectId,
    required String date,
    int? lectureId,
    String? genderFilter,
  }) async => _data(
    await _api.get(
      '/delegate/attendances/$subjectId/$date/report',
      queryParameters: {
        if (lectureId != null) 'lecture_id': lectureId,
        if (genderFilter != null) 'gender_filter': genderFilter,
      },
    ),
  );

  Future<List<int>> attendanceReportPdf({
    required int subjectId,
    required String date,
    int? lectureId,
  }) => _api.getBytes(
    '/delegate/attendances/$subjectId/$date/report-pdf',
    queryParameters: {if (lectureId != null) 'lecture_id': lectureId},
  );

  Future<Map<String, dynamic>> authorizedGrades() async =>
      _data(await _api.get('/delegate/authorized-grades'));

  Future<Map<String, dynamic>> authorizedGradeDetails(int categoryId) async =>
      _data(await _api.get('/delegate/authorized-grades/$categoryId'));

  Future<String> saveAuthorizedGrades({
    required int categoryId,
    required List<Map<String, dynamic>> grades,
  }) async {
    final response = await _api.post(
      '/delegate/authorized-grades/$categoryId/store',
      data: {'grades': grades},
    );
    return (response['message'] ?? 'تم إرسال الدرجات للمراجعة.').toString();
  }

  Future<Map<String, dynamic>> helperDelegations() async =>
      _data(await _api.get('/delegate/grade-helper-delegations'));

  Future<Map<String, dynamic>> helperDelegationStudents(int categoryId) async =>
      _data(
        await _api.get(
          '/delegate/grade-helper-delegations/students',
          queryParameters: {'category_id': categoryId},
        ),
      );

  Future<String> createHelperDelegation(Map<String, dynamic> data) async {
    final response = await _api.post(
      '/delegate/grade-helper-delegations',
      data: data,
    );
    return (response['message'] ?? 'تم إنشاء التفويض.').toString();
  }

  Future<String> revokeHelperDelegation(int id) async {
    final response = await _api.delete(
      '/delegate/grade-helper-delegations/$id',
    );
    return (response['message'] ?? 'تم إلغاء التفويض.').toString();
  }

  Future<Map<String, dynamic>> messages() async =>
      _data(await _api.get('/delegate/messages'));

  Future<List<dynamic>> eligibleStudents() async =>
      _list(await _api.get('/delegate/messages/eligible-students'));

  Future<Map<String, dynamic>> conversation(int id) async =>
      _data(await _api.get('/delegate/messages/$id'));

  Future<String> sendStudentMessage({
    int? conversationId,
    int? studentId,
    required String content,
  }) async {
    final response = await _api.post(
      '/delegate/messages',
      data: {
        if (conversationId != null) 'conversation_id': conversationId,
        if (studentId != null) 'student_id': studentId,
        'content': content,
      },
    );
    return (response['message'] ?? 'تم إرسال الرسالة.').toString();
  }

  Future<Map<String, dynamic>> doctorChats() async =>
      _data(await _api.get('/delegate/doctor-chats'));

  Future<List<dynamic>> eligibleDoctors() async =>
      _list(await _api.get('/delegate/doctor-chats/eligible-doctors'));

  Future<Map<String, dynamic>> doctorChat(int id) async =>
      _data(await _api.get('/delegate/doctor-chats/$id'));

  Future<String> sendDoctorMessage({
    int? conversationId,
    int? doctorId,
    required String content,
  }) async {
    final response = await _api.post(
      '/delegate/doctor-chats',
      data: {
        if (conversationId != null) 'conversation_id': conversationId,
        if (doctorId != null) 'doctor_id': doctorId,
        'content': content,
      },
    );
    return (response['message'] ?? 'تم إرسال الرسالة.').toString();
  }

  Future<Map<String, dynamic>> inquiries({String? status}) async {
    return _data(
      await _api.get(
        '/delegate/inquiries',
        queryParameters: {
          if (status != null && status.isNotEmpty) 'status': status,
        },
      ),
    );
  }

  Future<Map<String, dynamic>> inquiry(int id) async =>
      _data(await _api.get('/delegate/inquiries/$id'));

  Future<String> replyInquiry({required int id, required String reply}) async {
    final response = await _api.post(
      '/delegate/inquiries/$id/reply',
      data: {'reply': reply},
    );
    return (response['message'] ?? 'تم الرد على الاستفسار.').toString();
  }

  Future<String> forwardInquiry(int id) async {
    final response = await _api.post('/delegate/inquiries/$id/forward');
    return (response['message'] ?? 'تم تحويل الاستفسار.').toString();
  }

  Future<String> updateInquiryStatus({
    required int id,
    required String status,
    bool? isPublic,
  }) async {
    final response = await _api.patch(
      '/delegate/inquiries/$id/status',
      data: {'status': status, if (isPublic != null) 'is_public': isPublic},
    );
    return (response['message'] ?? 'تم تحديث الحالة.').toString();
  }
}

class DelegateSubscriptionRepository {
  const DelegateSubscriptionRepository(this._api);

  final ApiClient _api;

  Future<SubscriptionOverview> fetch() async {
    final response = await _api.get('/delegate/subscription');
    return SubscriptionOverview.fromJson(_data(response));
  }

  Future<String> redeem(String code) async {
    final response = await _api.post(
      '/delegate/subscription/redeem',
      data: {'code': code},
    );
    return (response['message'] ?? 'تم شحن الرصيد.').toString();
  }

  Future<String> subscribe(int packageId) async {
    final response = await _api.post(
      '/delegate/subscription/subscribe',
      data: {'package_id': packageId},
    );
    return (response['message'] ?? 'تم تفعيل الاشتراك.').toString();
  }

  Future<String> toggleAutoRenew(bool value) async {
    final response = await _api.post(
      '/delegate/subscription/auto-renew',
      data: {'auto_renew': value},
    );
    return (response['message'] ?? 'تم تحديث التجديد التلقائي.').toString();
  }
}

class DelegateLedgerRepository {
  const DelegateLedgerRepository(this._api);

  final ApiClient _api;

  Future<FinancialLedger> fetch({int page = 1}) async {
    final response = await _api.get(
      '/delegate/ledger',
      queryParameters: {'page': page},
    );
    return FinancialLedger.fromJson(_data(response));
  }

  Future<List<int>> exportPdf() => _api.getBytes('/delegate/ledger/export');
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
  if (data is Map<String, dynamic>) {
    final nested = data['data'];
    if (nested is List) return nested;
    for (final value in data.values) {
      if (value is List) return value;
    }
  }
  throw const ApiException('استجابة غير مكتملة من الخادم.');
}
