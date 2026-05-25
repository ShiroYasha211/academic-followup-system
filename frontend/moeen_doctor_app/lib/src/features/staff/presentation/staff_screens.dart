import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

import '../../../core/downloads/download_service.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/refresh/staff_refresh_coordinator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/moeen_dialogs.dart';
import '../../../shared/widgets/status_message.dart';
import '../../auth/data/staff_auth_session.dart';
import '../../auth/logic/auth_controller.dart';
import '../data/staff_repository.dart';
import 'administrative_management_screens.dart';
import 'administrative_operations_screens.dart';
import 'doctor_workflow_screens.dart';
import 'staff_account_screens.dart';
import 'staff_shell.dart';

part 'doctor_academic_screens.dart';
part 'doctor_assignments.dart';
part 'doctor_library.dart';
part 'doctor_announcements.dart';
part 'doctor_grades.dart';
part 'doctor_quizzes.dart';
part 'doctor_stars.dart';
part 'doctor_inquiries.dart';
part 'doctor_messages.dart';
part 'doctor_news_notifications.dart';
part 'doctor_clinical.dart';

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  final session = ref.watch(authControllerProvider).valueOrNull;
  final cachePrefix =
      'staff.${session?.email ?? 'guest'}.${session?.workspace.name ?? 'doctor'}';
  return StaffRepository(
    ref.watch(authenticatedApiClientProvider),
    cache: ref.watch(offlineCacheProvider),
    cachePrefix: cachePrefix,
  );
});

bool staffIsSubscriptionRequired(Object? error) {
  return error is ApiException &&
      (error.code == 'subscription_required' || error.statusCode == 402);
}

String staffSubscriptionRouteFor(BuildContext context) {
  final path = GoRouterState.of(context).uri.path;
  return path.startsWith('/administrative')
      ? '/administrative/subscription'
      : '/doctor/subscription';
}

Future<void> showStaffSubscriptionRequiredDialog(
  BuildContext context,
  Object error,
) async {
  final message = error is ApiException
      ? error.message
      : 'يجب الاشتراك للوصول إلى هذه الميزة.';
  final approved = await showMoeenConfirmDialog(
    context: context,
    title: 'هذه الميزة تحتاج اشتراك',
    message: message,
    confirmLabel: 'الاشتراك الآن',
    cancelLabel: 'لاحقاً',
    icon: Icons.lock_rounded,
    color: AppColors.goldDeep,
  );
  if (approved && context.mounted) {
    context.go(staffSubscriptionRouteFor(context));
  }
}

final _resourceProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, StaffMenuItem>((ref, item) {
      ref.watch(staffRefreshCoordinatorProvider.select((state) => state.version));
      return ref.watch(staffRepositoryProvider).get(item.endpoint);
    });

