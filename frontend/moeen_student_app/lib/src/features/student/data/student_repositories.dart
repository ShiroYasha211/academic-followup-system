// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/authenticated_api_client.dart';
import '../../../core/offline/offline_cache_service.dart';
import '../../../core/providers.dart';
import 'models/financial_ledger.dart';
import 'models/card_generation_models.dart';
import 'models/student_dashboard.dart';
import 'models/subscription_models.dart';
import '../../auth/logic/auth_controller.dart';
import 'flashcard_local_store.dart';

final studentDashboardRepositoryProvider = Provider<StudentDashboardRepository>(
  (ref) {
    return StudentDashboardRepository(
      ref.watch(authenticatedApiClientProvider),
      ref.watch(offlineCacheServiceProvider),
    );
  },
);

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(
    ref.watch(authenticatedApiClientProvider),
    ref.watch(offlineCacheServiceProvider),
  );
});

final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) {
  return LedgerRepository(
    ref.watch(authenticatedApiClientProvider),
    ref.watch(offlineCacheServiceProvider),
  );
});

final cardGenerationRepositoryProvider = Provider<CardGenerationRepository>((
  ref,
) {
  return CardGenerationRepository(ref.watch(authenticatedApiClientProvider));
});

final studentContentRepositoryProvider = Provider<StudentContentRepository>((
  ref,
) {
  return StudentContentRepository(
    ref.watch(authenticatedApiClientProvider),
    ref.watch(offlineCacheServiceProvider),
    cacheScope: ref.watch(authControllerProvider).valueOrNull == null
        ? 'signed_out'
        : FlashcardLocalStore.keyFor(
            ref.watch(authControllerProvider).valueOrNull!,
          ),
  );
});

final studentSupportSettingsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
      return ref.watch(studentContentRepositoryProvider).fetchSupportSettings();
    });

class StudentDashboardRepository {
  const StudentDashboardRepository(this._api, this._cache);

  final ApiClient _api;
  final OfflineCacheService _cache;

  Future<StudentDashboard> fetch() async {
    final data = await _cachedMap(
      cache: _cache,
      key: 'student.dashboard',
      load: () async => _data(await _api.get('/student/dashboard')),
    );
    return StudentDashboard.fromJson(data);
  }
}

class SubscriptionRepository {
  const SubscriptionRepository(this._api, this._cache);

  final ApiClient _api;
  final OfflineCacheService _cache;

  Future<SubscriptionOverview> fetch() async {
    final data = await _cachedMap(
      cache: _cache,
      key: 'student.subscription',
      load: () async => _data(await _api.get('/student/subscription')),
    );
    return SubscriptionOverview.fromJson(data);
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
  const LedgerRepository(this._api, this._cache);

  final ApiClient _api;
  final OfflineCacheService _cache;

  Future<FinancialLedger> fetch({int page = 1}) async {
    final data = await _cachedMap(
      cache: _cache,
      key: 'student.ledger.$page',
      load: () async => _data(
        await _api.get('/student/ledger', queryParameters: {'page': page}),
      ),
    );
    return FinancialLedger.fromJson(data);
  }

  Future<String> exportUrl() async {
    return '/student/ledger/export';
  }

  Future<List<int>> exportPdf() {
    return _api.getBytes('/student/ledger/export');
  }
}

class CardGenerationRepository {
  const CardGenerationRepository(this._api);

  final ApiClient _api;

  Future<CardGenerationOverview> fetch({int page = 1}) async {
    final response = await _api.get(
      '/student/cards-generate',
      queryParameters: {'page': page},
    );
    return CardGenerationOverview.fromJson(_data(response));
  }

  Future<String> generate({required int count, required double amount}) async {
    final response = await _api.post(
      '/student/cards-generate',
      data: {'count': count, 'amount': amount},
    );
    return (response['message'] ?? 'تم توليد الكروت بنجاح.').toString();
  }
}

class StudentContentRepository {
  static final Map<String, Future<void>> _settingsWrites = {};
  const StudentContentRepository(
    this._api,
    this._cache, {
    this.cacheScope = 'signed_out',
  });
  final String cacheScope;

  final ApiClient _api;
  final OfflineCacheService _cache;

