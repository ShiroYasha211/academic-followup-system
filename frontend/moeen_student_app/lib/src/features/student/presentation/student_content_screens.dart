// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:moeen_student_app/src/features/student/presentation/student_dashboard_screen.dart';

import '../../../core/config/app_config.dart';
import '../../../core/downloads/download_service.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/notifications/push_notification_service.dart';
import '../../../core/offline/connectivity_service.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/moeen_dialogs.dart';
import '../../../shared/widgets/library_browser.dart';
import '../../auth/logic/auth_controller.dart';
import '../data/flashcard_local_store.dart';
import '../data/student_repositories.dart';
import '../logic/one_line_notification_scheduler.dart';
import '../logic/floating_review.dart';
import '../logic/smart_review_queue.dart';
import '../data/tree_farm_local_store.dart';
import '../logic/student_controllers.dart';
import 'student_subscription_screen.dart';
import 'widgets/student_shell.dart';
import 'widgets/student_widgets.dart';

part 'student_subjects_screen.dart';
part 'student_subject_detail_screen.dart';
part 'student_study_center_screen.dart';
part 'student_study_session_screen.dart';
part 'student_schedule_screen.dart';
part 'student_news_screen.dart';
part 'student_quizzes_screen.dart';
part 'student_stars_screen.dart';
part 'student_notifications_screen.dart';
part 'student_exams_screen.dart';
part 'student_resources_screen.dart';
part 'student_library_screen.dart';
part 'student_library_navigation_screens.dart';
part 'student_flashcards_screen.dart';
part 'student_flashcards_home.dart';
part 'student_flashcards_packs.dart';
part 'student_flashcards_analytics.dart';
part 'student_flashcards_difficulty.dart';
part 'student_flashcards_history.dart';
part 'student_flashcards_upcoming.dart';
part 'student_flashcards_today.dart';
part 'student_flashcards_quick_review.dart';
part 'student_flashcards_hero_widgets.dart';
part 'student_flashcards_pack_widgets.dart';
part 'student_flashcards_today_widgets.dart';
part 'student_flashcards_dashboard_widgets.dart';
part 'student_flashcards_ui_widgets.dart';
part 'student_flashcards_details_screen.dart';
part 'student_flashcards_details_widgets.dart';
part 'student_flashcards_import.dart';
part 'student_flashcards_review.dart';
part 'student_flashcards_store.dart';
part 'student_flashcards_forms.dart';
part 'student_flashcards_item_widgets.dart';
part 'student_flashcards_review_summary_widgets.dart';
part 'student_flashcards_shot_review_card.dart';
part 'student_flashcards_smart_review_prompt.dart';
part 'student_flashcards_smart_review_settings.dart';
part 'student_flashcards_floating_settings.dart';
part 'student_flashcards_permissions.dart';
part 'student_flashcards_helpers.dart';
part 'student_assignments_screen.dart';
part 'student_qr_scan_screen.dart';
part 'student_reminders_screen.dart';
part 'student_messages_screen.dart';
part 'student_inquiries_screen.dart';
part 'student_profile_screen.dart';
part 'student_clinical_screen.dart';
part 'student_authorized_grades_screen.dart';
part 'student_tree_farm_screen.dart';
part 'widgets/student_content_widgets.dart';
part 'utils/student_content_formatters.dart';

class SubjectFilters {
  const SubjectFilters({this.termId, this.semesterId});

  final int? termId;
  final int? semesterId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubjectFilters &&
          other.termId == termId &&
          other.semesterId == semesterId;

  @override
  int get hashCode => Object.hash(termId, semesterId);
}

final _subjectsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, SubjectFilters>((ref, filters) {
      return ref
          .watch(studentContentRepositoryProvider)
          .subjects(termId: filters.termId, semesterId: filters.semesterId);
    });

final _subjectDetailsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, id) {
      return ref.watch(studentContentRepositoryProvider).subjectDetails(id);
    });

final _studyProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, tab) {
      return ref.watch(studentContentRepositoryProvider).studyCenter(tab: tab);
    });

final _studySessionProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, id) {
      return ref.watch(studentContentRepositoryProvider).studySession(id);
    });

final _scheduleProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) {
  return ref.watch(studentContentRepositoryProvider).schedules();
});

final _newsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, source) {
      return ref
          .watch(studentContentRepositoryProvider)
          .newsHub(source: source);
    });

final _quizzesProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) {
  return ref.watch(studentContentRepositoryProvider).quizzes();
});

final _quizTakeProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, ({String? accessCode, int quizId})>((
      ref,
      params,
    ) {
      return ref
          .watch(studentContentRepositoryProvider)
          .takeQuiz(params.quizId, accessCode: params.accessCode);
    });