final staffRoutes = <GoRoute>[
  GoRoute(
    path: StaffDashboardScreen.route,
    builder: (context, state) => const StaffAccountDashboardScreen(),
  ),
  GoRoute(
    path: StaffProfileScreen.route,
    builder: (context, state) => const StaffAccountProfileScreen(),
  ),
  GoRoute(
    path: '/doctor/subscription',
    builder: (context, state) => const StaffSubscriptionScreen(
      workspace: StaffWorkspace.doctor,
      currentRoute: '/doctor/subscription',
    ),
  ),
  GoRoute(
    path: '/doctor/ledger',
    builder: (context, state) => const StaffLedgerScreen(
      workspace: StaffWorkspace.doctor,
      currentRoute: '/doctor/ledger',
    ),
  ),
  GoRoute(
    path: DoctorExcusesScreen.route,
    builder: (context, state) => const DoctorExcusesScreen(),
  ),
  GoRoute(
    path: DoctorAttendanceScreen.route,
    builder: (context, state) => const DoctorAttendanceScreen(),
  ),
  GoRoute(
    path: DoctorAttendanceTrackingScreen.route,
    builder: (context, state) {
      final extra = state.extra is Map
          ? Map<String, dynamic>.from(state.extra as Map)
          : const <String, dynamic>{};
      return DoctorAttendanceTrackingScreen(
        subjectId: int.parse(state.pathParameters['subjectId']!),
        date: extra['date']?.toString(),
        lectureId: extra['lecture_id'],
      );
    },
  ),
  GoRoute(
    path: DoctorReportsScreen.route,
    builder: (context, state) => const DoctorReportsScreen(),
  ),
  GoRoute(
    path: DoctorSubjectReportScreen.route,
    builder: (context, state) => DoctorSubjectReportScreen(
      subjectId: int.parse(state.pathParameters['subjectId']!),
    ),
  ),
  GoRoute(
    path: DoctorAssignmentsScreen.route,
    builder: (context, state) => const DoctorAssignmentsScreen(),
  ),
  GoRoute(
    path: DoctorAssignmentDetailsScreen.route,
    builder: (context, state) => DoctorAssignmentDetailsScreen(
      assignmentId: int.parse(state.pathParameters['assignmentId']!),
    ),
  ),
  GoRoute(
    path: DoctorGradesScreen.route,
    builder: (context, state) => const DoctorGradesScreen(),
  ),
  GoRoute(
    path: DoctorGradeSubjectScreen.route,
    builder: (context, state) => DoctorGradeSubjectScreen(
      subjectId: int.parse(state.pathParameters['subjectId']!),
      subject: state.extra is Map
          ? Map<String, dynamic>.from(state.extra as Map)
          : null,
    ),
  ),
  GoRoute(
    path: DoctorLibraryScreen.route,
    builder: (context, state) => const DoctorLibraryScreen(),
  ),
  GoRoute(
    path: DoctorAnnouncementsScreen.route,
    builder: (context, state) => const DoctorAnnouncementsScreen(),
  ),
  GoRoute(
    path: DoctorQuizzesScreen.route,
    builder: (context, state) => const DoctorQuizzesScreen(),
  ),
  GoRoute(
    path: DoctorQuizFormScreen.createRoute,
    builder: (context, state) => DoctorQuizFormScreen(
      subjects: state.extra is Map
          ? _docList((state.extra as Map)['subjects'])
          : const [],
    ),
  ),
  GoRoute(
    path: DoctorQuizFormScreen.editRoute,
    builder: (context, state) => DoctorQuizFormScreen(
      quizId: int.parse(state.pathParameters['quizId']!),
      subjects: state.extra is Map
          ? _docList((state.extra as Map)['subjects'])
          : const [],
      quizDetails: state.extra is Map
          ? _docMap((state.extra as Map)['details'])
          : const {},
    ),
  ),
  GoRoute(
    path: DoctorQuizDetailsScreen.route,
    builder: (context, state) => DoctorQuizDetailsScreen(
      quizId: int.parse(state.pathParameters['quizId']!),
      subjects: state.extra is Map
          ? _docList((state.extra as Map)['subjects'])
          : const [],
    ),
  ),
  GoRoute(
    path: DoctorStarsScreen.route,
    builder: (context, state) => const DoctorStarsScreen(),
  ),
  GoRoute(
    path: DoctorInquiriesScreen.route,
    builder: (context, state) => const DoctorInquiriesScreen(),
  ),
  GoRoute(
    path: DoctorInquiryDetailsScreen.route,
    builder: (context, state) => DoctorInquiryDetailsScreen(
      inquiryId: int.parse(state.pathParameters['inquiryId']!),
    ),
  ),
  GoRoute(
    path: DoctorMessagesScreen.route,
    builder: (context, state) => const DoctorMessagesScreen(),
  ),
  GoRoute(
    path: DoctorStartConversationScreen.route,
    builder: (context, state) => const DoctorStartConversationScreen(),
  ),
  GoRoute(
    path: DoctorConversationScreen.route,
    builder: (context, state) => DoctorConversationScreen(
      conversationId: int.parse(state.pathParameters['conversationId']!),
    ),
  ),
  GoRoute(
    path: DoctorNewsScreen.route,
    builder: (context, state) => const DoctorNewsScreen(),
  ),
  GoRoute(
    path: DoctorNotificationsScreen.route,
    builder: (context, state) => const DoctorNotificationsScreen(),
  ),
  GoRoute(
    path: DoctorClinicalScreen.route,
    builder: (context, state) => const DoctorClinicalScreen(),
  ),
  GoRoute(
    path: DoctorClinicalSectionScreen.route,
    builder: (context, state) => DoctorClinicalSectionScreen(
      section: state.pathParameters['section']!,
    ),
  ),
  GoRoute(
    path: '/administrative/subscription',
    builder: (context, state) => const StaffSubscriptionScreen(
      workspace: StaffWorkspace.administrative,
      currentRoute: '/administrative/subscription',
    ),
  ),
  GoRoute(
    path: '/administrative/ledger',
    builder: (context, state) => const StaffLedgerScreen(
      workspace: StaffWorkspace.administrative,
      currentRoute: '/administrative/ledger',
    ),
  ),
  GoRoute(
    path: StaffAdministrativeSettingsScreen.route,
    builder: (context, state) => const StaffAdministrativeSettingsScreen(),
  ),
  GoRoute(
    path: AdministrativeMajorsScreen.route,
    builder: (context, state) => const AdministrativeMajorsScreen(),
  ),
  GoRoute(
    path: AdministrativeSubjectsScreen.route,
    builder: (context, state) => const AdministrativeSubjectsScreen(),
  ),
  GoRoute(
    path: AdministrativeDoctorsScreen.route,
    builder: (context, state) => const AdministrativeDoctorsScreen(),
  ),
  GoRoute(
    path: AdministrativeStudentsScreen.route,
    builder: (context, state) => const AdministrativeStudentsScreen(),
  ),
  GoRoute(
    path: AdministrativeDelegatesScreen.route,
    builder: (context, state) => const AdministrativeDelegatesScreen(),
  ),
  GoRoute(
    path: AdministrativeNotificationsScreen.route,
    builder: (context, state) => const AdministrativeNotificationsScreen(),
  ),
  GoRoute(
    path: AdministrativeExcusesScreen.route,
    builder: (context, state) => const AdministrativeExcusesScreen(),
  ),
  GoRoute(
    path: AdministrativeReportsScreen.route,
    builder: (context, state) => const AdministrativeReportsScreen(),
  ),
  GoRoute(
    path: AdministrativeExamsScreen.route,
    builder: (context, state) => const AdministrativeExamsScreen(),
  ),
  GoRoute(
    path: AdministrativeSchedulesScreen.route,
    builder: (context, state) => const AdministrativeSchedulesScreen(),
  ),
  ...staffMenuItems
      .map(
        (item) => GoRoute(
          path: item.route,
          builder: (context, state) => StaffResourceScreen(item: item),
        ),
      )
      .where(
        (route) =>
            route.path != '/doctor/subscription' &&
            route.path != '/doctor/ledger' &&
            route.path != DoctorExcusesScreen.route &&
            route.path != DoctorAttendanceScreen.route &&
            route.path != DoctorReportsScreen.route &&
            route.path != DoctorAssignmentsScreen.route &&
            route.path != DoctorGradesScreen.route &&
            route.path != DoctorLibraryScreen.route &&
            route.path != DoctorAnnouncementsScreen.route &&
            route.path != DoctorQuizzesScreen.route &&
            route.path != DoctorStarsScreen.route &&
            route.path != DoctorInquiriesScreen.route &&
            route.path != DoctorMessagesScreen.route &&
            route.path != DoctorNewsScreen.route &&
            route.path != DoctorNotificationsScreen.route &&
            route.path != DoctorClinicalScreen.route &&
            route.path != '/administrative/subscription' &&
            route.path != '/administrative/ledger' &&
            route.path != StaffAdministrativeSettingsScreen.route &&
            route.path != AdministrativeMajorsScreen.route &&
            route.path != AdministrativeSubjectsScreen.route &&
            route.path != AdministrativeDoctorsScreen.route &&
            route.path != AdministrativeStudentsScreen.route &&
            route.path != AdministrativeDelegatesScreen.route &&
            route.path != AdministrativeNotificationsScreen.route &&
            route.path != AdministrativeExcusesScreen.route &&
            route.path != AdministrativeReportsScreen.route &&
            route.path != AdministrativeExamsScreen.route &&
            route.path != AdministrativeSchedulesScreen.route,
      ),
];

