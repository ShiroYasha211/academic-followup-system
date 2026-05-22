import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/moeen_dialogs.dart';
import '../../../shared/widgets/status_message.dart';
import '../data/staff_repository.dart';
import 'staff_shell.dart';

final _adminOpsRepositoryProvider = Provider<StaffRepository>((ref) {
  return StaffRepository(ref.watch(authenticatedApiClientProvider));
});

class AdministrativeNotificationsScreen extends StatelessWidget {
  const AdministrativeNotificationsScreen({super.key});

  static const route = '/administrative/notifications';

  @override
  Widget build(BuildContext context) {
    return const _NotificationsView();
  }
}

class AdministrativeExcusesScreen extends StatelessWidget {
  const AdministrativeExcusesScreen({super.key});

  static const route = '/administrative/excuses';

  @override
  Widget build(BuildContext context) {
    return const _ExcusesView();
  }
}

class AdministrativeReportsScreen extends StatelessWidget {
  const AdministrativeReportsScreen({super.key});

  static const route = '/administrative/reports';

  @override
  Widget build(BuildContext context) {
    return const _ReportsView();
  }
}

class AdministrativeExamsScreen extends StatelessWidget {
  const AdministrativeExamsScreen({super.key});

  static const route = '/administrative/exams';

  @override
  Widget build(BuildContext context) {
    return const _ExamSchedulesView();
  }
}

class AdministrativeSchedulesScreen extends StatelessWidget {
  const AdministrativeSchedulesScreen({super.key});

  static const route = '/administrative/schedules';

  @override
  Widget build(BuildContext context) {
    return const _LectureSchedulesView();
  }
}

class _NotificationsView extends ConsumerStatefulWidget {
  const _NotificationsView();