final _quizResultProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, attemptId) {
      return ref.watch(studentContentRepositoryProvider).quizResult(attemptId);
    });

final _starsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return ref.watch(studentContentRepositoryProvider).stars();
});

final _treeFarmProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) {
  return ref.watch(studentContentRepositoryProvider).treeFarm();
});

final _publicFarmProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) {
  return ref.watch(studentContentRepositoryProvider).publicTreeFarm();
});

final _notificationsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, page) {
      return ref
          .watch(studentContentRepositoryProvider)
          .notifications(page: page);
    });

final _authorizedGradesProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, tick) {
      return ref.watch(studentContentRepositoryProvider).authorizedGrades();
    });

final _authorizedGradeDetailsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, categoryId) {
      return ref
          .watch(studentContentRepositoryProvider)
          .authorizedGradeDetails(categoryId);
    });

final _examsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return ref.watch(studentContentRepositoryProvider).exams();
});

final _resourcesProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, ResourceQuery>((ref, query) {
      return ref
          .watch(studentContentRepositoryProvider)
          .resources(
            search: query.search,
            subjectId: query.subjectId,
            category: query.category,
            sort: query.sort,
            scheduled: query.scheduled,
            page: query.page,
          );
    });

final _libraryProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, LibraryQuery>((ref, query) {
      return ref
          .watch(studentContentRepositoryProvider)
          .library(
            search: query.search,
            subjectId: query.subjectId,
            category: query.category,
            fileType: query.fileType,
            myUploads: query.myUploads,
            page: query.page,
          );
    });

final _flashcardsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  final store = ref.watch(flashcardLocalStoreProvider);
  try {
    final data = await ref.watch(studentContentRepositoryProvider).flashcards();
    await store.cacheHome(data);
    return data;
  } on ApiException catch (error) {
    if (!error.isOffline) rethrow;
    final cached = await store.loadHome();
    if (cached != null) return cached;
    rethrow;
  }
});

final _flashcardDetailsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, id) async {
      final store = ref.watch(flashcardLocalStoreProvider);
      try {
        final data = await ref
            .watch(studentContentRepositoryProvider)
            .flashcardDetails(id);
        await store.cachePackDetails(id, data);
        return data;
      } on ApiException catch (error) {
        if (!error.isOffline) rethrow;
        final cached = await store.loadPackDetails(id);
        if (cached != null) return cached;
        rethrow;
      }
    });

final _flashcardReviewProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, id) async {
      final store = ref.watch(flashcardLocalStoreProvider);
      try {
        final data = await ref
            .watch(studentContentRepositoryProvider)
            .flashcardReview(id);
        await store.cachePackReview(id, data);
        return data;
      } on ApiException catch (error) {
        if (!error.isOffline) rethrow;
        final cached = await store.loadPackReview(id);
        if (cached != null) return cached;
        rethrow;
      }
    });

final _flashcardDailyQueueProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
      final store = ref.watch(flashcardLocalStoreProvider);
      try {
        final data = await ref
            .watch(studentContentRepositoryProvider)
            .flashcardDailyQueue();
        await store.cacheDailyQueue(data);
        await FloatingReview.updateQueue(store.accountKey, data);
        return data;
      } on ApiException catch (error) {
        if (!error.isOffline) rethrow;
        final cached = await store.loadDailyQueue();
        if (cached != null) return cached;
        rethrow;
      }
    });

final studentDueFlashcardCountProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final data = await ref.watch(_flashcardDailyQueueProvider.future);
  final local = await ref.watch(flashcardLocalStoreProvider).load();
  return SmartReviewQueue.pending(data, local, availableOnly: true).length;
});

final _flashcardOneLineNotificationsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
      final store = ref.watch(flashcardLocalStoreProvider);
      try {
        final data = await ref
            .watch(studentContentRepositoryProvider)
            .flashcardOneLineNotifications();
        await store.cacheOneLineNotifications(data);
        return data;
      } on ApiException catch (error) {
        if (!error.isOffline) rethrow;
        final cached = await store.loadOneLineNotifications();
        if (cached != null) return cached;
        rethrow;
      }
    });

final _flashcardSettingsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
      final store = ref.watch(flashcardLocalStoreProvider);
      try {
        final data = await ref
            .watch(studentContentRepositoryProvider)
            .flashcardSettings();
        await store.cacheSettings(data);
        if (await ref.read(connectivityServiceProvider).isOnline()) {
          await store.applyServerSmartReviewSettings(data);
        }
        return data;
      } on ApiException catch (error) {
        if (!error.isOffline) rethrow;
        final cached = await store.loadSettings();
        if (cached != null) return cached;
        final home = await store.loadHome();
        if (home != null && home['settings'] is Map) {
          return {'settings': Map<String, dynamic>.from(home['settings'])};
        }
        rethrow;
      }
    });