class StaffMenuItem {
  const StaffMenuItem({
    required this.label,
    required this.route,
    required this.endpoint,
    required this.icon,
    required this.workspace,
    this.createEndpoint,
    this.updateEndpoint,
    this.deleteEndpoint,
    this.exportEndpoint,
    this.formFields = const [],
    this.description,
  });

  final String label;
  final String route;
  final String endpoint;
  final IconData icon;
  final StaffWorkspace workspace;
  final String? createEndpoint;
  final String? updateEndpoint;
  final String? deleteEndpoint;
  final String? exportEndpoint;
  final List<ResourceField> formFields;
  final String? description;

  bool get canCreate => createEndpoint != null && formFields.isNotEmpty;
  bool get canExport => exportEndpoint != null;
}

class ResourceField {
  const ResourceField(
    this.key,
    this.label, {
    this.keyboardType,
    this.required = true,
    this.multiline = false,
    this.file = false,
  });

  final String key;
  final String label;
  final TextInputType? keyboardType;
  final bool required;
  final bool multiline;
  final bool file;
}

const _doctor = StaffWorkspace.doctor;
const _admin = StaffWorkspace.administrative;

const staffMenuItems = <StaffMenuItem>[
  StaffMenuItem(
    label: 'الحضور',
    route: '/doctor/attendance',
    endpoint: '/doctor/attendance',
    icon: Icons.fact_check_rounded,
    workspace: _doctor,
    description: 'رصد الحضور، QR، التقارير، وتفعيل رصد المندوب.',
  ),
  StaffMenuItem(
    label: 'التكاليف',
    route: '/doctor/assignments',
    endpoint: '/doctor/assignments',
    icon: Icons.assignment_rounded,
    workspace: _doctor,
    createEndpoint: '/doctor/assignments',
    formFields: [
      ResourceField('title', 'عنوان التكليف'),
      ResourceField('description', 'الوصف', multiline: true),
      ResourceField(
        'subject_id',
        'معرف المادة',
        keyboardType: TextInputType.number,
      ),
      ResourceField('due_date', 'تاريخ التسليم'),
    ],
  ),
  StaffMenuItem(
    label: 'الدرجات',
    route: '/doctor/grades',
    endpoint: '/doctor/grades',
    icon: Icons.grade_rounded,
    workspace: _doctor,
  ),
  StaffMenuItem(
    label: 'استفسارات الطلاب',
    route: '/doctor/inquiries',
    endpoint: '/doctor/inquiries',
    icon: Icons.forum_rounded,
    workspace: _doctor,
  ),
  StaffMenuItem(
    label: 'إعلاناتي',
    route: '/doctor/announcements',
    endpoint: '/doctor/announcements',
    icon: Icons.campaign_rounded,
    workspace: _doctor,
    createEndpoint: '/doctor/announcements',
    formFields: [
      ResourceField('title', 'عنوان الإعلان'),
      ResourceField('content', 'المحتوى', multiline: true),
      ResourceField(
        'subject_id',
        'معرف المادة',
        keyboardType: TextInputType.number,
        required: false,
      ),
    ],
  ),
  StaffMenuItem(
    label: 'الكويزات',
    route: '/doctor/quizzes',
    endpoint: '/doctor/quizzes',
    icon: Icons.quiz_rounded,
    workspace: _doctor,
  ),
  StaffMenuItem(
    label: 'النجوم',
    route: '/doctor/stars',
    endpoint: '/doctor/stars',
    icon: Icons.stars_rounded,
    workspace: _doctor,
  ),
  StaffMenuItem(
    label: 'المكتبة المشتركة',
    route: '/doctor/library',
    endpoint: '/doctor/library',
    icon: Icons.local_library_rounded,
    workspace: _doctor,
  ),
  StaffMenuItem(
    label: 'الرسائل',
    route: '/doctor/messages',
    endpoint: '/doctor/messages',
    icon: Icons.chat_rounded,
    workspace: _doctor,
  ),
  StaffMenuItem(
    label: 'الأخبار',
    route: '/doctor/news',
    endpoint: '/doctor/news',
    icon: Icons.newspaper_rounded,
    workspace: _doctor,
  ),
  StaffMenuItem(
    label: 'الإشعارات',
    route: '/doctor/notifications',
    endpoint: '/doctor/notifications',
    icon: Icons.notifications_rounded,
    workspace: _doctor,
  ),
  StaffMenuItem(
    label: 'أعذار الغياب',
    route: '/doctor/excuses',
    endpoint: '/doctor/excuses',
    icon: Icons.verified_user_rounded,
    workspace: _doctor,
  ),
  StaffMenuItem(
    label: 'التقارير',
    route: '/doctor/reports',
    endpoint: '/doctor/reports',
    icon: Icons.analytics_rounded,
    workspace: _doctor,
  ),
  StaffMenuItem(
    label: 'القسم السريري',
    route: '/doctor/clinical',
    endpoint: '/doctor/clinical/overview',
    icon: Icons.medical_services_rounded,
    workspace: _doctor,
    description: 'المراكز، الأقسام، الحالات، التقييمات، وسجل التدريب السريري.',
  ),
  StaffMenuItem(
    label: 'الاشتراك',
    route: '/doctor/subscription',
    endpoint: '/doctor/subscription',
    icon: Icons.workspace_premium_rounded,
    workspace: _doctor,
  ),
  StaffMenuItem(
    label: 'كشف الحساب',
    route: '/doctor/ledger',
    endpoint: '/doctor/ledger',
    exportEndpoint: '/doctor/ledger/export',
    icon: Icons.receipt_long_rounded,
    workspace: _doctor,
  ),
  StaffMenuItem(
    label: 'إعدادات الكلية',
    route: '/administrative/settings',
    endpoint: '/administrative/settings',
    icon: Icons.settings_rounded,
    workspace: _admin,
  ),
  StaffMenuItem(
    label: 'الطلاب',
    route: '/administrative/students',
    endpoint: '/administrative/students',
    icon: Icons.groups_rounded,
    workspace: _admin,
    createEndpoint: '/administrative/students',
    formFields: [
      ResourceField('name', 'اسم الطالب'),
      ResourceField('email', 'البريد الإلكتروني'),
      ResourceField('student_number', 'رقم القيد'),
      ResourceField('password', 'كلمة المرور'),
      ResourceField(
        'major_id',
        'معرف التخصص',
        keyboardType: TextInputType.number,
      ),
      ResourceField(
        'level_id',
        'معرف المستوى',
        keyboardType: TextInputType.number,
      ),
      ResourceField('gender', 'الجنس'),
    ],
  ),
  StaffMenuItem(
    label: 'الدكاترة',
    route: '/administrative/doctors',
    endpoint: '/administrative/doctors',
    icon: Icons.school_rounded,
    workspace: _admin,
    createEndpoint: '/administrative/doctors',
    formFields: [
      ResourceField('name', 'اسم الدكتور'),
      ResourceField('email', 'البريد الإلكتروني'),
      ResourceField('password', 'كلمة المرور'),
      ResourceField(
        'major_id',
        'معرف التخصص',
        keyboardType: TextInputType.number,
        required: false,
      ),
      ResourceField(
        'administrative_access',
        'صلاحية مسؤول إداري',
        required: false,
      ),
    ],
  ),
  StaffMenuItem(
    label: 'المندوبون',
    route: '/administrative/delegates',
    endpoint: '/administrative/delegates',
    icon: Icons.admin_panel_settings_rounded,
    workspace: _admin,
  ),
  StaffMenuItem(
    label: 'التخصصات',
    route: '/administrative/majors',
    endpoint: '/administrative/majors',
    icon: Icons.account_tree_rounded,
    workspace: _admin,
    createEndpoint: '/administrative/majors',
    formFields: [
      ResourceField('name', 'اسم التخصص'),
      ResourceField(
        'levels_count',
        'عدد المستويات',
        keyboardType: TextInputType.number,
      ),
    ],
  ),
  StaffMenuItem(
    label: 'المواد',
    route: '/administrative/subjects',
    endpoint: '/administrative/subjects',
    icon: Icons.menu_book_rounded,
    workspace: _admin,
    createEndpoint: '/administrative/subjects',
    formFields: [
      ResourceField('name', 'اسم المادة'),
      ResourceField('code', 'رمز المادة', required: false),
      ResourceField(
        'major_id',
        'معرف التخصص',
        keyboardType: TextInputType.number,
      ),
      ResourceField(
        'level_id',
        'معرف المستوى',
        keyboardType: TextInputType.number,
      ),
      ResourceField(
        'doctor_id',
        'معرف الدكتور',
        keyboardType: TextInputType.number,
        required: false,
      ),
    ],
  ),
  StaffMenuItem(
    label: 'جداول الاختبارات',
    route: '/administrative/exams',
    endpoint: '/administrative/exams',
    icon: Icons.event_note_rounded,
    workspace: _admin,
  ),
  StaffMenuItem(
    label: 'الجداول الدراسية',
    route: '/administrative/schedules',
    endpoint: '/administrative/schedules',
    icon: Icons.calendar_month_rounded,
    workspace: _admin,
  ),
  StaffMenuItem(
    label: 'إشعارات الكلية',
    route: '/administrative/notifications',
    endpoint: '/administrative/notifications',
    icon: Icons.notifications_active_rounded,
    workspace: _admin,
    createEndpoint: '/administrative/notifications',
    formFields: [
      ResourceField('title', 'عنوان الإشعار'),
      ResourceField('message', 'نص الإشعار', multiline: true),
      ResourceField('target_type', 'الفئة المستهدفة'),
    ],
  ),
  StaffMenuItem(
    label: 'الأعذار',
    route: '/administrative/excuses',
    endpoint: '/administrative/excuses',
    icon: Icons.verified_rounded,
    workspace: _admin,
  ),
  StaffMenuItem(
    label: 'التقارير',
    route: '/administrative/reports',
    endpoint: '/administrative/reports',
    icon: Icons.analytics_rounded,
    workspace: _admin,
  ),
  StaffMenuItem(
    label: 'الاشتراك',
    route: '/administrative/subscription',
    endpoint: '/administrative/subscription',
    icon: Icons.workspace_premium_rounded,
    workspace: _admin,
  ),
  StaffMenuItem(
    label: 'كشف الحساب',
    route: '/administrative/ledger',
    endpoint: '/administrative/ledger',
    exportEndpoint: '/administrative/ledger/export',
    icon: Icons.receipt_long_rounded,
    workspace: _admin,
  ),
];

