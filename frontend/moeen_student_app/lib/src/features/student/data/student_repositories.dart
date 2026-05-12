// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/authenticated_api_client.dart';
import 'models/financial_ledger.dart';
import 'models/student_dashboard.dart';
import 'models/subscription_models.dart';

final studentDashboardRepositoryProvider = Provider<StudentDashboardRepository>(
  (ref) {
    return StudentDashboardRepository(
      ref.watch(authenticatedApiClientProvider),
    );
  },
);

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(ref.watch(authenticatedApiClientProvider));
});

final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) {
  return LedgerRepository(ref.watch(authenticatedApiClientProvider));
});

final studentContentRepositoryProvider = Provider<StudentContentRepository>((
  ref,
) {
  return StudentContentRepository(ref.watch(authenticatedApiClientProvider));
});

class StudentDashboardRepository {
  const StudentDashboardRepository(this._api);

  final ApiClient _api;

  Future<StudentDashboard> fetch() async {
    final response = await _api.get('/student/dashboard');
    return StudentDashboard.fromJson(_data(response));
  }
}

class SubscriptionRepository {
  const SubscriptionRepository(this._api);

  final ApiClient _api;

  Future<SubscriptionOverview> fetch() async {
    final response = await _api.get('/student/subscription');
    return SubscriptionOverview.fromJson(_data(response));
  }

  Future<String> redeem(String code) async {
    final response = await _api.post(
      '/student/subscription/redeem',
      data: {'code': code},
    );
    return (response['message'] ?? 'تم شحن الرصيد بنجاح.').toString();
  }

  Future<String> subscribe(int packageId) async {
    final response = await _api.post(
      '/student/subscription/subscribe',
      data: {'package_id': packageId},
    );
    return (response['message'] ?? 'تم تفعيل الاشتراك بنجاح.').toString();
  }

  Future<String> toggleAutoRenew(bool value) async {
    final response = await _api.post(
      '/student/subscription/auto-renew',
      data: {'auto_renew': value},
    );
    return (response['message'] ?? 'تم تحديث التجديد التلقائي.').toString();
  }
}

class LedgerRepository {
  const LedgerRepository(this._api);

  final ApiClient _api;

  Future<FinancialLedger> fetch({int page = 1}) async {
    final response = await _api.get(
      '/student/ledger',
      queryParameters: {'page': page},
    );
    return FinancialLedger.fromJson(_data(response));
  }

  Future<String> exportUrl() async {
    return '/student/ledger/export';
  }

  Future<List<int>> exportPdf() {
    return _api.getBytes('/student/ledger/export');
  }
}

class StudentContentRepository {
  const StudentContentRepository(this._api);

  final ApiClient _api;

  Future<List<dynamic>> subjects() async {
    final response = await _api.get('/student/subjects');
    return _listData(response);
  }

  Future<Map<String, dynamic>> subjectDetails(int id) async {
    final response = await _api.get('/student/subjects/$id');
    return _data(response);
  }

  Future<String> toggleLectureListen(int lectureId) async {
    final response = await _api.post(
      '/student/lectures/$lectureId/toggle-listen',
    );
    return (response['message'] ?? 'تم تحديث حالة المحاضرة.').toString();
  }

  Future<String> submitExcuse({
    required int attendanceId,
    required String reason,
    String? filePath,
    String? fileName,
  }) async {
    final form = FormData.fromMap({
      'attendance_id': attendanceId,
      'reason': reason,
      if (filePath != null && fileName != null)
        'attachment': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
    });
    final response = await _api.post('/student/excuse', data: form);
    return (response['message'] ?? 'تم إرسال العذر بنجاح.').toString();
  }

  Future<Map<String, dynamic>> studyCenter({String? tab}) async {
    try {
      await _api.get('/student/study-center/check-reminders');
    } catch (_) {
      // Reminder checks should not block opening the study center.
    }

    final response = await _api.get(
      '/student/study-center',
      queryParameters: {if (tab != null) 'tab': tab},
    );
    return _data(response);
  }

  Future<Map<String, dynamic>> studySession(int id) async {
    final response = await _api.get('/student/study-center/$id/session');
    return _data(response);
  }

  Future<Map<String, dynamic>> addStudySessionColumn({
    required int itemId,
    required String name,
  }) async {
    final response = await _api.post(
      '/student/study-center/$itemId/columns',
      data: {'name': name},
    );
    return _data(response);
  }

