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
    final stats = _map(_data?['stats']);
    final statItems = [
      _Stat('الكل', _int(stats['all']).toString(),
          Icons.inbox_rounded, AppColors.royalBlue),
      _Stat('قيد المراجعة', _int(stats['pending']).toString(),
          Icons.hourglass_empty_rounded, AppColors.goldDeep),
      _Stat('مقبولة', _int(stats['accepted']).toString(),
          Icons.check_circle_rounded, AppColors.success),
    ];

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
              // ── Premium Excuse Hero ───────────────────────────────────
              _ExcuseScreenHero(
                total: _int(stats['all']),
                pending: _int(stats['pending']),
              ),
              const SizedBox(height: 16),

              // ── Stats Row ────────────────────────────────────────────
              _StatsRow(stats: statItems),
              const SizedBox(height: 14),

              // ── Unified Filter + Search Panel ────────────────────────
              _ExcuseFilterPanel(
                status: _status,
                controller: _searchController,
                onStatusChanged: (value) {
                  setState(() { _status = value; _page = 1; });
                  _load();
                },
                onSearch: () { _page = 1; _load(); },
              ),
              const SizedBox(height: 16),

              // ── Notice (view-only mode) ──────────────────────────────
              if (!(_data?['can_review'] == true))
                const _NoticeCard(
                  message:
                      'استقبال الأعذار مضبوط حاليًا على دكتور المادة، لذلك هذه الصفحة للعرض فقط.',
                ),

              // ── Excuse List ──────────────────────────────────────────
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

              // ── Pagination ───────────────────────────────────────────
              _Pagination(
                page: _pageInfo(_data?['pagination'], _excuses.length),
                onPrevious: _page > 1
                    ? () { _page--; _load(); }
                    : null,
                onNext: _page <
                        _pageInfo(_data?['pagination'], _excuses.length).lastPage
                    ? () { _page++; _load(); }
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
  final _searchController = TextEditingController();
  Map<String, dynamic>? _data;
  Map<String, dynamic>? _createData;
  Object? _error;
  bool _loading = true;
  int _page = 1;
  int? _majorId;
  int? _levelId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _load();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<bool> _onBackPressed() async {
    if (_majorId != null) {
      _clearMajor();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_majorId == null) {
      return StaffShell(
        title: 'جداول الاختبارات',
        currentRoute: AdministrativeExamsScreen.route,
        onBackPressed: _onBackPressed,
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
                  title: 'اختيار التخصص',
                  subtitle:
                      'حدد التخصص أولًا لعرض جداول الاختبارات الخاصة به فقط.',
                  icon: Icons.account_tree_rounded,
                  color: AppColors.royalBlue,
                ),
                const SizedBox(height: 16),
                _SearchBox(
                  controller: _searchController,
                  onSearch: _onSearchChanged,
                ),
                const SizedBox(height: 16),
                if (_filteredMajors.isEmpty)
                  const _EmptyState()
                else
                  ..._filteredMajors.map(
                    (major) => _ExamMajorCard(
                      major: major,
                      onTap: () => _selectMajor(_int(major['id'])),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return StaffShell(
      title: 'جداول الاختبارات',
      currentRoute: AdministrativeExamsScreen.route,
      onBackPressed: _onBackPressed,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        backgroundColor: AppColors.royalBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'إضافة جدول اختبارات',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
      child: _SchedulePage(
        loading: _loading,
        error: _error,
        title: 'جداول الاختبارات',
        subtitle: 'إنشاء جداول اختبارات كاملة حسب التخصص والمستوى والترم.',
        icon: Icons.event_note_rounded,
        color: AppColors.royalBlue,
        count: _searchController.text.trim().isEmpty
            ? _pagination.total
            : _schedules.length,
        onRetry: _load,
        children: [
          _ExamMajorHeader(
            major: _selectedMajor,
            onChange: _clearMajor,
          ),
          const SizedBox(height: 12),
          _ExamLevelFilters(
            data: _createData ?? const {},
            majorId: _majorId,
            levelId: _levelId,
            searchController: _searchController,
            onLevel: (value) {
              setState(() {
                _levelId = value;
              });
              _load();
            },
            onSearch: _onSearchChanged,
          ),
          const SizedBox(height: 16),
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
          if (_searchController.text.trim().isEmpty)
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

  List<Map<String, dynamic>> get _allSchedules => _list(_data?['schedules']);
  List<Map<String, dynamic>> get _schedules {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _allSchedules;

    return _allSchedules.where((item) {
      final haystack = [
        item['title'],
        item['description'],
        _map(item['major'])['name'],
        _map(item['level'])['name'],
        _map(item['term'])['name'],
        _map(item['creator'])['name'],
        ..._list(item['items']).map((entry) => _map(entry['subject'])['name']),
      ].whereType<Object>().map((value) => value.toString().toLowerCase()).join(' ');
      return haystack.contains(query);
    }).toList();
  }
  _PageInfo get _pagination =>
      _pageInfo(_data?['pagination'], _allSchedules.length);

  List<Map<String, dynamic>> get _majors => _list(_createData?['majors']);

  Map<String, dynamic> get _selectedMajor => _majors.firstWhere(
        (major) => _int(major['id']) == _majorId,
        orElse: () => const {},
      );

  List<Map<String, dynamic>> get _filteredMajors {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _majors;
    return _majors.where((major) {
      final name = (major['name'] ?? '').toString().toLowerCase();
      return name.contains(query);
    }).toList();
  }

  void _onSearchChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _selectMajor(int id) {
    _searchController.clear();
    setState(() {
      _majorId = id;
      _levelId = null;
      _page = 1;
      _data = null;
    });
    _load();
  }

  void _clearMajor() {
    _searchController.clear();
    setState(() {
      _majorId = null;
      _levelId = null;
      _page = 1;
      _data = null;
    });
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(_adminOpsRepositoryProvider);
      final create =
          _createData ??
          _map((await repo.get('/administrative/exams/create-data'))['data']);
      if (_majorId == null) {
        if (!mounted) return;
        setState(() {
          _createData = create;
          _data = null;
        });
        return;
      }

      final query = {
        'page': _page,
        'major_id': _majorId,
        if (_levelId != null) 'level_id': _levelId,
      };
      final data = await repo.get(
        '/administrative/exams',
        query: query,
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
      title: item == null ? 'إضافة جدول اختبارات' : 'تعديل جدول اختبارات',
      icon: Icons.event_note_rounded,
      color: AppColors.royalBlue,
      fullScreen: true,
      child: _ExamScheduleForm(
        item: item,
        fixedMajorId: item == null ? _majorId : null,
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
        color: AppColors.royalBlue,
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

class _LectureSchedulesViewState extends ConsumerState<_LectureSchedulesView>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  Map<String, dynamic>? _data;
  Map<String, dynamic>? _createData;
  Object? _error;
  bool _loading = true;
  int? _majorId;
  int? _levelId;
  late TabController _tabController;
  final List<int> _daysOrder = [7, 1, 2, 3, 4, 5, 6]; // Sat to Fri (mapped: 7=Sat, 1=Sun, 2=Mon, 3=Tue, 4=Wed, 5=Thu, 6=Fri)

  int _doctorDayFromDateTime(int weekday) {
    if (weekday == DateTime.sunday) return 1;
    return weekday + 1;
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    
    final now = DateTime.now();
    int currentDay = _doctorDayFromDateTime(now.weekday);
    int initialIndex = _daysOrder.indexOf(currentDay);
    if (initialIndex == -1) initialIndex = 0;
    
    _tabController = TabController(
      length: _daysOrder.length,
      vsync: this,
      initialIndex: initialIndex,
    );
    _load();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<bool> _onBackPressed() async {
    if (_majorId != null) {
      _clearMajor();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_majorId == null) {
      return StaffShell(
        title: 'جداول المحاضرات',
        currentRoute: AdministrativeSchedulesScreen.route,
        onBackPressed: _onBackPressed,
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
                  title: 'اختيار التخصص',
                  subtitle:
                      'حدد التخصص أولًا لعرض جداول المحاضرات الخاصة به فقط.',
                  icon: Icons.account_tree_rounded,
                  color: AppColors.teal,
                ),
                const SizedBox(height: 16),
                _SearchBox(
                  controller: _searchController,
                  onSearch: _onSearchChanged,
                ),
                const SizedBox(height: 16),
                if (_filteredMajors.isEmpty)
                  const _EmptyState()
                else
                  ..._filteredMajors.map(
                    (major) => _ExamMajorCard(
                      major: major,
                      onTap: () => _selectMajor(_int(major['id'])),
                      countKey: 'lecture_schedules_count',
                      countLabel: 'جداول محاضرات',
                      color: AppColors.teal,
                      icon: Icons.calendar_month_rounded,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return StaffShell(
      title: 'جداول المحاضرات',
      currentRoute: AdministrativeSchedulesScreen.route,
      onBackPressed: _onBackPressed,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'إضافة جدول محاضرات',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
      child: _ScaffoldBody(
        loading: _loading,
        error: _error,
        onRetry: _load,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _OpsHero(
                      title: 'جداول المحاضرات',
                      subtitle: 'تنظيم مواعيد المحاضرات والقاعات وربطها بالدكتور والمادة.',
                      icon: Icons.calendar_month_rounded,
                      color: AppColors.teal,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.teal.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.teal.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, color: AppColors.teal, size: 20),
                          const SizedBox(width: 10),
                          const Text(
                            'إجمالي الجداول المسجلة',
                            style: TextStyle(
                              color: AppColors.midnight,
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.teal,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _searchController.text.trim().isEmpty
                                  ? _pagination.total.toString()
                                  : _schedules.length.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ExamMajorHeader(
                      major: _selectedMajor,
                      onChange: _clearMajor,
                      color: AppColors.teal,
                    ),
                    const SizedBox(height: 12),
                    _ExamLevelFilters(
                      data: _createData ?? const {},
                      majorId: _majorId,
                      levelId: _levelId,
                      searchController: _searchController,
                      onLevel: (value) {
                        setState(() {
                          _levelId = value;
                        });
                        _load();
                      },
                      onSearch: _onSearchChanged,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SchedulesSliverAppBarDelegate(
                height: 74,
                child: Container(
                  color: AppColors.cream,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.slate200.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: AppColors.teal,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.teal.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.slate600,
                      labelStyle: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      tabs: _daysOrder.map((day) {
                        final count = _schedules
                            .where((item) => _int(item['day_of_week']) == day)
                            .length;
                        return Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_dayLabel(day)),
                              if (count > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    count.toString(),
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: _daysOrder.map((day) {
              final dayItems = _schedules
                  .where((item) => _int(item['day_of_week']) == day)
                  .toList();
              if (dayItems.isEmpty) {
                return _DailyEmptyState(dayName: _dayLabel(day));
              }
              return RefreshIndicator(
                onRefresh: _load,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  itemCount: dayItems.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = dayItems[index];
                    return _LectureScheduleCard(
                      item: item,
                      onEdit: () => _openForm(item: item),
                      onDelete: () => _delete(item),
                    );
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _allSchedules => _list(_data?['schedules']);
  List<Map<String, dynamic>> get _schedules {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _allSchedules;

    return _allSchedules.where((item) {
      final subject = _map(item['subject']);
      final haystack = [
        subject['name'],
        _map(subject['major'])['name'],
        _map(subject['level'])['name'],
        _map(subject['doctor'])['name'],
        item['hall_name'],
        _dayLabel(item['day_of_week']),
      ].whereType<Object>().map((value) => value.toString().toLowerCase()).join(' ');
      return haystack.contains(query);
    }).toList();
  }
  _PageInfo get _pagination =>
      _pageInfo(_data?['pagination'], _allSchedules.length);

  List<Map<String, dynamic>> get _majors => _list(_createData?['majors']);

  Map<String, dynamic> get _selectedMajor => _majors.firstWhere(
        (major) => _int(major['id']) == _majorId,
        orElse: () => const {},
      );

  List<Map<String, dynamic>> get _filteredMajors {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _majors;
    return _majors.where((major) {
      final name = (major['name'] ?? '').toString().toLowerCase();
      return name.contains(query);
    }).toList();
  }

  void _onSearchChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _selectMajor(int id) {
    _searchController.clear();
    setState(() {
      _majorId = id;
      _levelId = null;
      _data = null;
    });
    _load();
  }

  void _clearMajor() {
    _searchController.clear();
    setState(() {
      _majorId = null;
      _levelId = null;
      _data = null;
    });
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(_adminOpsRepositoryProvider);
      final create =
          _createData ??
          _map(
            (await repo.get('/administrative/schedules/create-data'))['data'],
          );
      if (_majorId == null) {
        if (!mounted) return;
        setState(() {
          _createData = create;
          _data = null;
        });
        return;
      }

      final query = {
        'page': 1,
        'major_id': _majorId,
        if (_levelId != null) 'level_id': _levelId,
        'per_page': 100,
      };
      final data = await repo.get(
        '/administrative/schedules',
        query: query,
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
        fixedMajorId: item == null ? _majorId : null,
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
        // ── Visual Accept / Reject Selector ──────────────────────────────
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
            'قرار العذر',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w900,
              fontSize: 13.5,
              color: AppColors.midnight,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _DecisionTile(
                selected: _status == 'accepted',
                label: 'قبول العذر',
                icon: Icons.check_circle_rounded,
                color: AppColors.success,
                onTap: () => setState(() => _status = 'accepted'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DecisionTile(
                selected: _status == 'rejected',
                label: 'رفض العذر',
                icon: Icons.cancel_rounded,
                color: AppColors.danger,
                onTap: () => setState(() => _status = 'rejected'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Resolution Dropdown (accepted only) ──────────────────────────
        if (_status == 'accepted') ...[
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
          const SizedBox(height: 4),
        ],

        // ── Admin Note ───────────────────────────────────────────────────
        _text(_comment, 'ملاحظة إدارية (اختياري)', required: false, maxLines: 3),
        const SizedBox(height: 20),

        // ── Submit ───────────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: _status == 'accepted'
                  ? [AppColors.success, AppColors.success.withValues(alpha: 0.8)]
                  : [AppColors.danger, AppColors.danger.withValues(alpha: 0.8)],
            ),
            boxShadow: [
              BoxShadow(
                color: (_status == 'accepted' ? AppColors.success : AppColors.danger)
                    .withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FilledButton.icon(
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
            style: FilledButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: _saving
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white,
                    ),
                  )
                : Icon(
                    _status == 'accepted'
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                  ),
            label: Text(
              _saving
                  ? 'جاري الحفظ...'
                  : _status == 'accepted'
                      ? 'تأكيد قبول العذر'
                      : 'تأكيد رفض العذر',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
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
    required this.fixedMajorId,
    required this.createData,
    required this.repository,
    required this.onSubmit,
  });

  final Map<String, dynamic>? item;
  final int? fixedMajorId;
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
      fallback: _int(item['major_id'], fallback: widget.fixedMajorId ?? 0),
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
          if (widget.fixedMajorId != null && widget.item == null)
            _LockedExamMajor(major: selectedMajor),
          if (!(widget.fixedMajorId != null && widget.item == null))
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
              index: entry.key + 1,
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
          OutlinedButton.icon(
            onPressed: () => setState(() => _items.add(_ExamItemDraft())),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text(
              'إضافة مادة للجدول',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.royalBlue,
              side: const BorderSide(color: AppColors.royalBlue),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saving ? null : _submit,
            icon: const Icon(Icons.save_rounded, size: 18),
            label: Text(
              _saving ? 'جاري الحفظ...' : 'حفظ جدول الاختبارات',
              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.royalBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
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
    required this.fixedMajorId,
    required this.createData,
    required this.repository,
    required this.onSubmit,
  });

  final Map<String, dynamic>? item;
  final int? fixedMajorId;
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
      fallback: _int(subject['major_id'], fallback: widget.fixedMajorId ?? 0),
    );
    _levelId = _int(
      _map(subject['level'])['id'],
      fallback: _int(subject['level_id']),
    );
    _subjectId = _int(subject['id'], fallback: _int(item['subject_id']));
    _day = _int(item['day_of_week'], fallback: 1);
    _start.text = _ExamItemDraft._cleanTime(item['start_time']?.toString());
    _end.text = _ExamItemDraft._cleanTime(item['end_time']?.toString());
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
          if (widget.fixedMajorId != null && widget.item == null)
            _LockedExamMajor(major: selectedMajor, color: AppColors.teal),
          if (!(widget.fixedMajorId != null && widget.item == null))
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
          _text(
            _start,
            'وقت البداية',
            hint: 'اختر وقت البداية',
            readOnly: true,
            onTap: () async {
              TimeOfDay initialTime = TimeOfDay.now();
              final parts = _start.text.split(':');
              if (parts.length == 2) {
                final h = int.tryParse(parts[0]);
                final m = int.tryParse(parts[1]);
                if (h != null && m != null) {
                  initialTime = TimeOfDay(hour: h, minute: m);
                }
              }
              final time = await showTimePicker(
                context: context,
                initialTime: initialTime,
              );
              if (time != null) {
                _start.text = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
              }
            },
          ),
          _text(
            _end,
            'وقت النهاية',
            hint: 'اختر وقت النهاية',
            readOnly: true,
            onTap: () async {
              TimeOfDay initialTime = TimeOfDay.now();
              final parts = _end.text.split(':');
              if (parts.length == 2) {
                final h = int.tryParse(parts[0]);
                final m = int.tryParse(parts[1]);
                if (h != null && m != null) {
                  initialTime = TimeOfDay(hour: h, minute: m);
                }
              }
              final time = await showTimePicker(
                context: context,
                initialTime: initialTime,
              );
              if (time != null) {
                _end.text = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
              }
            },
          ),
          _text(_hall, 'القاعة', required: false),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saving ? null : _submit,
            icon: const Icon(Icons.save_rounded, size: 18),
            label: Text(
              _saving ? 'جاري الحفظ...' : 'حفظ جدول المحاضرة',
              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
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
    final status = (item['status'] ?? '').toString();
    final color = _statusColor(status);
    final reason = (item['reason'] ?? '').toString();
    final date = (attendance['date'] ?? item['created_at'] ?? '').toString();
    final isPending = status == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status accent bar ────────────────────────────────────────
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.4)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header: Avatar + Name + Status Badge ─────────────
                Row(
                  children: [
                    // Avatar with initials
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withValues(alpha: 0.2),
                            color.withValues(alpha: 0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _getStudentInitials((student['name'] ?? '').toString()),
                        style: TextStyle(
                          color: color,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (student['name'] ?? '-').toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w900,
                              fontSize: 14.5,
                              color: AppColors.midnight,
                            ),
                          ),
                          Text(
                            'رقم القيد: ${student['student_number'] ?? '-'}',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              color: AppColors.slate400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            switch (status) {
                              'accepted' => Icons.check_circle_rounded,
                              'rejected' => Icons.cancel_rounded,
                              _ => Icons.hourglass_empty_rounded,
                            },
                            color: color,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _statusLabel(status),
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w900,
                              fontSize: 10.5,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Meta Info Chips ───────────────────────────────────
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoCapsule(
                      icon: Icons.menu_book_rounded,
                      text: (subject['name'] ?? '-').toString(),
                      color: AppColors.royalBlue,
                    ),
                    _InfoCapsule(
                      icon: Icons.calendar_today_rounded,
                      text: date.length >= 10 ? date.substring(0, 10) : date,
                      color: AppColors.slate500,
                    ),
                  ],
                ),

                // ── Reason Quote ─────────────────────────────────────
                if (reason.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.goldDeep.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.goldDeep.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.format_quote_rounded,
                          color: AppColors.goldDeep,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            reason,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.slate600,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Review Button (pending only) ──────────────────────
                if (canReview && isPending) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onReview,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        shadowColor: AppColors.teal.withValues(alpha: 0.3),
                        elevation: 4,
                      ),
                      icon: const Icon(Icons.fact_check_rounded, size: 18),
                      label: const Text(
                        'مراجعة واتخاذ قرار',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Helper: get Arabic initials
String _getStudentInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || name.isEmpty) return '؟';
  if (parts.length == 1) return parts[0][0];
  return '${parts[0][0]}${parts[1][0]}';
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

  Widget _buildPill(String text, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final majorName = _map(item['major'])['name'] ?? '-';
    final levelName = _map(item['level'])['name'] ?? '-';
    final termName = _map(item['term'])['name'] ?? '-';
    final creatorName = _map(item['creator'])['name'] ?? '-';
    final isPublished = item['is_published'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.royalBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.event_note_rounded,
                    color: AppColors.royalBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (item['title'] ?? '-').toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: AppColors.midnight,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$majorName / $levelName / $termName',
                        style: const TextStyle(
                          color: AppColors.slate500,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _buildPill(
                  isPublished ? 'منشور' : 'مسودة',
                  isPublished ? AppColors.success : AppColors.warning,
                  icon: isPublished ? Icons.check_circle_rounded : Icons.edit_attributes_rounded,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPill(
                  'بواسطة: $creatorName',
                  AppColors.slate600,
                  icon: Icons.person_rounded,
                ),
                if (item['items'] != null)
                  _buildPill(
                    'المواد: ${_list(item['items']).length}',
                    AppColors.royalBlue,
                    icon: Icons.menu_book_rounded,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.slate100),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: onDetails,
                    icon: const Icon(Icons.visibility_rounded, size: 16),
                    label: const Text(
                      'عرض التفاصيل',
                      style: TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Cairo', fontSize: 13),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.royalBlue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text(
                      'تعديل',
                      style: TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Cairo', fontSize: 13),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_rounded, size: 16),
                    label: const Text(
                      'حذف',
                      style: TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Cairo', fontSize: 13),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
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
    final subjectName = (subject['name'] ?? '-').toString();
    final doctorName = _map(subject['doctor'])['name'] ?? '-';
    final majorName = _map(subject['major'])['name'] ?? '-';
    final levelName = _map(subject['level'])['name'] ?? '-';
    final hallName = item['hall_name'] ?? '-';
    final startTime = _formatTime(item['start_time']?.toString() ?? '');
    final endTime = _formatTime(item['end_time']?.toString() ?? '');
    final isLive = _isTimeInRange(item['start_time']?.toString() ?? '', item['end_time']?.toString() ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLive ? AppColors.teal : AppColors.slate200,
          width: isLive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 85,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
              decoration: BoxDecoration(
                color: isLive
                    ? AppColors.teal.withValues(alpha: 0.05)
                    : AppColors.slate50,
                border: BorderDirectional(
                  end: BorderSide(
                    color: isLive
                        ? AppColors.teal.withValues(alpha: 0.2)
                        : AppColors.slate200,
                  ),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    startTime,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Cairo',
                      color: isLive ? AppColors.teal : AppColors.midnight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 20,
                    width: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          isLive ? AppColors.teal : AppColors.slate300,
                          isLive
                              ? AppColors.teal.withValues(alpha: 0)
                              : AppColors.slate200.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    endTime,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Cairo',
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            subjectName,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Cairo',
                              color: AppColors.midnight,
                              height: 1.25,
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert_rounded,
                            color: AppColors.slate400,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          onSelected: (value) {
                            if (value == 'edit') {
                              onEdit();
                            } else if (value == 'delete') {
                              onDelete();
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit_rounded,
                                    size: 18,
                                    color: AppColors.teal,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'تعديل',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                    color: AppColors.danger,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'حذف',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.danger,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _IconInfo(
                      icon: Icons.person_rounded,
                      text: 'الدكتور: $doctorName',
                      color: AppColors.slate600,
                    ),
                    const SizedBox(height: 6),
                    _IconInfo(
                      icon: Icons.room_rounded,
                      text: 'القاعة: $hallName',
                      color: AppColors.teal,
                    ),
                    const SizedBox(height: 6),
                    _IconInfo(
                      icon: Icons.school_rounded,
                      text: '$majorName / $levelName',
                      color: AppColors.royalBlue,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ──────────────────────────────────────────────────────────────────────────
// Excuse Screen Hero — Premium identity banner for the excuse screen
// ──────────────────────────────────────────────────────────────────────────
class _ExcuseScreenHero extends StatelessWidget {
  const _ExcuseScreenHero({required this.total, required this.pending});

  final int total;
  final int pending;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B3E),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D1B3E).withValues(alpha: 0.4),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Teal glow accent
          Positioned(
            top: -30, right: -30,
            child: Container(
              width: 130, height: 130,
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Top teal line
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.teal.withValues(alpha: 0),
                    AppColors.teal,
                    AppColors.teal.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.teal.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: AppColors.teal,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'إدارة الأعذار',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'مراجعة أعذار الطلاب واتخاذ القرار المناسب',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: AppColors.slate400,
                        ),
                      ),
                    ],
                  ),
                ),
                // Pending badge
                if (pending > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.goldDeep.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.goldDeep.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          pending.toString(),
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: AppColors.goldDeep,
                          ),
                        ),
                        const Text(
                          'معلقة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            color: AppColors.goldDeep,
                          ),
                        ),
                      ],
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

// ──────────────────────────────────────────────────────────────────────────
// Excuse Filter Panel — Unified search + status pills panel
// ──────────────────────────────────────────────────────────────────────────
class _ExcuseFilterPanel extends StatelessWidget {
  const _ExcuseFilterPanel({
    required this.status,
    required this.controller,
    required this.onStatusChanged,
    required this.onSearch,
  });

  final String status;
  final TextEditingController controller;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          // Search input
          _SearchBox(controller: controller, onSearch: onSearch),
          const SizedBox(height: 12),
          // Status pills
          _ChoicePillBar(
            value: status,
            items: const {
              'all': 'الكل',
              'pending': 'معلقة',
              'accepted': 'مقبولة',
              'rejected': 'مرفوضة',
            },
            onChanged: onStatusChanged,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Decision Tile — Visual accept/reject selector button
// ──────────────────────────────────────────────────────────────────────────
class _DecisionTile extends StatelessWidget {
  const _DecisionTile({
    required this.selected,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : AppColors.slate50,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? color : AppColors.slate200,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected
                    ? color.withValues(alpha: 0.12)
                    : AppColors.slate200.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: selected ? color : AppColors.slate400,
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: selected ? color : AppColors.slate500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Info Capsule — Metadata chip for excuse cards
// ──────────────────────────────────────────────────────────────────────────
class _InfoCapsule extends StatelessWidget {
  const _InfoCapsule({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
              color: color,
            ),
          ),
        ],
      ),
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
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B3E),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D1B3E).withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Accent color glow
          Positioned(
            top: -20, right: -20,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Top accent line
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0),
                    color,
                    color.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: color.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(icon, color: color, size: 28),
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
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.slate400,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ],
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
    final itemWidth = (MediaQuery.sizeOf(context).width - 60) / 3;
    return Row(
      children: stats.asMap().entries.map((entry) {
        final i = entry.key;
        final stat = entry.value;
        return [
          SizedBox(
            width: itemWidth,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.slate100),
                boxShadow: [
                  BoxShadow(
                    color: stat.color.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Color line at top
                  Container(
                    height: 3,
                    width: 28,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: stat.color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Text(
                    stat.value,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: stat.color,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stat.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: AppColors.slate500,
                      fontWeight: FontWeight.w700,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (i < stats.length - 1) const SizedBox(width: 10),
        ];
      }).expand((x) => x).toList(),
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

class _ExamMajorCard extends StatelessWidget {
  const _ExamMajorCard({
    required this.major,
    required this.onTap,
    this.countKey = 'exam_schedules_count',
    this.countLabel = 'جداول اختبارات',
    this.color = AppColors.royalBlue,
    this.icon = Icons.account_tree_rounded,
  });

  final Map<String, dynamic> major;
  final VoidCallback onTap;
  final String countKey;
  final String countLabel;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final levels = _list(major['levels']);
    final schedulesCount = _int(major[countKey]);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.slate100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                icon,
                color: color,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (major['name'] ?? '-').toString(),
                    style: const TextStyle(
                      color: AppColors.midnight,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _ChipText('${levels.length} مستويات'),
                      _ChipText('$schedulesCount $countLabel'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamMajorHeader extends StatelessWidget {
  const _ExamMajorHeader({
    required this.major,
    required this.onChange,
    this.color = AppColors.royalBlue,
  });

  final Map<String, dynamic> major;
  final VoidCallback onChange;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(Icons.account_tree_rounded, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'التخصص الحالي',
                  style: TextStyle(
                    color: AppColors.slate500,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
                Text(
                  (major['name'] ?? '-').toString(),
                  style: const TextStyle(
                    color: AppColors.midnight,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onChange,
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: const Text('تغيير'),
            style: TextButton.styleFrom(
              foregroundColor: color,
              textStyle: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedExamMajor extends StatelessWidget {
  const _LockedExamMajor({
    required this.major,
    this.color = AppColors.royalBlue,
  });

  final Map<String, dynamic> major;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_rounded, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'التخصص: ${(major['name'] ?? '-').toString()}',
              style: const TextStyle(
                color: AppColors.midnight,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamLevelFilters extends StatelessWidget {
  const _ExamLevelFilters({
    required this.data,
    required this.majorId,
    required this.levelId,
    required this.searchController,
    required this.onLevel,
    required this.onSearch,
  });

  final Map<String, dynamic> data;
  final int? majorId;
  final int? levelId;
  final TextEditingController searchController;
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
        _CompactDropdown<int>(
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
        const SizedBox(height: 10),
        _SearchBox(controller: searchController, onSearch: onSearch),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 10),
                  const Text(
                    'إجمالي الجداول المسجلة',
                    style: TextStyle(
                      color: AppColors.midnight,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ],
              ),
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

  Map<String, String> _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return {'day': '-', 'month': 'التاريخ'};
    }
    try {
      final parsed = DateTime.tryParse(dateStr);
      if (parsed != null) {
        final months = [
          'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
          'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
        ];
        return {
          'day': parsed.day.toString(),
          'month': months[parsed.month - 1],
        };
      }
    } catch (_) {}

    final parts = dateStr.split(RegExp(r'[-/]'));
    if (parts.length >= 3) {
      if (parts[0].length == 4) {
        final monthIdx = int.tryParse(parts[1]);
        final months = [
          'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
          'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
        ];
        final monthName = (monthIdx != null && monthIdx >= 1 && monthIdx <= 12)
            ? months[monthIdx - 1]
            : parts[1];
        return {
          'day': parts[2],
          'month': monthName,
        };
      } else {
        final monthIdx = int.tryParse(parts[1]);
        final months = [
          'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
          'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
        ];
        final monthName = (monthIdx != null && monthIdx >= 1 && monthIdx <= 12)
            ? months[monthIdx - 1]
            : parts[1];
        return {
          'day': parts[0],
          'month': monthName,
        };
      }
    }

    return {'day': dateStr, 'month': 'اختبار'};
  }

  @override
  Widget build(BuildContext context) {
    final items = _list(data['items']);
    final majorName = _map(data['major'])['name'] ?? '-';
    final levelName = _map(data['level'])['name'] ?? '-';
    final termName = _map(data['term'])['name'] ?? '-';
    final description = data['description']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (data['title'] ?? 'تفاصيل الجدول').toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$majorName / $levelName / $termName',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  fontFamily: 'Cairo',
                ),
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontFamily: 'Cairo',
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Row(
          children: [
            Icon(Icons.calendar_today_rounded, color: AppColors.royalBlue, size: 18),
            SizedBox(width: 8),
            Text(
              'مواعيد الاختبارات المشمولة',
              style: TextStyle(
                color: AppColors.midnight,
                fontWeight: FontWeight.w900,
                fontSize: 15,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (items.isEmpty)
          const _EmptyState()
        else
          ...items.map(
            (item) {
              final dateInfo = _parseDate(item['exam_date']?.toString());
              final subjectName = (_map(item['subject'])['name'] ?? '-').toString();
              final startTime = _formatExamTime(item['start_time']);
              final endTime = _formatExamTime(item['end_time']);
              final locationName = (item['location'] ?? '').toString();

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 58,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.royalBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.15)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            dateInfo['day']!,
                            style: const TextStyle(
                              color: AppColors.royalBlue,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              fontFamily: 'Cairo',
                              height: 1.1,
                            ),
                          ),
                          Text(
                            dateInfo['month']!,
                            style: const TextStyle(
                              color: AppColors.royalBlue,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.slate100),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.015),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subjectName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                color: AppColors.midnight,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 14, color: AppColors.slate500),
                                const SizedBox(width: 6),
                                Text(
                                  '$startTime - $endTime',
                                  style: const TextStyle(
                                    color: AppColors.slate600,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Icon(Icons.location_on_rounded, size: 14, color: AppColors.slate500),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    locationName.isNotEmpty ? locationName : '-',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.slate600,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
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
    required this.index,
    required this.draft,
    required this.subjects,
    required this.onRemove,
  });

  final int index;
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.royalBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'المادة رقم $index',
                style: const TextStyle(
                  color: AppColors.royalBlue,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'مادة الاختبار',
                style: TextStyle(
                  color: AppColors.midnight,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  fontFamily: 'Cairo',
                ),
              ),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  color: AppColors.danger,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _dropdown<int>(
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
          _text(
            draft.date,
            'تاريخ الاختبار',
            hint: 'اختر تاريخ الاختبار',
            readOnly: true,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.tryParse(draft.date.text) ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (date != null) {
                draft.date.text =
                    "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
              }
            },
          ),
          Row(
            children: [
              Expanded(
                child: _text(
                  draft.start,
                  'البداية',
                  hint: 'اختر الوقت',
                  readOnly: true,
                  onTap: () async {
                    TimeOfDay initialTime = TimeOfDay.now();
                    final parts = draft.start.text.split(':');
                    if (parts.length == 2) {
                      final h = int.tryParse(parts[0]);
                      final m = int.tryParse(parts[1]);
                      if (h != null && m != null) {
                        initialTime = TimeOfDay(hour: h, minute: m);
                      }
                    }
                    final time = await showTimePicker(
                      context: context,
                      initialTime: initialTime,
                    );
                    if (time != null) {
                      draft.start.text =
                          "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _text(
                  draft.end,
                  'النهاية',
                  hint: 'اختر الوقت',
                  readOnly: true,
                  onTap: () async {
                    TimeOfDay initialTime = TimeOfDay.now();
                    final parts = draft.end.text.split(':');
                    if (parts.length == 2) {
                      final h = int.tryParse(parts[0]);
                      final m = int.tryParse(parts[1]);
                      if (h != null && m != null) {
                        initialTime = TimeOfDay(hour: h, minute: m);
                      }
                    }
                    final time = await showTimePicker(
                      context: context,
                      initialTime: initialTime,
                    );
                    if (time != null) {
                      draft.end.text =
                          "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
                    }
                  },
                ),
              ),
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

  static String _cleanDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) {
        return "${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}";
      }
    } catch (_) {}
    return raw.split('T')[0].split(' ')[0];
  }

  static String _cleanTime(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final parts = raw.split(':');
    if (parts.length >= 2) {
      return "${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}";
    }
    return raw;
  }

  factory _ExamItemDraft.fromJson(Map<String, dynamic> json) {
    return _ExamItemDraft()
      ..subjectId = _int(
        _map(json['subject'])['id'],
        fallback: _int(json['subject_id']),
      )
      ..date.text = _cleanDate(json['exam_date']?.toString())
      ..start.text = _cleanTime(json['start_time']?.toString())
      ..end.text = _cleanTime(json['end_time']?.toString())
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate100),
      ),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => onSearch(),
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w700,
          fontSize: 13.5,
          color: AppColors.midnight,
        ),
        decoration: InputDecoration(
          hintText: 'بحث باسم الطالب أو رقم القيد...',
          hintStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
            color: AppColors.slate400,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.slate400,
            size: 20,
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                onPressed: controller.clear,
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.slate400,
                  size: 18,
                ),
              );
            },
          ),
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14,
          ),
        ),
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

  // Status-color mapping for pills
  Color _pillColor(String key) => switch (key) {
    'pending' => AppColors.goldDeep,
    'accepted' => AppColors.success,
    'rejected' => AppColors.danger,
    _ => AppColors.royalBlue,
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: items.entries.map((entry) {
          final isSelected = value == entry.key;
          final chipColor = _pillColor(entry.key);
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: GestureDetector(
              onTap: () => onChanged(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? chipColor.withValues(alpha: 0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: isSelected ? chipColor : AppColors.slate200,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                    fontSize: 12.5,
                    color: isSelected ? chipColor : AppColors.slate600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
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
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.goldDeep.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.goldDeep.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.goldDeep.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.goldDeep,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
                color: AppColors.slate700,
                height: 1.4,
              ),
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
  bool readOnly = false,
  VoidCallback? onTap,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return 'هذا الحقل مطلوب.';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: AppColors.slate50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.slate200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.slate100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.royalBlue, width: 1.5),
        ),
        labelStyle: const TextStyle(
          color: AppColors.slate600,
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        hintStyle: const TextStyle(
          color: AppColors.slate400,
          fontFamily: 'Cairo',
          fontSize: 12,
        ),
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
        filled: true,
        fillColor: AppColors.slate50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.slate200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.slate100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.royalBlue, width: 1.5),
        ),
        labelStyle: const TextStyle(
          color: AppColors.slate600,
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
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

String _formatExamTime(Object? value) {
  final raw = (value ?? '').toString().trim();
  if (raw.isEmpty) return '-';
  final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(raw);
  if (match == null) return raw;

  final hour = int.tryParse(match.group(1) ?? '');
  final minute = int.tryParse(match.group(2) ?? '');
  if (hour == null || minute == null) return raw;

  final period = hour >= 12 ? 'م' : 'ص';
  final normalizedHour = hour % 12 == 0 ? 12 : hour % 12;
  return '$normalizedHour:${minute.toString().padLeft(2, '0')} $period';
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

String _formatTime(String value) {
  if (value.isEmpty) return '-';
  final cleaned = _ExamItemDraft._cleanTime(value);
  if (cleaned.contains(':')) {
    final parts = cleaned.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour != null && minute != null) {
        final period = hour >= 12 ? 'م' : 'ص';
        final hour12 = hour % 12 == 0 ? 12 : hour % 12;
        return '$hour12:${minute.toString().padLeft(2, '0')} $period';
      }
    }
  }
  return cleaned;
}

bool _isTimeInRange(String startStr, String endStr) {
  if (startStr.isEmpty || endStr.isEmpty) return false;
  try {
    final now = DateTime.now();
    final today = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final start = DateTime.parse(
      '$today ${startStr.length == 5 ? "$startStr:00" : startStr}',
    );
    final end = DateTime.parse(
      '$today ${endStr.length == 5 ? "$endStr:00" : endStr}',
    );
    return now.isAfter(start) && now.isBefore(end);
  } catch (_) {
    return false;
  }
}

class _DailyEmptyState extends StatelessWidget {
  const _DailyEmptyState({required this.dayName});
  final String dayName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today_outlined, color: AppColors.slate300, size: 48),
            const SizedBox(height: 12),
            Text(
              'لا توجد محاضرات يوم $dayName',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.slate500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SchedulesSliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SchedulesSliverAppBarDelegate({required this.child, this.height = 64});
  final Widget child;
  final double height;

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;

  @override
  bool shouldRebuild(_SchedulesSliverAppBarDelegate oldDelegate) => false;
}

class _IconInfo extends StatelessWidget {
  const _IconInfo({
    required this.icon,
    required this.text,
    this.color = AppColors.slate500,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