class StaffDashboardScreen extends ConsumerWidget {
  const StaffDashboardScreen({super.key});

  static const route = '/staff/dashboard';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    final endpoint = session?.workspace == StaffWorkspace.administrative
        ? '/administrative/dashboard'
        : '/doctor/dashboard';
    final state = ref.watch(_dashboardProvider(endpoint));

    return StaffShell(
      title: 'لوحة التحكم',
      currentRoute: route,
      child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(_dashboardProvider(endpoint)),
        child: state.when(
          loading: () => const _LoadingList(),
          error: (error, _) => _ErrorView(error: error),
          data: (data) => _DashboardView(data: data),
        ),
      ),
    );
  }
}

final _dashboardProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, path) {
      ref.watch(staffRefreshCoordinatorProvider.select((state) => state.version));
      return ref.watch(staffRepositoryProvider).get(path);
    });

class StaffProfileScreen extends ConsumerWidget {
  const StaffProfileScreen({super.key});

  static const route = '/staff/profile';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    return StaffShell(
      title: 'ملفي الشخصي',
      currentRoute: route,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        children: [
          _HeaderCard(
            icon: Icons.person_rounded,
            title: session?.name ?? '-',
            subtitle: session?.email ?? '-',
          ),
          const SizedBox(height: 16),
          _InfoTile(label: 'الدور', value: session?.role ?? '-'),
          _InfoTile(label: 'الجامعة', value: session?.university ?? '-'),
          _InfoTile(label: 'الكلية', value: session?.college ?? '-'),
          _InfoTile(label: 'التخصص', value: session?.major ?? '-'),
        ],
      ),
    );
  }
}