  @override
  ConsumerState<_NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends ConsumerState<_NotificationsView> {
  Map<String, dynamic>? _data;
  Map<String, dynamic>? _createData;
  Object? _error;
  bool _loading = true;
  int _page = 1;
  String _type = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'الإعلانات والإشعارات الجماعية',
      currentRoute: AdministrativeNotificationsScreen.route,
      child: _ScaffoldBody(
        loading: _loading,
        error: _error,
        onRetry: _load,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              const _OpsHero(
                title: 'الإعلانات والإشعارات الجماعية',
                subtitle:
                    'إرسال إعلان أو استبيان لفئات محددة ومتابعة القراءة والتفاعل.',
                icon: Icons.campaign_rounded,
                color: AppColors.rose,
              ),
              const SizedBox(height: 16),
              _StatsRow(
                stats: [
                  _Stat(
                    'الإجمالي',
                    _pagination.total.toString(),
                    Icons.notifications_rounded,
                    AppColors.rose,
                  ),
                  _Stat(
                    'المقروء',
                    _readTotal.toString(),
                    Icons.mark_email_read_rounded,
                    AppColors.success,
                  ),
                  _Stat(
                    'الأنواع',
                    _map(_data?['type_stats']).length.toString(),
                    Icons.category_rounded,
                    AppColors.violet,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _ChoicePillBar(
                      value: _type,
                      items: const {
                        'all': 'الكل',
                        'announcement': 'إعلان',
                        'exam': 'اختبار',
                        'assignment': 'تكليف',
                        'attendance': 'حضور',
                        'poll': 'استبيان',
                      },
                      onChanged: (value) {
                        setState(() {
                          _type = value;
                          _page = 1;
                        });
                        _load();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _openCreate,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.rose,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_broadcasts.isEmpty)
                const _EmptyState()
              else
                ..._broadcasts.map(
                  (item) => _NotificationCard(
                    item: item,
                    onTap: () => _openDetails(item['batch_id'].toString()),
                    onDelete: () => _delete(item['batch_id'].toString()),
                  ),
                ),
              _Pagination(
                page: _pagination,
                onPrevious: _page > 1
                    ? () {
                        _page--;
                        _load();
                      }
                    : null,
                onNext: _page < _pagination.lastPage
                    ? () {
                        _page++;
                        _load();
                      }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _broadcasts => _list(_data?['broadcasts']);

  _PageInfo get _pagination =>
      _pageInfo(_data?['pagination'], _broadcasts.length);

  int get _readTotal =>
      _broadcasts.fold(0, (sum, item) => sum + _int(item['read_count']));

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(_adminOpsRepositoryProvider);
      final query = <String, dynamic>{'page': _page};
      if (_type != 'all') query['type'] = _type;
      final response = await repo.get(
        '/administrative/notifications',
        query: query,
      );
      final create =
          _createData ??
          _map(
            (await repo.get(
              '/administrative/notifications/create-data',
            ))['data'],
          );
      if (!mounted) return;
      setState(() {
        _data = _map(response['data']);
        _createData = create;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openCreate() {
    return showMoeenBottomSheet<void>(
      context: context,
      title: 'إرسال إشعار جماعي',
      icon: Icons.campaign_rounded,
      color: AppColors.rose,
      fullScreen: true,
      child: _NotificationForm(
        data: _createData ?? const {},
        onSubmit: (payload) async {
          await _runSave(
            () => ref
                .read(_adminOpsRepositoryProvider)
                .upload('/administrative/notifications', payload),
            successTitle: 'تم إرسال الإشعار',
            closeSheet: true,
          );
        },
      ),
    );
  }

  Future<void> _openDetails(String batchId) async {
    try {
      final response = await ref
          .read(_adminOpsRepositoryProvider)
          .get('/administrative/notifications/$batchId');
      if (!mounted) return;
      await showMoeenBottomSheet<void>(
        context: context,
        title: 'تفاصيل الإشعار',
        icon: Icons.analytics_rounded,
        color: AppColors.rose,
        fullScreen: true,
        child: _NotificationDetails(data: _map(response['data'])),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      await _errorDialog('تعذر فتح التفاصيل', error.message);
    }
  }

  Future<void> _delete(String batchId) async {
    final approved = await showMoeenConfirmDialog(
      context: context,
      title: 'حذف الإشعار',
      message: 'سيتم حذف الإشعار الجماعي ونتائج الاستبيان إن وجدت.',
      confirmLabel: 'حذف',
      icon: Icons.delete_rounded,
      color: AppColors.danger,
    );
    if (!approved) return;
    await _runSave(
      () => ref
          .read(_adminOpsRepositoryProvider)
          .delete('/administrative/notifications/$batchId'),
      successTitle: 'تم حذف الإشعار',
    );
  }

  Future<void> _runSave(
    Future<Map<String, dynamic>> Function() action, {
    required String successTitle,
    bool closeSheet = false,
  }) async {
    try {
      final response = await action();
      if (!mounted) return;
      if (closeSheet) Navigator.of(context).maybePop();
      await showMoeenInfoDialog(
        context: context,
        title: successTitle,
        message: (response['message'] ?? 'تمت العملية بنجاح.').toString(),
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
      );
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      await _errorDialog('تعذرت العملية', error.message);
    }
  }

  Future<void> _errorDialog(String title, String message) {
    return showMoeenInfoDialog(
      context: context,
      title: title,
      message: message,
      icon: Icons.error_rounded,
      color: AppColors.danger,
    );
  }
}

class _ExcusesView extends ConsumerStatefulWidget {
  const _ExcusesView();

  @override
  ConsumerState<_ExcusesView> createState() => _ExcusesViewState();
}

class _ExcusesViewState extends ConsumerState<_ExcusesView> {
  final _searchController = TextEditingController();
  Map<String, dynamic>? _data;
  Object? _error;
  bool _loading = true;
  int _page = 1;
  String _status = 'pending';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'الأعذار',
      currentRoute: AdministrativeExcusesScreen.route,
      child: _ScaffoldBody(
        loading: _loading,
        error: _error,
        onRetry: _load,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              const _OpsHero(
                title: 'إدارة الأعذار',
                subtitle:
                    'مراجعة أعذار الطلاب واتخاذ القرار المناسب حسب إعدادات الكلية.',
                icon: Icons.verified_rounded,
                color: AppColors.teal,
              ),
              const SizedBox(height: 16),
              _StatsRow(
                stats: [
                  _Stat(
                    'الكل',
                    _int(_map(_data?['stats'])['all']).toString(),
                    Icons.inbox_rounded,
                    AppColors.slate600,
                  ),
                  _Stat(
                    'قيد المراجعة',
                    _int(_map(_data?['stats'])['pending']).toString(),
                    Icons.pending_actions_rounded,
                    AppColors.goldDeep,
                  ),
                  _Stat(
                    'مقبولة',
                    _int(_map(_data?['stats'])['accepted']).toString(),
                    Icons.check_circle_rounded,
                    AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _ChoicePillBar(
                value: _status,
                items: const {
                  'all': 'الكل',
                  'pending': 'معلقة',
                  'accepted': 'مقبولة',
                  'rejected': 'مرفوضة',
                },
                onChanged: (value) {
                  setState(() {
                    _status = value;
                    _page = 1;
                  });
                  _load();
                },
              ),
              const SizedBox(height: 12),
              _SearchBox(
                controller: _searchController,
                onSearch: () {
                  _page = 1;
                  _load();
                },
              ),
              const SizedBox(height: 16),
              if (!(_data?['can_review'] == true))
                const _NoticeCard(
                  message:
                      'استقبال الأعذار مضبوط حاليًا على دكتور المادة، لذلك هذه الصفحة للعرض فقط.',
                ),
              if (_excuses.isEmpty)
                const _EmptyState()
              else
                ..._excuses.map(
                  (item) => _ExcuseCard(
                    item: item,
                    canReview: _data?['can_review'] == true,
                    onReview: () => _reviewExcuse(item),
                  ),
                ),
              _Pagination(
                page: _pageInfo(_data?['pagination'], _excuses.length),
                onPrevious: _page > 1
                    ? () {
                        _page--;
                        _load();
                      }
                    : null,
                onNext:
                    _page <
                        _pageInfo(
                          _data?['pagination'],
                          _excuses.length,
                        ).lastPage
                    ? () {
                        _page++;
                        _load();
                      }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _excuses => _list(_data?['excuses']);

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final query = {
        'page': _page,
        'status': _status,
        if (_searchController.text.trim().isNotEmpty)
          'search': _searchController.text.trim(),
      };
      final response = await ref
          .read(_adminOpsRepositoryProvider)
          .get('/administrative/excuses', query: query);
      if (mounted) setState(() => _data = _map(response['data']));
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reviewExcuse(Map<String, dynamic> item) {
    return showMoeenBottomSheet<void>(
      context: context,
      title: 'قرار العذر',
      icon: Icons.fact_check_rounded,
      color: AppColors.teal,
      child: _ExcuseReviewForm(
        options: _list(_data?['resolution_options']),
        onSubmit: (payload) async {
          try {
            final response = await ref
                .read(_adminOpsRepositoryProvider)
                .patch('/administrative/excuses/${item['id']}', payload);
            if (!mounted) return;
            Navigator.of(context).pop();
            await showMoeenInfoDialog(
              context: context,
              title: 'تم تحديث العذر',
              message: (response['message'] ?? 'تم تحديث القرار بنجاح.')
                  .toString(),
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
            );
            await _load();
          } on ApiException catch (error) {
            if (!mounted) return;
            await showMoeenInfoDialog(
              context: context,
              title: 'تعذر تحديث العذر',
              message: error.message,
              icon: Icons.error_rounded,
              color: AppColors.danger,
            );
          }
        },
      ),
    );
  }
}

class _ReportsView extends ConsumerStatefulWidget {
  const _ReportsView();

  @override
  ConsumerState<_ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends ConsumerState<_ReportsView> {
  final _searchController = TextEditingController();
  Map<String, dynamic>? _summaryData;
  Map<String, dynamic>? _attendanceData;
  Object? _error;
  bool _loading = true;
  int _page = 1;
  int? _majorId;
  int? _levelId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'تقارير القسم',
      currentRoute: AdministrativeReportsScreen.route,
      child: _ScaffoldBody(
        loading: _loading,
        error: _error,
        onRetry: _load,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              const _OpsHero(
                title: 'تقارير القسم وتعديل الحضور',
                subtitle:
                    'ملخصات تشغيلية وتقارير حضور مع إمكانية تعديل حالة السجل من نفس الصفحة.',
                icon: Icons.analytics_rounded,
                color: AppColors.royalBlue,
              ),
              const SizedBox(height: 16),
              _ReportSummaryGrid(summary: _map(_summaryData?['summary'])),
              const SizedBox(height: 18),
              const _SectionTitle(
                'تعديل الحضور من التقارير',
                Icons.fact_check_rounded,
              ),
              const SizedBox(height: 12),
              _ReportFilters(
                data: _summaryData ?? const {},
                majorId: _majorId,
                levelId: _levelId,
                searchController: _searchController,
                onMajor: (value) {
                  _majorId = value;
                  _levelId = null;
                  _page = 1;
                  _loadAttendance();
                },
                onLevel: (value) {
                  _levelId = value;
                  _page = 1;
                  _loadAttendance();
                },
                onSearch: () {
                  _page = 1;
                  _loadAttendance();
                },
              ),
              const SizedBox(height: 14),
              if (_attendanceRecords.isEmpty)
                const _EmptyState()
              else
                ..._attendanceRecords.map(
                  (record) => _AttendanceRecordCard(
                    item: record,
                    onEdit: () => _editAttendance(record),
                  ),
                ),
              _Pagination(
                page: _pageInfo(
                  _attendanceData?['pagination'],
                  _attendanceRecords.length,
                ),
                onPrevious: _page > 1
                    ? () {
                        _page--;
                        _loadAttendance();
                      }
                    : null,
                onNext:
                    _page <
                        _pageInfo(
                          _attendanceData?['pagination'],
                          _attendanceRecords.length,
                        ).lastPage
                    ? () {
                        _page++;
                        _loadAttendance();
                      }
                    : null,
              ),
              const SizedBox(height: 20),
              const _SectionTitle('تقارير إضافية', Icons.query_stats_rounded),
              const SizedBox(height: 12),
              _ReportActionGrid(
                onDoctorPerformance: _openDoctorPerformance,
                onLevelSummary: () =>
                    _openLevelPicker('ملخص المستوى', _openLevelSummary),
                onThreshold: () => _openThresholdPicker(),
              ),
              const SizedBox(height: 20),
              const _SectionTitle(
                'تقارير تفصيلية',
                Icons.stacked_bar_chart_rounded,
              ),
              const SizedBox(height: 12),
              ..._list(_summaryData?['subjects'])
                  .take(8)
                  .map(
                    (subject) => _SubjectReportTile(
                      subject: subject,
                      onTap: () => _openSubjectReport(subject),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _attendanceRecords =>
      _list(_attendanceData?['records']);

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(_adminOpsRepositoryProvider);
      final summary = await repo.get('/administrative/reports');
      final attendance = await repo.get(
        '/administrative/reports/attendance',
        query: _attendanceQuery(),
      );
      if (!mounted) return;
      setState(() {
        _summaryData = _map(summary['data']);
        _attendanceData = _map(attendance['data']);
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadAttendance() async {
    try {
      final response = await ref
          .read(_adminOpsRepositoryProvider)
          .get('/administrative/reports/attendance', query: _attendanceQuery());
      if (mounted) setState(() => _attendanceData = _map(response['data']));
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Map<String, dynamic> _attendanceQuery() {
    return {
      'page': _page,
      if (_majorId != null) 'major_id': _majorId,
      if (_levelId != null) 'level_id': _levelId,
      if (_searchController.text.trim().isNotEmpty)
        'search': _searchController.text.trim(),
    };
  }

  Future<void> _editAttendance(Map<String, dynamic> record) {
    return showMoeenBottomSheet<void>(
      context: context,
      title: 'تعديل حالة الحضور',
      icon: Icons.edit_calendar_rounded,
      color: AppColors.royalBlue,
      child: _AttendanceStatusForm(
        current: (record['status'] ?? 'absent').toString(),
        onSubmit: (status) async {
          try {
            final response = await ref.read(_adminOpsRepositoryProvider).patch(
              '/administrative/attendance/${record['id']}',
              {'status': status},
            );
            if (!mounted) return;
            Navigator.of(context).pop();
            await showMoeenInfoDialog(
              context: context,
              title: 'تم تعديل الحضور',
              message: (response['message'] ?? 'تم تحديث حالة الحضور.')
                  .toString(),
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
            );
            await _loadAttendance();
          } on ApiException catch (error) {
            if (!mounted) return;
            await showMoeenInfoDialog(
              context: context,
              title: 'تعذر تعديل الحضور',
              message: error.message,
              icon: Icons.error_rounded,
              color: AppColors.danger,
            );
          }
        },
      ),
    );
  }

  Future<void> _openSubjectReport(Map<String, dynamic> subject) async {
    try {
      final response = await ref
          .read(_adminOpsRepositoryProvider)
          .get(
            '/administrative/reports/subject',
            query: {'subject_id': subject['id']},
          );
      if (!mounted) return;
      await showMoeenBottomSheet<void>(
        context: context,
        title: 'تقرير المادة',
        icon: Icons.menu_book_rounded,
        color: AppColors.royalBlue,
        fullScreen: true,
        child: _SubjectReportDetails(data: _map(response['data'])),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      await showMoeenInfoDialog(
        context: context,
        title: 'تعذر فتح التقرير',
        message: error.message,
        icon: Icons.error_rounded,
        color: AppColors.danger,
      );
    }
  }

  Future<void> _openDoctorPerformance() async {
    try {
      final response = await ref
          .read(_adminOpsRepositoryProvider)
          .get('/administrative/reports/doctor-performance');
      if (!mounted) return;
      await showMoeenBottomSheet<void>(
        context: context,
        title: 'أداء الدكاترة',
        icon: Icons.school_rounded,
        color: AppColors.royalBlue,
        fullScreen: true,
        child: _SimpleListReport(
          items: _list(response['data']),
          titleOf: (item) => (item['name'] ?? '-').toString(),
          linesOf: (item) => [
            item['email']?.toString() ?? '',
            'جلسات QR: ${item['qr_sessions_count'] ?? 0}',
            'نسبة الحضور: ${item['attendance_rate'] ?? 0}%',
          ],
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      await _showError(context, error.message);
    }
  }

  Future<void> _openLevelPicker(
    String title,
    Future<void> Function(int levelId) action,
  ) {
    return showMoeenBottomSheet<void>(
      context: context,
      title: title,
      icon: Icons.layers_rounded,
      color: AppColors.teal,
      child: _LevelPickerForm(
        majors: _list(_summaryData?['majors']),
        onSubmit: action,
      ),
    );
  }

  Future<void> _openLevelSummary(int levelId) async {
    try {
      final response = await ref
          .read(_adminOpsRepositoryProvider)
          .get(
            '/administrative/reports/level-summary',
            query: {'level_id': levelId},
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      await showMoeenBottomSheet<void>(
        context: context,
        title: 'ملخص المستوى',
        icon: Icons.layers_rounded,
        color: AppColors.teal,
        fullScreen: true,
        child: _LevelSummaryReport(data: _map(response['data'])),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      await _showError(context, error.message);
    }
  }

  Future<void> _openThresholdPicker() {
    return showMoeenBottomSheet<void>(
      context: context,
      title: 'تنبيه نسبة الغياب',
      icon: Icons.warning_rounded,
      color: AppColors.goldDeep,
      child: _ThresholdReportForm(
        majors: _list(_summaryData?['majors']),
        onSubmit: _openThresholdReport,
      ),
    );
  }

  Future<void> _openThresholdReport(int levelId, int threshold) async {
    try {
      final response = await ref
          .read(_adminOpsRepositoryProvider)
          .get(
            '/administrative/reports/threshold',
            query: {'level_id': levelId, 'threshold': threshold},
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      await showMoeenBottomSheet<void>(
        context: context,
        title: 'طلاب تجاوزوا نسبة الغياب',
        icon: Icons.warning_rounded,
        color: AppColors.goldDeep,
        fullScreen: true,
        child: _ThresholdReportDetails(data: _map(response['data'])),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      await _showError(context, error.message);
    }
  }
}

class _ExamSchedulesView extends ConsumerStatefulWidget {
  const _ExamSchedulesView();

  @override
  ConsumerState<_ExamSchedulesView> createState() => _ExamSchedulesViewState();
}

class _ExamSchedulesViewState extends ConsumerState<_ExamSchedulesView> {
  Map<String, dynamic>? _data;
  Map<String, dynamic>? _createData;
  Object? _error;
  bool _loading = true;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'جداول الاختبارات',
      currentRoute: AdministrativeExamsScreen.route,
      child: _SchedulePage(
        loading: _loading,
        error: _error,
        title: 'جداول الاختبارات',
        subtitle: 'إنشاء جداول اختبارات كاملة حسب التخصص والمستوى والترم.',
        icon: Icons.event_note_rounded,
        color: AppColors.violet,
        count: _pagination.total,
        onRetry: _load,
        onCreate: _openForm,
        children: [
          if (_schedules.isEmpty)
            const _EmptyState()
          else
            ..._schedules.map(
              (item) => _ExamScheduleCard(
                item: item,
                onDetails: () => _details(item),
                onEdit: () => _openForm(item: item),
                onDelete: () => _delete(item),
              ),
            ),
          _Pagination(
            page: _pagination,
            onPrevious: _page > 1
                ? () {
                    _page--;
                    _load();
                  }
                : null,
            onNext: _page < _pagination.lastPage
                ? () {
                    _page++;
                    _load();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _schedules => _list(_data?['schedules']);
  _PageInfo get _pagination =>
      _pageInfo(_data?['pagination'], _schedules.length);

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(_adminOpsRepositoryProvider);
      final data = await repo.get(
        '/administrative/exams',
        query: {'page': _page},
      );
      final create =
          _createData ??
          _map((await repo.get('/administrative/exams/create-data'))['data']);
      if (!mounted) return;
      setState(() {
        _data = _map(data['data']);
        _createData = create;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm({Map<String, dynamic>? item}) {
    return showMoeenBottomSheet<void>(
      context: context,
      title: item == null ? 'إضافة جدول اختبارات' : 'تعديل جدول اختبارات',
      icon: Icons.event_note_rounded,
      color: AppColors.violet,
      fullScreen: true,
      child: _ExamScheduleForm(
        item: item,
        createData: _createData ?? const {},
        repository: ref.read(_adminOpsRepositoryProvider),
        onSubmit: (payload) async {
          await _save(
            item == null
                ? () => ref
                      .read(_adminOpsRepositoryProvider)
                      .post('/administrative/exams', payload)
                : () => ref
                      .read(_adminOpsRepositoryProvider)
                      .put('/administrative/exams/${item['id']}', payload),
            closeSheet: true,
          );
        },
      ),
    );
  }

  Future<void> _details(Map<String, dynamic> item) async {
    try {
      final response = await ref
          .read(_adminOpsRepositoryProvider)
          .get('/administrative/exams/${item['id']}');
      if (!mounted) return;
      await showMoeenBottomSheet<void>(
        context: context,
        title: 'تفاصيل جدول الاختبارات',
        icon: Icons.event_note_rounded,
        color: AppColors.violet,
        fullScreen: true,
        child: _ExamScheduleDetails(data: _map(response['data'])),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      await _showError(context, error.message);
    }
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final approved = await showMoeenConfirmDialog(
      context: context,
      title: 'حذف جدول الاختبارات',
      message: 'هل تريد حذف هذا الجدول؟',
      confirmLabel: 'حذف',
      icon: Icons.delete_rounded,
      color: AppColors.danger,
    );
    if (!approved) return;
    await _save(
      () => ref
          .read(_adminOpsRepositoryProvider)
          .delete('/administrative/exams/${item['id']}'),
    );
  }

  Future<void> _save(
    Future<Map<String, dynamic>> Function() action, {
    bool closeSheet = false,
  }) async {
    try {
      final response = await action();
      if (!mounted) return;
      if (closeSheet) Navigator.of(context).maybePop();
      await showMoeenInfoDialog(
        context: context,
        title: 'تمت العملية',
        message: (response['message'] ?? 'تم حفظ البيانات بنجاح.').toString(),
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
      );
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      await _showError(context, error.message);
    }
  }
}

class _LectureSchedulesView extends ConsumerStatefulWidget {
  const _LectureSchedulesView();

  @override
  ConsumerState<_LectureSchedulesView> createState() =>
      _LectureSchedulesViewState();
}

class _LectureSchedulesViewState extends ConsumerState<_LectureSchedulesView> {
  Map<String, dynamic>? _data;
  Map<String, dynamic>? _createData;
  Object? _error;
  bool _loading = true;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'جداول المحاضرات',
      currentRoute: AdministrativeSchedulesScreen.route,
      child: _SchedulePage(
        loading: _loading,
        error: _error,
        title: 'جداول المحاضرات',
        subtitle: 'تنظيم مواعيد المحاضرات والقاعات وربطها بالدكتور والمادة.',
        icon: Icons.calendar_month_rounded,
        color: AppColors.teal,
        count: _pagination.total,
        onRetry: _load,
        onCreate: _openForm,
        children: [
          if (_schedules.isEmpty)
            const _EmptyState()
          else
            ..._schedules.map(
              (item) => _LectureScheduleCard(
                item: item,
                onEdit: () => _openForm(item: item),
                onDelete: () => _delete(item),
              ),
            ),
          _Pagination(
            page: _pagination,
            onPrevious: _page > 1
                ? () {
                    _page--;
                    _load();
                  }
                : null,
            onNext: _page < _pagination.lastPage
                ? () {
                    _page++;
                    _load();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _schedules => _list(_data?['schedules']);
  _PageInfo get _pagination =>
      _pageInfo(_data?['pagination'], _schedules.length);

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(_adminOpsRepositoryProvider);
      final data = await repo.get(
        '/administrative/schedules',
        query: {'page': _page},
      );
      final create =
          _createData ??
          _map(
            (await repo.get('/administrative/schedules/create-data'))['data'],
          );
      if (!mounted) return;
      setState(() {
        _data = _map(data['data']);
        _createData = create;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm({Map<String, dynamic>? item}) {
    return showMoeenBottomSheet<void>(
      context: context,
      title: item == null ? 'إضافة جدول محاضرة' : 'تعديل جدول محاضرة',
      icon: Icons.calendar_month_rounded,
      color: AppColors.teal,
      fullScreen: true,
      child: _LectureScheduleForm(
        item: item,
        createData: _createData ?? const {},
        repository: ref.read(_adminOpsRepositoryProvider),
        onSubmit: (payload) async {
          await _save(
            item == null
                ? () => ref
                      .read(_adminOpsRepositoryProvider)
                      .post('/administrative/schedules', payload)
                : () => ref
                      .read(_adminOpsRepositoryProvider)
                      .put('/administrative/schedules/${item['id']}', payload),
            closeSheet: true,
          );
        },
      ),
    );
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final approved = await showMoeenConfirmDialog(
      context: context,
      title: 'حذف جدول المحاضرة',
      message: 'هل تريد حذف هذا الموعد من الجدول؟',
      confirmLabel: 'حذف',
      icon: Icons.delete_rounded,
      color: AppColors.danger,
    );
    if (!approved) return;
    await _save(
      () => ref
          .read(_adminOpsRepositoryProvider)
          .delete('/administrative/schedules/${item['id']}'),
    );
  }

  Future<void> _save(
    Future<Map<String, dynamic>> Function() action, {
    bool closeSheet = false,
  }) async {
    try {
      final response = await action();
      if (!mounted) return;
      if (closeSheet) Navigator.of(context).maybePop();
      await showMoeenInfoDialog(
        context: context,
        title: 'تمت العملية',
        message: (response['message'] ?? 'تم حفظ البيانات بنجاح.').toString(),
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
      );
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      await _showError(context, error.message);
    }
  }
}

class _NotificationForm extends StatefulWidget {
  const _NotificationForm({required this.data, required this.onSubmit});

  final Map<String, dynamic> data;
  final Future<void> Function(Map<String, dynamic> payload) onSubmit;

  @override
  State<_NotificationForm> createState() => _NotificationFormState();
}

class _NotificationFormState extends State<_NotificationForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _message = TextEditingController();
  final _pollOption = TextEditingController();
  final _pollOptions = <String>[];
  String _type = 'announcement';
  String _target = 'all';
  int? _majorId;
  int? _levelId;
  PlatformFile? _file;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    _pollOption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final majors = _list(widget.data['majors']);
    final selectedMajor = majors.firstWhere(
      (major) => _int(major['id']) == _majorId,
      orElse: () => const {},
    );
    final levels = _list(selectedMajor['levels']);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _text(_title, 'عنوان الإشعار'),
          _text(_message, 'نص الإشعار', maxLines: 5),
          _dropdown<String>(
            label: 'نوع الإشعار',
            value: _type,
            items: const [
              _MenuItem('announcement', 'إعلان'),
              _MenuItem('exam', 'اختبار'),
              _MenuItem('assignment', 'تكليف'),
              _MenuItem('attendance', 'حضور'),
              _MenuItem('poll', 'استبيان'),
            ],
            onChanged: (value) =>
                setState(() => _type = value ?? 'announcement'),
          ),
          _dropdown<String>(
            label: 'الفئة المستهدفة',
            value: _target,
            items: const [
              _MenuItem('all', 'كل الكلية'),
              _MenuItem('major', 'تخصص محدد'),
              _MenuItem('level', 'مستوى محدد'),
              _MenuItem('doctors', 'الدكاترة'),
              _MenuItem('delegates', 'المندوبون'),
            ],
            onChanged: (value) => setState(() {
              _target = value ?? 'all';
              _majorId = null;
              _levelId = null;
            }),
          ),
          if (_target == 'major' || _target == 'level')
            _dropdown<int>(
              label: 'التخصص',
              value: _majorId,
              items: majors
                  .map(
                    (m) =>
                        _MenuItem(_int(m['id']), (m['name'] ?? '').toString()),
                  )
                  .toList(),
              onChanged: (value) => setState(() {
                _majorId = value;
                _levelId = null;
              }),
            ),
          if (_target == 'level')
            _dropdown<int>(
              label: 'المستوى',
              value: _levelId,
              items: levels
                  .map(
                    (l) =>
                        _MenuItem(_int(l['id']), (l['name'] ?? '').toString()),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _levelId = value),
            ),
          _AttachmentPicker(
            file: _file,
            onPick: _pickFile,
            onClear: () => setState(() => _file = null),
          ),
          if (_type == 'poll')
            _PollOptionsEditor(
              controller: _pollOption,
              options: _pollOptions,
              onChanged: () => setState(() {}),
            ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _saving ? null : _submit,
            icon: const Icon(Icons.send_rounded),
            label: Text(_saving ? 'جاري الإرسال...' : 'إرسال الإشعار'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return;
    setState(() => _file = result.files.first);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_type == 'poll' && _pollOptions.length < 2) {
      await _showError(context, 'أضف خيارين على الأقل للاستبيان.');
      return;
    }
    setState(() => _saving = true);
    final payload = <String, dynamic>{
      'title': _title.text.trim(),
      'message': _message.text.trim(),
      'type': _type,
      'target': _target,
      if (_majorId != null) 'major_id': _majorId,
      if (_levelId != null) 'level_id': _levelId,
      if (_type == 'poll') 'poll_options': _pollOptions,
      if (_file?.bytes != null)
        'attachment': MultipartFile.fromBytes(
          _file!.bytes!,
          filename: _file!.name,
        ),
    };
    await widget.onSubmit(payload);
    if (mounted) setState(() => _saving = false);
  }
}

class _ExcuseReviewForm extends StatefulWidget {
  const _ExcuseReviewForm({required this.options, required this.onSubmit});

  final List<Map<String, dynamic>> options;
  final Future<void> Function(Map<String, dynamic> payload) onSubmit;

  @override
  State<_ExcuseReviewForm> createState() => _ExcuseReviewFormState();
}

class _ExcuseReviewFormState extends State<_ExcuseReviewForm> {
  final _comment = TextEditingController();
  String _status = 'accepted';
  String? _resolution;
  bool _saving = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _dropdown<String>(
          label: 'القرار',
          value: _status,
          items: const [
            _MenuItem('accepted', 'قبول العذر'),
            _MenuItem('rejected', 'رفض العذر'),
          ],
          onChanged: (value) => setState(() => _status = value ?? 'accepted'),
        ),
        if (_status == 'accepted')
          _dropdown<String>(
            label: 'الإجراء بعد القبول',
            value: _resolution,
            items: widget.options
                .map(
                  (item) => _MenuItem(
                    (item['value'] ?? '').toString(),
                    (item['label'] ?? item['value'] ?? '').toString(),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _resolution = value),
          ),
        _text(_comment, 'ملاحظة إدارية', required: false, maxLines: 3),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _saving
              ? null
              : () async {
                  if (_status == 'accepted' && (_resolution ?? '').isEmpty) {
                    await _showError(
                      context,
                      'حدد الإجراء المطلوب عند قبول العذر.',
                    );
                    return;
                  }
                  setState(() => _saving = true);
                  await widget.onSubmit({
                    'status': _status,
                    if (_status == 'accepted') 'resolution': _resolution,
                    if (_comment.text.trim().isNotEmpty)
                      'comment': _comment.text.trim(),
                  });
                  if (mounted) setState(() => _saving = false);
                },
          icon: const Icon(Icons.save_rounded),
          label: Text(_saving ? 'جاري الحفظ...' : 'حفظ القرار'),
        ),
      ],
    );
  }
}

class _AttendanceStatusForm extends StatefulWidget {
  const _AttendanceStatusForm({required this.current, required this.onSubmit});

  final String current;
  final Future<void> Function(String status) onSubmit;

  @override
  State<_AttendanceStatusForm> createState() => _AttendanceStatusFormState();
}

class _AttendanceStatusFormState extends State<_AttendanceStatusForm> {
  late String _status = widget.current;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _dropdown<String>(
          label: 'حالة الحضور',
          value: _status,
          items: const [
            _MenuItem('present', 'حاضر'),
            _MenuItem('absent', 'غائب'),
            _MenuItem('late', 'متأخر'),
            _MenuItem('excused', 'معذور'),
            _MenuItem('permitted', 'مأذون'),
            _MenuItem('exempted', 'مستثنى'),
          ],
          onChanged: (value) => setState(() => _status = value ?? 'absent'),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _saving
              ? null
              : () async {
                  setState(() => _saving = true);
                  await widget.onSubmit(_status);
                  if (mounted) setState(() => _saving = false);
                },
          icon: const Icon(Icons.save_rounded),
          label: Text(_saving ? 'جاري الحفظ...' : 'حفظ الحالة'),
        ),
      ],
    );
  }
}

class _ExamScheduleForm extends StatefulWidget {
  const _ExamScheduleForm({
    required this.item,
    required this.createData,
    required this.repository,
    required this.onSubmit,
  });

  final Map<String, dynamic>? item;
  final Map<String, dynamic> createData;
  final StaffRepository repository;
  final Future<void> Function(Map<String, dynamic> payload) onSubmit;

  @override
  State<_ExamScheduleForm> createState() => _ExamScheduleFormState();
}

class _ExamScheduleFormState extends State<_ExamScheduleForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _items = <_ExamItemDraft>[];
  int? _majorId;
  int? _levelId;
  int? _termId;
  bool _published = true;
  List<Map<String, dynamic>> _subjects = const [];
  List<Map<String, dynamic>> _terms = const [];
  bool _loadingOptions = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item ?? const <String, dynamic>{};
    _title.text = (item['title'] ?? '').toString();
    _description.text = (item['description'] ?? '').toString();
    _published = item['is_published'] != false;
    _majorId = _int(
      _map(item['major'])['id'],
      fallback: _int(item['major_id']),
    );
    _levelId = _int(
      _map(item['level'])['id'],
      fallback: _int(item['level_id']),
    );
    _termId = _int(_map(item['term'])['id'], fallback: _int(item['term_id']));
    for (final entry in _list(item['items'])) {
      _items.add(_ExamItemDraft.fromJson(entry));
    }
    if (_items.isEmpty) _items.add(_ExamItemDraft());
    if (_levelId != null && _levelId != 0) _loadSubjects(_levelId!);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final majors = _list(widget.createData['majors']);
    final selectedMajor = majors.firstWhere(
      (major) => _int(major['id']) == _majorId,
      orElse: () => const {},
    );
    final levels = _list(selectedMajor['levels']);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _text(_title, 'عنوان الجدول'),
          _text(_description, 'الوصف', required: false, maxLines: 3),
          _dropdown<int>(
            label: 'التخصص',
            value: _majorId == 0 ? null : _majorId,
            items: majors
                .map(
                  (m) => _MenuItem(_int(m['id']), (m['name'] ?? '').toString()),
                )
                .toList(),
            onChanged: (value) => setState(() {
              _majorId = value;
              _levelId = null;
              _termId = null;
              _subjects = const [];
              _terms = const [];
            }),
          ),
          _dropdown<int>(
            label: 'المستوى',
            value: _levelId == 0 ? null : _levelId,
            items: levels
                .map(
                  (l) => _MenuItem(_int(l['id']), (l['name'] ?? '').toString()),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _levelId = value;
                _termId = null;
              });
              if (value != null) _loadSubjects(value);
            },
          ),
          _dropdown<int>(
            label: 'الترم',
            value: _termId == 0 ? null : _termId,
            items: _terms
                .map(
                  (t) => _MenuItem(_int(t['id']), (t['name'] ?? '').toString()),
                )
                .toList(),
            onChanged: (value) => setState(() => _termId = value),
          ),
          SwitchListTile(
            value: _published,
            onChanged: (value) => setState(() => _published = value),
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'نشر الجدول للطلاب',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 8),
          const _SectionTitle('مواد الاختبار', Icons.list_alt_rounded),
          const SizedBox(height: 10),
          if (_loadingOptions) const LinearProgressIndicator(),
          ..._items.asMap().entries.map(
            (entry) => _ExamItemEditor(
              draft: entry.value,
              subjects: _subjects,
              onRemove: _items.length > 1
                  ? () => setState(() {
                      entry.value.dispose();
                      _items.removeAt(entry.key);
                    })
                  : null,
            ),
          ),
          TextButton.icon(
            onPressed: () => setState(() => _items.add(_ExamItemDraft())),
            icon: const Icon(Icons.add_rounded),
            label: const Text('إضافة مادة للجدول'),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saving ? null : _submit,
            icon: const Icon(Icons.save_rounded),
            label: Text(_saving ? 'جاري الحفظ...' : 'حفظ جدول الاختبارات'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSubjects(int levelId) async {
    setState(() => _loadingOptions = true);
    try {
      final response = await widget.repository.get(
        '/administrative/exams/helper/subjects/$levelId',
      );
      if (!mounted) return;
      setState(() {
        _subjects = _list(_map(response['data'])['subjects']);
        _terms = _list(_map(response['data'])['terms']);
      });
    } finally {
      if (mounted) setState(() => _loadingOptions = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await widget.onSubmit({
      'title': _title.text.trim(),
      'description': _nullable(_description.text),
      'major_id': _majorId,
      'level_id': _levelId,
      'term_id': _termId,
      'is_published': _published,
      'items': _items.map((item) => item.toJson()).toList(),
    });
    if (mounted) setState(() => _saving = false);
  }
}

class _LectureScheduleForm extends StatefulWidget {
  const _LectureScheduleForm({
    required this.item,
    required this.createData,
    required this.repository,
    required this.onSubmit,
  });

  final Map<String, dynamic>? item;
  final Map<String, dynamic> createData;
  final StaffRepository repository;
  final Future<void> Function(Map<String, dynamic> payload) onSubmit;

  @override
  State<_LectureScheduleForm> createState() => _LectureScheduleFormState();
}

class _LectureScheduleFormState extends State<_LectureScheduleForm> {
  final _formKey = GlobalKey<FormState>();
  final _hall = TextEditingController();
  final _start = TextEditingController();
  final _end = TextEditingController();
  int? _majorId;
  int? _levelId;
  int? _subjectId;
  int _day = 1;
  List<Map<String, dynamic>> _subjects = const [];
  bool _loadingSubjects = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item ?? const <String, dynamic>{};
    final subject = _map(item['subject']);
    _majorId = _int(
      _map(subject['major'])['id'],
      fallback: _int(subject['major_id']),
    );
    _levelId = _int(
      _map(subject['level'])['id'],
      fallback: _int(subject['level_id']),
    );
    _subjectId = _int(subject['id'], fallback: _int(item['subject_id']));
    _day = _int(item['day_of_week'], fallback: 1);
    _start.text = (item['start_time'] ?? '').toString();
    _end.text = (item['end_time'] ?? '').toString();
    _hall.text = (item['hall_name'] ?? '').toString();
    if (_levelId != null && _levelId != 0) _loadSubjects(_levelId!);
  }

  @override
  void dispose() {
    _hall.dispose();
    _start.dispose();
    _end.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final majors = _list(widget.createData['majors']);
    final selectedMajor = majors.firstWhere(
      (major) => _int(major['id']) == _majorId,
      orElse: () => const {},
    );
    final levels = _list(selectedMajor['levels']);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _dropdown<int>(
            label: 'التخصص',
            value: _majorId == 0 ? null : _majorId,
            items: majors
                .map(
                  (m) => _MenuItem(_int(m['id']), (m['name'] ?? '').toString()),
                )
                .toList(),
            onChanged: (value) => setState(() {
              _majorId = value;
              _levelId = null;
              _subjectId = null;
              _subjects = const [];
            }),
          ),
          _dropdown<int>(
            label: 'المستوى',
            value: _levelId == 0 ? null : _levelId,
            items: levels
                .map(
                  (l) => _MenuItem(_int(l['id']), (l['name'] ?? '').toString()),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _levelId = value;
                _subjectId = null;
              });
              if (value != null) _loadSubjects(value);
            },
          ),
          if (_loadingSubjects) const LinearProgressIndicator(),
          _dropdown<int>(
            label: 'المادة',
            value: _subjectId == 0 ? null : _subjectId,
            items: _subjects
                .map((s) => _MenuItem(_int(s['id']), _subjectLabel(s)))
                .toList(),
            onChanged: (value) => setState(() => _subjectId = value),
          ),
          _dropdown<int>(
            label: 'اليوم',
            value: _day,
            items: const [
              _MenuItem(1, 'الأحد'),
              _MenuItem(2, 'الاثنين'),
              _MenuItem(3, 'الثلاثاء'),
              _MenuItem(4, 'الأربعاء'),
              _MenuItem(5, 'الخميس'),
              _MenuItem(6, 'الجمعة'),
              _MenuItem(7, 'السبت'),
            ],
            onChanged: (value) => setState(() => _day = value ?? 1),
          ),
          _text(_start, 'وقت البداية', hint: '08:00'),
          _text(_end, 'وقت النهاية', hint: '10:00'),
          _text(_hall, 'القاعة', required: false),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saving ? null : _submit,
            icon: const Icon(Icons.save_rounded),
            label: Text(_saving ? 'جاري الحفظ...' : 'حفظ جدول المحاضرة'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSubjects(int levelId) async {
    setState(() => _loadingSubjects = true);
    try {
      final response = await widget.repository.get(
        '/administrative/schedules/helper/subjects/$levelId',
      );
      if (mounted) setState(() => _subjects = _list(response['data']));
    } finally {
      if (mounted) setState(() => _loadingSubjects = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await widget.onSubmit({
      'subject_id': _subjectId,
      'day_of_week': _day,
      'start_time': _start.text.trim(),
      'end_time': _end.text.trim(),
      'hall_name': _nullable(_hall.text),
    });
    if (mounted) setState(() => _saving = false);
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final total = _int(item['total_count']);
    final read = _int(item['read_count']);
    return _ActionCard(
      icon: Icons.campaign_rounded,
      color: AppColors.rose,
      title: (item['title'] ?? '').toString(),
      subtitle: '${_typeLabel(item['type'])} • ${item['created_at'] ?? ''}',
      chips: ['المستلمون: $total', 'المقروء: $read'],
      actions: [
        _RoundAction(
          icon: Icons.visibility_rounded,
          color: AppColors.royalBlue,
          onTap: onTap,
        ),
        _RoundAction(
          icon: Icons.delete_rounded,
          color: AppColors.danger,
          onTap: onDelete,
        ),
      ],
    );
  }
}

class _ExcuseCard extends StatelessWidget {
  const _ExcuseCard({
    required this.item,
    required this.canReview,
    required this.onReview,
  });

  final Map<String, dynamic> item;
  final bool canReview;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final student = _map(item['student']);
    final attendance = _map(item['attendance']);
    final subject = _map(attendance['subject']);
    return _ActionCard(
      icon: Icons.verified_rounded,
      color: _statusColor(item['status']),
      title: (student['name'] ?? '-').toString(),
      subtitle:
          '${subject['name'] ?? '-'} • ${attendance['date'] ?? item['created_at'] ?? ''}',
      chips: [
        _statusLabel(item['status']),
        'رقم القيد: ${student['student_number'] ?? '-'}',
        if ((item['reason'] ?? '').toString().isNotEmpty)
          item['reason'].toString(),
      ],
      actions: [
        if (canReview && item['status'] == 'pending')
          _RoundAction(
            icon: Icons.fact_check_rounded,
            color: AppColors.teal,
            onTap: onReview,
          ),
      ],
    );
  }
}

class _AttendanceRecordCard extends StatelessWidget {
  const _AttendanceRecordCard({required this.item, required this.onEdit});

  final Map<String, dynamic> item;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final student = _map(item['student']);
    final subject = _map(item['subject']);
    return _ActionCard(
      icon: Icons.fact_check_rounded,
      color: _statusColor(item['status']),
      title: (student['name'] ?? '-').toString(),
      subtitle: '${subject['name'] ?? '-'} • ${item['date'] ?? ''}',
      chips: [
        item['status_label']?.toString() ?? _attendanceLabel(item['status']),
        'رقم القيد: ${student['student_number'] ?? '-'}',
        if (item['excuse'] != null) 'يوجد عذر',
      ],
      actions: [
        _RoundAction(
          icon: Icons.edit_rounded,
          color: AppColors.royalBlue,
          onTap: onEdit,
        ),
      ],
    );
  }
}

class _ExamScheduleCard extends StatelessWidget {
  const _ExamScheduleCard({
    required this.item,
    required this.onDetails,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> item;
  final VoidCallback onDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return _ActionCard(
      icon: Icons.event_note_rounded,
      color: AppColors.violet,
      title: (item['title'] ?? '').toString(),
      subtitle:
          '${_map(item['major'])['name'] ?? '-'} / ${_map(item['level'])['name'] ?? '-'} / ${_map(item['term'])['name'] ?? '-'}',
      chips: [
        item['is_published'] == true ? 'منشور' : 'مسودة',
        'بواسطة: ${_map(item['creator'])['name'] ?? '-'}',
      ],
      actions: [
        _RoundAction(
          icon: Icons.visibility_rounded,
          color: AppColors.royalBlue,
          onTap: onDetails,
        ),
        _RoundAction(
          icon: Icons.edit_rounded,
          color: AppColors.teal,
          onTap: onEdit,
        ),
        _RoundAction(
          icon: Icons.delete_rounded,
          color: AppColors.danger,
          onTap: onDelete,
        ),
      ],
    );
  }
}

class _LectureScheduleCard extends StatelessWidget {
  const _LectureScheduleCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final subject = _map(item['subject']);
    return _ActionCard(
      icon: Icons.calendar_month_rounded,
      color: AppColors.teal,
      title: (subject['name'] ?? '-').toString(),
      subtitle:
          '${_dayLabel(item['day_of_week'])} • ${item['start_time'] ?? ''} - ${item['end_time'] ?? ''}',
      chips: [
        'القاعة: ${item['hall_name'] ?? '-'}',
        'الدكتور: ${_map(subject['doctor'])['name'] ?? '-'}',
        '${_map(subject['major'])['name'] ?? '-'} / ${_map(subject['level'])['name'] ?? '-'}',
      ],
      actions: [
        _RoundAction(
          icon: Icons.edit_rounded,
          color: AppColors.royalBlue,
          onTap: onEdit,
        ),
        _RoundAction(
          icon: Icons.delete_rounded,
          color: AppColors.danger,
          onTap: onDelete,
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.chips,
    this.actions = const [],
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final List<String> chips;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
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
                      title.isEmpty ? '-' : title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.slate500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              ...actions,
            ],
          ),
          if (chips.where((c) => c.trim().isNotEmpty).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: chips
                    .where((chip) => chip.trim().isNotEmpty)
                    .map((chip) => _ChipText(chip))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon),
      color: color,
      style: IconButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
      ),
    );
  }
}

class _OpsHero extends StatelessWidget {
  const _OpsHero({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.72)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
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
              borderRadius: BorderRadius.circular(18),
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
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w600,
                    height: 1.35,
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

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final List<_Stat> stats;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: stats
          .map(
            (stat) => SizedBox(
              width: (MediaQuery.sizeOf(context).width - 60) / 3,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: _cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(stat.icon, color: stat.color),
                    const SizedBox(height: 10),
                    Text(
                      stat.value,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      stat.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.slate500,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ReportSummaryGrid extends StatelessWidget {
  const _ReportSummaryGrid({required this.summary});

  final Map<String, dynamic> summary;

  @override
  Widget build(BuildContext context) {
    return _StatsRow(
      stats: [
        _Stat(
          'الطلاب',
          _int(summary['total_students']).toString(),
          Icons.groups_rounded,
          AppColors.teal,
        ),
        _Stat(
          'المواد',
          _int(summary['total_subjects']).toString(),
          Icons.menu_book_rounded,
          AppColors.violet,
        ),
        _Stat(
          'الحضور',
          _int(summary['present_count']).toString(),
          Icons.check_circle_rounded,
          AppColors.success,
        ),
        _Stat(
          'الغياب',
          _int(summary['absent_count']).toString(),
          Icons.cancel_rounded,
          AppColors.danger,
        ),
        _Stat(
          'الأعذار',
          _int(summary['excused_count']).toString(),
          Icons.verified_rounded,
          AppColors.goldDeep,
        ),
        _Stat(
          'حرمان',
          _int(summary['deprived_count']).toString(),
          Icons.block_rounded,
          AppColors.rose,
        ),
      ],
    );
  }
}

class _ReportFilters extends StatelessWidget {
  const _ReportFilters({
    required this.data,
    required this.majorId,
    required this.levelId,
    required this.searchController,
    required this.onMajor,
    required this.onLevel,
    required this.onSearch,
  });

  final Map<String, dynamic> data;
  final int? majorId;
  final int? levelId;
  final TextEditingController searchController;
  final ValueChanged<int?> onMajor;
  final ValueChanged<int?> onLevel;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final majors = _list(data['majors']);
    final selected = majors.firstWhere(
      (major) => _int(major['id']) == majorId,
      orElse: () => const {},
    );
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _CompactDropdown<int>(
                label: 'التخصص',
                value: majorId,
                items: majors
                    .map(
                      (m) => _MenuItem(
                        _int(m['id']),
                        (m['name'] ?? '').toString(),
                      ),
                    )
                    .toList(),
                onChanged: onMajor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CompactDropdown<int>(
                label: 'المستوى',
                value: levelId,
                items: _list(selected['levels'])
                    .map(
                      (l) => _MenuItem(
                        _int(l['id']),
                        (l['name'] ?? '').toString(),
                      ),
                    )
                    .toList(),
                onChanged: onLevel,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _SearchBox(controller: searchController, onSearch: onSearch),
      ],
    );
  }
}

class _SchedulePage extends StatelessWidget {
  const _SchedulePage({
    required this.loading,
    required this.error,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.count,
    required this.onRetry,
    required this.onCreate,
    required this.children,
  });

  final bool loading;
  final Object? error;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int count;
  final VoidCallback onRetry;
  final VoidCallback onCreate;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _ScaffoldBody(
      loading: loading,
      error: error,
      onRetry: onRetry,
      child: RefreshIndicator(
        onRefresh: () async => onRetry(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            _OpsHero(
              title: title,
              subtitle: subtitle,
              icon: icon,
              color: color,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatsRow(
                    stats: [
                      _Stat('عدد الجداول', count.toString(), icon, color),
                      _Stat(
                        'منظم',
                        'API',
                        Icons.security_rounded,
                        AppColors.success,
                      ),
                      _Stat(
                        'إدارة',
                        'CRUD',
                        Icons.tune_rounded,
                        AppColors.royalBlue,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: onCreate,
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _NotificationDetails extends StatelessWidget {
  const _NotificationDetails({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final stats = _map(data['stats']);
    final recipients = _list(data['recipients']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DetailBlock(
          title: stats['title']?.toString() ?? '-',
          lines: [
            stats['message']?.toString() ?? '',
            'النوع: ${_typeLabel(stats['type'])}',
            'المستلمون: ${stats['total_count'] ?? 0}',
            'المقروء: ${stats['read_count'] ?? 0}',
            if (stats['attachment_name'] != null)
              'المرفق: ${stats['attachment_name']}',
          ],
        ),
        if (_list(stats['poll_options']).isNotEmpty) ...[
          const SizedBox(height: 12),
          const _SectionTitle('نتائج الاستبيان', Icons.poll_rounded),
          const SizedBox(height: 8),
          ..._list(stats['poll_options']).map(
            (option) => _DetailBlock(
              title: (option['text'] ?? '').toString(),
              lines: [
                '${option['count'] ?? 0} صوت • ${option['percentage'] ?? 0}%',
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        const _SectionTitle('المستلمون', Icons.groups_rounded),
        const SizedBox(height: 8),
        ...recipients
            .take(50)
            .map(
              (user) => _DetailBlock(
                title: (user['name'] ?? '-').toString(),
                lines: [
                  user['email']?.toString() ?? '',
                  user['read_at'] == null
                      ? 'غير مقروء'
                      : 'مقروء: ${user['read_at']}',
                ],
              ),
            ),
      ],
    );
  }
}

class _SubjectReportDetails extends StatelessWidget {
  const _SubjectReportDetails({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final subject = _map(data['subject']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DetailBlock(
          title: (subject['name'] ?? 'تقرير المادة').toString(),
          lines: [
            'التخصص: ${_map(subject['major'])['name'] ?? '-'}',
            'المستوى: ${_map(subject['level'])['name'] ?? '-'}',
            'الدكتور: ${_map(subject['doctor'])['name'] ?? '-'}',
          ],
        ),
        const SizedBox(height: 12),
        ..._list(data['report']).map((row) {
          final student = _map(row['student']);
          return _DetailBlock(
            title: (student['name'] ?? '-').toString(),
            lines: [
              'حضور: ${row['present'] ?? 0} • غياب: ${row['absent'] ?? 0} • تأخير: ${row['late'] ?? 0}',
              'نسبة الغياب: ${row['absence_percentage'] ?? 0}%',
            ],
          );
        }),
      ],
    );
  }
}

class _ExamScheduleDetails extends StatelessWidget {
  const _ExamScheduleDetails({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final items = _list(data['items']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DetailBlock(
          title: (data['title'] ?? '-').toString(),
          lines: [
            '${_map(data['major'])['name'] ?? '-'} / ${_map(data['level'])['name'] ?? '-'} / ${_map(data['term'])['name'] ?? '-'}',
            data['description']?.toString() ?? '',
          ],
        ),
        const SizedBox(height: 12),
        ...items.map(
          (item) => _DetailBlock(
            title: (_map(item['subject'])['name'] ?? '-').toString(),
            lines: [
              'التاريخ: ${item['exam_date'] ?? '-'}',
              'الوقت: ${item['start_time'] ?? '-'} - ${item['end_time'] ?? '-'}',
              'المكان: ${item['location'] ?? '-'}',
            ],
          ),
        ),
      ],
    );
  }
}

class _ReportActionGrid extends StatelessWidget {
  const _ReportActionGrid({
    required this.onDoctorPerformance,
    required this.onLevelSummary,
    required this.onThreshold,
  });

  final VoidCallback onDoctorPerformance;
  final VoidCallback onLevelSummary;
  final VoidCallback onThreshold;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _ReportAction(
          'أداء الدكاترة',
          Icons.school_rounded,
          AppColors.royalBlue,
          onDoctorPerformance,
        ),
        _ReportAction(
          'ملخص المستوى',
          Icons.layers_rounded,
          AppColors.teal,
          onLevelSummary,
        ),
        _ReportAction(
          'نسبة الغياب',
          Icons.warning_rounded,
          AppColors.goldDeep,
          onThreshold,
        ),
      ],
    );
  }
}

class _ReportAction extends StatelessWidget {
  const _ReportAction(this.label, this.icon, this.color, this.onTap);

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 50) / 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelPickerForm extends StatefulWidget {
  const _LevelPickerForm({required this.majors, required this.onSubmit});

  final List<Map<String, dynamic>> majors;
  final Future<void> Function(int levelId) onSubmit;

  @override
  State<_LevelPickerForm> createState() => _LevelPickerFormState();
}

class _LevelPickerFormState extends State<_LevelPickerForm> {
  int? _majorId;
  int? _levelId;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.majors.firstWhere(
      (major) => _int(major['id']) == _majorId,
      orElse: () => const {},
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _dropdown<int>(
          label: 'التخصص',
          value: _majorId,
          items: widget.majors
              .map(
                (m) => _MenuItem(_int(m['id']), (m['name'] ?? '').toString()),
              )
              .toList(),
          onChanged: (value) => setState(() {
            _majorId = value;
            _levelId = null;
          }),
        ),
        _dropdown<int>(
          label: 'المستوى',
          value: _levelId,
          items: _list(selected['levels'])
              .map(
                (l) => _MenuItem(_int(l['id']), (l['name'] ?? '').toString()),
              )
              .toList(),
          onChanged: (value) => setState(() => _levelId = value),
        ),
        FilledButton.icon(
          onPressed: _loading || _levelId == null
              ? null
              : () async {
                  setState(() => _loading = true);
                  await widget.onSubmit(_levelId!);
                  if (mounted) setState(() => _loading = false);
                },
          icon: const Icon(Icons.visibility_rounded),
          label: Text(_loading ? 'جاري التحميل...' : 'عرض التقرير'),
        ),
      ],
    );
  }
}

class _ThresholdReportForm extends StatefulWidget {
  const _ThresholdReportForm({required this.majors, required this.onSubmit});

  final List<Map<String, dynamic>> majors;
  final Future<void> Function(int levelId, int threshold) onSubmit;

  @override
  State<_ThresholdReportForm> createState() => _ThresholdReportFormState();
}

class _ThresholdReportFormState extends State<_ThresholdReportForm> {
  final _threshold = TextEditingController(text: '75');
  int? _majorId;
  int? _levelId;
  bool _loading = false;

  @override
  void dispose() {
    _threshold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.majors.firstWhere(
      (major) => _int(major['id']) == _majorId,
      orElse: () => const {},
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _dropdown<int>(
          label: 'التخصص',
          value: _majorId,
          items: widget.majors
              .map(
                (m) => _MenuItem(_int(m['id']), (m['name'] ?? '').toString()),
              )
              .toList(),
          onChanged: (value) => setState(() {
            _majorId = value;
            _levelId = null;
          }),
        ),
        _dropdown<int>(
          label: 'المستوى',
          value: _levelId,
          items: _list(selected['levels'])
              .map(
                (l) => _MenuItem(_int(l['id']), (l['name'] ?? '').toString()),
              )
              .toList(),
          onChanged: (value) => setState(() => _levelId = value),
        ),
        _text(_threshold, 'نسبة الغياب', hint: '75'),
        FilledButton.icon(
          onPressed: _loading || _levelId == null
              ? null
              : () async {
                  setState(() => _loading = true);
                  await widget.onSubmit(
                    _levelId!,
                    _int(_threshold.text, fallback: 75),
                  );
                  if (mounted) setState(() => _loading = false);
                },
          icon: const Icon(Icons.visibility_rounded),
          label: Text(_loading ? 'جاري التحميل...' : 'عرض التقرير'),
        ),
      ],
    );
  }
}

class _SimpleListReport extends StatelessWidget {
  const _SimpleListReport({
    required this.items,
    required this.titleOf,
    required this.linesOf,
  });

  final List<Map<String, dynamic>> items;
  final String Function(Map<String, dynamic> item) titleOf;
  final List<String> Function(Map<String, dynamic> item) linesOf;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const _EmptyState();
    return Column(
      children: items
          .map(
            (item) => _DetailBlock(title: titleOf(item), lines: linesOf(item)),
          )
          .toList(),
    );
  }
}

class _LevelSummaryReport extends StatelessWidget {
  const _LevelSummaryReport({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DetailBlock(
          title: (_map(data['level'])['name'] ?? 'المستوى').toString(),
          lines: [
            'التخصص: ${_map(_map(data['level'])['major'])['name'] ?? '-'}',
            'عدد الطلاب: ${_list(data['students']).length}',
            'المندوب: ${_map(data['delegate'])['name'] ?? '-'}',
          ],
        ),
        ..._list(data['subject_stats']).map((item) {
          final subject = _map(item['subject']);
          return _DetailBlock(
            title: (subject['name'] ?? '-').toString(),
            lines: [
              'إجمالي السجلات: ${item['total_records'] ?? 0}',
              'نسبة الحضور: ${item['attendance_rate'] ?? 0}%',
            ],
          );
        }),
      ],
    );
  }
}

class _ThresholdReportDetails extends StatelessWidget {
  const _ThresholdReportDetails({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final alerts = _list(data['alerts']);
    if (alerts.isEmpty) return const _EmptyState();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: alerts.map((item) {
        final student = _map(item['student']);
        final subject = _map(item['subject']);
        return _DetailBlock(
          title: (student['name'] ?? '-').toString(),
          lines: [
            'المادة: ${subject['name'] ?? '-'}',
            'نسبة الغياب: ${item['absence_percentage'] ?? 0}%',
            'غياب ${item['absent_count'] ?? 0} من ${item['total_sessions'] ?? 0} جلسة',
          ],
        );
      }).toList(),
    );
  }
}

class _ExamItemEditor extends StatelessWidget {
  const _ExamItemEditor({
    required this.draft,
    required this.subjects,
    required this.onRemove,
  });

  final _ExamItemDraft draft;
  final List<Map<String, dynamic>> subjects;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _dropdown<int>(
                  label: 'المادة',
                  value: draft.subjectId,
                  items: subjects
                      .map(
                        (s) => _MenuItem(
                          _int(s['id']),
                          (s['name'] ?? '').toString(),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => draft.subjectId = value,
                ),
              ),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_rounded),
                  color: AppColors.danger,
                ),
            ],
          ),
          _text(draft.date, 'تاريخ الاختبار', hint: '2026-05-20'),
          Row(
            children: [
              Expanded(child: _text(draft.start, 'البداية', hint: '08:00')),
              const SizedBox(width: 10),
              Expanded(child: _text(draft.end, 'النهاية', hint: '10:00')),
            ],
          ),
          _text(draft.location, 'المكان', required: false),
        ],
      ),
    );
  }
}

class _ExamItemDraft {
  _ExamItemDraft();

  factory _ExamItemDraft.fromJson(Map<String, dynamic> json) {
    return _ExamItemDraft()
      ..subjectId = _int(
        _map(json['subject'])['id'],
        fallback: _int(json['subject_id']),
      )
      ..date.text = (json['exam_date'] ?? '').toString()
      ..start.text = (json['start_time'] ?? '').toString()
      ..end.text = (json['end_time'] ?? '').toString()
      ..location.text = (json['location'] ?? '').toString();
  }

  int? subjectId;
  final date = TextEditingController();
  final start = TextEditingController();
  final end = TextEditingController();
  final location = TextEditingController();

  Map<String, dynamic> toJson() => {
    'subject_id': subjectId,
    'exam_date': date.text.trim(),
    'start_time': start.text.trim(),
    'end_time': end.text.trim(),
    'location': _nullable(location.text),
  };

  void dispose() {
    date.dispose();
    start.dispose();
    end.dispose();
    location.dispose();
  }
}

class _ScaffoldBody extends StatelessWidget {
  const _ScaffoldBody({
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.child,
  });

  final bool loading;
  final Object? error;
  final VoidCallback onRetry;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return StatusMessage(
        title: 'تعذر تحميل البيانات',
        message: error is ApiException
            ? (error as ApiException).message
            : 'حدث خطأ أثناء تحميل الصفحة.',
        icon: Icons.error_outline_rounded,
        action: FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('إعادة المحاولة'),
        ),
      );
    }
    return child;
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.controller, required this.onSearch});

  final TextEditingController controller;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => onSearch(),
      decoration: InputDecoration(
        hintText: 'بحث...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: IconButton(
          onPressed: onSearch,
          icon: const Icon(Icons.arrow_forward_rounded),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}

class _ChoicePillBar extends StatelessWidget {
  const _ChoicePillBar({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.entries
            .map(
              (entry) => Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: ChoiceChip(
                  selected: value == entry.key,
                  label: Text(entry.value),
                  onSelected: (_) => onChanged(entry.key),
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.goldDeep.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.goldDeep.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_rounded, color: AppColors.goldDeep),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: const Column(
        children: [
          Icon(Icons.inbox_rounded, color: AppColors.slate400, size: 44),
          SizedBox(height: 8),
          Text(
            'لا توجد بيانات مطابقة حاليًا.',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
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
        Icon(icon, color: AppColors.royalBlue),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
      ],
    );
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          ...lines
              .where((line) => line.trim().isNotEmpty)
              .map(
                (line) => Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    line,
                    style: const TextStyle(
                      color: AppColors.slate600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _SubjectReportTile extends StatelessWidget {
  const _SubjectReportTile({required this.subject, required this.onTap});

  final Map<String, dynamic> subject;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _ActionCard(
      icon: Icons.menu_book_rounded,
      color: AppColors.royalBlue,
      title: (subject['name'] ?? '-').toString(),
      subtitle:
          '${_map(subject['major'])['name'] ?? '-'} / ${_map(subject['level'])['name'] ?? '-'}',
      chips: const ['تقرير المادة'],
      actions: [
        _RoundAction(
          icon: Icons.visibility_rounded,
          color: AppColors.royalBlue,
          onTap: onTap,
        ),
      ],
    );
  }
}

class _AttachmentPicker extends StatelessWidget {
  const _AttachmentPicker({
    required this.file,
    required this.onPick,
    required this.onClear,
  });

  final PlatformFile? file;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const Icon(Icons.attach_file_rounded, color: AppColors.royalBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              file?.name ?? 'لا يوجد مرفق',
              style: const TextStyle(fontWeight: FontWeight.w800),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: onPick,
            child: Text(file == null ? 'اختيار' : 'تغيير'),
          ),
          if (file != null)
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded),
            ),
        ],
      ),
    );
  }
}

class _PollOptionsEditor extends StatelessWidget {
  const _PollOptionsEditor({
    required this.controller,
    required this.options,
    required this.onChanged,
  });

  final TextEditingController controller;
  final List<String> options;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'خيارات الاستبيان',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _text(controller, 'اكتب خيارًا', required: false),
              ),
              IconButton(
                onPressed: () {
                  final value = controller.text.trim();
                  if (value.isEmpty) return;
                  options.add(value);
                  controller.clear();
                  onChanged();
                },
                icon: const Icon(Icons.add_circle_rounded),
                color: AppColors.royalBlue,
              ),
            ],
          ),
          ...options.asMap().entries.map(
            (entry) => ListTile(
              dense: true,
              title: Text(entry.value),
              trailing: IconButton(
                onPressed: () {
                  options.removeAt(entry.key);
                  onChanged();
                },
                icon: const Icon(Icons.delete_rounded),
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactDropdown<T> extends StatelessWidget {
  const _CompactDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<_MenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return _dropdown<T>(
      label: label,
      value: value,
      items: items,
      onChanged: onChanged,
      required: false,
    );
  }
}

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.page,
    required this.onPrevious,
    required this.onNext,
  });

  final _PageInfo page;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    if (page.lastPage <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
        Text(
          '${page.currentPage} / ${page.lastPage}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
      ],
    );
  }
}

class _ChipText extends StatelessWidget {
  const _ChipText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.slate600,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

Widget _text(
  TextEditingController controller,
  String label, {
  bool required = true,
  int maxLines = 1,
  String? hint,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return 'هذا الحقل مطلوب.';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}

Widget _dropdown<T>({
  required String label,
  required T? value,
  required List<_MenuItem<T>> items,
  required ValueChanged<T?> onChanged,
  bool required = true,
}) {
  final values = items.map((item) => item.value).toSet();
  final safeValue = values.contains(value) ? value : null;
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: DropdownButtonFormField<T>(
      initialValue: safeValue,
      isExpanded: true,
      validator: required
          ? (value) => value == null ? 'هذا الحقل مطلوب.' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      items: [
        if (!required)
          DropdownMenuItem<T>(value: null, child: const Text('الكل')),
        ...items.map(
          (item) => DropdownMenuItem<T>(
            value: item.value,
            child: Text(item.label, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: onChanged,
    ),
  );
}

class _Stat {
  const _Stat(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _PageInfo {
  const _PageInfo(this.currentPage, this.lastPage, this.total);

  final int currentPage;
  final int lastPage;
  final int total;
}

class _MenuItem<T> {
  const _MenuItem(this.value, this.label);

  final T value;
  final String label;
}

_PageInfo _pageInfo(Object? value, int fallbackTotal) {
  final map = _map(value);
  if (map.isEmpty) return _PageInfo(1, 1, fallbackTotal);
  return _PageInfo(
    _int(map['current_page'], fallback: 1),
    _int(map['last_page'], fallback: 1),
    _int(map['total'], fallback: fallbackTotal),
  );
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: AppColors.slate200),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.035),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

Future<void> _showError(BuildContext context, String message) {
  return showMoeenInfoDialog(
    context: context,
    title: 'تعذرت العملية',
    message: message,
    icon: Icons.error_rounded,
    color: AppColors.danger,
  );
}

String _typeLabel(Object? value) {
  return switch ((value ?? '').toString()) {
    'exam' => 'اختبار',
    'assignment' => 'تكليف',
    'attendance' => 'حضور',
    'poll' => 'استبيان',
    _ => 'إعلان',
  };
}

String _statusLabel(Object? value) {
  return switch ((value ?? '').toString()) {
    'accepted' => 'مقبول',
    'rejected' => 'مرفوض',
    'pending' => 'معلق',
    _ => value?.toString() ?? '-',
  };
}

String _attendanceLabel(Object? value) {
  return switch ((value ?? '').toString()) {
    'present' => 'حاضر',
    'absent' => 'غائب',
    'late' => 'متأخر',
    'excused' => 'معذور',
    'permitted' => 'مأذون',
    'exempted' => 'مستثنى',
    _ => value?.toString() ?? '-',
  };
}

Color _statusColor(Object? value) {
  return switch ((value ?? '').toString()) {
    'accepted' || 'present' => AppColors.success,
    'rejected' || 'absent' => AppColors.danger,
    'pending' || 'late' => AppColors.goldDeep,
    _ => AppColors.royalBlue,
  };
}

String _dayLabel(Object? value) {
  return switch (_int(value, fallback: 1)) {
    1 => 'الأحد',
    2 => 'الاثنين',
    3 => 'الثلاثاء',
    4 => 'الأربعاء',
    5 => 'الخميس',
    6 => 'الجمعة',
    7 => 'السبت',
    _ => '-',
  };
}

String _subjectLabel(Map<String, dynamic> subject) {
  final doctor = _map(subject['doctor'])['name'];
  final name = (subject['name'] ?? '-').toString();
  return doctor == null ? name : '$name - $doctor';
}

String? _nullable(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

List<Map<String, dynamic>> _list(Object? value) {
  if (value is List) return value.whereType<Map>().map(_map).toList();
  return const [];
}

int _int(Object? value, {int fallback = 0}) {
  if (value == null) return fallback;
  return int.tryParse(value.toString()) ?? fallback;
}
