// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:moeen_student_app/src/features/student/presentation/student_dashboard_screen.dart';

import '../../../core/config/app_config.dart';
import '../../../core/downloads/download_service.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/moeen_dialogs.dart';
import '../../auth/logic/auth_controller.dart';
import '../data/student_repositories.dart';
import '../logic/student_controllers.dart';
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
part 'student_flashcards_screen.dart';
part 'student_assignments_screen.dart';
part 'student_qr_scan_screen.dart';
part 'student_reminders_screen.dart';
part 'student_messages_screen.dart';
part 'student_inquiries_screen.dart';
part 'student_profile_screen.dart';
part 'student_clinical_screen.dart';
part 'widgets/student_content_widgets.dart';
part 'utils/student_content_formatters.dart';

final _subjectsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) {
  return ref.watch(studentContentRepositoryProvider).subjects();
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

final _notificationsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, page) {
      return ref
          .watch(studentContentRepositoryProvider)
          .notifications(page: page);
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
) {
  return ref.watch(studentContentRepositoryProvider).flashcards();
});

final _flashcardDetailsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, id) {
      return ref.watch(studentContentRepositoryProvider).flashcardDetails(id);
    });

final _flashcardReviewProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, id) {
      return ref.watch(studentContentRepositoryProvider).flashcardReview(id);
    });

final _flashcardStoreProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, search) {
      return ref
          .watch(studentContentRepositoryProvider)
          .flashcardStore(search: search, displayMode: 'one_line');
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

final _clinicalMockExamsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
      return ref.watch(studentContentRepositoryProvider).clinicalMockExams();
    });

final _clinicalRareCasesProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
      return ref.watch(studentContentRepositoryProvider).clinicalRareCases();
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