class StaffResourceScreen extends ConsumerWidget {
  const StaffResourceScreen({super.key, required this.item});

  final StaffMenuItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_resourceProvider(item));
    return StaffShell(
      title: item.label,
      currentRoute: item.route,
      floatingActionButton: item.canCreate
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateForm(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة'),
            )
          : null,
      child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(_resourceProvider(item)),
        child: state.when(
          loading: () => const _LoadingList(),
          error: (error, _) => _ErrorView(error: error),
          data: (data) => _ResourceView(item: item, response: data),
        ),
      ),
    );
  }

  Future<void> _showCreateForm(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => _ResourceForm(
        title: 'إضافة ${item.label}',
        fields: item.formFields,
        onSubmit: (data) async {
          await ref
              .read(staffRepositoryProvider)
              .post(item.createEndpoint!, data);
          ref.invalidate(_resourceProvider(item));
        },
      ),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final content = _payload(data);
    final flattened = _flatten(content);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      children: [
        const _HeaderCard(
          icon: Icons.dashboard_rounded,
          title: 'نظرة عامة',
          subtitle: 'ملخص مباشر من لوحة الويب وواجهات الـ API.',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: flattened.entries.take(12).map((entry) {
            return _StatCard(label: entry.key, value: entry.value);
          }).toList(),
        ),
      ],
    );
  }
}