final _flashcardUpcomingProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
      final store = ref.watch(flashcardLocalStoreProvider);
      try {
        final data = await ref
            .watch(studentContentRepositoryProvider)
            .flashcardUpcoming();
        await store.cacheUpcoming(data);
        return data;
      } on ApiException catch (error) {
        if (!error.isOffline) rethrow;
        final cached = await store.loadUpcoming();
        if (cached != null) return cached;
        rethrow;
      }
    });

final _flashcardHistoryProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
      final store = ref.watch(flashcardLocalStoreProvider);
      try {
        final data = await ref
            .watch(studentContentRepositoryProvider)
            .flashcardHistory();
        await store.cacheHistory(data);
        return data;
      } on ApiException catch (error) {
        if (!error.isOffline) rethrow;
        final cached = await store.loadHistory();
        if (cached != null) return cached;
        rethrow;
      }
    });

final _flashcardDifficultyProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
      final store = ref.watch(flashcardLocalStoreProvider);
      try {
        final data = await ref
            .watch(studentContentRepositoryProvider)
            .flashcardDifficulty();
        await store.cacheDifficulty(data);
        return data;
      } on ApiException catch (error) {
        if (!error.isOffline) rethrow;
        final cached = await store.loadDifficulty();
        if (cached != null) return cached;
        rethrow;
      }
    });

final _flashcardAnalyticsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
      final store = ref.watch(flashcardLocalStoreProvider);
      try {
        final data = await ref
            .watch(studentContentRepositoryProvider)
            .flashcardAnalytics();
        await store.cacheAnalytics(data);
        return data;
      } on ApiException catch (error) {
        if (!error.isOffline) rethrow;
        final cached = await store.loadAnalytics();
        if (cached != null) return cached;
        rethrow;
      }
    });

final _flashcardStoreProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
      return ref
          .watch(studentContentRepositoryProvider)
          .flashcardStore(displayMode: 'one_line');
    });

final _assignmentsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, sortBy) {
      return ref
          .watch(studentContentRepositoryProvider)
          .assignments(sortBy: sortBy);
    });

final _assignmentDetailsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, id) {
      return ref.watch(studentContentRepositoryProvider).assignmentDetails(id);
    });

final _remindersProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) {
  return ref.watch(studentContentRepositoryProvider).reminders();
});

final _messagesProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) {
  return ref.watch(studentContentRepositoryProvider).messages();
});

final _clinicalLogbookProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
      return ref.watch(studentContentRepositoryProvider).clinicalLogbook();
    });

final _clinicalEvaluationsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
      return ref.watch(studentContentRepositoryProvider).clinicalEvaluations();
    });

final _clinicalEvaluationProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, id) {
      return ref.watch(studentContentRepositoryProvider).clinicalEvaluation(id);
    });

final _clinicalMockExamsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
      return ref.watch(studentContentRepositoryProvider).clinicalMockExams();
    });

final _clinicalRareCasesProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
      return ref.watch(studentContentRepositoryProvider).clinicalRareCases();
    });

final _clinicalRareCaseProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, id) {
      return ref.watch(studentContentRepositoryProvider).clinicalRareCase(id);
    });

final _clinicalMockTakeProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, id) {
      return ref.watch(studentContentRepositoryProvider).clinicalMockTake(id);
    });

final _clinicalMockResultProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, id) {
      return ref.watch(studentContentRepositoryProvider).clinicalMockResult(id);
    });

final _conversationProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, id) {
      return ref.watch(studentContentRepositoryProvider).conversation(id);
    });

final _inquiriesProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, status) {
      return ref
          .watch(studentContentRepositoryProvider)
          .inquiries(status: status == 'all' ? null : status);
    });

final _inquiryOptionsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
      return ref.watch(studentContentRepositoryProvider).inquiryOptions();
    });

final _inquiryDetailsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, id) {
      return ref.watch(studentContentRepositoryProvider).inquiryDetails(id);
    });

final _studentProfileProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
      return ref.watch(studentContentRepositoryProvider).profile();
    });

typedef ResourceQuery = ({
  String? search,
  int? subjectId,
  String? category,
  String sort,
  bool scheduled,
  int page,
});

typedef LibraryQuery = ({
  String? search,
  int? subjectId,
  String? category,
  String? fileType,
  bool myUploads,
  int page,
});

const _palette = [
  Color(0xFF4338CA),
  Color(0xFF0F766E),
  Color(0xFFEA580C),
  Color(0xFFBE123C),
  Color(0xFF0369A1),
  Color(0xFF7C3AED),
];