  Future<Map<String, dynamic>> subjects({int? termId, int? semesterId}) async {
    return _cachedMap(
      cache: _cache,
      key:
          'student.subjects.term_${termId ?? 'all'}.semester_${semesterId ?? 'all'}',
      load: () async {
        final response = await _api.get(
          '/student/subjects',
          queryParameters: {
            if (termId != null) 'term_id': termId,
            if (semesterId != null) 'semester_id': semesterId,
          },
        );
        final data = _data(response);
        if (data.isNotEmpty) return data;
        return {
          'subjects': _listData(response),
          'terms': const [],
          'major': null,
        };
      },
    );
  }

  Future<Map<String, dynamic>> subjectDetails(int id) async {
    return _cachedMap(
      cache: _cache,
      key: 'student.subject.$id',
      load: () async => _data(await _api.get('/student/subjects/$id')),
    );
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

    return _cachedMap(
      cache: _cache,
      key: 'student.study_center.${tab ?? 'all'}',
      load: () async => _data(
        await _api.get(
          '/student/study-center',
          queryParameters: {if (tab != null) 'tab': tab},
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> studySession(int id) async {
    return _cachedMap(
      cache: _cache,
      key: 'student.study_session.$id',
      load: () async =>
          _data(await _api.get('/student/study-center/$id/session')),
    );
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
    final useCache = DateTime.now().year > 0;
    if (useCache) {
      return _cachedMap(
        cache: _cache,
        key: 'student.schedules',
        load: () async {
          final response = await _api.get('/student/schedules');
          final data = response['data'];
          if (data is Map<String, dynamic>) return data;
          if (data is Map) {
            return data.map((key, value) => MapEntry(key.toString(), value));
          }
          if (data is List && data.isEmpty) return <String, dynamic>{};
          throw const ApiException('استجابة غير مكتملة من الخادم.');
        },
      );
    }
    final response = await _api.get('/student/schedules');
    final data = response['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map)
      return data.map((key, value) => MapEntry(key.toString(), value));
    if (data is List && data.isEmpty) return <String, dynamic>{};
    throw const ApiException('استجابة غير مكتملة من الخادم.');
  }

  Future<Map<String, dynamic>> newsHub({String? source, int page = 1}) async {
    return _cachedMap(
      cache: _cache,
      key: 'student.news.${source ?? 'all'}.$page',
      load: () async => _data(
        await _api.get(
          '/student/news-hub',
          queryParameters: {
            'page': page,
            if (source != null && source != 'all') 'source': source,
          },
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> quizzes() async {
    return _cachedMap(
      cache: _cache,
      key: 'student.quizzes',
      load: () async => _data(await _api.get('/student/quizzes')),
    );
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
    return _cachedMap(
      cache: _cache,
      key: 'student.quiz_result.$attemptId',
      load: () async =>
          _data(await _api.get('/student/quizzes/results/$attemptId')),
    );
  }

  Future<Map<String, dynamic>> stars({int page = 1}) async {
    return _cachedMap(
      cache: _cache,
      key: 'student.stars.$page',
      load: () async => _data(
        await _api.get('/student/stars', queryParameters: {'page': page}),
      ),
    );
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

  Future<Map<String, dynamic>> treeFarm() async {
    return _cachedMap(
      cache: _cache,
      key: 'student.tree_farm',
      load: () async => _flexData(await _api.get('/student/tree-farm')),
    );
  }

  Future<Map<String, dynamic>> publicTreeFarm() async {
    return _cachedMap(
      cache: _cache,
      key: 'student.tree_farm.public',
      load: () async =>
          _flexData(await _api.get('/student/tree-farm/public-farm')),
    );
  }

  Future<Map<String, dynamic>> startTreeFarmSession({
    required String farmScope,
    required int plannedMinutes,
    required String clientUuid,
  }) async {
    final response = await _api.post(
      '/student/tree-farm/sessions/start',
      data: {
        'farm_scope': farmScope,
        'planned_minutes': plannedMinutes,
        'client_uuid': clientUuid,
      },
    );
    return _flexData(response);
  }

  Future<Map<String, dynamic>> treeFarmHeartbeat(int sessionId) async {
    return _flexData(
      await _api.post('/student/tree-farm/sessions/$sessionId/heartbeat'),
    );
  }

  Future<Map<String, dynamic>> requestTreeFarmGrace({
    required int sessionId,
    required int seconds,
  }) async {
    return _flexData(
      await _api.post(
        '/student/tree-farm/sessions/$sessionId/grace',
        data: {'seconds': seconds},
      ),
    );
  }

  Future<Map<String, dynamic>> finishTreeFarmSession(int sessionId) async {
    return _flexData(
      await _api.post(
        '/student/tree-farm/sessions/$sessionId/finish',
        data: {'finish_reason': 'completed'},
      ),
    );
  }

  Future<Map<String, dynamic>> syncTreeFarmOffline({
    required List<Map<String, dynamic>> sessions,
    required List<Map<String, dynamic>> thoughts,
  }) async {
    return _flexData(
      await _api.post(
        '/student/tree-farm/offline-sync',
        data: {'sessions': sessions, 'thoughts': thoughts},
      ),
    );
  }

  Future<Map<String, dynamic>> storeTreeFarmThought({
    required String body,
    String? clientUuid,
    int? sessionId,
    DateTime? reminderAt,
  }) async {
    return _flexData(
      await _api.post(
        '/student/tree-farm/thoughts',
        data: {
          'body': body,
          if (clientUuid != null) 'client_uuid': clientUuid,
          if (sessionId != null) 'session_id': sessionId,
          if (reminderAt != null) 'reminder_at': reminderAt.toIso8601String(),
        },
      ),
    );
  }

  Future<Map<String, dynamic>> requestTreeFarmReward(int coinsAmount) async {
    return _flexData(
      await _api.post(
        '/student/tree-farm/reward-requests',
        data: {'coins_amount': coinsAmount},
      ),
    );
  }

  Future<Map<String, dynamic>> updateTreeFarmProfile({
    String? publicName,
    bool? isPublic,
    bool? useAlias,
  }) async {
    return _flexData(
      await _api.patch(
        '/student/tree-farm/profile',
        data: {
          if (publicName != null) 'public_name': publicName,
          if (isPublic != null) 'is_public': isPublic,
          if (useAlias != null) 'use_alias': useAlias,
        },
      ),
    );
  }

  Future<Map<String, dynamic>> notifications({int page = 1}) async {
    return _cachedMap(
      cache: _cache,
      key: 'student.notifications.$page',
      load: () async => _data(
        await _api.get(
          '/student/notifications',
          queryParameters: {'page': page},
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> unreadNotificationsCount() async {
    return _cachedMap(
      cache: _cache,
      key: 'student.notifications.unread_count',
      load: () async =>
          _data(await _api.get('/student/notifications/unread-count')),
      maxAge: const Duration(hours: 24),
    );
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

  Future<String> retractVoteNotification({required int notificationId}) async {
    final response = await _api.delete(
      '/student/notifications/$notificationId/vote',
    );
    return (response['message'] ?? 'تم سحب التصويت بنجاح.').toString();
  }

  Future<Map<String, dynamic>> authorizedGrades() async {
    return _cachedMap(
      cache: _cache,
      key: 'student.authorized_grades',
      load: () async => _data(await _api.get('/student/authorized-grades')),
    );
  }

  Future<Map<String, dynamic>> authorizedGradeDetails(int categoryId) async {
    return _data(await _api.get('/student/authorized-grades/$categoryId'));
  }

  Future<String> saveAuthorizedGrades({
    required int categoryId,
    required List<Map<String, dynamic>> grades,
  }) async {
    final response = await _api.post(
      '/student/authorized-grades/$categoryId/store',
      data: {'grades': grades},
    );
    return (response['message'] ?? 'تم إرسال الدرجات إلى الدكتور للمراجعة.')
        .toString();
  }

  Future<Map<String, dynamic>> exams() async {
    return _cachedMap(
      cache: _cache,
      key: 'student.exams',
      load: () async => _data(await _api.get('/student/exams')),
    );
  }

  Future<Map<String, dynamic>> resources({
    String? search,
    int? subjectId,
    String? category,
    String sort = 'newest',
    bool scheduled = false,
    int page = 1,
  }) async {
    return _cachedMap(
      cache: _cache,
      key:
          'student.resources.$page.$sort.${search ?? ''}.${subjectId ?? 'all'}.${category ?? 'all'}.$scheduled',
      load: () async => _data(
        await _api.get(
          '/student/resources',
          queryParameters: {
            'page': page,
            'sort': sort,
            if (search != null && search.trim().isNotEmpty)
              'search': search.trim(),
            if (subjectId != null && subjectId > 0) 'subject_id': subjectId,
            if (category != null && category != 'all') 'category': category,
            if (scheduled) 'scheduled': '1',
          },
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> library({
    String? search,
    int? subjectId,
    String? category,
    String? fileType,
    bool myUploads = false,
    int page = 1,
  }) async {
    return _cachedMap(
      cache: _cache,
      key:
          'student.library.$page.${search ?? ''}.${subjectId ?? 'all'}.${category ?? 'all'}.${fileType ?? 'all'}.$myUploads',
      load: () async => _data(
        await _api.get(
          '/student/library',
          queryParameters: {
            'page': page,
            if (search != null && search.trim().isNotEmpty)
              'search': search.trim(),
            if (subjectId != null && subjectId > 0) 'subject_id': subjectId,
            if (category != null && category != 'all') 'category': category,
            if (fileType != null && fileType != 'all') 'file_type': fileType,
            if (myUploads) 'my_uploads': '1',
          },
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> libraryNavigation({
    required String type,
    required String node,
    String? search,
    int page = 1,
  }) async {
    return _data(
      await _api.get(
        '/student/library/navigation',
        queryParameters: {
          'type': type,
          'node': node,
          'page': page,
          'per_page': 20,
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
        },
      ),
    );
  }

  Future<void> createLibraryNode({
    required int spaceId,
    int? parentId,
    required String title,
  }) async {
    await _api.post(
      '/student/library/manage/nodes',
      data: {
        'library_space_id': spaceId,
        if (parentId != null) 'parent_id': parentId,
        'title': title,
        'node_type': 'folder',
        'icon': 'folder',
      },
    );
  }

  Future<void> updateLibraryNode(int nodeId, String title) async {
    await _api.patch(
      '/student/library/manage/nodes/$nodeId',
      data: {'title': title},
    );
  }

  Future<void> deleteLibraryNode(int nodeId) async {
    await _api.delete('/student/library/manage/nodes/$nodeId');
  }

  Future<void> reorderLibraryNodes(
    int spaceId,
    List<Map<String, dynamic>> items,
  ) async {
    await _api.post(
      '/student/library/manage/nodes/reorder',
      data: {'library_space_id': spaceId, 'items': items},
    );
  }

  Future<void> uploadLibraryNodeResource({
    required int nodeId,
    required String title,
    required String description,
    required String visibility,
    required String filePath,
    required String fileName,
  }) async {
    await _api.post(
      '/student/library/manage/resources/upload',
      data: FormData.fromMap({
        'node_id': nodeId,
        'title': title,
        if (description.isNotEmpty) 'description': description,
        'visibility': visibility,
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      }),
    );
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
    return _cachedMap(
      cache: _cache,
      key: '$cacheScope.student.flashcards',
      load: () async => _data(await _api.get('/student/flashcards')),
    );
  }

  Future<Map<String, dynamic>> flashcardDetails(int id) async {
    return _cachedMap(
      cache: _cache,
      key: '$cacheScope.student.flashcard.$id',
      load: () async => _data(await _api.get('/student/flashcards/$id')),
    );
  }

  Future<Map<String, dynamic>> flashcardReview(int id) async {
    return _cachedMap(
      cache: _cache,
      key: '$cacheScope.student.flashcard_review.$id',
      load: () async => _data(await _api.get('/student/flashcards/$id/review')),
    );
  }

  Future<Map<String, dynamic>> flashcardDailyQueue() async {
    return _cachedMap(
      cache: _cache,
      key: '$cacheScope.student.flashcard_daily_queue',
      load: () async =>
          _data(await _api.get('/student/flashcards/daily-queue')),
    );
  }

  Future<Map<String, dynamic>> restartFlashcardDailyQueue() async {
    return _data(await _api.post('/student/flashcards/daily-queue/restart'));
  }

  Future<Map<String, dynamic>> flashcardOneLineNotifications({
    bool reschedule = false,
  }) async {
    return _cachedMap(
      cache: _cache,
      key: '$cacheScope.student.flashcard_one_line_notifications',
      load: () async => _data(
        await _api.get(
          '/student/flashcards/one-line-notifications',
          queryParameters: {'days': 3, if (reschedule) 'reschedule': 1},
        ),
      ),
    );
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
    return (response['message'] ?? 'تم إنشاء الحزمة بنجاح.').toString();
  }

  Future<String> deleteFlashcardPack(int id) async {
    final response = await _api.delete('/student/flashcards/$id');
    return (response['message'] ?? 'تم حذف الحزمة بنجاح.').toString();
  }

  Future<String> toggleFlashcardPack(int id) async {
    final response = await _api.post('/student/flashcards/$id/toggle');
    return (response['message'] ?? 'تم تحديث حالة الحزمة.').toString();
  }

  Future<String> cloneFlashcardPack(int id) async {
    final response = await _api.post('/student/flashcards/clone/$id');
    return (response['message'] ?? 'تمت إضافة الحزمة إلى مكتبتك.').toString();
  }

  Future<String> createFlashcardItem(
    int packId,
    Map<String, dynamic> data,
  ) async {
    final response = await _api.post(
      '/student/flashcards/$packId/items',
      data: data,
    );
    return (response['message'] ?? 'تمت إضافة البطاقة بنجاح.').toString();
  }

  Future<Map<String, dynamic>> previewFlashcardImport({
    required int packId,
    String? filePath,
    List<int>? fileBytes,
    required String fileName,
  }) async {
    final form = FormData.fromMap({
      'file': fileBytes != null
          ? MultipartFile.fromBytes(fileBytes, filename: fileName)
          : await MultipartFile.fromFile(filePath!, filename: fileName),
    });
    final response = await _api.post(
      '/student/flashcards/$packId/import-preview',
      data: form,
    );
    return _data(response);
  }

  Future<List<int>> downloadFlashcardImportTemplate() {
    return _api.getBytes('/student/flashcards/import-template');
  }

  Future<Map<String, dynamic>> confirmFlashcardImport({
    required int packId,
    required Map<String, dynamic> payload,
  }) async {
    final response = await _api.post(
      '/student/flashcards/$packId/import-confirm',
      data: payload,
    );
    return {
      ..._data(response),
      'message': (response['message'] ?? 'تم استيراد الملف بنجاح.').toString(),
    };
  }

  Future<String> deleteFlashcardItem(int itemId) async {
    final response = await _api.delete('/student/flashcards/items/$itemId');
    return (response['message'] ?? 'تم حذف البطاقة بنجاح.').toString();
  }

  Future<String> updateFlashcardItem(
    int itemId,
    Map<String, dynamic> data,
  ) async {
    final response = await _api.put(
      '/student/flashcards/items/$itemId',
      data: data,
    );
    return (response['message'] ?? 'تم تعديل البطاقة بنجاح.').toString();
  }

  Future<String> recordFlashcardProgress({
    required int itemId,
    required String responseLevel,
    String? clientEventId,
  }) async {
    final response = await _api.post(
      '/student/flashcards/progress',
      data: {
        'item_id': itemId,
        'response_level': responseLevel,
        if (clientEventId != null) 'client_event_id': clientEventId,
      },
    );
    return (response['message'] ?? 'تم تسجيل المراجعة.').toString();
  }

  Future<Map<String, dynamic>> flashcardSettings() async {
    await _settingsWrites[cacheScope];
    return _cachedMap(
      cache: _cache,
      key: '$cacheScope.student.flashcards.settings',
      load: () async => _data(await _api.get('/student/flashcards/settings')),
    );
  }

  Future<Map<String, dynamic>> flashcardUpcoming() async {
    return _cachedMap(
      cache: _cache,
      key: '$cacheScope.student.flashcards.upcoming',
      load: () async => _data(await _api.get('/student/flashcards/upcoming')),
    );
  }

  Future<Map<String, dynamic>> flashcardHistory() async {
    return _cachedMap(
      cache: _cache,
      key: '$cacheScope.student.flashcards.history',
      load: () async => _data(await _api.get('/student/flashcards/history')),
    );
  }

  Future<Map<String, dynamic>> flashcardDifficulty() async {
    return _cachedMap(
      cache: _cache,
      key: '$cacheScope.student.flashcards.difficulty',
      load: () async => _data(await _api.get('/student/flashcards/difficulty')),
    );
  }

  Future<Map<String, dynamic>> flashcardAnalytics() async {
    return _cachedMap(
      cache: _cache,
      key: '$cacheScope.student.flashcards.analytics',
      load: () async => _data(await _api.get('/student/flashcards/analytics')),
    );
  }

  Future<String> updateFlashcardPack(int id, Map<String, dynamic> data) async {
    final response = await _api.put('/student/flashcards/$id', data: data);
    return (response['message'] ?? 'تم تحديث الحزمة بنجاح.').toString();
  }

  Future<Map<String, dynamic>> updateFlashcardSettings(
    Map<String, dynamic> data,
  ) async {
    final operation = (_settingsWrites[cacheScope] ?? Future<void>.value())
        .then((_) async {
          final response = await _api.put(
            '/student/flashcards/settings',
            data: data,
          );
          final saved = _data(response);
          await _cache.writeMap(
            '$cacheScope.student.flashcards.settings',
            saved,
          );
          return saved;
        });
    final tail = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    _settingsWrites[cacheScope] = tail;
    tail.then((_) {
      if (identical(_settingsWrites[cacheScope], tail))
        _settingsWrites.remove(cacheScope);
    });
    return operation;
  }

  Future<Map<String, dynamic>> logTreeFarmSession({
    required String farmScope,
    required int focusedSeconds,
    required String startedAt,
    required String endedAt,
    required String clientUuid,
    int? subjectId,
    String? subjectName,
  }) async {
    final response = await _api.post(
      '/student/tree-farm/log',
      data: {
        'farm_scope': farmScope,
        'focused_seconds': focusedSeconds,
        'started_at': startedAt,
        'ended_at': endedAt,
        'client_uuid': clientUuid,
        if (subjectId != null) 'subject_id': subjectId,
        if (subjectName != null) 'subject_name': subjectName,
      },
    );
    return _flexData(response);
  }

  Future<Map<String, dynamic>> assignments({String sortBy = 'due_date'}) async {
    return _cachedMap(
      cache: _cache,
      key: 'student.assignments.$sortBy',
      load: () async => _data(
        await _api.get(
          '/student/assignments',
          queryParameters: {'sort_by': sortBy},
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> assignmentDetails(int id) async {
    return _cachedMap(
      cache: _cache,
      key: 'student.assignment.$id',
      load: () async =>
          _data(await _api.get('/student/assignments/$id/details')),
    );
  }

  Future<String> updateAssignmentPriority({
    required int assignmentId,
    required int priority,
  }) async {
    final response = await _api.post(
      '/student/assignments/$assignmentId/priority',
      data: {'priority': priority},
    );
    return (response['message'] ?? 'تم تحديث الأولوية.').toString();
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
    return (response['message'] ?? 'تم تسليم التكليف بنجاح.').toString();
  }

  Future<Map<String, dynamic>> reminders() async {
    return _cachedMap(
      cache: _cache,
      key: 'student.reminders',
      load: () async => _data(await _api.get('/student/reminders')),
    );
  }

  Future<String> scanQrAttendance(String token) async {
    final response = await _api.post(
      '/student/qr-attendance/scan',
      data: {'token': token},
    );
    if (response['confirmed'] == false) {
      throw ApiException(
        (response['message'] ?? 'لم يتم تأكيد حضورك. حاول مسح الكود مرة أخرى.')
            .toString(),
      );
    }
    return (response['message'] ?? 'تم تسجيل الحضور بنجاح.').toString();
  }

  Future<Map<String, dynamic>> messages() async {
    return _cachedMap(
      cache: _cache,
      key: 'student.messages',
      load: () async => _data(await _api.get('/student/messages')),
    );
  }

  Future<Map<String, dynamic>> startConversation() async {
    final response = await _api.get('/student/messages/start');
    return _data(response);
  }

  Future<Map<String, dynamic>> conversation(int id) async {
    return _cachedMap(
      cache: _cache,
      key: 'student.conversation.$id',
      load: () async => _data(await _api.get('/student/messages/$id')),
    );
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
    return _cachedMap(
      cache: _cache,
      key: 'student.clinical.logbook',
      load: () async => _data(await _api.get('/student/clinical/logbook')),
    );
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

  Future<Map<String, dynamic>> regenerateClinicalLogQr(int id) async {
    final response = await _api.post(
      '/student/clinical/logbook/$id/regenerate-qr',
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
    return _cachedMap(
      cache: _cache,
      key: 'student.clinical.evaluations',
      load: () async => _data(await _api.get('/student/clinical/evaluations')),
    );
  }

  Future<Map<String, dynamic>> clinicalEvaluation(int id) async {
    return _cachedMap(
      cache: _cache,
      key: 'student.clinical.evaluation.$id',
      load: () async =>
          _data(await _api.get('/student/clinical/evaluations/$id')),
    );
  }

  Future<Map<String, dynamic>> clinicalMockExams() async {
    return _cachedMap(
      cache: _cache,
      key: 'student.clinical.mock_exams',
      load: () async => _data(await _api.get('/student/clinical/mock-exams')),
    );
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
    return _cachedMap(
      cache: _cache,
      key: 'student.clinical.mock_result.$evaluationId',
      load: () async => _data(
        await _api.get('/student/clinical/mock-exams/results/$evaluationId'),
      ),
    );
  }

  Future<Map<String, dynamic>> clinicalRareCases() async {
    return _cachedMap(
      cache: _cache,
      key: 'student.clinical.rare_cases',
      load: () async => _data(await _api.get('/student/clinical/rare-cases')),
    );
  }

  Future<Map<String, dynamic>> clinicalRareCase(int id) async {
    return _cachedMap(
      cache: _cache,
      key: 'student.clinical.rare_case.$id',
      load: () async =>
          _data(await _api.get('/student/clinical/rare-cases/$id')),
    );
  }

  Future<Map<String, dynamic>> inquiries({String? status}) async {
    return _cachedMap(
      cache: _cache,
      key: 'student.inquiries.${status ?? 'all'}',
      load: () async => _data(
        await _api.get(
          '/student/inquiries',
          queryParameters: {
            if (status != null && status.isNotEmpty) 'status': status,
          },
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> inquiryOptions() async {
    return _cachedMap(
      cache: _cache,
      key: 'student.inquiries.options',
      load: () async => _data(await _api.get('/student/inquiries/options')),
    );
  }

  Future<Map<String, dynamic>> inquiryDetails(int id) async {
    return _cachedMap(
      cache: _cache,
      key: 'student.inquiry.$id',
      load: () async => _data(await _api.get('/student/inquiries/$id')),
    );
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
    return _cachedMap(
      cache: _cache,
      key: 'student.profile',
      load: () async => _data(await _api.get('/student/me')),
      maxAge: const Duration(hours: 24),
    );
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

  Future<String> submitDeviceRequest({
    required String requestedDeviceName,
    String? platform,
    required String reason,
  }) async {
    final response = await _api.post(
      '/student/devices/request',
      data: {
        'requested_device_name': requestedDeviceName,
        if (platform != null) 'platform': platform,
        'reason': reason,
      },
    );
    return (response['message'] ?? 'تم تقديم طلب استخدام جهاز فرعي بنجاح.')
        .toString();
  }

  Future<Map<String, dynamic>> fetchSupportSettings() async {
    return _cachedMap(
      cache: _cache,
      key: 'student.support_settings',
      load: () async => _data(await _api.get('/student/support-settings')),
      maxAge: const Duration(hours: 1),
    );
  }
}

Future<Map<String, dynamic>> _cachedMap({
  required OfflineCacheService cache,
  required String key,
  required Future<Map<String, dynamic>> Function() load,
  Duration maxAge = OfflineCacheService.maxOfflineAge,
}) async {
  try {
    final data = await load();
    await cache.writeMap(key, data);
    return data;
  } on ApiException catch (error) {
    if (!error.isOffline) rethrow;
    final cached = await cache.readMap(key, maxAge: maxAge);
    if (cached != null) return cached;
    throw ApiException(
      'لا توجد بيانات محفوظة لهذه الصفحة. يرجى الاتصال بالإنترنت للتحديث.',
      isOffline: true,
      statusCode: error.statusCode,
    );
  }
}

Map<String, dynamic> _data(Map<String, dynamic> response) {
  final data = response['data'];
  if (data is Map<String, dynamic>) return data;
  throw const ApiException('استجابة غير مكتملة من الخادم.');
}

Map<String, dynamic> _flexData(Map<String, dynamic> response) {
  final data = response['data'];
  if (data is Map<String, dynamic>) return data;
  return response;
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