class _ResourceView extends StatelessWidget {
  const _ResourceView({required this.item, required this.response});

  final StaffMenuItem item;
  final Map<String, dynamic> response;

  @override
  Widget build(BuildContext context) {
    final payload = _payload(response);
    final list = _extractList(payload);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 90),
      children: [
        _HeaderCard(
          icon: item.icon,
          title: item.label,
          subtitle:
              item.description ?? 'تم ربط هذه الشاشة بواجهة ${item.endpoint}.',
          trailing: item.canExport
              ? IconButton.filledTonal(
                  onPressed: () => _downloadExport(context, item),
                  icon: const Icon(Icons.download_rounded),
                  tooltip: 'تحميل',
                )
              : null,
        ),
        const SizedBox(height: 16),
        if (list.isNotEmpty)
          ...list.map((row) => _RecordCard(record: row))
        else
          _JsonCard(data: payload),
      ],
    );
  }

  Future<void> _downloadExport(BuildContext context, StaffMenuItem item) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    try {
      messenger.showSnackBar(
        const SnackBar(content: Text('جاري تحميل الملف...')),
      );
      final bytes = await container
          .read(staffRepositoryProvider)
          .download(item.exportEndpoint!);
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/${item.label}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(bytes, flush: true);
      await OpenFilex.open(file.path);
    } on ApiException catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }
}