  Future<Map<String, dynamic>> updateStudySessionColumn({
    required int columnId,
    required String name,
  }) async {
    final response = await _api.put(
      '/student/study-center/columns/$columnId',
      data: {'name': name},
    );
    return _data(response);
  }

  Future<Map<String, dynamic>> deleteStudySessionColumn(int columnId) async {
    final response = await _api.delete(
      '/student/study-center/columns/$columnId',
    );
    return _data(response);
  }

  Future<Map<String, dynamic>> incrementStudySessionColumn(int columnId) async {
    final response = await _api.post(
      '/student/study-center/columns/$columnId/increment',
    );
    return _data(response);
  }

  Future<Map<String, dynamic>> undoStudySessionAction(int itemId) async {
    final response = await _api.post(
      '/student/study-center/$itemId/undo-last-action',
    );
    return _data(response);
  }

  Future<Map<String, dynamic>> undoStudySessionColumnAction(
    int columnId,
  ) async {
    final response = await _api.post(
      '/student/study-center/columns/$columnId/undo-last-action',
    );
    return _data(response);
  }

  Future<String> addCustomStudyTask(Map<String, dynamic> data) async {
    final response = await _api.post(
      '/student/study-center/custom-task',
      data: data,
    );
    return (response['message'] ?? 'تمت إضافة المهمة.').toString();
  }

  Future<String> updateStudyItem(int id, Map<String, dynamic> data) async {
    final response = await _api.put('/student/study-center/$id', data: data);
    return (response['message'] ?? 'تم تحديث العنصر.').toString();
  }

  Future<String> deleteStudyItem(int id) async {
    final response = await _api.delete('/student/study-center/$id');
    return (response['message'] ?? 'تم حذف العنصر.').toString();
  }

