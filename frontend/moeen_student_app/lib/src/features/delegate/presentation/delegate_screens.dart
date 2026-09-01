import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart' as intl;

import '../../../core/network/api_exception.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/downloads/download_service.dart';
import '../../../shared/widgets/moeen_dialogs.dart';
import '../../../shared/widgets/library_browser.dart';
import '../../auth/logic/auth_controller.dart';
import '../../student/data/models/financial_ledger.dart';
import '../../student/data/models/subscription_models.dart';
import '../../student/data/student_repositories.dart';
import '../data/delegate_repositories.dart';
import '../logic/delegate_controllers.dart';
import 'widgets/delegate_shell.dart';

part 'delegate_dashboard_screen.dart';
part 'delegate_account_screens.dart';
part 'delegate_news_notifications_screen.dart';
part 'delegate_students_subjects_screens.dart';
part 'delegate_academic_screens.dart';
part 'delegate_content_screens.dart';
part 'delegate_library_navigation_screens.dart';
part 'delegate_attendance_grades_screens.dart';
part 'delegate_communication_screens.dart';
part 'delegate_list_widgets.dart';
part 'delegate_student_forms.dart';
part 'delegate_academic_forms.dart';
part 'delegate_attendance_grade_forms.dart';
part 'delegate_misc_forms.dart';
part 'delegate_chat_widgets.dart';
part 'delegate_core_helpers.dart';
part 'delegate_profile_widgets.dart';
part 'delegate_subscription_widgets.dart';
part 'delegate_ledger_widgets.dart';
part 'delegate_student_subject_widgets.dart';
part 'delegate_attendance_tracking_screen.dart';
part 'delegate_attendance_form_screen.dart';
part 'delegate_qr_session_screen.dart';

final _delegateNewsProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) => ref.watch(delegateRepositoryProvider).news(),
);
final _delegateNotificationsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>(
      (ref) => ref.watch(delegateRepositoryProvider).notifications(),
    );
final _delegateSubjectsProvider = FutureProvider.autoDispose<List<dynamic>>(
  (ref) => ref.watch(delegateRepositoryProvider).subjects(),
);
final _delegateSchedulesProvider = FutureProvider.autoDispose<List<dynamic>>(
  (ref) => ref.watch(delegateRepositoryProvider).schedules(),
);
final _delegateExamsProvider = FutureProvider.autoDispose<List<dynamic>>(
  (ref) => ref.watch(delegateRepositoryProvider).examSchedules(),
);
final _delegateAssignmentsProvider = FutureProvider.autoDispose<List<dynamic>>(
  (ref) => ref.watch(delegateRepositoryProvider).assignments(),
);
final _delegateAssignmentPermissionsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>(
      (ref) => ref.watch(delegateRepositoryProvider).assignmentPermissions(),
    );
final _delegateResourcesProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>(
      (ref) => ref.watch(delegateRepositoryProvider).resources(),
    );
final _delegateSharedLibraryProvider = FutureProvider.autoDispose
    .family<List<dynamic>, ({String? query, String? category, int? subjectId})>(
      (ref, q) => ref
          .watch(delegateRepositoryProvider)
          .searchLibrary(
            query: q.query,
            category: q.category,
            subjectId: q.subjectId,
          ),
    );
final _delegateRemindersProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>(
      (ref, filter) =>
          ref.watch(delegateRepositoryProvider).reminders(filter: filter),
    );
final _delegateAnnouncementsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, ({String? query, String? category})>(
      (ref, q) => ref
          .watch(delegateRepositoryProvider)
          .announcements(query: q.query, category: q.category),
    );
final _delegateAttendanceProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, ({String? search, String? date})>(
      (ref, q) => ref
          .watch(delegateRepositoryProvider)
          .attendance(search: q.search, date: q.date),
    );
final _delegateAbsenceAlertsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>(
      (ref) => ref.watch(delegateRepositoryProvider).attendanceAlerts(),
    );
final _delegateAuthorizedGradesProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>(
      (ref) => ref.watch(delegateRepositoryProvider).authorizedGrades(),
    );
final _delegateHelperTasksProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>(
      (ref) => ref.watch(delegateRepositoryProvider).helperDelegations(),
    );
final _delegateMessagesProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>(
      (ref) => ref.watch(delegateRepositoryProvider).messages(),
    );
final _delegateDoctorChatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>(
      (ref) => ref.watch(delegateRepositoryProvider).doctorChats(),
    );
final _delegateInquiriesProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>(
      (ref, status) => ref
          .watch(delegateRepositoryProvider)
          .inquiries(status: status == 'all' ? null : status),
    );
final _delegateProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  final delegateMe = await ref.watch(delegateRepositoryProvider).me();
  try {
    // Fallback to student profile to fill in missing academic data (university/college)
    final studentMe = await ref
        .watch(studentContentRepositoryProvider)
        .profile();
    return {...studentMe, ...delegateMe};
  } catch (_) {
    return delegateMe;
  }
});