class _ResourceForm extends StatefulWidget {
  const _ResourceForm({
    required this.title,
    required this.fields,
    required this.onSubmit,
  });

  final String title;
  final List<ResourceField> fields;
  final Future<void> Function(Map<String, dynamic> data) onSubmit;

  @override
  State<_ResourceForm> createState() => _ResourceFormState();
}

class _ResourceFormState extends State<_ResourceForm> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
  final Map<String, PlatformFile> _files = {};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final field in widget.fields)
        if (!field.file) field.key: TextEditingController(),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 18),
                ...widget.fields.map(_fieldWidget),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('حفظ'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldWidget(ResourceField field) {
    if (field.file) {
      final file = _files[field.key];
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: OutlinedButton.icon(
          onPressed: () async {
            final result = await FilePicker.platform.pickFiles();
            if (result?.files.single != null) {
              setState(() => _files[field.key] = result!.files.single);
            }
          },
          icon: const Icon(Icons.attach_file_rounded),
          label: Text(file?.name ?? field.label),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _controllers[field.key],
        keyboardType: field.keyboardType,
        minLines: field.multiline ? 3 : 1,
        maxLines: field.multiline ? 6 : 1,
        validator: field.required
            ? (value) => value == null || value.trim().isEmpty
                  ? 'هذا الحقل مطلوب.'
                  : null
            : null,
        decoration: InputDecoration(labelText: field.label),
      ),
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _submitting = true);
    try {
      final data = <String, dynamic>{};
      for (final entry in _controllers.entries) {
        data[entry.key] = _coerce(entry.value.text.trim());
      }
      for (final entry in _files.entries) {
        data[entry.key] = entry.value.path;
      }
      await widget.onSubmit(data);
      if (mounted) Navigator.pop(context);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Object? _coerce(String value) {
    if (value.isEmpty) return null;
    if (value == 'true') return true;
    if (value == 'false') return false;
    return int.tryParse(value) ?? double.tryParse(value) ?? value;
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _humanize(label),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _display(value),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record});

  final Map<String, dynamic> record;

  @override
  Widget build(BuildContext context) {
    final title = _firstText(record, const [
      'title',
      'name',
      'subject_name',
      'student_name',
      'email',
      'question',
    ]);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          ...record.entries
              .where((entry) => _isScalar(entry.value))
              .take(6)
              .map(
                (entry) => _InfoTile(
                  label: _humanize(entry.key),
                  value: _display(entry.value),
                  compact: true,
                ),
              ),
        ],
      ),
    );
  }
}

