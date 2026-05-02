import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/moeen_dialogs.dart';
import '../../auth/logic/auth_controller.dart';
import '../../student/data/models/financial_ledger.dart';
import '../../student/data/models/subscription_models.dart';
import '../data/delegate_repositories.dart';
import '../logic/delegate_controllers.dart';
import 'widgets/delegate_shell.dart';

final _delegateNewsProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) => ref.watch(delegateRepositoryProvider).news(),
);
final _delegateNotificationsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>(
      (ref) => ref.watch(delegateRepositoryProvider).notifications(),
    );
final _delegateStudentsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>(
      (ref, page) => ref.watch(delegateRepositoryProvider).students(page: page),
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
final _delegateResourcesProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>(
      (ref) => ref.watch(delegateRepositoryProvider).resources(),
    );
final _delegateRemindersProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>(
      (ref, filter) =>
          ref.watch(delegateRepositoryProvider).reminders(filter: filter),
    );
final _delegateAnnouncementsProvider =
    FutureProvider.autoDispose<List<dynamic>>(
      (ref) => ref.watch(delegateRepositoryProvider).announcements(),
    );
final _delegateAttendanceProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>(
      (ref) => ref.watch(delegateRepositoryProvider).attendance(),
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
final _delegateProfileProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>(
      (ref) => ref.watch(delegateRepositoryProvider).me(),
    );

class DelegateDashboardScreen extends ConsumerWidget {
  const DelegateDashboardScreen({super.key});
  static const route = DelegateRoutes.dashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(delegateDashboardProvider);
    final session = ref.watch(authControllerProvider).valueOrNull;

    return DelegateShell(
      currentIndex: 0,
      title: 'الرئيسية',
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(delegateDashboardProvider),
        builder: (data) {
          final stats = asMap(data['stats']);
          final subjects = asList(data['subjects']);
          final topAbsent = asList(data['top_absent_students']);
          final risk = asList(data['at_risk_students']);
          final latestAttendance = asList(data['latest_attendance']);
          final latestStudents = asList(data['latest_students']);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(delegateDashboardProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
              children: [
                _HeroPanel(
                  title: 'مرحبًا ${session?.name ?? 'بمندوب الدفعة'}',
                  subtitle:
                      'لوحة تشغيلية لإدارة الدفعة، الحضور، المواد، والتواصل الأكاديمي.',
                  icon: Icons.admin_panel_settings_rounded,
                  colors: const [
                    AppColors.royalBlueDark,
                    AppColors.royalBlue,
                    AppColors.teal,
                  ],
                ),
                const SizedBox(height: 18),
                _QuickQrCard(
                  onTap: () => context.go(DelegateRoutes.qrAttendance),
                ),
                const SizedBox(height: 22),
                _StatsGrid(
                  items: [
                    _StatItem(
                      'المواد',
                      value(stats, 'total_subjects'),
                      Icons.auto_stories_rounded,
                      AppColors.royalBlue,
                    ),
                    _StatItem(
                      'الطلاب',
                      value(stats, 'total_students'),
                      Icons.groups_rounded,
                      AppColors.teal,
                    ),
                    _StatItem(
                      'تكاليف نشطة',
                      value(stats, 'active_assignments'),
                      Icons.assignment_rounded,
                      AppColors.orange,
                    ),
                    _StatItem(
                      'اختبارات قادمة',
                      value(stats, 'upcoming_exams'),
                      Icons.fact_check_rounded,
                      AppColors.danger,
                    ),
                    _StatItem(
                      'محاضرات اليوم',
                      value(stats, 'today_lectures'),
                      Icons.today_rounded,
                      AppColors.info,
                    ),
                    _StatItem(
                      'تنبيهات غياب',
                      value(stats, 'absence_alerts'),
                      Icons.warning_rounded,
                      AppColors.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _SectionTitle('مسارات سريعة', Icons.bolt_rounded),
                const SizedBox(height: 12),
                _ActionGrid(
                  actions: [
                    _Action(
                      'الطلاب',
                      Icons.groups_rounded,
                      DelegateRoutes.students,
                      AppColors.teal,
                    ),
                    _Action(
                      'المواد',
                      Icons.auto_stories_rounded,
                      DelegateRoutes.subjects,
                      AppColors.royalBlue,
                    ),
                    _Action(
                      'الحضور',
                      Icons.how_to_reg_rounded,
                      DelegateRoutes.attendance,
                      AppColors.success,
                    ),
                    _Action(
                      'الدرجات',
                      Icons.grade_rounded,
                      DelegateRoutes.authorizedGrades,
                      AppColors.goldDeep,
                    ),
                    _Action(
                      'التواصل',
                      Icons.forum_rounded,
                      DelegateRoutes.messages,
                      AppColors.violet,
                    ),
                    _Action(
                      'إعلان دفعة',
                      Icons.campaign_rounded,
                      DelegateRoutes.announcements,
                      AppColors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _DashboardStrip(
                  title: 'مواد الدفعة',
                  icon: Icons.library_books_rounded,
                  items: subjects,
                  empty: 'لا توجد مواد مرتبطة بالدفعة.',
                ),
                _DashboardStrip(
                  title: 'الأكثر غيابًا',
                  icon: Icons.person_off_rounded,
                  items: topAbsent,
                  empty: 'لا توجد بيانات غياب حالية.',
                ),
                _DashboardStrip(
                  title: 'طلاب معرضون للخطر',
                  icon: Icons.report_rounded,
                  items: risk,
                  empty: 'لا توجد مؤشرات خطورة حالية.',
                ),
                _DashboardStrip(
                  title: 'آخر سجلات الحضور',
                  icon: Icons.timeline_rounded,
                  items: latestAttendance,
                  empty: 'لا توجد سجلات حضور حديثة.',
                ),
                _DashboardStrip(
                  title: 'آخر الطلاب',
                  icon: Icons.person_add_alt_rounded,
                  items: latestStudents,
                  empty: 'لا توجد بيانات طلاب حديثة.',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class DelegateSubscriptionScreen extends ConsumerStatefulWidget {
  const DelegateSubscriptionScreen({super.key});
  static const route = DelegateRoutes.subscription;

  @override
  ConsumerState<DelegateSubscriptionScreen> createState() =>
      _DelegateSubscriptionScreenState();
}

class _DelegateSubscriptionScreenState
    extends ConsumerState<DelegateSubscriptionScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(delegateSubscriptionProvider);
    return DelegateShell(
      currentIndex: 20,
      title: 'الاشتراك والرصيد',
      child: _AsyncBody<SubscriptionOverview>(
        state: state,
        onRetry: () => ref.invalidate(delegateSubscriptionProvider),
        builder: (data) => ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
          children: [
            _HeroPanel(
              title: '${data.userBalance.toStringAsFixed(0)} ريال',
              subtitle: data.isSubscribed
                  ? 'اشتراكك مفعل حتى ${data.subscribedUntil ?? '-'}'
                  : 'اشحن رصيدك واختر الباقة المناسبة.',
              icon: Icons.workspace_premium_rounded,
              colors: const [AppColors.goldDeep, AppColors.orange],
            ),
            const SizedBox(height: 18),
            _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('شحن الرصيد', style: _titleStyle),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'كود الكرت',
                      prefixIcon: Icon(Icons.confirmation_number_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _loading ? null : () => _redeem(),
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_card_rounded),
                    label: const Text('شحن الرصيد'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _SectionTitle('الباقات المتاحة', Icons.layers_rounded),
            const SizedBox(height: 12),
            ...data.packages.map(
              (package) => _PackageCard(
                package: package,
                subscribed: data.isSubscribed,
                onSubscribe: () => _subscribe(package.id),
              ),
            ),
            SwitchListTile(
              value: data.autoRenew,
              onChanged: (value) => _toggleAutoRenew(value),
              title: const Text(
                'التجديد التلقائي',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: const Text('تجديد الاشتراك تلقائيًا عند توفر الرصيد.'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _redeem() async {
    if (_codeController.text.trim().isEmpty) return;
    await _run(
      context,
      () => ref
          .read(delegateSubscriptionProvider.notifier)
          .redeem(_codeController.text.trim()),
      after: () {
        _codeController.clear();
        ref.invalidate(delegateSubscriptionProvider);
      },
    );
  }

  Future<void> _subscribe(int id) async {
    await _run(
      context,
      () => ref.read(delegateSubscriptionProvider.notifier).subscribe(id),
      after: () {
        ref.invalidate(delegateSubscriptionProvider);
      },
    );
  }

  Future<void> _toggleAutoRenew(bool value) async {
    await _run(
      context,
      () => ref
          .read(delegateSubscriptionProvider.notifier)
          .toggleAutoRenew(value),
      after: () {
        ref.invalidate(delegateSubscriptionProvider);
      },
    );
  }
}

class DelegateLedgerScreen extends ConsumerStatefulWidget {
  const DelegateLedgerScreen({super.key});
  static const route = DelegateRoutes.ledger;

  @override
  ConsumerState<DelegateLedgerScreen> createState() =>
      _DelegateLedgerScreenState();
}

class _DelegateLedgerScreenState extends ConsumerState<DelegateLedgerScreen> {
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(delegateLedgerProvider);
    return DelegateShell(
      currentIndex: 21,
      title: 'كشف الحساب',
      child: _AsyncBody<FinancialLedger>(
        state: state,
        onRetry: () => ref.invalidate(delegateLedgerProvider),
        builder: (ledger) => ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
          children: [
            _HeroPanel(
              title: '${ledger.balance.toStringAsFixed(0)} ريال',
              subtitle: 'رصيد حساب المندوب والحركات المالية.',
              icon: Icons.receipt_long_rounded,
              colors: const [AppColors.royalBlue, AppColors.violet],
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _exporting ? null : _export,
              icon: _exporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_rounded),
              label: const Text('تحميل كشف PDF'),
            ),
            const SizedBox(height: 16),
            ...ledger.transactions.map(
              (transaction) => _GlassCard(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor:
                        (transaction.amount >= 0
                                ? AppColors.success
                                : AppColors.danger)
                            .withValues(alpha: 0.12),
                    child: Icon(
                      transaction.amount >= 0
                          ? Icons.add_rounded
                          : Icons.remove_rounded,
                    ),
                  ),
                  title: Text(
                    transaction.description,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(transaction.createdAt),
                  trailing: Text(
                    transaction.amount.toStringAsFixed(0),
                    style: TextStyle(
                      color: transaction.amount >= 0
                          ? AppColors.success
                          : AppColors.danger,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final bytes = await ref.read(delegateLedgerProvider.notifier).exportPdf();
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'حفظ كشف الحساب',
        fileName: 'delegate_statement.pdf',
        bytes: Uint8List.fromList(bytes),
      );
      if (path != null && path.isNotEmpty) {
        await OpenFilex.open(path);
      }
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }
}

class DelegateProfileScreen extends ConsumerWidget {
  const DelegateProfileScreen({super.key});
  static const route = DelegateRoutes.profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_delegateProfileProvider);
    return DelegateShell(
      currentIndex: 22,
      title: 'صفحتي',
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_delegateProfileProvider),
        builder: (data) {
          final user = asMap(data['user'] ?? data);
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
            children: [
              _HeroPanel(
                title: text(user, 'name', fallback: 'مندوب الدفعة'),
                subtitle: text(
                  user,
                  'email',
                  fallback: 'بيانات الحساب والصلاحيات',
                ),
                icon: Icons.person_rounded,
                colors: const [AppColors.royalBlueDark, AppColors.royalBlue],
              ),
              const SizedBox(height: 18),
              _InfoTile(
                'الدور',
                text(user, 'role', fallback: 'delegate'),
                Icons.verified_user_rounded,
              ),
              _InfoTile(
                'رقم القيد',
                text(user, 'student_number', fallback: '-'),
                Icons.badge_rounded,
              ),
              _InfoTile(
                'الحالة',
                text(user, 'status', fallback: '-'),
                Icons.toggle_on_rounded,
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () => _changePassword(context, ref),
                icon: const Icon(Icons.lock_reset_rounded),
                label: const Text('تغيير كلمة المرور'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class DelegateNewsScreen extends ConsumerWidget {
  const DelegateNewsScreen({super.key});
  static const route = DelegateRoutes.news;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SimpleListScreen(
      title: 'أخبار الدفعة',
      index: 1,
      state: ref.watch(_delegateNewsProvider),
      onRetry: () => ref.invalidate(_delegateNewsProvider),
      icon: Icons.newspaper_rounded,
      colors: const [AppColors.orange, AppColors.goldDeep],
      extractor: (data) =>
          asList(asMap(data['data']).isNotEmpty ? data['data'] : data),
      itemBuilder: (item) => _NewsCard(item: item),
    );
  }
}

class DelegateNotificationsScreen extends ConsumerWidget {
  const DelegateNotificationsScreen({super.key});
  static const route = DelegateRoutes.notifications;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_delegateNotificationsProvider);
    return _SimpleListScreen(
      title: 'التنبيهات',
      index: 2,
      state: state,
      onRetry: () => ref.invalidate(_delegateNotificationsProvider),
      icon: Icons.notifications_active_rounded,
      colors: const [AppColors.royalBlue, AppColors.info],
      extractor: (data) => [
        ...asList(data['sent_warnings']),
        ...asList(data['notifications']),
      ],
      itemBuilder: (item) => _DataCard(
        title: text(
          item,
          'title',
          fallback: text(item, 'subject_name', fallback: 'تنبيه'),
        ),
        subtitle: text(item, 'message', fallback: text(item, 'student_name')),
        icon: Icons.notification_important_rounded,
        color: AppColors.warning,
      ),
    );
  }
}

class DelegateStudentsScreen extends ConsumerWidget {
  const DelegateStudentsScreen({super.key});
  static const route = DelegateRoutes.students;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_delegateStudentsProvider(1));
    return DelegateShell(
      currentIndex: 3,
      title: 'إدارة الطلاب',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _studentSheet(context, ref),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('طالب جديد'),
      ),
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_delegateStudentsProvider(1)),
        builder: (data) {
          final page = asMap(
            data['data'].runtimeType.toString().isNotEmpty ? data : data,
          );
          final items = asList(
            page['data'] ?? data['students'] ?? data['data'],
          );
          return _ListScaffold(
            title: '${items.length} طالب',
            subtitle: 'إدارة طلاب الدفعة وصلاحيات رفع المكتبة.',
            icon: Icons.groups_rounded,
            colors: const [AppColors.teal, AppColors.royalBlue],
            children: [
              for (final raw in items)
                _DataCard(
                  item: asMap(raw),
                  title: text(raw, 'name'),
                  subtitle:
                      'رقم القيد: ${text(raw, 'student_number', fallback: text(raw, 'university_id', fallback: '-'))}',
                  icon: Icons.person_rounded,
                  color: AppColors.teal,
                  actions: [
                    IconButton(
                      onPressed: () =>
                          _studentSheet(context, ref, item: asMap(raw)),
                      icon: const Icon(Icons.edit_rounded),
                    ),
                    IconButton(
                      onPressed: () =>
                          _studentPermissionSheet(context, ref, asMap(raw)),
                      icon: const Icon(Icons.security_rounded),
                    ),
                    IconButton(
                      onPressed: () => _delete(
                        context,
                        () => ref
                            .read(delegateRepositoryProvider)
                            .deleteStudent(number(raw, 'id').toInt()),
                        () => ref.invalidate(_delegateStudentsProvider(1)),
                      ),
                      icon: const Icon(
                        Icons.delete_rounded,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class DelegateSubjectsScreen extends ConsumerWidget {
  const DelegateSubjectsScreen({super.key});
  static const route = DelegateRoutes.subjects;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SimpleListScreen<List<dynamic>>(
      title: 'المواد',
      index: 4,
      state: ref.watch(_delegateSubjectsProvider),
      onRetry: () => ref.invalidate(_delegateSubjectsProvider),
      icon: Icons.auto_stories_rounded,
      colors: const [AppColors.royalBlue, AppColors.info],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _subjectSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('مادة جديدة'),
      ),
      extractor: (data) => data,
      itemBuilder: (item) {
        final subject = asMap(item);
        final doctor = asMap(subject['doctor']);
        final term = asMap(subject['term']);
        return _DataCard(
          title: text(subject, 'name'),
          subtitle:
              '${text(subject, 'code', fallback: '-')} | ${text(doctor, 'name', fallback: 'بدون دكتور')} | ${text(term, 'name', fallback: 'بدون ترم')}',
          icon: Icons.menu_book_rounded,
          color: AppColors.royalBlue,
          actions: [
            IconButton(
              onPressed: () => _subjectSheet(context, ref, item: subject),
              icon: const Icon(Icons.edit_rounded),
            ),
            IconButton(
              onPressed: () => _delete(
                context,
                () => ref
                    .read(delegateRepositoryProvider)
                    .deleteSubject(number(subject, 'id').toInt()),
                () => ref.invalidate(_delegateSubjectsProvider),
              ),
              icon: const Icon(Icons.delete_rounded, color: AppColors.danger),
            ),
          ],
        );
      },
    );
  }
}

class DelegateSchedulesScreen extends ConsumerWidget {
  const DelegateSchedulesScreen({super.key});
  static const route = DelegateRoutes.schedules;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SimpleListScreen<List<dynamic>>(
      title: 'الجدول الدراسي',
      index: 5,
      state: ref.watch(_delegateSchedulesProvider),
      onRetry: () => ref.invalidate(_delegateSchedulesProvider),
      icon: Icons.calendar_month_rounded,
      colors: const [AppColors.violet, AppColors.royalBlue],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _scheduleSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('محاضرة'),
      ),
      extractor: (data) => data,
      itemBuilder: (item) {
        final schedule = asMap(item);
        final subject = asMap(schedule['subject']);
        return _DataCard(
          title: text(subject, 'name', fallback: 'محاضرة'),
          subtitle:
              'اليوم ${text(schedule, 'day_of_week')} | ${text(schedule, 'start_time')} - ${text(schedule, 'end_time')} | ${text(schedule, 'hall_name', fallback: '-')}',
          icon: Icons.event_rounded,
          color: AppColors.violet,
          actions: [
            IconButton(
              onPressed: () => _scheduleSheet(context, ref, item: schedule),
              icon: const Icon(Icons.edit_rounded),
            ),
            IconButton(
              onPressed: () => _delete(
                context,
                () => ref
                    .read(delegateRepositoryProvider)
                    .deleteSchedule(number(schedule, 'id').toInt()),
                () => ref.invalidate(_delegateSchedulesProvider),
              ),
              icon: const Icon(Icons.delete_rounded, color: AppColors.danger),
            ),
          ],
        );
      },
    );
  }
}

class DelegateExamSchedulesScreen extends ConsumerWidget {
  const DelegateExamSchedulesScreen({super.key});
  static const route = DelegateRoutes.exams;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SimpleListScreen<List<dynamic>>(
      title: 'جداول الاختبارات',
      index: 6,
      state: ref.watch(_delegateExamsProvider),
      onRetry: () => ref.invalidate(_delegateExamsProvider),
      icon: Icons.fact_check_rounded,
      colors: const [AppColors.danger, AppColors.orange],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _examScheduleSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('جدول اختبار'),
      ),
      extractor: (data) => data,
      itemBuilder: (item) {
        final exam = asMap(item);
        final items = asList(exam['items']);
        return _DataCard(
          title: text(exam, 'title', fallback: 'جدول اختبارات'),
          subtitle:
              '${items.length} اختبار | ${text(exam, 'description', fallback: 'بدون وصف')}',
          icon: Icons.assignment_rounded,
          color: AppColors.danger,
          actions: [
            IconButton(
              onPressed: () => _examScheduleSheet(context, ref, item: exam),
              icon: const Icon(Icons.edit_rounded),
            ),
            IconButton(
              onPressed: () => _delete(
                context,
                () => ref
                    .read(delegateRepositoryProvider)
                    .deleteExamSchedule(number(exam, 'id').toInt()),
                () => ref.invalidate(_delegateExamsProvider),
              ),
              icon: const Icon(Icons.delete_rounded, color: AppColors.danger),
            ),
          ],
        );
      },
    );
  }
}

class DelegateAssignmentsScreen extends ConsumerWidget {
  const DelegateAssignmentsScreen({super.key});
  static const route = DelegateRoutes.assignments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SimpleListScreen<List<dynamic>>(
      title: 'التكاليف',
      index: 7,
      state: ref.watch(_delegateAssignmentsProvider),
      onRetry: () => ref.invalidate(_delegateAssignmentsProvider),
      icon: Icons.assignment_turned_in_rounded,
      colors: const [AppColors.orange, AppColors.goldDeep],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _assignmentSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('تكليف'),
      ),
      extractor: (data) => data,
      itemBuilder: (item) {
        final assignment = asMap(item);
        final subject = asMap(assignment['subject']);
        return _DataCard(
          title: text(assignment, 'title'),
          subtitle:
              '${text(subject, 'name', fallback: 'مادة')} | التسليم: ${text(assignment, 'due_date', fallback: '-')}',
          icon: Icons.task_alt_rounded,
          color: AppColors.orange,
          actions: [
            IconButton(
              onPressed: () => _assignmentSheet(context, ref, item: assignment),
              icon: const Icon(Icons.edit_rounded),
            ),
            IconButton(
              onPressed: () => _delete(
                context,
                () => ref
                    .read(delegateRepositoryProvider)
                    .deleteAssignment(number(assignment, 'id').toInt()),
                () => ref.invalidate(_delegateAssignmentsProvider),
              ),
              icon: const Icon(Icons.delete_rounded, color: AppColors.danger),
            ),
          ],
        );
      },
    );
  }
}

class DelegateResourcesScreen extends ConsumerWidget {
  const DelegateResourcesScreen({super.key});
  static const route = DelegateRoutes.resources;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SimpleListScreen<Map<String, dynamic>>(
      title: 'مصادر المقرر',
      index: 8,
      state: ref.watch(_delegateResourcesProvider),
      onRetry: () => ref.invalidate(_delegateResourcesProvider),
      icon: Icons.folder_special_rounded,
      colors: const [AppColors.royalBlue, AppColors.teal],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _resourceSheet(context, ref),
        icon: const Icon(Icons.upload_file_rounded),
        label: const Text('رفع ملف'),
      ),
      extractor: (data) => asList(data['resources']),
      itemBuilder: (item) {
        final resource = asMap(item);
        final subject = asMap(resource['subject']);
        return _DataCard(
          title: text(resource, 'title'),
          subtitle:
              '${text(subject, 'name', fallback: 'مادة')} | ${text(resource, 'category', fallback: '-')}',
          icon: Icons.insert_drive_file_rounded,
          color: AppColors.royalBlue,
          actions: [
            IconButton(
              onPressed: () => _delete(
                context,
                () => ref
                    .read(delegateRepositoryProvider)
                    .deleteResource(number(resource, 'id').toInt()),
                () => ref.invalidate(_delegateResourcesProvider),
              ),
              icon: const Icon(Icons.delete_rounded, color: AppColors.danger),
            ),
          ],
        );
      },
    );
  }
}

class DelegateLibraryImportScreen extends ConsumerStatefulWidget {
  const DelegateLibraryImportScreen({super.key});
  static const route = DelegateRoutes.libraryImport;

  @override
  ConsumerState<DelegateLibraryImportScreen> createState() =>
      _DelegateLibraryImportScreenState();
}

class _DelegateLibraryImportScreenState
    extends ConsumerState<DelegateLibraryImportScreen> {
  final _search = TextEditingController();
  AsyncValue<List<dynamic>>? _results;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return DelegateShell(
      currentIndex: 9,
      title: 'استيراد من المكتبة',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
        children: [
          const _HeroPanel(
            title: 'استيراد الموارد',
            subtitle: 'ابحث في مكتبة الدفعة واستورد الملف إلى مادة محددة.',
            icon: Icons.library_add_rounded,
            colors: [AppColors.teal, AppColors.royalBlue],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _search,
            decoration: InputDecoration(
              labelText: 'ابحث عن ملف',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward_rounded),
                onPressed: _searchLibrary,
              ),
            ),
            onSubmitted: (_) => _searchLibrary(),
          ),
          const SizedBox(height: 16),
          if (results == null)
            const _EmptyState('ابدأ البحث لعرض الملفات القابلة للاستيراد.')
          else
            _AsyncBody<List<dynamic>>(
              state: results,
              onRetry: _searchLibrary,
              builder: (items) => Column(
                children: [
                  for (final raw in items)
                    _DataCard(
                      title: text(raw, 'title'),
                      subtitle: text(
                        asMap(raw)['subject'],
                        'name',
                        fallback: 'مورد مكتبة',
                      ),
                      icon: Icons.library_books_rounded,
                      color: AppColors.teal,
                      actions: [
                        IconButton(
                          onPressed: () =>
                              _importResourceSheet(context, ref, asMap(raw)),
                          icon: const Icon(Icons.download_rounded),
                        ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _searchLibrary() async {
    setState(() {
      _results = const AsyncLoading();
    });
    final result = await AsyncValue.guard(
      () => ref
          .read(delegateRepositoryProvider)
          .searchLibrary(_search.text.trim()),
    );
    if (mounted) setState(() => _results = result);
  }
}

class DelegateRemindersScreen extends ConsumerWidget {
  const DelegateRemindersScreen({super.key});
  static const route = DelegateRoutes.reminders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SimpleListScreen<Map<String, dynamic>>(
      title: 'التذكيرات',
      index: 10,
      state: ref.watch(_delegateRemindersProvider('upcoming')),
      onRetry: () => ref.invalidate(_delegateRemindersProvider('upcoming')),
      icon: Icons.event_note_rounded,
      colors: const [AppColors.info, AppColors.royalBlue],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _reminderSheet(context, ref),
        icon: const Icon(Icons.add_alert_rounded),
        label: const Text('تذكير'),
      ),
      extractor: (data) => asList(data['reminders']),
      itemBuilder: (item) => _DataCard(
        title: text(item, 'title'),
        subtitle:
            '${text(item, 'event_date', fallback: '-')} | ${text(item, 'description', fallback: '')}',
        icon: Icons.notifications_rounded,
        color: AppColors.info,
        actions: [
          IconButton(
            onPressed: () => _reminderSheet(context, ref, item: asMap(item)),
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            onPressed: () => _delete(
              context,
              () => ref
                  .read(delegateRepositoryProvider)
                  .deleteReminder(number(item, 'id').toInt()),
              () => ref.invalidate(_delegateRemindersProvider('upcoming')),
            ),
            icon: const Icon(Icons.delete_rounded, color: AppColors.danger),
          ),
        ],
      ),
    );
  }
}

class DelegateAnnouncementsScreen extends ConsumerWidget {
  const DelegateAnnouncementsScreen({super.key});
  static const route = DelegateRoutes.announcements;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SimpleListScreen<List<dynamic>>(
      title: 'إعلانات الدفعة',
      index: 11,
      state: ref.watch(_delegateAnnouncementsProvider),
      onRetry: () => ref.invalidate(_delegateAnnouncementsProvider),
      icon: Icons.campaign_rounded,
      colors: const [AppColors.orange, AppColors.rose],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _announcementSheet(context, ref),
        icon: const Icon(Icons.campaign_rounded),
        label: const Text('نشر'),
      ),
      extractor: (data) => data,
      itemBuilder: (item) => _DataCard(
        title: text(item, 'title'),
        subtitle: text(
          item,
          'content',
          fallback: text(item, 'category', fallback: 'إعلان'),
        ),
        icon: Icons.campaign_rounded,
        color: AppColors.orange,
        actions: [
          IconButton(
            onPressed: () =>
                _announcementSheet(context, ref, item: asMap(item)),
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            onPressed: () => _delete(
              context,
              () => ref
                  .read(delegateRepositoryProvider)
                  .deleteAnnouncement(number(item, 'id').toInt()),
              () => ref.invalidate(_delegateAnnouncementsProvider),
            ),
            icon: const Icon(Icons.delete_rounded, color: AppColors.danger),
          ),
        ],
      ),
    );
  }
}

class DelegateAttendanceScreen extends ConsumerWidget {
  const DelegateAttendanceScreen({super.key});
  static const route = DelegateRoutes.attendance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SimpleListScreen<Map<String, dynamic>>(
      title: 'رصد الحضور',
      index: 12,
      state: ref.watch(_delegateAttendanceProvider),
      onRetry: () => ref.invalidate(_delegateAttendanceProvider),
      icon: Icons.how_to_reg_rounded,
      colors: const [AppColors.success, AppColors.teal],
      extractor: (data) => asList(data['subjects']),
      itemBuilder: (item) {
        final subject = asMap(item);
        final allowed = subject['allow_delegate_attendance'] == true;
        return _DataCard(
          title: text(subject, 'name'),
          subtitle: allowed ? 'متاح للمندوب رصد الحضور' : 'مغلق من الدكتور',
          icon: allowed ? Icons.check_circle_rounded : Icons.lock_rounded,
          color: allowed ? AppColors.success : AppColors.slate400,
          actions: [
            if (allowed)
              IconButton(
                onPressed: () => _attendanceSheet(context, ref, subject),
                icon: const Icon(Icons.edit_calendar_rounded),
              ),
          ],
        );
      },
    );
  }
}

class DelegateQrAttendanceScreen extends ConsumerStatefulWidget {
  const DelegateQrAttendanceScreen({super.key});
  static const route = DelegateRoutes.qrAttendance;

  @override
  ConsumerState<DelegateQrAttendanceScreen> createState() =>
      _DelegateQrAttendanceScreenState();
}

class _DelegateQrAttendanceScreenState
    extends ConsumerState<DelegateQrAttendanceScreen> {
  Map<String, dynamic>? _session;
  Map<String, dynamic>? _status;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DelegateShell(
      currentIndex: 13,
      title: 'QR حضور',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
        children: [
          const _HeroPanel(
            title: 'جلسة QR حضور',
            subtitle: 'ابدأ جلسة تصوير للدفعة وتابع المسح مباشرة.',
            icon: Icons.qr_code_2_rounded,
            colors: [AppColors.teal, AppColors.royalBlue],
          ),
          const SizedBox(height: 16),
          if (_session == null)
            ElevatedButton.icon(
              onPressed: () => _startQrSession(
                context,
                ref,
                onStarted: (session) {
                  setState(() => _session = session);
                  unawaited(_startPolling());
                },
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('بدء جلسة QR'),
            )
          else ...[
            _GlassCard(
              child: Column(
                children: [
                  const Text('رمز الجلسة الحالي', style: _titleStyle),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: AppColors.royalBlue.withValues(alpha: 0.12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.royalBlue.withValues(alpha: 0.12),
                          blurRadius: 22,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: text(
                        _session!,
                        'current_token',
                        fallback: text(_status, 'token', fallback: ''),
                      ),
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SelectableText(
                    text(
                      _session!,
                      'current_token',
                      fallback: text(_status, 'token', fallback: ''),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'المصوّرون: ${value(_status, 'scanned_count')} / ${value(_status, 'total_students')}',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _refreshQr,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('تحديث'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _finalizeQr,
                        icon: const Icon(Icons.stop_circle_rounded),
                        label: const Text('إنهاء'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionTitle('آخر حالة', Icons.people_rounded),
            ...asList(_status?['students'])
                .take(30)
                .map(
                  (raw) => _DataCard(
                    title: text(
                      raw,
                      'name',
                      fallback: text(raw, 'student_name'),
                    ),
                    subtitle: text(
                      raw,
                      'status',
                      fallback: text(raw, 'scan_status', fallback: '-'),
                    ),
                    icon: Icons.person_rounded,
                    color: AppColors.teal,
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Future<void> _refreshQr() async {
    final id = number(_session, 'id').toInt();
    if (id <= 0) return;
    final status = await ref.read(delegateRepositoryProvider).qrStatus(id);
    if (mounted) setState(() => _status = status);
  }

  Future<void> _finalizeQr() async {
    final id = number(_session, 'id').toInt();
    if (id <= 0) return;
    await _run(
      context,
      () => ref.read(delegateRepositoryProvider).finalizeQr(id),
      after: () {
        _timer?.cancel();
        setState(() {
          _session = null;
          _status = null;
        });
      },
    );
  }

  Future<void> _startPolling() async {
    _timer?.cancel();
    await _refreshQr();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _refreshQr());
  }
}

class DelegateAbsenceAlertsScreen extends ConsumerWidget {
  const DelegateAbsenceAlertsScreen({super.key});
  static const route = DelegateRoutes.absenceAlerts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SimpleListScreen<Map<String, dynamic>>(
      title: 'إنذارات الغياب',
      index: 14,
      state: ref.watch(_delegateAbsenceAlertsProvider),
      onRetry: () => ref.invalidate(_delegateAbsenceAlertsProvider),
      icon: Icons.warning_rounded,
      colors: const [AppColors.warning, AppColors.danger],
      extractor: (data) => [
        ...asList(data['absent_today']),
        ...asList(data['at_risk_students']),
      ],
      itemBuilder: (item) {
        final student = asMap(item['student']);
        final subject = asMap(item['subject']);
        return _DataCard(
          title: text(
            student,
            'name',
            fallback: text(item, 'student_name', fallback: 'طالب'),
          ),
          subtitle:
              '${text(subject, 'name', fallback: text(item, 'subject_name', fallback: 'مادة'))} | نسبة/عدد الغياب: ${value(item, 'absence_rate', fallback: value(item, 'absence_count'))}',
          icon: Icons.person_off_rounded,
          color: AppColors.warning,
        );
      },
    );
  }
}

class DelegateAuthorizedGradesScreen extends ConsumerWidget {
  const DelegateAuthorizedGradesScreen({super.key});
  static const route = DelegateRoutes.authorizedGrades;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SimpleListScreen<Map<String, dynamic>>(
      title: 'الدرجات المفوضة',
      index: 15,
      state: ref.watch(_delegateAuthorizedGradesProvider),
      onRetry: () => ref.invalidate(_delegateAuthorizedGradesProvider),
      icon: Icons.grade_rounded,
      colors: const [AppColors.goldDeep, AppColors.orange],
      extractor: (data) => [
        ...asList(data['direct_delegations']),
        ...asList(data['helper_tasks']).map((task) => asMap(task)['category']),
      ],
      itemBuilder: (item) {
        final category = asMap(item);
        final subject = asMap(category['subject']);
        return _DataCard(
          title: text(
            category,
            'name',
            fallback: text(category, 'title', fallback: 'تفويض درجات'),
          ),
          subtitle:
              '${text(subject, 'name', fallback: 'مادة')} | الدرجة: ${value(category, 'max_score')}',
          icon: Icons.grade_rounded,
          color: AppColors.goldDeep,
          actions: [
            IconButton(
              onPressed: () => _gradesEntrySheet(
                context,
                ref,
                number(category, 'id').toInt(),
              ),
              icon: const Icon(Icons.edit_note_rounded),
            ),
          ],
        );
      },
    );
  }
}

class DelegateGradeHelperDelegationsScreen extends ConsumerWidget {
  const DelegateGradeHelperDelegationsScreen({super.key});
  static const route = DelegateRoutes.gradeDelegations;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SimpleListScreen<Map<String, dynamic>>(
      title: 'تفويض مساعدي الرصد',
      index: 16,
      state: ref.watch(_delegateHelperTasksProvider),
      onRetry: () => ref.invalidate(_delegateHelperTasksProvider),
      icon: Icons.manage_accounts_rounded,
      colors: const [AppColors.violet, AppColors.royalBlue],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _helperDelegationSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('تفويض'),
      ),
      extractor: (data) => asList(data['tasks']),
      itemBuilder: (item) => _DataCard(
        title: text(item, 'title', fallback: 'تفويض مساعد'),
        subtitle:
            '${text(asMap(item)['helper_user'], 'name', fallback: '-')} | ${text(item, 'delegation_type', fallback: '-')}',
        icon: Icons.manage_accounts_rounded,
        color: AppColors.violet,
        actions: [
          IconButton(
            onPressed: () => _delete(
              context,
              () => ref
                  .read(delegateRepositoryProvider)
                  .revokeHelperDelegation(number(item, 'id').toInt()),
              () => ref.invalidate(_delegateHelperTasksProvider),
            ),
            icon: const Icon(Icons.cancel_rounded, color: AppColors.danger),
          ),
        ],
      ),
    );
  }
}

class DelegateMessagesScreen extends ConsumerWidget {
  const DelegateMessagesScreen({super.key});
  static const route = DelegateRoutes.messages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ChatListScreen(
      title: 'رسائل الطلاب',
      index: 17,
      state: ref.watch(_delegateMessagesProvider),
      onRetry: () => ref.invalidate(_delegateMessagesProvider),
      extractor: (data) => asList(data['conversations'] ?? data['data']),
      eligibleLoader: () =>
          ref.read(delegateRepositoryProvider).eligibleStudents(),
      openPath: (id) => '/delegate/messages/$id',
      startMessage: ({required int recipientId, required String content}) => ref
          .read(delegateRepositoryProvider)
          .sendStudentMessage(studentId: recipientId, content: content),
    );
  }
}

class DelegateConversationScreen extends ConsumerStatefulWidget {
  const DelegateConversationScreen({super.key, required this.conversationId});
  final int conversationId;

  @override
  ConsumerState<DelegateConversationScreen> createState() =>
      _DelegateConversationScreenState();
}

class _DelegateConversationScreenState
    extends ConsumerState<DelegateConversationScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref
        .read(delegateRepositoryProvider)
        .conversation(widget.conversationId);
  }

  @override
  Widget build(BuildContext context) {
    return _ConversationView(
      title: 'محادثة طالب',
      future: _future,
      reload: () => setState(
        () => _future = ref
            .read(delegateRepositoryProvider)
            .conversation(widget.conversationId),
      ),
      send: (body) => ref
          .read(delegateRepositoryProvider)
          .sendStudentMessage(
            conversationId: widget.conversationId,
            content: body,
          ),
    );
  }
}

class DelegateDoctorChatsScreen extends ConsumerWidget {
  const DelegateDoctorChatsScreen({super.key});
  static const route = DelegateRoutes.doctorChats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ChatListScreen(
      title: 'محادثات الدكاترة',
      index: 18,
      state: ref.watch(_delegateDoctorChatsProvider),
      onRetry: () => ref.invalidate(_delegateDoctorChatsProvider),
      extractor: (data) => asList(data['conversations'] ?? data['data']),
      eligibleLoader: () =>
          ref.read(delegateRepositoryProvider).eligibleDoctors(),
      openPath: (id) => '/delegate/doctor-chats/$id',
      startMessage: ({required int recipientId, required String content}) => ref
          .read(delegateRepositoryProvider)
          .sendDoctorMessage(doctorId: recipientId, content: content),
    );
  }
}

class DelegateDoctorConversationScreen extends ConsumerStatefulWidget {
  const DelegateDoctorConversationScreen({
    super.key,
    required this.conversationId,
  });
  final int conversationId;

  @override
  ConsumerState<DelegateDoctorConversationScreen> createState() =>
      _DelegateDoctorConversationScreenState();
}

class _DelegateDoctorConversationScreenState
    extends ConsumerState<DelegateDoctorConversationScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref
        .read(delegateRepositoryProvider)
        .doctorChat(widget.conversationId);
  }

  @override
  Widget build(BuildContext context) {
    return _ConversationView(
      title: 'محادثة دكتور',
      future: _future,
      reload: () => setState(
        () => _future = ref
            .read(delegateRepositoryProvider)
            .doctorChat(widget.conversationId),
      ),
      send: (body) => ref
          .read(delegateRepositoryProvider)
          .sendDoctorMessage(
            conversationId: widget.conversationId,
            content: body,
          ),
    );
  }
}

class DelegateInquiriesScreen extends ConsumerStatefulWidget {
  const DelegateInquiriesScreen({super.key});
  static const route = DelegateRoutes.inquiries;

  @override
  ConsumerState<DelegateInquiriesScreen> createState() =>
      _DelegateInquiriesScreenState();
}

class _DelegateInquiriesScreenState
    extends ConsumerState<DelegateInquiriesScreen> {
  String _status = 'all';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_delegateInquiriesProvider(_status));
    return DelegateShell(
      currentIndex: 19,
      title: 'استفسارات الدكتور',
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_delegateInquiriesProvider(_status)),
        builder: (data) {
          final items = asList(data['inquiries']);
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
            children: [
              const _HeroPanel(
                title: 'استفسارات الطلاب',
                subtitle: 'راجع الاستفسارات، أجب مباشرة أو حوّلها إلى الدكتور.',
                icon: Icons.contact_support_rounded,
                colors: [AppColors.violet, AppColors.royalBlue],
              ),
              const SizedBox(height: 14),
              _FilterChips(
                value: _status,
                options: const {
                  'all': 'الكل',
                  'pending': 'معلقة',
                  'forwarded': 'محولة',
                  'answered': 'مجاب',
                  'closed': 'مغلقة',
                },
                onChanged: (value) => setState(() => _status = value),
              ),
              const SizedBox(height: 14),
              if (items.isEmpty)
                const _EmptyState('لا توجد استفسارات بهذه الحالة.'),
              for (final raw in items)
                _DataCard(
                  title: text(
                    raw,
                    'title',
                    fallback: text(raw, 'question', fallback: 'استفسار'),
                  ),
                  subtitle:
                      '${text(asMap(raw)['student'], 'name', fallback: 'طالب')} | ${text(raw, 'status', fallback: '-')}',
                  icon: Icons.question_answer_rounded,
                  color: AppColors.violet,
                  actions: [
                    if (text(raw, 'status') == 'pending')
                      IconButton(
                        onPressed: () =>
                            _replyInquirySheet(context, ref, asMap(raw)),
                        icon: const Icon(Icons.reply_rounded),
                      ),
                    if (text(raw, 'status') == 'pending')
                      IconButton(
                        onPressed: () => _run(
                          context,
                          () => ref
                              .read(delegateRepositoryProvider)
                              .forwardInquiry(number(raw, 'id').toInt()),
                          after: () => ref.invalidate(
                            _delegateInquiriesProvider(_status),
                          ),
                        ),
                        icon: const Icon(Icons.forward_rounded),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared UI

class _SimpleListScreen<T> extends StatelessWidget {
  const _SimpleListScreen({
    required this.title,
    required this.index,
    required this.state,
    required this.onRetry,
    required this.icon,
    required this.colors,
    required this.extractor,
    required this.itemBuilder,
    this.floatingActionButton,
  });

  final String title;
  final int index;
  final AsyncValue<T> state;
  final VoidCallback onRetry;
  final IconData icon;
  final List<Color> colors;
  final List<dynamic> Function(T data) extractor;
  final Widget Function(dynamic item) itemBuilder;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return DelegateShell(
      currentIndex: index,
      title: title,
      floatingActionButton: floatingActionButton,
      child: _AsyncBody<T>(
        state: state,
        onRetry: onRetry,
        builder: (data) {
          final items = extractor(data);
          return RefreshIndicator(
            onRefresh: () async => onRetry(),
            child: _ListScaffold(
              title: '$title (${items.length})',
              subtitle: 'إدارة وعرض بيانات $title بتنسيق واضح وسريع.',
              icon: icon,
              colors: colors,
              children: [
                if (items.isEmpty) const _EmptyState('لا توجد بيانات حالية.'),
                for (final item in items) itemBuilder(item),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ListScaffold extends StatelessWidget {
  const _ListScaffold({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.children,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
      children: [
        _HeroPanel(
          title: title,
          subtitle: subtitle,
          icon: icon,
          colors: colors,
        ),
        const SizedBox(height: 18),
        ...children,
      ],
    );
  }
}

class _AsyncBody<T> extends StatelessWidget {
  const _AsyncBody({
    required this.state,
    required this.builder,
    required this.onRetry,
  });
  final AsyncValue<T> state;
  final Widget Function(T data) builder;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          _ErrorState(message: error.toString(), onRetry: onRetry),
      data: builder,
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.84),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child, this.margin});
  final Widget child;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DataCard extends StatelessWidget {
  const _DataCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.item,
    this.actions = const [],
  });

  final Map<String, dynamic>? item;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? 'بدون عنوان' : title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: AppColors.midnight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate600,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          if (actions.isNotEmpty) Wrap(spacing: 2, children: actions),
        ],
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.item});
  final Object? item;

  @override
  Widget build(BuildContext context) {
    final map = asMap(item);
    final sender = asMap(map['sender']);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 6, color: _typeColor(text(map, 'type'))),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.campaign_rounded,
                      color: _typeColor(text(map, 'type')),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        text(map, 'title', fallback: 'خبر جديد'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  text(map, 'message', fallback: text(map, 'content')),
                  style: const TextStyle(
                    height: 1.6,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'المصدر: ${text(sender, 'name', fallback: 'الإدارة')} | ${timeText(map)}',
                  style: const TextStyle(
                    color: AppColors.slate500,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickQrCard extends StatelessWidget {
  const _QuickQrCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.teal, Color(0xFF14B8A6)],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.teal.withValues(alpha: 0.18),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.qr_code_2_rounded,
                  color: AppColors.teal,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'بدء تحضير QR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'افتح جلسة حضور وتابع الطلاب مباشرة.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.items});
  final List<_StatItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.22,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _GlassCard(
          child: Stack(
            children: [
              PositionedDirectional(
                end: -6,
                top: -8,
                child: Icon(
                  item.icon,
                  size: 58,
                  color: item.color.withValues(alpha: 0.06),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(item.icon, color: item.color),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.value,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.midnight,
                        ),
                      ),
                      Text(
                        item.label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.actions});
  final List<_Action> actions;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: actions.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.92,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        return InkWell(
          onTap: () => context.go(action.route),
          borderRadius: BorderRadius.circular(24),
          child: _GlassCard(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(action.icon, color: action.color, size: 28),
                const SizedBox(height: 10),
                Text(
                  action.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DashboardStrip extends StatelessWidget {
  const _DashboardStrip({
    required this.title,
    required this.icon,
    required this.items,
    required this.empty,
  });
  final String title;
  final IconData icon;
  final List<dynamic> items;
  final String empty;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title, icon),
          const SizedBox(height: 12),
          if (items.isEmpty)
            _EmptyState(empty)
          else
            ...items.take(5).map((raw) {
              final item = asMap(raw);
              final subject = asMap(item['subject']);
              final student = asMap(item['student']);
              return _DataCard(
                title: text(
                  item,
                  'name',
                  fallback: text(
                    student,
                    'name',
                    fallback: text(
                      subject,
                      'name',
                      fallback: text(item, 'title', fallback: title),
                    ),
                  ),
                ),
                subtitle: text(
                  item,
                  'message',
                  fallback:
                      'العدد/النسبة: ${value(item, 'absence_count', fallback: value(item, 'absence_rate', fallback: value(item, 'total_records')))}',
                ),
                icon: icon,
                color: AppColors.royalBlue,
              );
            }),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, this.icon);
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.royalBlue, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.midnight,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => _GlassCard(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.slate500,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Interaction sheets

Future<void> _studentSheet(
  BuildContext context,
  WidgetRef ref, {
  Map<String, dynamic>? item,
}) async {
  final name = TextEditingController(text: text(item, 'name'));
  final email = TextEditingController(text: text(item, 'email'));
  final numberController = TextEditingController(
    text: text(item, 'student_number'),
  );
  final password = TextEditingController();
  var gender = text(item, 'gender', fallback: 'male');
  await _formSheet(
    context,
    title: item == null ? 'إضافة طالب' : 'تعديل طالب',
    fields: [
      TextField(
        controller: name,
        decoration: const InputDecoration(labelText: 'اسم الطالب'),
      ),
      TextField(
        controller: email,
        decoration: const InputDecoration(labelText: 'البريد'),
      ),
      TextField(
        controller: numberController,
        decoration: const InputDecoration(labelText: 'رقم القيد'),
      ),
      DropdownButtonFormField<String>(
        value: gender,
        items: const [
          DropdownMenuItem(value: 'male', child: Text('ذكر')),
          DropdownMenuItem(value: 'female', child: Text('أنثى')),
        ],
        onChanged: (value) => gender = value ?? 'male',
        decoration: const InputDecoration(labelText: 'الجنس'),
      ),
      TextField(
        controller: password,
        obscureText: true,
        decoration: InputDecoration(
          labelText: item == null ? 'كلمة المرور' : 'كلمة مرور جديدة اختيارية',
        ),
      ),
    ],
    onSave: () async {
      final data = {
        'name': name.text.trim(),
        'email': email.text.trim(),
        'student_number': numberController.text.trim(),
        'gender': gender,
        if (password.text.isNotEmpty) 'password': password.text,
        if (password.text.isNotEmpty) 'password_confirmation': password.text,
      };
      if (item == null) {
        data['password'] = password.text;
        data['password_confirmation'] = password.text;
        return ref.read(delegateRepositoryProvider).createStudent(data);
      }
      return ref
          .read(delegateRepositoryProvider)
          .updateStudent(number(item, 'id').toInt(), data);
    },
    after: () => ref.invalidate(_delegateStudentsProvider(1)),
  );
}

Future<void> _studentPermissionSheet(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> student,
) async {
  final id = number(student, 'id').toInt();
  final data = await ref
      .read(delegateRepositoryProvider)
      .studentPermissions(id);
  var canUpload = data['can_upload_library'] == true;
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('صلاحيات ${text(student, 'name')}', style: _titleStyle),
            SwitchListTile(
              value: canUpload,
              onChanged: (value) => setState(() => canUpload = value),
              title: const Text('رفع ملفات المكتبة المشتركة'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _run(
                  context,
                  () => ref
                      .read(delegateRepositoryProvider)
                      .updateStudentPermissions(
                        id: id,
                        canUploadLibrary: canUpload,
                      ),
                  after: () {},
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('حفظ الصلاحيات'),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _subjectSheet(
  BuildContext context,
  WidgetRef ref, {
  Map<String, dynamic>? item,
}) async {
  final repo = ref.read(delegateRepositoryProvider);
  final results = await Future.wait([repo.doctors(), repo.terms()]);
  if (!context.mounted) return;
  final doctors = results[0];
  final terms = results[1];
  final name = TextEditingController(text: text(item, 'name'));
  final code = TextEditingController(text: text(item, 'code'));
  var doctorId = number(
    item,
    'doctor_id',
    fallback: number(asMap(item?['doctor']), 'id'),
  ).toInt();
  var termId = number(
    item,
    'term_id',
    fallback: number(asMap(item?['term']), 'id'),
  ).toInt();
  doctorId = doctorId == 0 && doctors.isNotEmpty
      ? number(doctors.first, 'id').toInt()
      : doctorId;
  termId = termId == 0 && terms.isNotEmpty
      ? number(terms.first, 'id').toInt()
      : termId;

  await _formSheet(
    context,
    title: item == null ? 'إضافة مادة' : 'تعديل مادة',
    fields: [
      TextField(
        controller: name,
        decoration: const InputDecoration(labelText: 'اسم المادة'),
      ),
      TextField(
        controller: code,
        decoration: const InputDecoration(labelText: 'الكود'),
      ),
      DropdownButtonFormField<int>(
        value: doctorId == 0 ? null : doctorId,
        items: doctors
            .map(
              (doctor) => DropdownMenuItem(
                value: number(doctor, 'id').toInt(),
                child: Text(text(doctor, 'name')),
              ),
            )
            .toList(),
        onChanged: (value) => doctorId = value ?? 0,
        decoration: const InputDecoration(labelText: 'الدكتور'),
      ),
      DropdownButtonFormField<int>(
        value: termId == 0 ? null : termId,
        items: terms
            .map(
              (term) => DropdownMenuItem(
                value: number(term, 'id').toInt(),
                child: Text(text(term, 'name')),
              ),
            )
            .toList(),
        onChanged: (value) => termId = value ?? 0,
        decoration: const InputDecoration(labelText: 'الترم'),
      ),
    ],
    onSave: () => repo.saveSubject(
      id: item == null ? null : number(item, 'id').toInt(),
      data: {
        'name': name.text.trim(),
        'code': code.text.trim(),
        'doctor_id': doctorId,
        'term_id': termId,
      },
    ),
    after: () => ref.invalidate(_delegateSubjectsProvider),
  );
}

Future<void> _scheduleSheet(
  BuildContext context,
  WidgetRef ref, {
  Map<String, dynamic>? item,
}) async {
  final subjects = await ref.read(delegateRepositoryProvider).subjects();
  if (!context.mounted) return;
  var subjectId = number(
    item,
    'subject_id',
    fallback: number(asMap(item?['subject']), 'id'),
  ).toInt();
  subjectId = subjectId == 0 && subjects.isNotEmpty
      ? number(subjects.first, 'id').toInt()
      : subjectId;
  var day = number(item, 'day_of_week', fallback: 1).toInt();
  final start = TextEditingController(
    text: text(item, 'start_time', fallback: '08:00'),
  );
  final end = TextEditingController(
    text: text(item, 'end_time', fallback: '10:00'),
  );
  final hall = TextEditingController(text: text(item, 'hall_name'));
  await _formSheet(
    context,
    title: item == null ? 'إضافة محاضرة' : 'تعديل محاضرة',
    fields: [
      DropdownButtonFormField<int>(
        value: subjectId == 0 ? null : subjectId,
        items: subjects
            .map(
              (subject) => DropdownMenuItem(
                value: number(subject, 'id').toInt(),
                child: Text(text(subject, 'name')),
              ),
            )
            .toList(),
        onChanged: (value) => subjectId = value ?? 0,
        decoration: const InputDecoration(labelText: 'المادة'),
      ),
      DropdownButtonFormField<int>(
        value: day,
        items: const [
          DropdownMenuItem(value: 1, child: Text('الاثنين')),
          DropdownMenuItem(value: 2, child: Text('الثلاثاء')),
          DropdownMenuItem(value: 3, child: Text('الأربعاء')),
          DropdownMenuItem(value: 4, child: Text('الخميس')),
          DropdownMenuItem(value: 5, child: Text('الجمعة')),
          DropdownMenuItem(value: 6, child: Text('السبت')),
          DropdownMenuItem(value: 7, child: Text('الأحد')),
        ],
        onChanged: (value) => day = value ?? 1,
        decoration: const InputDecoration(labelText: 'اليوم'),
      ),
      TextField(
        controller: start,
        decoration: const InputDecoration(labelText: 'بداية المحاضرة H:i'),
      ),
      TextField(
        controller: end,
        decoration: const InputDecoration(labelText: 'نهاية المحاضرة H:i'),
      ),
      TextField(
        controller: hall,
        decoration: const InputDecoration(labelText: 'القاعة'),
      ),
    ],
    onSave: () => ref
        .read(delegateRepositoryProvider)
        .saveSchedule(
          id: item == null ? null : number(item, 'id').toInt(),
          data: {
            'subject_id': subjectId,
            'day_of_week': day,
            'start_time': start.text.trim(),
            'end_time': end.text.trim(),
            'hall_name': hall.text.trim(),
          },
        ),
    after: () => ref.invalidate(_delegateSchedulesProvider),
  );
}

Future<void> _assignmentSheet(
  BuildContext context,
  WidgetRef ref, {
  Map<String, dynamic>? item,
}) async {
  final subjects = await ref.read(delegateRepositoryProvider).subjects();
  if (!context.mounted) return;
  var subjectId = number(
    item,
    'subject_id',
    fallback: number(asMap(item?['subject']), 'id'),
  ).toInt();
  subjectId = subjectId == 0 && subjects.isNotEmpty
      ? number(subjects.first, 'id').toInt()
      : subjectId;
  final title = TextEditingController(text: text(item, 'title'));
  final description = TextEditingController(text: text(item, 'description'));
  final due = TextEditingController(
    text: text(
      item,
      'due_date',
      fallback: DateTime.now()
          .add(const Duration(days: 1))
          .toIso8601String()
          .split('T')
          .first,
    ),
  );
  var requiresSubmission = item?['requires_submission'] != false;
  await _formSheet(
    context,
    title: item == null ? 'إضافة تكليف' : 'تعديل تكليف',
    fields: [
      DropdownButtonFormField<int>(
        value: subjectId == 0 ? null : subjectId,
        items: subjects
            .map(
              (subject) => DropdownMenuItem(
                value: number(subject, 'id').toInt(),
                child: Text(text(subject, 'name')),
              ),
            )
            .toList(),
        onChanged: (value) => subjectId = value ?? 0,
        decoration: const InputDecoration(labelText: 'المادة'),
      ),
      TextField(
        controller: title,
        decoration: const InputDecoration(labelText: 'العنوان'),
      ),
      TextField(
        controller: description,
        minLines: 3,
        maxLines: 5,
        decoration: const InputDecoration(labelText: 'الوصف'),
      ),
      TextField(
        controller: due,
        decoration: const InputDecoration(
          labelText: 'تاريخ التسليم YYYY-MM-DD',
        ),
      ),
      StatefulBuilder(
        builder: (context, setState) => SwitchListTile(
          value: requiresSubmission,
          onChanged: (value) => setState(() => requiresSubmission = value),
          title: const Text('يتطلب تسليم'),
        ),
      ),
    ],
    onSave: () => ref
        .read(delegateRepositoryProvider)
        .saveAssignment(
          id: item == null ? null : number(item, 'id').toInt(),
          data: {
            'subject_id': subjectId,
            'title': title.text.trim(),
            'description': description.text.trim(),
            'due_date': due.text.trim(),
            'requires_submission': requiresSubmission,
          },
        ),
    after: () => ref.invalidate(_delegateAssignmentsProvider),
  );
}

Future<void> _examScheduleSheet(
  BuildContext context,
  WidgetRef ref, {
  Map<String, dynamic>? item,
}) async {
  final subjects = await ref.read(delegateRepositoryProvider).subjects();
  if (!context.mounted) return;
  var subjectId = subjects.isNotEmpty
      ? number(subjects.first, 'id').toInt()
      : 0;
  final firstItem = asMap(
    asList(item?['items']).isNotEmpty ? asList(item?['items']).first : null,
  );
  if (firstItem.isNotEmpty)
    subjectId = number(
      firstItem,
      'subject_id',
      fallback: number(asMap(firstItem['subject']), 'id'),
    ).toInt();
  final title = TextEditingController(text: text(item, 'title'));
  final description = TextEditingController(text: text(item, 'description'));
  final date = TextEditingController(
    text: text(
      firstItem,
      'exam_date',
      fallback: DateTime.now()
          .add(const Duration(days: 7))
          .toIso8601String()
          .split('T')
          .first,
    ),
  );
  final start = TextEditingController(
    text: text(firstItem, 'start_time', fallback: '09:00'),
  );
  final end = TextEditingController(
    text: text(firstItem, 'end_time', fallback: '11:00'),
  );
  final location = TextEditingController(text: text(firstItem, 'location'));
  var examType = text(firstItem, 'exam_type', fallback: 'midterm');
  await _formSheet(
    context,
    title: item == null ? 'إضافة جدول اختبار' : 'تعديل جدول اختبار',
    fields: [
      TextField(
        controller: title,
        decoration: const InputDecoration(labelText: 'عنوان الجدول'),
      ),
      TextField(
        controller: description,
        decoration: const InputDecoration(labelText: 'الوصف'),
      ),
      DropdownButtonFormField<int>(
        value: subjectId == 0 ? null : subjectId,
        items: subjects
            .map(
              (subject) => DropdownMenuItem(
                value: number(subject, 'id').toInt(),
                child: Text(text(subject, 'name')),
              ),
            )
            .toList(),
        onChanged: (value) => subjectId = value ?? 0,
        decoration: const InputDecoration(labelText: 'المادة'),
      ),
      TextField(
        controller: date,
        decoration: const InputDecoration(
          labelText: 'تاريخ الاختبار YYYY-MM-DD',
        ),
      ),
      TextField(
        controller: start,
        decoration: const InputDecoration(labelText: 'البداية H:i'),
      ),
      TextField(
        controller: end,
        decoration: const InputDecoration(labelText: 'النهاية H:i'),
      ),
      TextField(
        controller: location,
        decoration: const InputDecoration(labelText: 'المكان'),
      ),
      DropdownButtonFormField<String>(
        value: examType,
        items: const [
          DropdownMenuItem(value: 'midterm', child: Text('نصفي')),
          DropdownMenuItem(value: 'final', child: Text('نهائي')),
          DropdownMenuItem(value: 'practical', child: Text('عملي')),
          DropdownMenuItem(value: 'quiz', child: Text('كويز')),
          DropdownMenuItem(value: 'other', child: Text('آخر')),
        ],
        onChanged: (value) => examType = value ?? 'midterm',
        decoration: const InputDecoration(labelText: 'نوع الاختبار'),
      ),
    ],
    onSave: () => ref
        .read(delegateRepositoryProvider)
        .saveExamSchedule(
          id: item == null ? null : number(item, 'id').toInt(),
          data: {
            'term_id': 1,
            'title': title.text.trim(),
            'description': description.text.trim(),
            'items': [
              {
                'subject_id': subjectId,
                'exam_date': date.text.trim(),
                'start_time': start.text.trim(),
                'end_time': end.text.trim(),
                'location': location.text.trim(),
                'exam_type': examType,
              },
            ],
          },
        ),
    after: () => ref.invalidate(_delegateExamsProvider),
  );
}

Future<void> _resourceSheet(BuildContext context, WidgetRef ref) async {
  final subjects = await ref.read(delegateRepositoryProvider).subjects();
  if (!context.mounted) return;
  var subjectId = subjects.isNotEmpty
      ? number(subjects.first, 'id').toInt()
      : 0;
  var category = 'lectures';
  final title = TextEditingController();
  final description = TextEditingController();
  PlatformFile? selected;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          8,
          22,
          MediaQuery.viewInsetsOf(context).bottom + 22,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('رفع مصدر مقرر', style: _titleStyle),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                value: subjectId == 0 ? null : subjectId,
                items: subjects
                    .map(
                      (subject) => DropdownMenuItem(
                        value: number(subject, 'id').toInt(),
                        child: Text(text(subject, 'name')),
                      ),
                    )
                    .toList(),
                onChanged: (value) => subjectId = value ?? 0,
                decoration: const InputDecoration(labelText: 'المادة'),
              ),
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'العنوان'),
              ),
              TextField(
                controller: description,
                decoration: const InputDecoration(labelText: 'الوصف'),
              ),
              DropdownButtonFormField<String>(
                value: category,
                items: const [
                  DropdownMenuItem(value: 'lectures', child: Text('محاضرات')),
                  DropdownMenuItem(value: 'references', child: Text('مراجع')),
                  DropdownMenuItem(value: 'summaries', child: Text('ملخصات')),
                  DropdownMenuItem(value: 'exams', child: Text('اختبارات')),
                  DropdownMenuItem(value: 'quizzes', child: Text('كويزات')),
                  DropdownMenuItem(value: 'other', child: Text('أخرى')),
                ],
                onChanged: (value) => category = value ?? 'lectures',
                decoration: const InputDecoration(labelText: 'التصنيف'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles();
                  if (result != null && result.files.isNotEmpty) {
                    setState(() => selected = result.files.single);
                  }
                },
                icon: const Icon(Icons.attach_file_rounded),
                label: Text(selected?.name ?? 'اختيار ملف'),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: selected?.path == null
                    ? null
                    : () async {
                        await _run(
                          context,
                          () => ref
                              .read(delegateRepositoryProvider)
                              .uploadResource(
                                subjectId: subjectId,
                                title: title.text.trim(),
                                category: category,
                                filePath: selected!.path!,
                                fileName: selected!.name,
                                description: description.text.trim(),
                              ),
                          after: () =>
                              ref.invalidate(_delegateResourcesProvider),
                        );
                        if (context.mounted) Navigator.pop(context);
                      },
                child: const Text('رفع الملف'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> _reminderSheet(
  BuildContext context,
  WidgetRef ref, {
  Map<String, dynamic>? item,
}) async {
  final title = TextEditingController(text: text(item, 'title'));
  final description = TextEditingController(text: text(item, 'description'));
  final eventDate = TextEditingController(
    text: text(
      item,
      'event_date',
      fallback: DateTime.now().add(const Duration(days: 1)).toIso8601String(),
    ),
  );
  final notifyAt = TextEditingController(
    text: text(item, 'notify_at', fallback: DateTime.now().toIso8601String()),
  );
  await _formSheet(
    context,
    title: item == null ? 'إضافة تذكير' : 'تعديل تذكير',
    fields: [
      TextField(
        controller: title,
        decoration: const InputDecoration(labelText: 'العنوان'),
      ),
      TextField(
        controller: description,
        decoration: const InputDecoration(labelText: 'الوصف'),
      ),
      TextField(
        controller: eventDate,
        decoration: const InputDecoration(labelText: 'وقت الحدث'),
      ),
      TextField(
        controller: notifyAt,
        decoration: const InputDecoration(labelText: 'وقت التنبيه'),
      ),
    ],
    onSave: () => ref
        .read(delegateRepositoryProvider)
        .saveReminder(
          id: item == null ? null : number(item, 'id').toInt(),
          data: {
            'title': title.text.trim(),
            'description': description.text.trim(),
            'event_date': eventDate.text.trim(),
            'notify_at': notifyAt.text.trim(),
          },
        ),
    after: () => ref.invalidate(_delegateRemindersProvider('upcoming')),
  );
}

Future<void> _announcementSheet(
  BuildContext context,
  WidgetRef ref, {
  Map<String, dynamic>? item,
}) async {
  final title = TextEditingController(text: text(item, 'title'));
  final content = TextEditingController(text: text(item, 'content'));
  var category = text(item, 'category', fallback: 'general');
  await _formSheet(
    context,
    title: item == null ? 'نشر إعلان' : 'تعديل إعلان',
    fields: [
      TextField(
        controller: title,
        decoration: const InputDecoration(labelText: 'العنوان'),
      ),
      TextField(
        controller: content,
        minLines: 4,
        maxLines: 7,
        decoration: const InputDecoration(labelText: 'المحتوى'),
      ),
      DropdownButtonFormField<String>(
        value: category,
        items: const [
          DropdownMenuItem(value: 'general', child: Text('عام')),
          DropdownMenuItem(value: 'academic', child: Text('أكاديمي')),
          DropdownMenuItem(value: 'urgent', child: Text('عاجل')),
        ],
        onChanged: (value) => category = value ?? 'general',
        decoration: const InputDecoration(labelText: 'النوع'),
      ),
    ],
    onSave: () => ref
        .read(delegateRepositoryProvider)
        .saveAnnouncement(
          id: item == null ? null : number(item, 'id').toInt(),
          data: {
            'title': title.text.trim(),
            'content': content.text.trim(),
            'category': category,
          },
        ),
    after: () => ref.invalidate(_delegateAnnouncementsProvider),
  );
}

Future<void> _attendanceSheet(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> subject,
) async {
  final title = TextEditingController(
    text: 'محاضرة ${DateTime.now().toIso8601String().split('T').first}',
  );
  final date = TextEditingController(
    text: DateTime.now().toIso8601String().split('T').first,
  );
  final data = await ref
      .read(delegateRepositoryProvider)
      .attendanceCreate(
        subjectId: number(subject, 'id').toInt(),
        date: date.text,
      );
  if (!context.mounted) return;
  final students = asList(data['students']);
  final statuses = <int, String>{
    for (final raw in students) number(raw, 'id').toInt(): 'present',
  };
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            Text('رصد حضور ${text(subject, 'name')}', style: _titleStyle),
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'عنوان المحاضرة'),
            ),
            TextField(
              controller: date,
              decoration: const InputDecoration(labelText: 'التاريخ'),
            ),
            const SizedBox(height: 14),
            for (final raw in students)
              _GlassCard(
                margin: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        text(raw, 'name'),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    DropdownButton<String>(
                      value: statuses[number(raw, 'id').toInt()],
                      items: const [
                        DropdownMenuItem(value: 'present', child: Text('حاضر')),
                        DropdownMenuItem(value: 'absent', child: Text('غائب')),
                        DropdownMenuItem(value: 'late', child: Text('متأخر')),
                        DropdownMenuItem(value: 'excused', child: Text('بعذر')),
                      ],
                      onChanged: (value) => setState(
                        () => statuses[number(raw, 'id').toInt()] =
                            value ?? 'present',
                      ),
                    ),
                  ],
                ),
              ),
            ElevatedButton(
              onPressed: () async {
                await _run(
                  context,
                  () => ref.read(delegateRepositoryProvider).saveAttendance({
                    'subject_id': number(subject, 'id').toInt(),
                    'title': title.text.trim(),
                    'date': date.text.trim(),
                    'students': statuses.entries
                        .map(
                          (entry) => {'id': entry.key, 'status': entry.value},
                        )
                        .toList(),
                  }),
                  after: () => ref.invalidate(_delegateAttendanceProvider),
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('حفظ الحضور'),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _startQrSession(
  BuildContext context,
  WidgetRef ref, {
  required ValueChanged<Map<String, dynamic>> onStarted,
}) async {
  final subjects = await ref.read(delegateRepositoryProvider).subjects();
  if (!context.mounted) return;
  var subjectId = subjects.isNotEmpty
      ? number(subjects.first, 'id').toInt()
      : 0;
  final title = TextEditingController(text: 'جلسة حضور QR');
  final date = TextEditingController(
    text: DateTime.now().toIso8601String().split('T').first,
  );
  await _formSheet(
    context,
    title: 'بدء جلسة QR',
    fields: [
      DropdownButtonFormField<int>(
        value: subjectId == 0 ? null : subjectId,
        items: subjects
            .where(
              (subject) => asMap(subject)['allow_delegate_attendance'] == true,
            )
            .map(
              (subject) => DropdownMenuItem(
                value: number(subject, 'id').toInt(),
                child: Text(text(subject, 'name')),
              ),
            )
            .toList(),
        onChanged: (value) => subjectId = value ?? 0,
        decoration: const InputDecoration(labelText: 'المادة'),
      ),
      TextField(
        controller: title,
        decoration: const InputDecoration(labelText: 'عنوان الجلسة'),
      ),
      TextField(
        controller: date,
        decoration: const InputDecoration(labelText: 'التاريخ'),
      ),
    ],
    onSave: () async {
      final session = await ref
          .read(delegateRepositoryProvider)
          .startQrAttendance({
            'subject_id': subjectId,
            'title': title.text.trim(),
            'date': date.text.trim(),
          });
      onStarted(session);
      return 'تم بدء الجلسة.';
    },
    after: () {},
  );
}

Future<void> _gradesEntrySheet(
  BuildContext context,
  WidgetRef ref,
  int categoryId,
) async {
  final data = await ref
      .read(delegateRepositoryProvider)
      .authorizedGradeDetails(categoryId);
  if (!context.mounted) return;
  final students = asList(data['students']);
  final controllers = <int, TextEditingController>{};
  for (final raw in students) {
    final id = number(raw, 'id').toInt();
    final current = asMap(raw)['current_grade'];
    controllers[id] = TextEditingController(text: text(current, 'score'));
  }
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.all(20),
        children: [
          const Text('رصد الدرجات', style: _titleStyle),
          const SizedBox(height: 12),
          for (final raw in students)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                controller: controllers[number(raw, 'id').toInt()],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText:
                      '${text(raw, 'name')} - ${text(raw, 'student_number', fallback: '-')}',
                ),
              ),
            ),
          ElevatedButton(
            onPressed: () async {
              final grades = controllers.entries
                  .where((entry) => entry.value.text.trim().isNotEmpty)
                  .map(
                    (entry) => {
                      'student_id': entry.key,
                      'score': entry.value.text.trim(),
                    },
                  )
                  .toList();
              await _run(
                context,
                () => ref
                    .read(delegateRepositoryProvider)
                    .saveAuthorizedGrades(
                      categoryId: categoryId,
                      grades: grades,
                    ),
                after: () => ref.invalidate(_delegateAuthorizedGradesProvider),
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('إرسال للمراجعة'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _helperDelegationSheet(BuildContext context, WidgetRef ref) async {
  final grades = await ref.read(delegateRepositoryProvider).authorizedGrades();
  final categories = asList(grades['direct_delegations']);
  if (!context.mounted || categories.isEmpty) {
    if (context.mounted)
      _toast(context, 'لا توجد تصنيفات مفوضة لإنشاء تفويض مساعد.');
    return;
  }
  var categoryId = number(categories.first, 'id').toInt();
  final title = TextEditingController(text: 'مهمة رصد درجات');
  final notes = TextEditingController();
  var helperId = 0;
  var delegationType = 'full';
  List<dynamic> students = const [];
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          8,
          22,
          MediaQuery.viewInsetsOf(context).bottom + 22,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('تفويض مساعد رصد', style: _titleStyle),
              DropdownButtonFormField<int>(
                value: categoryId,
                items: categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: number(category, 'id').toInt(),
                        child: Text(text(category, 'name')),
                      ),
                    )
                    .toList(),
                onChanged: (value) async {
                  categoryId = value ?? categoryId;
                  final data = await ref
                      .read(delegateRepositoryProvider)
                      .helperDelegationStudents(categoryId);
                  setState(() {
                    students = asList(data['eligible_students']);
                    helperId = students.isNotEmpty
                        ? number(students.first, 'id').toInt()
                        : 0;
                  });
                },
                decoration: const InputDecoration(labelText: 'التصنيف'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final data = await ref
                      .read(delegateRepositoryProvider)
                      .helperDelegationStudents(categoryId);
                  setState(() {
                    students = asList(data['eligible_students']);
                    helperId = students.isNotEmpty
                        ? number(students.first, 'id').toInt()
                        : 0;
                  });
                },
                icon: const Icon(Icons.people_rounded),
                label: const Text('تحميل الطلاب المتاحين'),
              ),
              if (students.isNotEmpty)
                DropdownButtonFormField<int>(
                  value: helperId == 0 ? null : helperId,
                  items: students
                      .map(
                        (student) => DropdownMenuItem(
                          value: number(student, 'id').toInt(),
                          child: Text(
                            '${text(student, 'name')} - ${text(student, 'role')}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => helperId = value ?? 0,
                  decoration: const InputDecoration(labelText: 'المساعد'),
                ),
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'عنوان المهمة'),
              ),
              TextField(
                controller: notes,
                decoration: const InputDecoration(labelText: 'ملاحظات'),
              ),
              DropdownButtonFormField<String>(
                value: delegationType,
                items: const [
                  DropdownMenuItem(value: 'full', child: Text('كل الطلاب')),
                  DropdownMenuItem(value: 'partial', child: Text('تفويض جزئي')),
                ],
                onChanged: (value) => delegationType = value ?? 'full',
                decoration: const InputDecoration(labelText: 'نطاق التفويض'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: helperId == 0
                    ? null
                    : () async {
                        await _run(
                          context,
                          () => ref
                              .read(delegateRepositoryProvider)
                              .createHelperDelegation({
                                'category_id': categoryId,
                                'helper_user_id': helperId,
                                'delegation_type': delegationType,
                                'title': title.text.trim(),
                                'notes': notes.text.trim(),
                                if (delegationType == 'partial')
                                  'student_ids': students
                                      .map(
                                        (student) =>
                                            number(student, 'id').toInt(),
                                      )
                                      .take(1)
                                      .toList(),
                              }),
                          after: () =>
                              ref.invalidate(_delegateHelperTasksProvider),
                        );
                        if (context.mounted) Navigator.pop(context);
                      },
                child: const Text('إنشاء التفويض'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> _importResourceSheet(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> resource,
) async {
  final subjects = await ref.read(delegateRepositoryProvider).subjects();
  if (!context.mounted) return;
  var subjectId = subjects.isNotEmpty
      ? number(subjects.first, 'id').toInt()
      : 0;
  await _formSheet(
    context,
    title: 'استيراد الملف',
    fields: [
      Text(
        text(resource, 'title'),
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      DropdownButtonFormField<int>(
        value: subjectId == 0 ? null : subjectId,
        items: subjects
            .map(
              (subject) => DropdownMenuItem(
                value: number(subject, 'id').toInt(),
                child: Text(text(subject, 'name')),
              ),
            )
            .toList(),
        onChanged: (value) => subjectId = value ?? 0,
        decoration: const InputDecoration(labelText: 'استيراد إلى المادة'),
      ),
    ],
    onSave: () => ref
        .read(delegateRepositoryProvider)
        .importResource(
          resourceId: number(resource, 'id').toInt(),
          subjectId: subjectId,
        ),
    after: () {},
  );
}

Future<void> _replyInquirySheet(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> inquiry,
) async {
  final reply = TextEditingController();
  await _formSheet(
    context,
    title: 'الرد على الاستفسار',
    fields: [
      Text(
        text(inquiry, 'question', fallback: text(inquiry, 'title')),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      TextField(
        controller: reply,
        minLines: 4,
        maxLines: 7,
        decoration: const InputDecoration(labelText: 'الرد'),
      ),
    ],
    onSave: () => ref
        .read(delegateRepositoryProvider)
        .replyInquiry(
          id: number(inquiry, 'id').toInt(),
          reply: reply.text.trim(),
        ),
    after: () => ref.invalidate(_delegateInquiriesProvider('all')),
  );
}

Future<void> _formSheet(
  BuildContext context, {
  required String title,
  required List<Widget> fields,
  required Future<String> Function() onSave,
  required VoidCallback after,
}) async {
  var saving = false;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          8,
          22,
          MediaQuery.viewInsetsOf(context).bottom + 22,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: _titleStyle),
              const SizedBox(height: 14),
              ...fields.expand((field) => [field, const SizedBox(height: 12)]),
              ElevatedButton.icon(
                onPressed: saving
                    ? null
                    : () async {
                        setState(() => saving = true);
                        try {
                          final message = await onSave();
                          if (context.mounted) {
                            Navigator.pop(context);
                            _toast(context, message);
                          }
                          after();
                        } catch (error) {
                          if (context.mounted) _showError(context, error);
                        } finally {
                          if (context.mounted) setState(() => saving = false);
                        }
                      },
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: const Text('حفظ'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> _delete(
  BuildContext context,
  Future<String> Function() action,
  VoidCallback after,
) async {
  final confirmed = await showMoeenConfirmDialog(
    context: context,
    title: 'تأكيد الحذف',
    message: 'هل تريد حذف هذا العنصر؟',
    confirmLabel: 'حذف',
    icon: Icons.delete_rounded,
    color: AppColors.danger,
    danger: true,
  );
  if (!confirmed) return;
  await _run(context, action, after: after);
}

Future<void> _run(
  BuildContext context,
  Future<dynamic> Function() action, {
  required VoidCallback after,
}) async {
  try {
    final result = await action();
    after();
    if (context.mounted)
      _toast(context, result?.toString() ?? 'تم تنفيذ العملية.');
  } catch (error) {
    if (context.mounted) _showError(context, error);
  }
}

// Chat widgets
class _ChatListScreen extends ConsumerWidget {
  const _ChatListScreen({
    required this.title,
    required this.index,
    required this.state,
    required this.onRetry,
    required this.extractor,
    required this.eligibleLoader,
    required this.openPath,
    required this.startMessage,
  });
  final String title;
  final int index;
  final AsyncValue<Map<String, dynamic>> state;
  final VoidCallback onRetry;
  final List<dynamic> Function(Map<String, dynamic>) extractor;
  final Future<List<dynamic>> Function() eligibleLoader;
  final String Function(int id) openPath;
  final Future<String> Function({
    required int recipientId,
    required String content,
  })
  startMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DelegateShell(
      currentIndex: index,
      title: title,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startChatSheet(context),
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text('محادثة'),
      ),
      child: _AsyncBody(
        state: state,
        onRetry: onRetry,
        builder: (data) {
          final items = extractor(data);
          return _ListScaffold(
            title: '$title (${items.length})',
            subtitle: 'دردشة منظمة وسريعة مع الأطراف المرتبطة بالدفعة.',
            icon: Icons.forum_rounded,
            colors: const [AppColors.violet, AppColors.royalBlue],
            children: [
              if (items.isEmpty) const _EmptyState('لا توجد محادثات حالية.'),
              for (final raw in items)
                InkWell(
                  onTap: () =>
                      context.push(openPath(number(raw, 'id').toInt())),
                  child: _DataCard(
                    title: text(
                      asMap(raw)['student'],
                      'name',
                      fallback: text(
                        asMap(raw)['doctor'],
                        'name',
                        fallback: 'محادثة',
                      ),
                    ),
                    subtitle: text(
                      asMap(raw)['last_message'],
                      'body',
                      fallback: text(
                        raw,
                        'last_message_at',
                        fallback: 'اضغط لعرض التفاصيل',
                      ),
                    ),
                    icon: Icons.chat_bubble_rounded,
                    color: AppColors.violet,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _startChatSheet(BuildContext context) async {
    final recipients = await eligibleLoader();
    if (!context.mounted) return;
    var recipientId = recipients.isNotEmpty
        ? number(recipients.first, 'id').toInt()
        : 0;
    final message = TextEditingController();
    await _formSheet(
      context,
      title: 'بدء محادثة',
      fields: [
        DropdownButtonFormField<int>(
          value: recipientId == 0 ? null : recipientId,
          items: recipients
              .map(
                (recipient) => DropdownMenuItem(
                  value: number(recipient, 'id').toInt(),
                  child: Text(text(recipient, 'name')),
                ),
              )
              .toList(),
          onChanged: (value) => recipientId = value ?? 0,
          decoration: const InputDecoration(labelText: 'المستلم'),
        ),
        TextField(
          controller: message,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(labelText: 'الرسالة'),
        ),
      ],
      onSave: () =>
          startMessage(recipientId: recipientId, content: message.text.trim()),
      after: onRetry,
    );
  }
}

class _ConversationView extends StatefulWidget {
  const _ConversationView({
    required this.title,
    required this.future,
    required this.reload,
    required this.send,
  });

  final String title;
  final Future<Map<String, dynamic>> future;
  final VoidCallback reload;
  final Future<String> Function(String body) send;

  @override
  State<_ConversationView> createState() => _ConversationViewState();
}

class _ConversationViewState extends State<_ConversationView> {
  final _message = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DelegateShell(
      currentIndex: 17,
      title: widget.title,
      child: FutureBuilder<Map<String, dynamic>>(
        future: widget.future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
              onRetry: widget.reload,
            );
          }
          final data = snapshot.data ?? {};
          final messages = asList(data['messages']);
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                  children: [
                    for (final raw in messages)
                      Align(
                        alignment:
                            text(asMap(raw)['sender'], 'role') == 'delegate'
                            ? AlignmentDirectional.centerEnd
                            : AlignmentDirectional.centerStart,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                          ),
                          decoration: BoxDecoration(
                            color:
                                text(asMap(raw)['sender'], 'role') == 'delegate'
                                ? AppColors.royalBlue
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            text(raw, 'body', fallback: text(raw, 'content')),
                            style: TextStyle(
                              color:
                                  text(asMap(raw)['sender'], 'role') ==
                                      'delegate'
                                  ? Colors.white
                                  : AppColors.midnight,
                              fontWeight: FontWeight.w700,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _message,
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'اكتب رسالة...',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _sending ? null : _send,
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _send() async {
    if (_message.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      await widget.send(_message.text.trim());
      _message.clear();
      widget.reload();
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final entry in options.entries)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                selected: value == entry.key,
                label: Text(entry.value),
                onSelected: (_) => onChanged(entry.key),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => _DataCard(
    title: label,
    subtitle: value,
    icon: icon,
    color: AppColors.royalBlue,
  );
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.package,
    required this.subscribed,
    required this.onSubscribe,
  });
  final SubscriptionPackage package;
  final bool subscribed;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) => _GlassCard(
    margin: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        const Icon(
          Icons.workspace_premium_rounded,
          color: AppColors.goldDeep,
          size: 34,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                package.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              Text(
                '${(package.priceDelegate > 0 ? package.priceDelegate : package.displayPrice).toStringAsFixed(0)} ريال | ${package.durationDays} يوم',
              ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: subscribed ? null : onSubscribe,
          child: const Text('اشتراك'),
        ),
      ],
    ),
  );
}

class _StatItem {
  const _StatItem(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _Action {
  const _Action(this.label, this.icon, this.route, this.color);
  final String label;
  final IconData icon;
  final String route;
  final Color color;
}

const _titleStyle = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w900,
  color: AppColors.midnight,
);

Map<String, dynamic> asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map)
    return value.map((key, value) => MapEntry(key.toString(), value));
  return const {};
}

List<dynamic> asList(Object? value) {
  if (value is List) return value;
  if (value is Map) {
    final data = value['data'];
    if (data is List) return data;
  }
  return const [];
}

String text(Object? source, String key, {String fallback = ''}) {
  final map = asMap(source);
  final value = map[key];
  if (value == null) return fallback;
  return value.toString();
}

num number(Object? source, String key, {num fallback = 0}) {
  final map = asMap(source);
  final value = map[key];
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? fallback;
}

String value(Object? source, String key, {String fallback = '0'}) {
  final map = asMap(source);
  final raw = map[key];
  if (raw == null || raw.toString().isEmpty) return fallback;
  return raw.toString();
}

String timeText(Object? source) {
  return text(
    source,
    'created_at',
    fallback: text(source, 'updated_at', fallback: '-'),
  );
}

Color _typeColor(String type) => switch (type) {
  'exam' => AppColors.danger,
  'assignment' => AppColors.orange,
  'poll' => AppColors.violet,
  'attendance' => AppColors.warning,
  _ => AppColors.royalBlue,
};

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

void _showError(BuildContext context, Object error) {
  final message = error is ApiException ? error.message : error.toString();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: AppColors.danger),
  );
}

Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
  final current = TextEditingController();
  final password = TextEditingController();
  final confirmation = TextEditingController();
  await _formSheet(
    context,
    title: 'تغيير كلمة المرور',
    fields: [
      TextField(
        controller: current,
        obscureText: true,
        decoration: const InputDecoration(labelText: 'كلمة المرور الحالية'),
      ),
      TextField(
        controller: password,
        obscureText: true,
        decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة'),
      ),
      TextField(
        controller: confirmation,
        obscureText: true,
        decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور'),
      ),
    ],
    onSave: () => ref
        .read(delegateRepositoryProvider)
        .changePassword(
          currentPassword: current.text,
          newPassword: password.text,
          confirmation: confirmation.text,
        ),
    after: () {},
  );
}