  Future<Map<String, dynamic>> schedules() async {
    final response = await _api.get('/student/schedules');
    final data = response['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map)
      return data.map((key, value) => MapEntry(key.toString(), value));
    if (data is List && data.isEmpty) return <String, dynamic>{};
    throw const ApiException('استجابة غير مكتملة من الخادم.');
  }

  Future<Map<String, dynamic>> newsHub({String? source, int page = 1}) async {
    final response = await _api.get(
      '/student/news-hub',
      queryParameters: {
        'page': page,
        if (source != null && source != 'all') 'source': source,
      },
    );
    return _data(response);
  }

  Future<Map<String, dynamic>> quizzes() async {
    final response = await _api.get('/student/quizzes');
    return _data(response);
  }

  Future<Map<String, dynamic>> takeQuiz(
    int quizId, {
    String? accessCode,
  }) async {
    final response = await _api.get(
      '/student/quizzes/$quizId/take',
      queryParameters: {
        if (accessCode != null && accessCode.isNotEmpty)
          'access_code': accessCode,
      },
    );
    return _data(response);
  }

  Future<Map<String, dynamic>> submitQuiz(
    int attemptId,
    Map<String, dynamic> answers,
  ) async {
    final response = await _api.post(
      '/student/quizzes/$attemptId/submit',
      data: {'answers': answers},
    );
    return _data(response);
  }

  Future<Map<String, dynamic>> quizResult(int attemptId) async {
    final response = await _api.get('/student/quizzes/results/$attemptId');
    return _data(response);
  }

  Future<Map<String, dynamic>> stars() async {
    final response = await _api.get('/student/stars');
    return _data(response);
  }

  Future<List<dynamic>> searchStarUsers(String query) async {
    final response = await _api.get(
      '/student/stars/search-users',
      queryParameters: {'query': query},
    );
    return _listData(response);
  }

  Future<String> giftStars({
    required int recipientId,
    required int amount,
    String? message,
  }) async {
    final response = await _api.post(
      '/student/stars/gift',
      data: {
        'recipient_id': recipientId,
        'amount': amount,
        if (message != null && message.isNotEmpty) 'message': message,
      },
    );
    return (response['message'] ?? 'تم إهداء النجوم بنجاح.').toString();
  }

  Future<Map<String, dynamic>> notifications({int page = 1}) async {
    final response = await _api.get(
      '/student/notifications',
      queryParameters: {'page': page},
    );
    return _data(response);
  }

  Future<Map<String, dynamic>> unreadNotificationsCount() async {
    final response = await _api.get('/student/notifications/unread-count');
    return _data(response);
  }

  Future<String> markNotificationRead(int id) async {
    final response = await _api.post('/student/notifications/$id/read');
    return (response['message'] ?? 'تم تحديد الإشعار كمقروء.').toString();
  }

  Future<String> markAllNotificationsRead() async {
    final response = await _api.post('/student/notifications/mark-all-read');
    return (response['message'] ?? 'تم تحديد جميع الإشعارات كمقروءة.')
        .toString();
  }

  Future<String> voteNotification({
    required int notificationId,
    required int optionId,
  }) async {
    final response = await _api.post(
      '/student/notifications/$notificationId/vote',
      data: {'poll_option_id': optionId},
    );
    return (response['message'] ?? 'تم تسجيل التصويت بنجاح.').toString();
  }

  Future<Map<String, dynamic>> exams() async {
    final response = await _api.get('/student/exams');
    return _data(response);
  }

  Future<Map<String, dynamic>> resources({
    String? search,
    int? subjectId,
    String? category,
    String sort = 'newest',
    bool scheduled = false,
    int page = 1,
  }) async {
    final response = await _api.get(
      '/student/resources',
      queryParameters: {
        'page': page,
        'sort': sort,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (subjectId != null && subjectId > 0) 'subject_id': subjectId,
        if (category != null && category != 'all') 'category': category,
        if (scheduled) 'scheduled': '1',
      },
    );
    return _data(response);
  }

  Future<Map<String, dynamic>> library({
    String? search,
    int? subjectId,
    String? category,
    String? fileType,
    bool myUploads = false,
    int page = 1,
  }) async {
    final response = await _api.get(
      '/student/library',
      queryParameters: {
        'page': page,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (subjectId != null && subjectId > 0) 'subject_id': subjectId,
        if (category != null && category != 'all') 'category': category,
        if (fileType != null && fileType != 'all') 'file_type': fileType,
        if (myUploads) 'my_uploads': '1',
      },
    );
    return _data(response);
  }

  Future<String> libraryDownloadUrl(int id) async {
    final response = await _api.get('/student/library/$id/download');
    final data = _data(response);
    final url = (data['download_url'] ?? '').toString();
    if (url.isEmpty) throw const ApiException('تعذر تجهيز رابط تحميل الملف.');
    return url;
  }

  Future<List<int>> downloadLibraryResource(int id) async {
    final url = await libraryDownloadUrl(id);
    return _api.getBytesFromUrl(url);
  }

  Future<String> uploadLibraryResource({
    required int subjectId,
    required String title,
    required String category,
    required String semesterInfo,
    required String visibility,
    required String filePath,
    required String fileName,
    String? description,
    String? subCategory,
    String? lecturerName,
    String? unitCoordinator,
  }) async {
    final form = FormData.fromMap({
      'subject_id': subjectId,
      'title': title,
      'category': category,
      'semester_info': semesterInfo,
      'visibility': visibility,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      if (subCategory != null && subCategory != 'none')
        'sub_category': subCategory,
      if (lecturerName != null && lecturerName.trim().isNotEmpty)
        'lecturer_name': lecturerName.trim(),
      if (unitCoordinator != null && unitCoordinator.trim().isNotEmpty)
        'unit_coordinator': unitCoordinator.trim(),
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final response = await _api.post('/student/library/upload', data: form);
    return (response['message'] ?? 'تم رفع الملف بنجاح.').toString();
  }

  Future<Map<String, dynamic>> flashcards() async {
    final response = await _api.get('/student/flashcards');
    return _data(response);
  }

  Future<Map<String, dynamic>> flashcardDetails(int id) async {
    final response = await _api.get('/student/flashcards/$id');
    return _data(response);
  }

  Future<Map<String, dynamic>> flashcardReview(int id) async {
    final response = await _api.get('/student/flashcards/$id/review');
    return _data(response);
  }

  Future<Map<String, dynamic>> flashcardStore({
    String? search,
    String? displayMode,
  }) async {
    final response = await _api.get(
      '/student/flashcards/store',
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (displayMode != null && displayMode.isNotEmpty)
          'display_mode': displayMode,
      },
    );
    return _data(response);
  }

  Future<String> createFlashcardPack(Map<String, dynamic> data) async {
    final response = await _api.post('/student/flashcards', data: data);
    return (response['message'] ?? '?? ????? ?????? ?????.').toString();
  }

  Future<String> deleteFlashcardPack(int id) async {
    final response = await _api.delete('/student/flashcards/$id');
    return (response['message'] ?? '?? ??? ?????? ?????.').toString();
  }

  Future<String> toggleFlashcardPack(int id) async {
    final response = await _api.post('/student/flashcards/$id/toggle');
    return (response['message'] ?? '?? ????? ???? ??????.').toString();
  }

  Future<String> cloneFlashcardPack(int id) async {
    final response = await _api.post('/student/flashcards/clone/$id');
    return (response['message'] ?? '??? ????? ?????? ??? ?????.').toString();
  }

  Future<String> createFlashcardItem(
    int packId,
    Map<String, dynamic> data,
  ) async {
    final response = await _api.post(
      '/student/flashcards/$packId/items',
      data: data,
    );
    return (response['message'] ?? '??? ????? ?????? ?????.').toString();
  }

  Future<String> deleteFlashcardItem(int itemId) async {
    final response = await _api.delete('/student/flashcards/items/$itemId');
    return (response['message'] ?? '?? ??? ?????? ?????.').toString();
  }

  Future<String> recordFlashcardProgress({
    required int itemId,
    required String responseLevel,
  }) async {
    final response = await _api.post(
      '/student/flashcards/progress',
      data: {'item_id': itemId, 'response_level': responseLevel},
    );
    return (response['message'] ?? '?? ????? ????????.').toString();
  }

  Future<Map<String, dynamic>> assignments({String sortBy = 'due_date'}) async {
    final response = await _api.get(
      '/student/assignments',
      queryParameters: {'sort_by': sortBy},
    );
    return _data(response);
  }

  Future<Map<String, dynamic>> assignmentDetails(int id) async {
    final response = await _api.get('/student/assignments/$id/details');
    return _data(response);
  }

  Future<String> updateAssignmentPriority({
    required int assignmentId,
    required int priority,
  }) async {
    final response = await _api.post(
      '/student/assignments/$assignmentId/priority',
      data: {'priority': priority},
    );
    return (response['message'] ?? '?? ????? ????????.').toString();
  }

  Future<String> submitAssignment({
    required int assignmentId,
    String? notes,
    String? filePath,
    String? fileName,
  }) async {
    final form = FormData.fromMap({
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      if (filePath != null && fileName != null)
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final response = await _api.post(
      '/student/assignments/$assignmentId/submit',
      data: form,
    );
    return (response['message'] ?? '?? ????? ??????? ?????.').toString();
  }

  Future<Map<String, dynamic>> reminders() async {
    final response = await _api.get('/student/reminders');
    return _data(response);
  }

  Future<String> scanQrAttendance(String token) async {
    final response = await _api.post(
      '/student/qr-attendance/scan',
      data: {'token': token},
    );
    return (response['message'] ?? '?? ????? ?????? ?????.').toString();
  }

  Future<Map<String, dynamic>> messages() async {
    final response = await _api.get('/student/messages');
    return _data(response);
  }

  Future<Map<String, dynamic>> startConversation() async {
    final response = await _api.get('/student/messages/start');
    return _data(response);
  }

  Future<Map<String, dynamic>> conversation(int id) async {
    final response = await _api.get('/student/messages/$id');
    return _data(response);
  }

  Future<Map<String, dynamic>> sendMessage({
    required int conversationId,
    required String body,
  }) async {
    final response = await _api.post(
      '/student/messages/$conversationId/send',
      data: {'body': body},
    );
    return _data(response);
  }

  Future<Map<String, dynamic>> clinicalLogbook() async {
    final response = await _api.get('/student/clinical/logbook');
    return _data(response);
  }

  Future<Map<String, dynamic>> createClinicalLog(
    Map<String, dynamic> data,
  ) async {
    final response = await _api.post('/student/clinical/logbook', data: data);
    return _data(response);
  }

  Future<Map<String, dynamic>> updateClinicalLog(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _api.put(
      '/student/clinical/logbook/$id',
      data: data,
    );
    return _data(response);
  }

  Future<String> deleteClinicalLog(int id) async {
    final response = await _api.delete('/student/clinical/logbook/$id');
    return (response['message'] ?? 'تم حذف السجل العملي.').toString();
  }

  Future<Map<String, dynamic>> submitClinicalAssignment({
    required int assignmentId,
    required String message,
  }) async {
    final response = await _api.post(
      '/student/clinical/assignments/$assignmentId/submit-review',
      data: {'student_completion_message': message},
    );
    return _data(response);
  }

  Future<Map<String, dynamic>> clinicalEvaluations() async {
    final response = await _api.get('/student/clinical/evaluations');
    return _data(response);
  }

  Future<Map<String, dynamic>> clinicalMockExams() async {
    final response = await _api.get('/student/clinical/mock-exams');
    return _data(response);
  }

  Future<Map<String, dynamic>> createClinicalCustomChecklist(
    Map<String, dynamic> data,
  ) async {
    final response = await _api.post(
      '/student/clinical/mock-exams/custom',
      data: data,
    );
    return _data(response);
  }

  Future<String> deleteClinicalCustomChecklist(int id) async {
    final response = await _api.delete(
      '/student/clinical/mock-exams/custom/$id',
    );
    return (response['message'] ?? 'تم حذف النموذج المخصص.').toString();
  }

  Future<Map<String, dynamic>> clinicalMockTake(int checklistId) async {
    final response = await _api.get(
      '/student/clinical/mock-exams/$checklistId/take',
    );
    return _data(response);
  }

  Future<Map<String, dynamic>> submitClinicalMockExam({
    required int checklistId,
    required int timeTaken,
    required Map<String, dynamic> scores,
  }) async {
    final response = await _api.post(
      '/student/clinical/mock-exams/$checklistId/submit',
      data: {'time_taken': timeTaken, 'scores': scores},
    );
    return _data(response);
  }

  Future<Map<String, dynamic>> clinicalMockResult(int evaluationId) async {
    final response = await _api.get(
      '/student/clinical/mock-exams/results/$evaluationId',
    );
    return _data(response);
  }

  Future<Map<String, dynamic>> clinicalRareCases() async {
    final response = await _api.get('/student/clinical/rare-cases');
    return _data(response);
  }

  Future<Map<String, dynamic>> clinicalRareCase(int id) async {
    final response = await _api.get('/student/clinical/rare-cases/$id');
    return _data(response);
  }

  Future<Map<String, dynamic>> inquiries({String? status}) async {
    final response = await _api.get(
      '/student/inquiries',
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    return _data(response);
  }

  Future<Map<String, dynamic>> inquiryOptions() async {
    final response = await _api.get('/student/inquiries/options');
    return _data(response);
  }

  Future<Map<String, dynamic>> inquiryDetails(int id) async {
    final response = await _api.get('/student/inquiries/$id');
    return _data(response);
  }

  Future<String> createInquiry({
    required int subjectId,
    required String title,
    required String question,
  }) async {
    final response = await _api.post(
      '/student/inquiries',
      data: {'subject_id': subjectId, 'title': title, 'question': question},
    );
    return (response['message'] ?? 'تم إرسال الاستفسار بنجاح.').toString();
  }

  Future<Map<String, dynamic>> profile() async {
    final response = await _api.get('/student/me');
    return _data(response);
  }

  Future<Map<String, dynamic>> updateEmail({
    required String email,
    required String currentPassword,
  }) async {
    final response = await _api.patch(
      '/student/profile/email',
      data: {'email': email, 'current_password': currentPassword},
    );
    return _data(response);
  }

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmation,
  }) async {
    final response = await _api.post(
      '/student/change-password',
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': confirmation,
      },
    );
    return (response['message'] ?? 'تم تغيير كلمة المرور بنجاح.').toString();
  }
}

Map<String, dynamic> _data(Map<String, dynamic> response) {
  final data = response['data'];
  if (data is Map<String, dynamic>) return data;
  throw const ApiException('استجابة غير مكتملة من الخادم.');
}

List<dynamic> _listData(Map<String, dynamic> response) {
  final data = response['data'];
  if (data is List) return data;
  if (data is Map<String, dynamic>) {
    final nested = data['data'];
    if (nested is List) return nested;
  }
  throw const ApiException('استجابة غير مكتملة من الخادم.');
}