class _JsonCard extends StatelessWidget {
  const _JsonCard({required this.data});

  final Object? data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: SelectableText(
        const JsonEncoder.withIndent('  ').convert(data),
        textDirection: TextDirection.ltr,
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    this.compact = false,
  });

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 4 : 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorView extends StatefulWidget {
  const _ErrorView({required this.error});

  final Object error;

  @override
  State<_ErrorView> createState() => _ErrorViewState();
}

class _ErrorViewState extends State<_ErrorView> {
  bool _dialogShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dialogShown && staffIsSubscriptionRequired(widget.error)) {
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showStaffSubscriptionRequiredDialog(context, widget.error);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionRequired = staffIsSubscriptionRequired(widget.error);
    final message = widget.error is ApiException
        ? (widget.error as ApiException).message
        : 'تعذر تحميل البيانات.';
    return StatusMessage(
      title: 'حدث خطأ',
      message: message,
      icon: subscriptionRequired
          ? Icons.lock_rounded
          : Icons.error_outline_rounded,
      action: subscriptionRequired
          ? FilledButton.icon(
              onPressed: () => context.go(staffSubscriptionRouteFor(context)),
              icon: const Icon(Icons.workspace_premium_rounded),
              label: const Text('الاشتراك الآن'),
            )
          : null,
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: AppColors.slate100),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.03),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

Object? _payload(Map<String, dynamic> response) => response['data'] ?? response;

List<Map<String, dynamic>> _extractList(Object? payload) {
  if (payload is List) {
    return payload
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
  if (payload is Map) {
    for (final key in const [
      'data',
      'items',
      'records',
      'subjects',
      'assignments',
      'notifications',
    ]) {
      final value = payload[key];
      if (value is List) {
        return value
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
  }
  return const [];
}

Map<String, Object?> _flatten(Object? value, [String prefix = '']) {
  final result = <String, Object?>{};
  if (value is Map) {
    for (final entry in value.entries) {
      final key = prefix.isEmpty
          ? entry.key.toString()
          : '$prefix.${entry.key}';
      if (_isScalar(entry.value)) {
        result[key] = entry.value;
      } else if (entry.value is Map) {
        result.addAll(_flatten(entry.value, key));
      }
    }
  }
  return result;
}

bool _isScalar(Object? value) =>
    value == null || value is String || value is num || value is bool;

String _display(Object? value) {
  if (value == null || value.toString().isEmpty) return '-';
  if (value is bool) return value ? 'نعم' : 'لا';
  return value.toString();
}

String _humanize(String key) {
  const labels = {
    'id': 'المعرف',
    'name': 'الاسم',
    'title': 'العنوان',
    'email': 'البريد',
    'status': 'الحالة',
    'created_at': 'تاريخ الإنشاء',
    'updated_at': 'آخر تحديث',
    'total': 'الإجمالي',
    'count': 'العدد',
    'balance': 'الرصيد',
  };
  return labels[key] ?? key.replaceAll('_', ' ');
}

String _firstText(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }
  }
  return 'سجل #${map['id'] ?? '-'}';
}
