import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart' as intl;

import '../../../core/downloads/download_service.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/moeen_dialogs.dart';
import 'staff_screens.dart';
import 'staff_shell.dart';

Future<void> _showWorkflowApiError(
  BuildContext context,
  ApiException error,
) async {
  if (staffIsSubscriptionRequired(error)) {
    await showStaffSubscriptionRequiredDialog(context, error);
    return;
  }
  if (!context.mounted) return;
  if (await _maybeRequestDoctorAttendanceEdit(context, error)) {
    return;
  }
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(error.message), backgroundColor: AppColors.danger),
  );
}

Future<bool> _maybeRequestDoctorAttendanceEdit(
  BuildContext context,
  ApiException error,
) async {
  if (error.statusCode != 403 ||
      !error.message.contains('تعديل سجل الحضور مغلق')) {
    return false;
  }

  final scope = _doctorAttendanceEditScope(error.errors);
  final reasonController = TextEditingController();
  var submitting = false;

  final sent = await showDialog<bool>(
    context: context,
    barrierDismissible: !submitting,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        Future<void> submit() async {
          final reason = reasonController.text.trim();
          if (reason.length < 5 || submitting) return;
          setDialogState(() => submitting = true);
          try {
            final response = await ProviderScope.containerOf(dialogContext)
                .read(staffRepositoryProvider)
                .post('/doctor/attendance-edit-requests', {
                  ...scope,
                  'reason': reason,
                });
            final message =
                response['message']?.toString() ??
                'تم إرسال طلب فتح تعديل الحضور.';
            if (!dialogContext.mounted) return;
            Navigator.pop(dialogContext, true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: AppColors.success,
              ),
            );
          } on ApiException catch (requestError) {
            if (!dialogContext.mounted) return;
            setDialogState(() => submitting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(requestError.message),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        }

        return AlertDialog(
          title: const Text('تعديل الحضور مغلق'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(error.message),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'سبب طلب فتح التعديل',
                  hintText: 'اكتب سبب التعديل المطلوب...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: submitting
                  ? null
                  : () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: submitting ? null : submit,
              child: submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('إرسال الطلب'),
            ),
          ],
        );
      },
    ),
  );

  reasonController.dispose();
  return sent == true;
}

Map<String, dynamic> _doctorAttendanceEditScope(Object? errors) {
  if (errors is Map<String, dynamic>) {
    return {
      if (errors['attendance_id'] != null)
        'attendance_id': errors['attendance_id'],
      if (errors['subject_id'] != null) 'subject_id': errors['subject_id'],
      if (errors['lecture_id'] != null) 'lecture_id': errors['lecture_id'],
      if (errors['qr_attendance_session_id'] != null)
        'qr_attendance_session_id': errors['qr_attendance_session_id'],
      if (errors['date'] != null) 'date': errors['date'],
    };
  }
  if (errors is Map) {
    return {
      if (errors['attendance_id'] != null)
        'attendance_id': errors['attendance_id'],
      if (errors['subject_id'] != null) 'subject_id': errors['subject_id'],
      if (errors['lecture_id'] != null) 'lecture_id': errors['lecture_id'],
      if (errors['qr_attendance_session_id'] != null)
        'qr_attendance_session_id': errors['qr_attendance_session_id'],
      if (errors['date'] != null) 'date': errors['date'],
    };
  }
  return const {};
}

class DoctorExcusesScreen extends ConsumerStatefulWidget {
  const DoctorExcusesScreen({super.key});

  static const route = '/doctor/excuses';

  @override
  ConsumerState<DoctorExcusesScreen> createState() =>
      _DoctorExcusesScreenState();
}

class _DoctorExcusesScreenState extends ConsumerState<DoctorExcusesScreen> {
  final _searchController = TextEditingController();
  String _status = 'pending';
  int? _subjectId;
  late Future<Map<String, dynamic>> _future = _fetch();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetch() {
    return ref
        .read(staffRepositoryProvider)
        .get('/doctor/excuses', query: const {'all': true});
  }

  void _reload() {
    setState(() {
      _future = _fetch();
    });
  }

  void _applyStatus(String status) {
    setState(() {
      _status = status;
    });
  }

  void _applySubject(int subjectId) {
    setState(() {
      _subjectId = subjectId == 0 ? null : subjectId;
    });
  }

  List<Map<String, dynamic>> _filteredExcuses(
    List<Map<String, dynamic>> source, {
    bool includeStatus = true,
  }) {
    final query = _searchController.text.trim().toLowerCase();
    return source.where((excuse) {
      if (includeStatus &&
          _status != 'all' &&
          _text(excuse, 'status') != _status) {
        return false;
      }

      if (_subjectId != null) {
        final attendance = _map(excuse['attendance']);
        final subject = _map(attendance['subject']);
        final subjectId = _int(attendance['subject_id']);
        final nestedSubjectId = _int(subject['id']);
        if (subjectId != _subjectId && nestedSubjectId != _subjectId) {
          return false;
        }
      }

      if (query.isNotEmpty) {
        final student = _map(excuse['student']);
        final haystack = [
          _text(student, 'name'),
          _text(student, 'student_number'),
          _text(excuse, 'reason'),
        ].join(' ').toLowerCase();
        if (!haystack.contains(query)) return false;
      }

      return true;
    }).toList();
  }

  Map<String, int> _localExcuseStats(List<Map<String, dynamic>> excuses) {
    return {
      'total': excuses.length,
      'pending': excuses
          .where((item) => _text(item, 'status') == 'pending')
          .length,
      'accepted': excuses
          .where((item) => _text(item, 'status') == 'accepted')
          .length,
      'rejected': excuses
          .where((item) => _text(item, 'status') == 'rejected')
          .length,
    };
  }

  @override
  Widget build(BuildContext context) {
    const statusFilters = [
      ('all', 'الكل', Icons.apps_rounded, AppColors.royalBlue),
      (
        'pending',
        'قيد المراجعة',
        Icons.hourglass_empty_rounded,
        AppColors.warning,
      ),
      ('accepted', 'مقبول', Icons.check_circle_rounded, AppColors.success),
      ('rejected', 'مرفوض', Icons.cancel_rounded, AppColors.danger),
    ];

    return StaffShell(
      title: 'أعذار الغياب',
      currentRoute: DoctorExcusesScreen.route,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _WorkflowError(error: snapshot.error!, onRetry: _reload);
          }

          final data = _map(snapshot.data?['data']);
          final workflow = _map(data['workflow']);
          final allExcuses = _list(data['excuses']);
          final scopedExcuses = _filteredExcuses(
            allExcuses,
            includeStatus: false,
          );
          final stats = _localExcuseStats(scopedExcuses);
          final excuses = _filteredExcuses(allExcuses);
          final subjects = _list(data['subjects']);

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                // Premium Unified Page Header Box
                _WorkflowHero(
                  icon: Icons.verified_user_rounded,
                  title: 'أعذار الغياب',
                  subtitle: 'راجع الأعذار الموجهة إليك واتخذ القرار النهائي.',
                ),
                const SizedBox(height: 18),

                // Unified Filter & Search Control Bento Panel
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.slate100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Premium Rounded Search Input
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.slate50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.slate100),
                        ),
                        child: TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          onChanged: (_) => setState(() {}),
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
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: AppColors.slate400,
                                      size: 18,
                                    ),
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.transparent,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Premium Subject Selection Capsule Dropdown
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.slate50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.slate100),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _subjectId ?? 0,
                            isExpanded: true,
                            icon: const Icon(
                              Icons.arrow_drop_down_rounded,
                              color: AppColors.slate500,
                              size: 28,
                            ),
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: AppColors.midnight,
                            ),
                            items: [
                              const DropdownMenuItem<int>(
                                value: 0,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.menu_book_rounded,
                                      color: AppColors.royalBlue,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text('كل المواد الدراسية'),
                                  ],
                                ),
                              ),
                              ...subjects.map(
                                (subject) => DropdownMenuItem<int>(
                                  value: _int(subject['id']),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.menu_book_rounded,
                                        color: AppColors.royalBlue,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _text(subject, 'name'),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) => _applySubject(value ?? 0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Horizontal Interactive Status Filters with Integrated Statistic Counts
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: statusFilters.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final filter = statusFilters[index];
                      final isSelected = _status == filter.$1;
                      final chipColor = filter.$4;

                      final count = switch (filter.$1) {
                        'pending' => _int(stats['pending']),
                        'accepted' => _int(stats['accepted']),
                        'rejected' => _int(stats['rejected']),
                        _ => _int(stats['total']),
                      };

                      return InkWell(
                        onTap: () => _applyStatus(filter.$1),
                        borderRadius: BorderRadius.circular(99),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? chipColor.withValues(alpha: 0.12)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: isSelected
                                  ? chipColor
                                  : AppColors.slate200,
                              width: isSelected ? 1.5 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: chipColor.withValues(alpha: 0.12),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSelected ? Icons.check_rounded : filter.$3,
                                color: isSelected
                                    ? chipColor
                                    : AppColors.slate500,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${filter.$2} ($count)',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: isSelected
                                      ? FontWeight.w900
                                      : FontWeight.w700,
                                  fontSize: 12,
                                  color: isSelected
                                      ? chipColor
                                      : AppColors.slate600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                _WorkflowSectionTitle(
                  title: 'طلبات الغياب المرفوعة',
                  icon: Icons.assignment_late_rounded,
                ),
                const SizedBox(height: 12),
                if (excuses.isEmpty)
                  const _WorkflowEmpty(
                    message: 'لا توجد أعذار مطابقة للفلاتر الحالية.',
                  )
                else
                  ...excuses.map(
                    (excuse) => _ExcuseCard(
                      excuse: excuse,
                      onTap: () =>
                          _showExcuseDetails(context, excuse, workflow),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showExcuseDetails(
    BuildContext context,
    Map<String, dynamic> excuse,
    Map<String, dynamic> workflow,
  ) async {
    await showMoeenBottomSheet(
      context: context,
      title: 'تفاصيل العذر',
      icon: Icons.verified_user_rounded,
      color: _statusColor(_text(excuse, 'status')),
      fullScreen: true,
      child: _ExcuseDetailsSheet(
        excuse: excuse,
        workflow: workflow,
        onReviewed: _reload,
      ),
    );
  }
}

class DoctorAttendanceScreen extends ConsumerStatefulWidget {
  const DoctorAttendanceScreen({super.key});

  static const route = '/doctor/attendance';

  @override
  ConsumerState<DoctorAttendanceScreen> createState() =>
      _DoctorAttendanceScreenState();
}

class _DoctorAttendanceScreenState extends ConsumerState<DoctorAttendanceScreen>
    with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> _future = _fetch();
  late TabController _tabController;

  String _searchQuery = '';
  DateTime? _selectedDate;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _searchQuery = query);
    });
  }

  Future<Map<String, dynamic>> _fetch() {
    return ref.read(staffRepositoryProvider).get('/doctor/attendance');
  }

  void _reload() {
    setState(() {
      _future = _fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'رصد الحضور',
      currentRoute: DoctorAttendanceScreen.route,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _WorkflowError(error: snapshot.error!, onRetry: _reload);
          }

          final data = _map(snapshot.data?['data']);
          final subjects = _list(data['subjects']);
          final sessions = _list(data['sessions']);

          // Apply reactive client-side search and date-filtering on sessions
          final filteredSessions = sessions.where((session) {
            final subject = _map(session['subject']);
            final lecture = _map(session['lecture']);
            final subjectName = _text(subject, 'name').toLowerCase();
            final lectureTitle = _text(lecture, 'title').toLowerCase();

            final matchesQuery =
                _searchQuery.isEmpty ||
                subjectName.contains(_searchQuery.toLowerCase()) ||
                lectureTitle.contains(_searchQuery.toLowerCase());

            if (!matchesQuery) return false;

            if (_selectedDate != null) {
              final sessionDateRaw = _text(session, 'date');
              final selectedDateStr = intl.DateFormat(
                'yyyy-MM-dd',
              ).format(_selectedDate!);
              return sessionDateRaw.startsWith(selectedDateStr);
            }

            return true;
          }).toList();

          return Column(
            children: [
              _PremiumTabBar(controller: _tabController),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    RefreshIndicator(
                      onRefresh: () async => _reload(),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                        children: [
                          _WorkflowHero(
                            icon: Icons.fact_check_rounded,
                            title: 'بدء جلسة حضور',
                            subtitle:
                                'اختر المادة لبدء الرصد أو لتحديث صلاحية المندوب.',
                          ),
                          const SizedBox(height: 18),
                          if (subjects.isEmpty)
                            const _WorkflowEmpty(
                              message: 'لا توجد مواد مسندة لك حتى الآن.',
                            )
                          else
                            ...subjects.map(
                              (subject) => _AttendanceSubjectCard(
                                subject: subject,
                                onStart: () async {
                                  await context.push(
                                    DoctorAttendanceTrackingScreen.path(
                                      _int(subject['id']),
                                    ),
                                  );
                                  _reload();
                                },
                                onToggleDelegate: () =>
                                    _toggleDelegate(subject),
                              ),
                            ),
                        ],
                      ),
                    ),
                    RefreshIndicator(
                      onRefresh: () async => _reload(),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                        children: [
                          _WorkflowHero(
                            icon: Icons.history_rounded,
                            title: 'سجلات الحضور',
                            subtitle:
                                'راجع الجلسات السابقة وافتح التقرير التفصيلي لكل جلسة.',
                          ),
                          const SizedBox(height: 12),
                          _HistoryFiltersHeader(
                            onSearch: _onSearchChanged,
                            selectedDate: _selectedDate,
                            onDateSelected: (d) =>
                                setState(() => _selectedDate = d),
                            onClear: () => setState(() {
                              _searchQuery = '';
                              _selectedDate = null;
                            }),
                          ),
                          const SizedBox(height: 18),
                          if (filteredSessions.isEmpty)
                            const _WorkflowEmpty(
                              message: 'لا توجد جلسات حضور تطابق فلترة البحث.',
                            )
                          else
                            ...filteredSessions.map(
                              (session) => _AttendanceSessionCard(
                                session: session,
                                onReport: () =>
                                    _showAttendanceReport(context, session),
                                onEdit: () async {
                                  final subjectId = _int(session['subject_id']);
                                  await context.push(
                                    DoctorAttendanceTrackingScreen.path(
                                      subjectId,
                                    ),
                                    extra: {
                                      'date': _text(session, 'date'),
                                      'lecture_id': session['lecture_id'],
                                    },
                                  );
                                  _reload();
                                },
                              ),
                            ),
                        ],
                      ),
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

  Future<void> _toggleDelegate(Map<String, dynamic> subject) async {
    try {
      await ref
          .read(staffRepositoryProvider)
          .post(
            '/doctor/attendance/${_int(subject['id'])}/toggle-delegate',
            {},
          );
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث صلاحية رصد المندوب.'),
          backgroundColor: AppColors.success,
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      await _showWorkflowApiError(context, error);
    }
  }

  Future<void> _showAttendanceReport(
    BuildContext context,
    Map<String, dynamic> session,
  ) async {
    await showMoeenBottomSheet(
      context: context,
      title: 'تقرير الحضور',
      icon: Icons.analytics_rounded,
      color: AppColors.royalBlue,
      fullScreen: true,
      child: _DoctorAttendanceReportPanel(
        session: session,
        onEdit: () async {
          Navigator.pop(context);
          final subjectId = _int(session['subject_id']);
          await context.push(
            DoctorAttendanceTrackingScreen.path(subjectId),
            extra: {
              'date': _text(session, 'date'),
              'lecture_id': session['lecture_id'],
            },
          );
          _reload();
        },
      ),
    );
  }
}

class DoctorAttendanceTrackingScreen extends ConsumerStatefulWidget {
  const DoctorAttendanceTrackingScreen({
    super.key,
    required this.subjectId,
    this.date,
    this.lectureId,
  });

  static const route = '/doctor/attendance/start/:subjectId';

  final int subjectId;
  final String? date;
  final Object? lectureId;

  static String path(int subjectId) => '/doctor/attendance/start/$subjectId';

  @override
  ConsumerState<DoctorAttendanceTrackingScreen> createState() =>
      _DoctorAttendanceTrackingScreenState();
}

class _DoctorAttendanceTrackingScreenState
    extends ConsumerState<DoctorAttendanceTrackingScreen> {
  final _titleController = TextEditingController();
  final _lectureNumberController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  final String _genderFilter = 'all';
  String _lectureType = 'official';
  bool _saving = false;
  bool _showStudents = true;
  bool _qrStarting = false;
  bool _qrFinalizing = false;
  bool _pairingWaiting = false;
  bool _externalFinalizedDialogShown = false;
  bool _desktopManagedQr = false;
  String? _pairingCode;
  String? _pairingExpiresAt;
  int _pairingRemainingSeconds = 0;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _searchQuery = '';
  late Future<Map<String, dynamic>> _future = _fetch();
  final Map<int, String> _statuses = {};
  List<Map<String, dynamic>> _students = const [];
  Map<String, dynamic> _subject = const {};
  int? _qrSessionId;
  String? _qrToken;
  int _rotationSeconds = 30;
  int _remainingSeconds = 30;
  Map<String, dynamic>? _qrStatus;
  Timer? _statusTimer;
  Timer? _rotateTimer;
  Timer? _countdownTimer;
  Timer? _pairingTimer;

  @override
  void dispose() {
    _stopQrTimers();
    _pairingTimer?.cancel();
    _titleController.dispose();
    _lectureNumberController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetch() async {
    final response = await ref
        .read(staffRepositoryProvider)
        .get(
          '/doctor/attendance/${widget.subjectId}/create',
          query: {
            if (widget.date != null) 'date': widget.date,
            if (widget.lectureId != null) 'lecture_id': widget.lectureId,
            'gender_filter': _genderFilter,
          },
        );
    final data = _map(response['data']);
    final prefill = _map(data['prefill']);
    _subject = _map(data['subject']);
    _students = _list(data['students']);
    _titleController.text = _text(
      prefill,
      'title',
      fallback: _titleController.text.isEmpty
          ? 'محاضرة'
          : _titleController.text,
    );
    _lectureNumberController.text = _text(prefill, 'lecture_number');
    _descriptionController.text = _text(
      prefill,
      'description',
      fallback: _descriptionController.text,
    );
    _lectureType = _text(prefill, 'lecture_type', fallback: _lectureType);
    _dateController.text = _text(
      prefill,
      'date',
      fallback: DateTime.now().toIso8601String().substring(0, 10),
    );
    final startTime = _text(prefill, 'start_time');
    if (startTime.isNotEmpty) _startTime = _parseTime(startTime);
    final endTime = _text(prefill, 'end_time');
    if (endTime.isNotEmpty) _endTime = _parseTime(endTime);
    _statuses
      ..clear()
      ..addAll(_initialStatuses(data));
    return response;
  }

  TimeOfDay? _parseTime(String raw) {
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(TimeOfDay value) {
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  Map<int, String> _initialStatuses(Map<String, dynamic> data) {
    final records = _map(data['attendance_records']);
    final result = <int, String>{};
    for (final student in _students) {
      final id = _int(student['id']);
      final record = _map(records['$id']);
      result[id] = _text(record, 'status', fallback: 'present');
    }
    final verification = _map(data['verification']);
    for (final raw in _list(verification['verifications'])) {
      final studentId = _int(raw['student_id']);
      final status = _text(raw, 'verification_status');
      if (status == 'confirmed_present' || status == 'scanned_present') {
        result[studentId] = 'present';
      } else if (status == 'confirmed_absent' || status == 'unscanned_absent') {
        result[studentId] = 'absent';
      }
    }
    return result;
  }

  bool get _hasActiveQr => _qrSessionId != null && _qrToken != null;
  bool get _hasUnsavedSession =>
      _hasActiveQr || _pairingWaiting || _statuses.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'جلسة حضور',
      currentRoute: DoctorAttendanceScreen.route,
      onBackPressed: _handleBack,
      onBeforeNavigate: (_) => _confirmLeaveSession(),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _WorkflowError(
              error: snapshot.error!,
              onRetry: () => setState(() {
                _future = _fetch();
              }),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              _AttendanceSubjectHeader(subject: _subject),
              const SizedBox(height: 20),
              _DoctorSessionForm(
                dateController: _dateController,
                titleController: _titleController,
                lectureNumberController: _lectureNumberController,
                descriptionController: _descriptionController,
                lectureType: _lectureType,
                onLectureTypeChanged: (value) =>
                    setState(() => _lectureType = value ?? 'official'),
                startTime: _startTime,
                endTime: _endTime,
                onPickDate: _pickDate,
                onPickStart: () => _pickTime(true),
                onPickEnd: () => _pickTime(false),
              ),
              const SizedBox(height: 20),
              _DoctorAttendanceActionBar(
                qrActive: _hasActiveQr,
                qrStarting: _qrStarting,
                pairingWaiting: _pairingWaiting,
                onManual: () => setState(() => _showStudents = true),
                onQr: _startQr,
                onPairing: _startPairing,
              ),
              if (_hasActiveQr) ...[
                const SizedBox(height: 20),
                _DoctorQrLivePanel(
                  token: _qrToken!,
                  rotationSeconds: _rotationSeconds,
                  remainingSeconds: _remainingSeconds,
                  scannedCount: _int(_qrStatus?['scanned_count']),
                  totalStudents: _int(_qrStatus?['total_students']),
                  recentScans: _list(_qrStatus?['recent_scans']),
                  presentStudents: _list(_qrStatus?['students'])
                      .where((student) => _text(student, 'status') == 'present')
                      .take(8)
                      .toList(),
                  finalizing: _qrFinalizing,
                  onRefresh: _refreshQrStatus,
                  onFinalize: _finalizeQrSession,
                ),
              ],
              if (_pairingWaiting && !_hasActiveQr) ...[
                const SizedBox(height: 20),
                _DoctorPairingWaitingCard(
                  onShowCode: _pairingCode == null
                      ? null
                      : () => _showPairingCodeDialog(
                          _pairingCode!,
                          _pairingExpiresAt ?? '',
                          _pairingRemainingSeconds,
                        ),
                  onCancel: () {
                    _pairingTimer?.cancel();
                    setState(() {
                      _pairingWaiting = false;
                      _pairingCode = null;
                      _pairingExpiresAt = null;
                      _pairingRemainingSeconds = 0;
                    });
                  },
                ),
              ],
              const SizedBox(height: 20),
              if (_showStudents) _buildStudentsSection(),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: AppColors.royalBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  shadowColor: AppColors.royalBlue.withValues(alpha: 0.3),
                  elevation: 6,
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded, color: Colors.white),
                label: const Text(
                  'حفظ جلسة الحضور والغياب',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<bool> _handleBack() async {
    if (!await _confirmLeaveSession()) return true;
    if (mounted) context.pop();
    return true;
  }

  Future<bool> _confirmLeaveSession() async {
    if (_hasUnsavedSession) {
      final approved = await showMoeenConfirmDialog(
        context: context,
        title: 'إلغاء جلسة التحضير؟',
        message:
            'أنت في جلسة تحضير حالية. هل تريد إلغاء الجلسة والخروج بدون حفظ؟',
        confirmLabel: 'نعم، إلغاء والخروج',
        cancelLabel: 'البقاء في الجلسة',
        icon: Icons.warning_amber_rounded,
        color: AppColors.danger,
      );
      if (!approved) return false;
      if (_hasActiveQr) await _cancelQrSession(showMessage: false);
      _pairingTimer?.cancel();
      if (mounted) {
        setState(() {
          _pairingWaiting = false;
          _pairingCode = null;
          _pairingExpiresAt = null;
          _pairingRemainingSeconds = 0;
        });
      }
    }
    return true;
  }

  Widget _buildStudentsSection() {
    final filteredStudents = _students.where((student) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return _text(student, 'name').toLowerCase().contains(query) ||
          _text(student, 'student_number').toLowerCase().contains(query);
    }).toList();
    final present = _statuses.values
        .where((status) => status == 'present')
        .length;
    final absent = _statuses.values
        .where((status) => status == 'absent')
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _AttendanceStatCard(
                label: 'حاضر',
                count: present,
                color: AppColors.success,
                icon: Icons.check_circle_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AttendanceStatCard(
                label: 'غائب',
                count: absent,
                color: AppColors.danger,
                icon: Icons.cancel_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AttendanceStatCard(
                label: 'الكل',
                count: _students.length,
                color: AppColors.royalBlue,
                icon: Icons.people_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        TextField(
          onChanged: (value) => setState(() => _searchQuery = value),
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
            color: AppColors.midnight,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: 'بحث باسم الطالب أو رقم القيد...',
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.royalBlue,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.slate200,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.royalBlue,
                width: 2,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.slate200,
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _selectAll('present'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppColors.success, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  foregroundColor: AppColors.success,
                ),
                icon: const Icon(Icons.done_all_rounded, size: 18),
                label: const Text(
                  'حضور الكل',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _selectAll('absent'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppColors.danger, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  foregroundColor: AppColors.danger,
                ),
                icon: const Icon(Icons.person_off_rounded, size: 18),
                label: const Text(
                  'غياب الكل',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...filteredStudents.map(
          (student) => _DoctorStudentAttendanceCard(
            student: student,
            status: _statuses[_int(student['id'])] ?? 'present',
            onChanged: (value) =>
                setState(() => _statuses[_int(student['id'])] = value),
          ),
        ),
      ],
    );
  }

  void _selectAll(String status) {
    setState(() {
      for (final student in _students) {
        _statuses[_int(student['id'])] = status;
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dateController.text) ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _dateController.text = picked.toIso8601String().substring(0, 10);
    });
  }

  Future<void> _pickTime(bool start) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start
          ? (_startTime ?? TimeOfDay.now())
          : (_endTime ?? TimeOfDay.now()),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty || _dateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أدخل عنوان المحاضرة وتاريخها قبل الحفظ.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(staffRepositoryProvider).post(
        '/doctor/attendance/${widget.subjectId}',
        {
          'date': _dateController.text.trim(),
          'title': _titleController.text.trim(),
          'lecture_number': _lectureNumberController.text.trim().isEmpty
              ? null
              : _lectureNumberController.text.trim(),
          'gender_filter': _genderFilter,
          'lecture_type': _lectureType,
          if (_descriptionController.text.trim().isNotEmpty)
            'description': _descriptionController.text.trim(),
          if (_startTime != null) 'start_time': _formatTime(_startTime!),
          if (_endTime != null) 'end_time': _formatTime(_endTime!),
          if (_qrSessionId != null) 'qr_session_id': _qrSessionId,
          'students': _students
              .map(
                (student) => {
                  'id': _int(student['id']),
                  'status': _statuses[_int(student['id'])] ?? 'absent',
                },
              )
              .toList(),
        },
      );
      if (!mounted) return;
      await showMoeenInfoDialog(
        context: context,
        title: 'تم حفظ الحضور',
        message: 'تم حفظ جلسة الحضور بنجاح.',
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
      );
      if (mounted) context.pop();
    } on ApiException catch (error) {
      if (!mounted) return;
      await _showWorkflowApiError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _startQr() async {
    if (_titleController.text.trim().isEmpty || _qrStarting || _hasActiveQr) {
      return;
    }
    setState(() {
      _qrStarting = true;
      _showStudents = true;
    });
    try {
      final response = await ref
          .read(staffRepositoryProvider)
          .post('/doctor/qr-attendance/start', {
            'subject_id': widget.subjectId,
            'title': _titleController.text.trim(),
            'date': _dateController.text.trim(),
            if (_lectureNumberController.text.trim().isNotEmpty)
              'lecture_number': _lectureNumberController.text.trim(),
          });
      _activateQrSession(_map(response['data']));
    } on ApiException catch (error) {
      if (mounted) await _showWorkflowApiError(context, error);
    } finally {
      if (mounted) setState(() => _qrStarting = false);
    }
  }

  Future<void> _startPairing() async {
    if (_titleController.text.trim().isEmpty) return;
    try {
      final response = await ref
          .read(staffRepositoryProvider)
          .post('/doctor/desktop/pairing-code', {
            'subject_id': widget.subjectId,
            'date': _dateController.text.trim(),
            'title': _titleController.text.trim(),
            if (_lectureNumberController.text.trim().isNotEmpty)
              'lecture_number': _lectureNumberController.text.trim(),
            'device_name': 'Mobile App',
          });
      final data = _map(response['data']);
      final code = _text(data, 'display_code', fallback: _text(data, 'code'));
      if (code.isEmpty) return;
      setState(() {
        _pairingWaiting = true;
        _pairingCode = code;
        _pairingExpiresAt = _text(data, 'expires_at');
        _pairingRemainingSeconds = _int(data['expires_in_seconds']);
        if (_pairingRemainingSeconds <= 0) _pairingRemainingSeconds = 600;
      });
      _startPairingPolling();
      _showPairingCodeDialog(
        code,
        _pairingExpiresAt ?? '',
        _pairingRemainingSeconds,
      );
    } on ApiException catch (error) {
      if (mounted) await _showWorkflowApiError(context, error);
    }
  }

  void _activateQrSession(Map<String, dynamic> session) {
    final id = _int(session['session_id'] ?? session['id']);
    final token = _text(session, 'token', fallback: _text(session, 'qr_code'));
    if (id <= 0 || token.isEmpty) return;
    _stopQrTimers();
    setState(() {
      _qrSessionId = id;
      _qrToken = token;
      _rotationSeconds = _int(session['rotation_seconds']);
      if (_rotationSeconds <= 0) _rotationSeconds = 30;
      _remainingSeconds = _rotationSeconds;
      _pairingWaiting = false;
      _pairingCode = null;
      _pairingExpiresAt = null;
      _pairingRemainingSeconds = 0;
      _desktopManagedQr = false;
      _externalFinalizedDialogShown = false;
    });
    _beginQrTimers();
    _refreshQrStatus();
  }

  void _beginQrTimers() {
    _statusTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _refreshQrStatus(),
    );
    _rotateTimer = Timer.periodic(
      Duration(seconds: _rotationSeconds),
      (_) => _rotateQrToken(),
    );
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remainingSeconds = _remainingSeconds > 0
            ? _remainingSeconds - 1
            : _rotationSeconds;
      });
    });
  }

  void _stopQrTimers() {
    _statusTimer?.cancel();
    _rotateTimer?.cancel();
    _countdownTimer?.cancel();
    _statusTimer = null;
    _rotateTimer = null;
    _countdownTimer = null;
  }

  Future<void> _rotateQrToken() async {
    final id = _qrSessionId;
    if (id == null || _desktopManagedQr) return;
    try {
      final response = await ref
          .read(staffRepositoryProvider)
          .get('/doctor/qr-attendance/$id/token');
      final data = _map(response['data']);
      if (!mounted) return;
      setState(() {
        _qrToken = _text(data, 'token');
        _rotationSeconds = _int(data['rotation_seconds']);
        if (_rotationSeconds <= 0) _rotationSeconds = 30;
        _remainingSeconds = _rotationSeconds;
      });
    } catch (_) {}
  }

  Future<void> _refreshQrStatus() async {
    final id = _qrSessionId;
    if (id == null) return;
    try {
      final response = await ref
          .read(staffRepositoryProvider)
          .get('/doctor/qr-attendance/$id/status');
      final data = _map(response['data']);
      if (!mounted) return;
      setState(() => _qrStatus = data);
      if (_text(data, 'session_status') == 'finalized') {
        _stopQrTimers();
        _applyQrStatus(data);
        if (!_externalFinalizedDialogShown) {
          _externalFinalizedDialogShown = true;
          await showMoeenInfoDialog(
            context: context,
            title: 'تم إنهاء الجلسة من الحاسوب',
            message:
                'تم تجهيز الحضور من جلسة QR. راجع القائمة ثم احفظ السجل النهائي.',
            icon: Icons.desktop_windows_rounded,
            color: AppColors.success,
          );
        }
      }
    } catch (_) {}
  }

  void _applyQrStatus(Map<String, dynamic> data) {
    setState(() {
      for (final student in _list(data['students'])) {
        final id = _int(student['id']);
        _statuses[id] = _text(student, 'status') == 'present'
            ? 'present'
            : 'absent';
      }
      _showStudents = true;
      _qrToken = null;
    });
  }

  Future<void> _finalizeQrSession() async {
    final id = _qrSessionId;
    if (id == null || _qrFinalizing) return;
    setState(() => _qrFinalizing = true);
    try {
      await ref
          .read(staffRepositoryProvider)
          .post('/doctor/qr-attendance/$id/finalize', {});
      final response = await ref
          .read(staffRepositoryProvider)
          .get('/doctor/qr-attendance/$id/status');
      _stopQrTimers();
      _applyQrStatus(_map(response['data']));
      if (mounted) _toast('تم إنهاء QR وتجهيز المراجعة.');
    } on ApiException catch (error) {
      if (mounted) await _showWorkflowApiError(context, error);
    } finally {
      if (mounted) setState(() => _qrFinalizing = false);
    }
  }

  Future<void> _cancelQrSession({bool showMessage = true}) async {
    final id = _qrSessionId;
    if (id == null) return;
    _stopQrTimers();
    try {
      await ref
          .read(staffRepositoryProvider)
          .post('/doctor/qr-attendance/$id/cancel', {});
      if (showMessage && mounted) _toast('تم إلغاء جلسة QR.');
    } finally {
      if (mounted) {
        setState(() {
          _qrSessionId = null;
          _qrToken = null;
          _qrStatus = null;
          _desktopManagedQr = false;
        });
      }
    }
  }

  void _startPairingPolling() {
    _pairingTimer?.cancel();
    _pairingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted || _hasActiveQr) return;
      if (_pairingRemainingSeconds <= 0) {
        _pairingTimer?.cancel();
        if (!mounted) return;
        setState(() {
          _pairingWaiting = false;
          _pairingCode = null;
          _pairingExpiresAt = null;
          _pairingRemainingSeconds = 0;
        });
        _toast('انتهت صلاحية رمز الربط. أنشئ رمزًا جديدًا للمتابعة.');
        return;
      }
      setState(() {
        _pairingRemainingSeconds = _pairingRemainingSeconds > 3
            ? _pairingRemainingSeconds - 3
            : 0;
      });
      try {
        final response = await ref
            .read(staffRepositoryProvider)
            .get(
              '/doctor/qr-attendance/active',
              query: {
                'subject_id': widget.subjectId,
                'date': _dateController.text.trim(),
                'title': _titleController.text.trim(),
                if (_lectureNumberController.text.trim().isNotEmpty)
                  'lecture_number': _lectureNumberController.text.trim(),
              },
            );
        final session = _map(_map(response['data'])['session']);
        final id = _int(session['id']);
        if (_text(session, 'status') != 'active') return;
        if (id <= 0) return;
        _pairingTimer?.cancel();
        setState(() {
          _qrSessionId = id;
          _qrToken = 'desktop-session';
          _pairingWaiting = false;
          _pairingRemainingSeconds = 0;
          _desktopManagedQr = true;
        });
        _beginQrTimers();
        await _refreshQrStatus();
      } catch (_) {}
    });
  }

  void _showPairingCodeDialog(
    String code,
    String expiresAt,
    int expiresInSeconds,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => _DoctorPairingCodeDialog(
        code: code,
        expiresAt: expiresAt,
        expiresInSeconds: expiresInSeconds,
        onHide: () => Navigator.pop(context),
        onCancel: () {
          Navigator.pop(context);
          _pairingTimer?.cancel();
          setState(() {
            _pairingWaiting = false;
            _pairingCode = null;
            _pairingExpiresAt = null;
            _pairingRemainingSeconds = 0;
          });
        },
      ),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class DoctorReportsScreen extends ConsumerStatefulWidget {
  const DoctorReportsScreen({super.key});

  static const route = '/doctor/reports';

  @override
  ConsumerState<DoctorReportsScreen> createState() =>
      _DoctorReportsScreenState();
}

class _DoctorReportsScreenState extends ConsumerState<DoctorReportsScreen> {
  late Future<Map<String, dynamic>> _future = _fetch();

  Future<Map<String, dynamic>> _fetch() {
    return ref.read(staffRepositoryProvider).get('/doctor/reports');
  }

  void _reload() {
    setState(() {
      _future = _fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'التقارير',
      currentRoute: DoctorReportsScreen.route,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _WorkflowError(error: snapshot.error!, onRetry: _reload);
          }
          final subjects = _list(snapshot.data?['data']);
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              children: [
                _WorkflowHero(
                  icon: Icons.analytics_rounded,
                  title: 'التقارير الدراسية',
                  subtitle:
                      'ملخص نسب الحضور والغياب لكل مادة مع تفاصيل الطلاب.',
                ),
                const SizedBox(height: 18),
                if (subjects.isEmpty)
                  const _WorkflowEmpty(message: 'لا توجد تقارير متاحة بعد.')
                else
                  ...subjects.map(
                    (subject) => _ReportSubjectCard(
                      subject: subject,
                      onTap: () => context.push(
                        DoctorSubjectReportScreen.path(_int(subject['id'])),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class DoctorSubjectReportScreen extends ConsumerStatefulWidget {
  const DoctorSubjectReportScreen({super.key, required this.subjectId});

  static const route = '/doctor/reports/:subjectId';

  final int subjectId;

  static String path(int subjectId) => '/doctor/reports/$subjectId';

  @override
  ConsumerState<DoctorSubjectReportScreen> createState() =>
      _DoctorSubjectReportScreenState();
}

class _DoctorSubjectReportScreenState
    extends ConsumerState<DoctorSubjectReportScreen> {
  late Future<Map<String, dynamic>> _future = _fetch();
  bool _downloading = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'name'; // 'name', 'rate_asc', 'rate_desc'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetch() {
    return ref
        .read(staffRepositoryProvider)
        .get('/doctor/reports/${widget.subjectId}');
  }

  void _reload() => setState(() {
    _future = _fetch();
  });

  Future<void> _downloadPdf() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final bytes = await ref
          .read(staffRepositoryProvider)
          .download('/doctor/reports/${widget.subjectId}/pdf');
      final result = await DownloadService.saveBytes(
        bytes: bytes,
        fileName:
            'doctor_subject_report_${widget.subjectId}_${DateTime.now().millisecondsSinceEpoch}.pdf',
        section: 'DoctorReports',
      );
      if (!mounted) return;
      await showMoeenInfoDialog(
        context: context,
        title: 'تم تحميل التقرير',
        message: result.opened
            ? 'تم حفظ وفتح التقرير بنجاح.\n${result.path}'
            : 'تم حفظ التقرير، لكن تعذر فتحه تلقائيًا.\n${result.path}',
        icon: result.opened
            ? Icons.check_circle_rounded
            : Icons.file_download_done_rounded,
        color: AppColors.success,
      );
    } catch (error) {
      if (!mounted) return;
      await showMoeenInfoDialog(
        context: context,
        title: 'تعذر تحميل التقرير',
        message: error is ApiException ? error.message : error.toString(),
        icon: Icons.error_outline_rounded,
        color: AppColors.danger,
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Widget _buildCompactMetricCard({
    required BuildContext context,
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    final width = (MediaQuery.sizeOf(context).width - 50) / 2;
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.12), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.slate500,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.midnight,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip({required String label, required String value}) {
    final isSelected = _sortBy == value;
    return ChoiceChip(
      selected: isSelected,
      label: Text(
        label,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w800,
          fontSize: 12,
          color: isSelected ? Colors.white : AppColors.slate700,
        ),
      ),
      selectedColor: AppColors.royalBlue,
      backgroundColor: AppColors.slate50,
      elevation: 0,
      pressElevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(99),
        side: BorderSide(
          color: isSelected ? AppColors.royalBlue : AppColors.slate200,
          width: 1,
        ),
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() => _sortBy = value);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'تفاصيل التقرير',
      currentRoute: DoctorReportsScreen.route,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _WorkflowError(error: snapshot.error!, onRetry: _reload);
          }
          final data = _map(snapshot.data?['data']);
          final subject = _map(data['subject']);
          final students = _list(data['students']);

          final averageRate = students.isEmpty
              ? 0
              : (students
                            .map((student) => _int(student['attendance_rate']))
                            .fold<int>(0, (sum, value) => sum + value) /
                        students.length)
                    .round();

          final totalLectures = students.isNotEmpty
              ? _int(students.first['total'])
              : 0;
          final atRiskCount = students
              .where((student) => _int(student['attendance_rate']) < 50)
              .length;

          // تصفية الطلاب محلياً
          final query = _searchQuery.trim().toLowerCase();
          var filteredStudents = students.where((student) {
            final name = _text(student, 'name').toLowerCase();
            final number = _text(student, 'student_number').toLowerCase();
            return name.contains(query) || number.contains(query);
          }).toList();

          // فرز وترتيب الطلاب محلياً
          if (_sortBy == 'name') {
            filteredStudents.sort(
              (a, b) => _text(a, 'name').compareTo(_text(b, 'name')),
            );
          } else if (_sortBy == 'rate_asc') {
            filteredStudents.sort(
              (a, b) => _int(
                a['attendance_rate'],
              ).compareTo(_int(b['attendance_rate'])),
            );
          } else if (_sortBy == 'rate_desc') {
            filteredStudents.sort(
              (a, b) => _int(
                b['attendance_rate'],
              ).compareTo(_int(a['attendance_rate'])),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                _WorkflowHero(
                  icon: Icons.analytics_rounded,
                  title: _text(subject, 'name', fallback: 'تقرير المادة'),
                  subtitle:
                      '${_text(subject, 'major', fallback: '-')} - ${_text(subject, 'level', fallback: '-')}',
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildCompactMetricCard(
                      context: context,
                      label: 'الطلاب',
                      value: '${students.length}',
                      color: AppColors.info,
                      icon: Icons.groups_rounded,
                    ),
                    _buildCompactMetricCard(
                      context: context,
                      label: 'المحاضرات',
                      value: '$totalLectures',
                      color: AppColors.royalBlue,
                      icon: Icons.menu_book_rounded,
                    ),
                    _buildCompactMetricCard(
                      context: context,
                      label: 'متوسط الحضور',
                      value: '$averageRate%',
                      color: _rateColor(averageRate),
                      icon: Icons.analytics_rounded,
                    ),
                    _buildCompactMetricCard(
                      context: context,
                      label: 'المتعثرين (<50%)',
                      value: '$atRiskCount',
                      color: AppColors.danger,
                      icon: Icons.warning_amber_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _downloading ? null : _downloadPdf,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.royalBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  icon: _downloading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.picture_as_pdf_rounded, size: 20),
                  label: const Text('تحميل تقرير الحضور PDF'),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.midnight,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'البحث عن طالب أو رقم القيد...',
                    hintStyle: const TextStyle(
                      fontFamily: 'Cairo',
                      color: AppColors.slate400,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.royalBlue,
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear_rounded,
                              color: AppColors.slate400,
                              size: 18,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.slate50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.slate200,
                        width: 1.2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.royalBlue,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildSortChip(label: 'أبجدياً بالاسم', value: 'name'),
                      const SizedBox(width: 8),
                      _buildSortChip(label: 'الأقل حضوراً', value: 'rate_asc'),
                      const SizedBox(width: 8),
                      _buildSortChip(
                        label: 'الأعلى حضوراً',
                        value: 'rate_desc',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _SubjectReportView(
                  subject: subject,
                  students: filteredStudents,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ExcuseDetailsSheet extends ConsumerStatefulWidget {
  const _ExcuseDetailsSheet({
    required this.excuse,
    required this.workflow,
    required this.onReviewed,
  });

  final Map<String, dynamic> excuse;
  final Map<String, dynamic> workflow;
  final VoidCallback onReviewed;

  @override
  ConsumerState<_ExcuseDetailsSheet> createState() =>
      _ExcuseDetailsSheetState();
}

class _ExcuseDetailsSheetState extends ConsumerState<_ExcuseDetailsSheet> {
  final _commentController = TextEditingController();
  String _decision = 'accepted';
  String? _resolution;
  bool _saving = false;
  final Map<String, bool> _downloadingFiles = {};

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _openOrDownloadFile({
    required String url,
    required String fileName,
    required String originalName,
  }) async {
    if (url.isEmpty) return;
    if (_downloadingFiles[url] == true) return;
    setState(() => _downloadingFiles[url] = true);
    try {
      for (final candidate in {fileName, originalName}) {
        final path = await DownloadService.openMoeenFile(
          fileName: candidate,
          section: 'Excuses',
        );
        if (path == null) continue;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم فتح المستند من التخزين الداخلي.')),
        );
        return;
      }

      final result = await DownloadService.downloadUrlToMoeenFolder(
        url: url,
        fileName: fileName,
        section: 'Excuses',
      );
      if (!mounted) return;
      await showMoeenInfoDialog(
        context: context,
        title: 'تم تحميل المستند',
        message: 'تم حفظ المستند بنجاح في:\n${result.path}',
        icon: Icons.file_download_done_rounded,
        color: AppColors.success,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء تحميل الملف: $error'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _downloadingFiles[url] = false);
      }
    }
  }

  String _excuseAttachmentFileName(Map<String, dynamic> item, String name) {
    final excuseId = _int(widget.excuse['id']);
    final attachmentId = _int(item['id']);
    final prefix = [
      if (excuseId > 0) 'excuse_$excuseId',
      if (attachmentId > 0) 'attachment_$attachmentId',
    ].join('_');
    return prefix.isEmpty ? name : '${prefix}_$name';
  }

  // ignore: unused_element
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.slate50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.slate500, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate400,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.midnight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final excuse = widget.excuse;
    final student = _map(excuse['student']);
    final attendance = _map(excuse['attendance']);
    final subject = _map(attendance['subject']);
    final attachments = _list(excuse['attachments']);
    final resolutions = _list(widget.workflow['resolution_options']);
    final pending = _text(excuse, 'status') == 'pending';
    final status = _text(excuse, 'status');
    final color = _statusColor(status);

    if (_decision == 'accepted' &&
        _resolution == null &&
        resolutions.isNotEmpty) {
      _resolution = _text(resolutions.first, 'value');
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Premium Case File Bento Board
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.slate100),
              boxShadow: [
                BoxShadow(
                  color: AppColors.royalBlue.withValues(alpha: 0.03),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Column(
                children: [
                  // Elegant Top Banner - Student ID Profile
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.royalBlue.withValues(alpha: 0.04),
                      border: Border(
                        bottom: BorderSide(color: AppColors.slate100),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Avatar with glowing colored border
                        Container(
                          width: 56,
                          height: 56,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.royalBlue.withValues(alpha: 0.2),
                              width: 2,
                            ),
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _getInitials(_text(student, 'name')),
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _text(student, 'name'),
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: AppColors.midnight,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Student number capsule
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.royalBlue.withValues(
                                    alpha: 0.06,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'رقم القيد: ${_text(student, 'student_number')}',
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                    color: AppColors.royalBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Diagnostic Info Row
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _BentoInfoTile(
                            icon: Icons.menu_book_rounded,
                            label: 'المادة الدراسية',
                            value: _text(subject, 'name', fallback: '-'),
                            color: AppColors.royalBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _BentoInfoTile(
                            icon: Icons.calendar_month_rounded,
                            label: 'تاريخ الغياب',
                            value: _formatCompactDate(
                              _text(attendance, 'date'),
                            ),
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Beautiful Excuse Reason Quote Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.1),
                width: 1.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.format_quote_rounded,
                    color: AppColors.warning,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'شرح عذر الغياب المقدم:',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _text(excuse, 'reason', fallback: '-'),
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13.5,
                          color: AppColors.midnight,
                          height: 1.6,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Medical Document Cards
          if (attachments.isNotEmpty) ...[
            const SizedBox(height: 20),
            const _WorkflowSectionTitle(
              title: 'المستندات والمرفقات الطبية',
              icon: Icons.attach_file_rounded,
            ),
            const SizedBox(height: 10),
            ...attachments.map((item) {
              final url = _text(item, 'file_url');
              final name = _text(item, 'file_name', fallback: 'مستند طبي');
              final localName = _excuseAttachmentFileName(item, name);
              final isDownloading = _downloadingFiles[url] ?? false;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.slate100),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.royalBlue.withValues(alpha: 0.02),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.royalBlue.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.description_rounded,
                        color: AppColors.royalBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w900,
                              fontSize: 13.5,
                              color: AppColors.midnight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.slate50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.slate100),
                            ),
                            child: const Text(
                              'مستند رسمي • اضغط للتحميل',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.slate500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    isDownloading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.royalBlue,
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: AppColors.royalBlue.withValues(
                                alpha: 0.08,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              tooltip: 'فتح أو تحميل المستند',
                              onPressed: () => _openOrDownloadFile(
                                url: url,
                                fileName: localName,
                                originalName: name,
                              ),
                              icon: const Icon(
                                Icons.open_in_new_rounded,
                                color: AppColors.royalBlue,
                                size: 20,
                              ),
                            ),
                          ),
                  ],
                ),
              );
            }),
          ],

          const SizedBox(height: 18),

          if (!pending) ...[
            const SizedBox(height: 16),
            // Approved/Rejected Elegant Container Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: color.withValues(alpha: 0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        status == 'accepted'
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: color,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        status == 'accepted'
                            ? 'تم قبول هذا العذر'
                            : 'تم رفض هذا العذر',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w900,
                          fontSize: 14.5,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  if (_text(excuse, 'resolution').isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: color.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Text(
                        'الإجراء المتخذ: ${_text(excuse, 'resolution')}',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                          color: AppColors.midnight,
                        ),
                      ),
                    ),
                  ],
                  if (_text(excuse, 'doctor_comment').isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(color: AppColors.slate200, height: 1),
                    const SizedBox(height: 10),
                    const Text(
                      'تعليق وملاحظة الدكتور:',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: AppColors.slate400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _text(excuse, 'doctor_comment'),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.midnight,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            // Choice Actions Board: Unified Premium Bento Control Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.slate100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 25,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'اتخاذ القرار المناسب:',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.midnight,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _decision = 'accepted';
                              if (resolutions.isNotEmpty &&
                                  _resolution == null) {
                                _resolution = _text(resolutions.first, 'value');
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(18),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: _decision == 'accepted'
                                  ? AppColors.success.withValues(alpha: 0.08)
                                  : AppColors.slate50,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: _decision == 'accepted'
                                    ? AppColors.success
                                    : AppColors.slate200,
                                width: _decision == 'accepted' ? 2 : 1,
                              ),
                              boxShadow: _decision == 'accepted'
                                  ? [
                                      BoxShadow(
                                        color: AppColors.success.withValues(
                                          alpha: 0.12,
                                        ),
                                        blurRadius: 15,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: _decision == 'accepted'
                                      ? AppColors.success
                                      : AppColors.slate400,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'قبول العذر',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13.5,
                                    color: _decision == 'accepted'
                                        ? AppColors.success
                                        : AppColors.slate600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _decision = 'rejected';
                              _resolution = null;
                            });
                          },
                          borderRadius: BorderRadius.circular(18),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: _decision == 'rejected'
                                  ? AppColors.danger.withValues(alpha: 0.08)
                                  : AppColors.slate50,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: _decision == 'rejected'
                                    ? AppColors.danger
                                    : AppColors.slate200,
                                width: _decision == 'rejected' ? 2 : 1,
                              ),
                              boxShadow: _decision == 'rejected'
                                  ? [
                                      BoxShadow(
                                        color: AppColors.danger.withValues(
                                          alpha: 0.12,
                                        ),
                                        blurRadius: 15,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.cancel_rounded,
                                  color: _decision == 'rejected'
                                      ? AppColors.danger
                                      : AppColors.slate400,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'رفض العذر',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13.5,
                                    color: _decision == 'rejected'
                                        ? AppColors.danger
                                        : AppColors.slate600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_decision == 'accepted' && resolutions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'نتيجة المعالجة بعد القبول:',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.midnight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.slate50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.slate100),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButtonFormField<String>(
                          initialValue:
                              _resolution ??
                              (resolutions.isNotEmpty
                                  ? _text(resolutions.first, 'value')
                                  : null),
                          icon: const Icon(
                            Icons.arrow_drop_down_rounded,
                            color: AppColors.slate500,
                            size: 28,
                          ),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(
                              Icons.handyman_rounded,
                              color: AppColors.success,
                              size: 20,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.midnight,
                          ),
                          items: resolutions
                              .map(
                                (item) => DropdownMenuItem<String>(
                                  value: _text(item, 'value'),
                                  child: Text(_text(item, 'label')),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _resolution = value),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  TextField(
                    controller: _commentController,
                    maxLines: 2,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.midnight,
                    ),
                    decoration: InputDecoration(
                      labelText: 'ملاحظة للطالب (اختياري)',
                      labelStyle: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate400,
                      ),
                      alignLabelWithHint: true,
                      filled: true,
                      fillColor: AppColors.slate50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.royalBlue,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: _decision == 'accepted'
                            ? AppColors.success
                            : AppColors.danger,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _decision == 'accepted'
                                      ? 'اعتماد وقبول العذر'
                                      : 'اعتماد ورفض العذر',
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_decision == 'accepted' &&
        (_resolution == null || _resolution!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اختر نتيجة المعالجة عند قبول العذر.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(staffRepositoryProvider)
          .put('/doctor/excuses/${_int(widget.excuse['id'])}', {
            'status': _decision,
            'resolution': _decision == 'accepted' ? _resolution : null,
            'comment': _commentController.text.trim(),
          });
      if (!mounted) return;
      Navigator.pop(context);
      widget.onReviewed();
      await showMoeenInfoDialog(
        context: context,
        title: 'تم حفظ القرار',
        message: 'تم تحديث قرار العذر بنجاح.',
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      await _showWorkflowApiError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _DoctorAttendanceReportPanel extends ConsumerStatefulWidget {
  const _DoctorAttendanceReportPanel({
    required this.session,
    required this.onEdit,
  });

  final Map<String, dynamic> session;
  final Future<void> Function() onEdit;

  @override
  ConsumerState<_DoctorAttendanceReportPanel> createState() =>
      _DoctorAttendanceReportPanelState();
}

class _DoctorAttendanceReportPanelState
    extends ConsumerState<_DoctorAttendanceReportPanel> {
  late Future<Map<String, dynamic>> _future = _fetch();
  bool _downloading = false;
  String _searchQuery = '';
  String _statusFilter = 'all';
  late final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _subjectId => _int(widget.session['subject_id']);
  String get _date => _normalizeApiDate(_text(widget.session, 'date'));
  String get _displayDate => _formatCompactDate(
    _text(widget.session, 'display_date', fallback: _date),
  );
  Object? get _lectureId => widget.session['lecture_id'];

  Future<Map<String, dynamic>> _fetch() {
    return ref
        .read(staffRepositoryProvider)
        .get(
          '/doctor/attendance/$_subjectId/$_date/report',
          query: {if (_lectureId != null) 'lecture_id': _lectureId},
        );
  }

  Future<void> _downloadPdf() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final bytes = await ref
          .read(staffRepositoryProvider)
          .download(
            '/doctor/attendance/$_subjectId/$_date/report-pdf',
            query: {if (_lectureId != null) 'lecture_id': _lectureId},
          );
      final result = await DownloadService.saveBytes(
        bytes: bytes,
        fileName: 'attendance_report_${_subjectId}_$_date.pdf',
        section: 'AttendanceReports',
      );
      if (!mounted) return;
      await showMoeenInfoDialog(
        context: context,
        title: 'تم تحميل التقرير',
        message: result.opened
            ? 'تم حفظ التقرير وفتحه بنجاح.'
            : 'تم حفظ التقرير في:\n${result.path}\nلكن تعذر فتحه تلقائيا.',
        icon: result.opened
            ? Icons.check_circle_rounded
            : Icons.file_download_done_rounded,
        color: result.opened ? AppColors.success : AppColors.info,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      await _showWorkflowApiError(context, error);
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Widget _buildFilterChip(String value, String label, Color color) {
    final selected = _statusFilter == value;
    return InkWell(
      onTap: () => setState(() => _statusFilter = value),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.12),
            width: 1.2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check_rounded, color: Colors.white, size: 14),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return _WorkflowError(
            error: snapshot.error!,
            onRetry: () => setState(() {
              _future = _fetch();
            }),
          );
        }

        final data = _map(snapshot.data?['data']);
        final lecture = _map(data['lecture']);
        final students = _list(data['students']);
        final summary = _map(data['summary']);
        final present = summary.isNotEmpty
            ? _int(summary['present'])
            : students
                  .where(
                    (student) =>
                        _normalizeAttendanceStatus(_text(student, 'status')) ==
                        'present',
                  )
                  .length;
        final absent = summary.isNotEmpty
            ? _int(summary['absent'])
            : students
                  .where(
                    (student) =>
                        _normalizeAttendanceStatus(_text(student, 'status')) ==
                        'absent',
                  )
                  .length;
        final late = summary.isNotEmpty
            ? _int(summary['late'])
            : students
                  .where(
                    (student) =>
                        _normalizeAttendanceStatus(_text(student, 'status')) ==
                        'late',
                  )
                  .length;

        // Apply reactive filtering and searching on students list
        final filteredStudents = students.where((student) {
          final name = _text(student, 'name').toLowerCase();
          final number = _text(student, 'student_number').toLowerCase();
          final status = _normalizeAttendanceStatus(_text(student, 'status'));

          final matchesQuery =
              _searchQuery.isEmpty ||
              name.contains(_searchQuery.toLowerCase()) ||
              number.contains(_searchQuery.toLowerCase());

          if (!matchesQuery) return false;

          if (_statusFilter != 'all') {
            return status == _statusFilter;
          }

          return true;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gorgeous Academic Ticket Subject Card
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: AppColors.slate100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.025),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left accent stripe
                      Container(width: 6, color: AppColors.royalBlue),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.royalBlue.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: AppColors.royalBlue.withValues(
                                          alpha: 0.12,
                                        ),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.auto_stories_rounded,
                                      color: AppColors.royalBlue,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _text(
                                            _map(data['subject']),
                                            'name',
                                            fallback: 'تقرير الحضور',
                                          ),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            fontFamily: 'Cairo',
                                            color: AppColors.midnight,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          'تفاصيل جلسة رصد حضور الطلاب',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.slate400,
                                            fontFamily: 'Cairo',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              const _DashedDivider(),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _ReportMetaChip(
                                    icon: Icons.calendar_month_rounded,
                                    label: _displayDate,
                                  ),
                                  if (lecture.isNotEmpty)
                                    _ReportMetaChip(
                                      icon: Icons.menu_book_rounded,
                                      label: _text(
                                        lecture,
                                        'title',
                                        fallback: 'محاضرة',
                                      ),
                                    ),
                                  if (_text(
                                    lecture,
                                    'lecture_number',
                                  ).isNotEmpty)
                                    _ReportMetaChip(
                                      icon: Icons.tag_rounded,
                                      label:
                                          'رقم ${_text(lecture, 'lecture_number')}',
                                    ),
                                  _ReportMetaChip(
                                    icon:
                                        _text(
                                              widget.session,
                                              'attendance_method',
                                            ) ==
                                            'qr'
                                        ? Icons.qr_code_rounded
                                        : Icons.edit_calendar_rounded,
                                    label:
                                        _text(
                                              widget.session,
                                              'attendance_method',
                                            ) ==
                                            'qr'
                                        ? 'تحضير QR'
                                        : 'تحضير يدوي',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Stats row (Flexible and aligned nicely)
            Row(
              children: [
                _ReportMetricCard(
                  label: 'الطلاب',
                  value: '${students.length}',
                  color: AppColors.royalBlue,
                  icon: Icons.people_alt_rounded,
                ),
                const SizedBox(width: 8),
                _ReportMetricCard(
                  label: 'حاضر',
                  value: '$present',
                  color: AppColors.success,
                  icon: Icons.check_circle_rounded,
                ),
                const SizedBox(width: 8),
                _ReportMetricCard(
                  label: 'غائب',
                  value: '$absent',
                  color: AppColors.danger,
                  icon: Icons.cancel_rounded,
                ),
                const SizedBox(width: 8),
                _ReportMetricCard(
                  label: 'متأخر',
                  value: '$late',
                  color: AppColors.warning,
                  icon: Icons.watch_later_rounded,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Action Buttons Panel
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onEdit,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.royalBlue,
                      side: const BorderSide(
                        color: AppColors.royalBlue,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text(
                      'تعديل الجلسة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _downloading ? null : _downloadPdf,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.royalBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                      shadowColor: AppColors.royalBlue.withValues(alpha: 0.2),
                    ),
                    icon: _downloading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.picture_as_pdf_rounded, size: 18),
                    label: const Text(
                      'تحميل التقرير',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Real-time Reactive Search Box
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.midnight,
              ),
              decoration: InputDecoration(
                hintText: 'بحث باسم الطالب أو رقم القيد...',
                hintStyle: const TextStyle(color: AppColors.slate400),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.royalBlue,
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: const Icon(
                          Icons.cancel_rounded,
                          color: AppColors.slate400,
                          size: 20,
                        ),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.slate50,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.slate100,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.royalBlue,
                    width: 2,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.slate100,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Horizontal Category Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    'all',
                    'الكل (${students.length})',
                    AppColors.royalBlue,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'present',
                    'حاضر ($present)',
                    AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'absent',
                    'غائب ($absent)',
                    AppColors.danger,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip('late', 'متأخر ($late)', AppColors.warning),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Student list with initial circle avatars and premium details
            filteredStudents.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'لا يوجد طلاب يطابقون خيارات التصفية والبحث.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate400,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = filteredStudents[index];
                      final name = _text(student, 'name');
                      final status = _normalizeAttendanceStatus(
                        _text(student, 'status'),
                      );
                      final color = _statusColor(status);
                      final initialLetter = name.isNotEmpty ? name[0] : '?';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.slate100),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Left status accent strip
                                Container(width: 5, color: color),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        // Circular initial avatar
                                        Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    color.withValues(
                                                      alpha: 0.15,
                                                    ),
                                                    color.withValues(
                                                      alpha: 0.05,
                                                    ),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: color.withValues(
                                                    alpha: 0.25,
                                                  ),
                                                  width: 1.5,
                                                ),
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                initialLetter,
                                                style: TextStyle(
                                                  color: color,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w900,
                                                  fontFamily: 'Cairo',
                                                ),
                                              ),
                                            ),
                                            // Mini status badge overlay
                                            Positioned(
                                              bottom: 0,
                                              right: 0,
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: color,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Icon(
                                                  status == 'present'
                                                      ? Icons.check_rounded
                                                      : status == 'absent'
                                                      ? Icons.close_rounded
                                                      : Icons
                                                            .access_time_rounded,
                                                  size: 10,
                                                  color: color,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 14),
                                        // Student details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  color: AppColors.midnight,
                                                  fontSize: 14,
                                                  fontFamily: 'Cairo',
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.badge_rounded,
                                                    size: 13,
                                                    color: AppColors.slate400,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    _text(
                                                      student,
                                                      'student_number',
                                                    ),
                                                    style: const TextStyle(
                                                      color: AppColors.slate400,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontFamily: 'Cairo',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Premium Status Badge
                                        _PremiumStatusBadge(
                                          status: status,
                                          color: color,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        );
      },
    );
  }
}

class _ReportMetricCard extends StatelessWidget {
  const _ReportMetricCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.12), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.015),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                fontFamily: 'Cairo',
                height: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.slate500,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 6),
            // Accent bottom bar
            Container(
              width: 16,
              height: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportMetaChip extends StatelessWidget {
  const _ReportMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.royalBlue),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.midnight,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();
  final double height = 1.2;
  final Color color = AppColors.slate200;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _DashedLinePainter(color: color, height: height),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color, required this.height});
  final Color color;
  final double height;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = height
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    double startX = 0;
    final y = size.height / 2;
    while (startX < size.width) {
      final endX = startX + dashWidth;
      final drawEndX = endX > size.width ? size.width : endX;
      canvas.drawLine(Offset(startX, y), Offset(drawEndX, y), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.height != height;
  }
}

class _PremiumStatusBadge extends StatelessWidget {
  const _PremiumStatusBadge({required this.status, required this.color});

  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.18), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status == 'present'
                ? Icons.check_circle_rounded
                : status == 'absent'
                ? Icons.cancel_rounded
                : Icons.watch_later_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            _statusLabel(status),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceSubjectHeader extends StatelessWidget {
  const _AttendanceSubjectHeader({required this.subject});

  final Map<String, dynamic> subject;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.royalBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.royalBlue.withValues(alpha: 0.12),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: AppColors.royalBlue,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _text(subject, 'name', fallback: 'المقرر'),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.midnight,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'إدارة الجلسة، الرصد اليدوي، وQR من شاشة واحدة متكاملة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
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

class _DoctorSessionForm extends StatelessWidget {
  const _DoctorSessionForm({
    required this.dateController,
    required this.titleController,
    required this.lectureNumberController,
    required this.descriptionController,
    required this.lectureType,
    required this.onLectureTypeChanged,
    required this.startTime,
    required this.endTime,
    required this.onPickDate,
    required this.onPickStart,
    required this.onPickEnd,
  });

  final TextEditingController dateController;
  final TextEditingController titleController;
  final TextEditingController lectureNumberController;
  final TextEditingController descriptionController;
  final String lectureType;
  final ValueChanged<String?> onLectureTypeChanged;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final VoidCallback onPickDate;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _WorkflowSectionTitle(
            title: 'تفاصيل الجلسة',
            icon: Icons.event_note_rounded,
          ),
          const SizedBox(height: 18),
          _DoctorMoeenTextField(
            controller: titleController,
            labelText: 'عنوان الجلسة',
            prefixIcon: const Icon(
              Icons.title_rounded,
              color: AppColors.royalBlue,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _DoctorMoeenTextField(
                  controller: dateController,
                  labelText: 'التاريخ',
                  readOnly: true,
                  onTap: onPickDate,
                  prefixIcon: const Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.royalBlue,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DoctorMoeenTextField(
                  controller: lectureNumberController,
                  labelText: 'رقم المحاضرة',
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(
                    Icons.tag_rounded,
                    color: AppColors.royalBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DoctorMoeenDropdownField<String>(
            initialValue: lectureType,
            labelText: 'نوع الجلسة',
            prefixIcon: const Icon(
              Icons.category_rounded,
              color: AppColors.royalBlue,
            ),
            items: const [
              DropdownMenuItem(
                value: 'official',
                child: Text(
                  'محاضرة رسمية',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              DropdownMenuItem(
                value: 'special',
                child: Text(
                  'محاضرة إضافية',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            onChanged: onLectureTypeChanged,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _TimePickerTile(
                  label: 'وقت البداية',
                  value: startTime,
                  onTap: onPickStart,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimePickerTile(
                  label: 'وقت النهاية',
                  value: endTime,
                  onTap: onPickEnd,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DoctorMoeenTextField(
            controller: descriptionController,
            labelText: 'ملاحظات الجلسة',
            maxLines: 3,
            alignLabelWithHint: true,
            prefixIcon: const Icon(
              Icons.notes_rounded,
              color: AppColors.royalBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimePickerTile extends StatelessWidget {
  const _TimePickerTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final TimeOfDay? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final formatted = value == null ? 'غير محدد' : value!.format(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.slate200, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.royalBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.access_time_filled_rounded,
                color: AppColors.royalBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: AppColors.slate400,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatted,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: value == null
                          ? AppColors.slate500
                          : AppColors.midnight,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorAttendanceActionBar extends StatelessWidget {
  const _DoctorAttendanceActionBar({
    required this.qrActive,
    required this.qrStarting,
    required this.pairingWaiting,
    required this.onManual,
    required this.onQr,
    required this.onPairing,
  });

  final bool qrActive;
  final bool qrStarting;
  final bool pairingWaiting;
  final VoidCallback onManual;
  final VoidCallback onQr;
  final VoidCallback onPairing;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _WorkflowSectionTitle(
            title: 'طرق الرصد المتاحة',
            icon: Icons.hub_rounded,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onManual,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.royalBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(
                    Icons.edit_calendar_rounded,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'رصد يدوي',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: qrActive || qrStarting ? null : onQr,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: qrStarting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.qr_code_2_rounded,
                          color: Colors.white,
                        ),
                  label: const Text(
                    'تحضير QR',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: pairingWaiting || qrActive ? null : onPairing,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.royalBlue, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(
              Icons.desktop_windows_rounded,
              color: AppColors.royalBlue,
            ),
            label: const Text(
              'ربط تطبيق العرض الخارجي (سبورة الذكية)',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w800,
                color: AppColors.royalBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorQrLivePanel extends StatelessWidget {
  const _DoctorQrLivePanel({
    required this.token,
    required this.rotationSeconds,
    required this.remainingSeconds,
    required this.scannedCount,
    required this.totalStudents,
    required this.recentScans,
    required this.presentStudents,
    required this.finalizing,
    required this.onRefresh,
    required this.onFinalize,
  });

  final String token;
  final int rotationSeconds;
  final int remainingSeconds;
  final int scannedCount;
  final int totalStudents;
  final List<Map<String, dynamic>> recentScans;
  final List<Map<String, dynamic>> presentStudents;
  final bool finalizing;
  final VoidCallback onRefresh;
  final VoidCallback onFinalize;

  @override
  Widget build(BuildContext context) {
    final cycleSeconds = rotationSeconds <= 0 ? 30 : rotationSeconds;
    final double progress =
        remainingSeconds.clamp(0, cycleSeconds) / cycleSeconds;
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: _WorkflowSectionTitle(
                  title: 'جلسة التحضير بالـ QR النشطة',
                  icon: Icons.qr_code_scanner_rounded,
                  maxLines: 2,
                  iconSize: 18,
                  gap: 7,
                ),
              ),
              IconButton(
                onPressed: onRefresh,
                tooltip: 'تحديث الجلسة',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.slate50,
                  foregroundColor: AppColors.royalBlue,
                ),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: AppColors.slate100, width: 1.5),
              ),
              child: QrImageView(
                data: token,
                size: 200,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.slate100,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.teal),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'يتجدد الرمز خلال $remainingSeconds ثانية تلقائياً',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Cairo',
              color: AppColors.slate500,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _AttendanceStatCard(
                  label: 'قاموا بالمسح',
                  count: scannedCount,
                  color: AppColors.success,
                  icon: Icons.how_to_reg_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AttendanceStatCard(
                  label: 'إجمالي طلاب المادة',
                  count: totalStudents,
                  color: AppColors.royalBlue,
                  icon: Icons.groups_rounded,
                ),
              ),
            ],
          ),
          if (recentScans.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'آخر الطلاب المنضمين للرصد',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w900,
                color: AppColors.midnight,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            ...recentScans
                .take(4)
                .map(
                  (student) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _text(student, 'name'),
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: AppColors.midnight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _text(student, 'student_number'),
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  color: AppColors.slate500,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
          if (presentStudents.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'الحاضرون مؤخراً',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w900,
                color: AppColors.midnight,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: presentStudents.map((student) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.royalBlue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.royalBlue.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.person_rounded,
                        size: 14,
                        color: AppColors.royalBlue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _text(student, 'name'),
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.royalBlue,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: finalizing ? null : onFinalize,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: finalizing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.stop_circle_rounded, color: Colors.white),
            label: const Text(
              'إنهاء الجلسة ومراجعة الحضور النهائي',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorPairingWaitingCard extends StatelessWidget {
  const _DoctorPairingWaitingCard({
    required this.onShowCode,
    required this.onCancel,
  });

  final VoidCallback? onShowCode;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.desktop_windows_rounded,
                  color: AppColors.royalBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'بانتظار شاشة العرض الخارجية',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.midnight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'رمز الربط ما زال صالحاً للاتصال بالسبورة الذكية أو شاشة العرض. يمكنك إظهاره مرة أخرى أو إيقاف عملية الربط.',
            style: TextStyle(
              fontFamily: 'Cairo',
              color: AppColors.slate500,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onShowCode,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(
                      color: AppColors.royalBlue,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(
                    Icons.visibility_rounded,
                    color: AppColors.royalBlue,
                    size: 18,
                  ),
                  label: const Text(
                    'إظهار رمز الربط',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w800,
                      color: AppColors.royalBlue,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextButton.icon(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.danger,
                    size: 18,
                  ),
                  label: const Text(
                    'إلغاء الاتصال',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w800,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DoctorPairingCodeDialog extends ConsumerStatefulWidget {
  const _DoctorPairingCodeDialog({
    required this.code,
    required this.expiresAt,
    required this.expiresInSeconds,
    required this.onHide,
    required this.onCancel,
  });

  final String code;
  final String expiresAt;
  final int expiresInSeconds;
  final VoidCallback onHide;
  final VoidCallback onCancel;

  @override
  _DoctorPairingCodeDialogState createState() =>
      _DoctorPairingCodeDialogState();
}

class _DoctorPairingCodeDialogState
    extends ConsumerState<_DoctorPairingCodeDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _countdownTimer;
  String _timeRemaining = '';
  int? _remainingSeconds;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _remainingSeconds = widget.expiresInSeconds > 0
        ? widget.expiresInSeconds
        : null;

    _startTicker();
  }

  void _startTicker() {
    _updateTime();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateTime();
      }
    });
  }

  void _updateTime() {
    final localRemaining = _remainingSeconds;
    if (localRemaining != null) {
      if (localRemaining <= 0) {
        setState(() {
          _timeRemaining = 'منتهية الصلاحية';
        });
        return;
      }
      final minutes = (localRemaining ~/ 60).toString().padLeft(2, '0');
      final seconds = (localRemaining % 60).toString().padLeft(2, '0');
      setState(() {
        _timeRemaining = '$minutes:$seconds متبقي';
        _remainingSeconds = localRemaining - 1;
      });
      return;
    }

    if (widget.expiresAt.isEmpty) {
      setState(() {
        _timeRemaining = '';
      });
      return;
    }
    try {
      final expiry = DateTime.parse(widget.expiresAt);
      final now = DateTime.now().toUtc();
      final diff = expiry.difference(now);
      if (diff.isNegative) {
        setState(() {
          _timeRemaining = 'منتهية الصلاحية';
        });
      } else {
        final minutes = diff.inMinutes.remainder(60).toString().padLeft(2, '0');
        final seconds = diff.inSeconds.remainder(60).toString().padLeft(2, '0');
        setState(() {
          _timeRemaining = '$minutes:$seconds متبقي';
        });
      }
    } catch (_) {
      setState(() {
        _timeRemaining = '';
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.royalBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.desktop_windows_rounded,
                color: AppColors.royalBlue,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'ربط تطبيق العرض',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.midnight,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'أدخل هذا الرمز في تطبيق العرض لبدء جلسة QR من الحاسوب.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cairo',
                color: AppColors.slate500,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + (_pulseController.value * 0.03);
                final glow = _pulseController.value * 12.0;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.royalBlue.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.royalBlue.withValues(alpha: 0.12),
                          blurRadius: glow,
                          spreadRadius: glow / 3,
                        ),
                      ],
                    ),
                    child: Text(
                      widget.code,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        color: AppColors.royalBlue,
                      ),
                    ),
                  ),
                );
              },
            ),
            if (_timeRemaining.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.slate100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer_rounded,
                      size: 14,
                      color: AppColors.slate500,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _timeRemaining,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.slate200),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'إلغاء الربط',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: widget.onHide,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.royalBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'إخفاء والانتظار',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceStatCard extends StatelessWidget {
  const _AttendanceStatCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  final String label;
  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.12), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 11,
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorStudentAttendanceCard extends StatelessWidget {
  const _DoctorStudentAttendanceCard({
    required this.student,
    required this.status,
    required this.onChanged,
  });

  final Map<String, dynamic> student;
  final String status;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _text(student, 'name'),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: AppColors.midnight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _text(student, 'student_number'),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: AppColors.slate500,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusPill(status: status),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatusToggle(
                label: 'حاضر',
                icon: Icons.check_circle_rounded,
                isActive: status == 'present',
                activeColor: AppColors.success,
                onTap: () => onChanged('present'),
              ),
              const SizedBox(width: 8),
              _StatusToggle(
                label: 'غائب',
                icon: Icons.cancel_rounded,
                isActive: status == 'absent',
                activeColor: AppColors.danger,
                onTap: () => onChanged('absent'),
              ),
              const SizedBox(width: 8),
              _StatusToggle(
                label: 'متأخر',
                icon: Icons.watch_later_rounded,
                isActive: status == 'late',
                activeColor: AppColors.warning,
                onTap: () => onChanged('late'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusToggle extends StatelessWidget {
  const _StatusToggle({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? activeColor : AppColors.slate200,
              width: 1.5,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.24),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? Colors.white : AppColors.slate400,
                size: 18,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: isActive ? Colors.white : AppColors.slate600,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectReportView extends StatelessWidget {
  const _SubjectReportView({required this.subject, required this.students});

  final Map<String, dynamic> subject;
  final List<dynamic> students;

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: Text(
            'لا توجد نتائج مطابقة للبحث.',
            style: TextStyle(
              fontFamily: 'Cairo',
              color: AppColors.slate500,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.royalBlue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'سجل الطلاب (${students.length})',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w900,
                color: AppColors.midnight,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...students.map((student) {
          final rate = _int(student['attendance_rate']);
          final name = _text(student, 'name');
          final number = _text(student, 'student_number');
          final rateColor = _rateColor(rate);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.slate200),
              boxShadow: [
                BoxShadow(
                  color: rateColor.withValues(alpha: 0.02),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [rateColor.withValues(alpha: 0.8), rateColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _getInitials(name),
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name & Student Number
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: AppColors.midnight,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'رقم القيد: $number',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              color: AppColors.slate500,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Attendance Rate Circle or Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: rateColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: rateColor.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Text(
                        '$rate%',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: rateColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Bento stats row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTinyStatChip(
                        'حاضر',
                        _int(student['present']),
                        AppColors.success,
                      ),
                      const SizedBox(width: 6),
                      _buildTinyStatChip(
                        'غائب',
                        _int(student['absent']),
                        AppColors.danger,
                      ),
                      const SizedBox(width: 6),
                      _buildTinyStatChip(
                        'بعذر',
                        _int(student['excused']),
                        AppColors.info,
                      ),
                      const SizedBox(width: 6),
                      _buildTinyStatChip(
                        'المحاضرات',
                        _int(student['total']),
                        AppColors.royalBlue,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTinyStatChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.slate200, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'Cairo',
              color: AppColors.slate500,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '$value',
            style: const TextStyle(
              fontFamily: 'Cairo',
              color: AppColors.midnight,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkflowHero extends StatelessWidget {
  const _WorkflowHero({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: Colors.white),
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
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  IconData _getIcon() {
    switch (label) {
      case 'الإجمالي':
        return Icons.analytics_rounded;
      case 'قيد المراجعة':
        return Icons.hourglass_empty_rounded;
      case 'مقبول':
        return Icons.check_circle_rounded;
      case 'مرفوض':
        return Icons.cancel_rounded;
      default:
        return Icons.analytics_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconData = _getIcon();
    return Container(
      width: (MediaQuery.sizeOf(context).width - 52) / 2,
      height: 98,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Ambient light glow background in HSL style
            Positioned(
              left: -15,
              top: -15,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
            // Accent bottom bar
            Positioned(
              bottom: 0,
              left: 20,
              right: 20,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(3),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            color: AppColors.slate500,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          value.toString(),
                          style: const TextStyle(
                            color: AppColors.midnight,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Cairo',
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconData, color: color, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkflowSectionTitle extends StatelessWidget {
  const _WorkflowSectionTitle({
    required this.title,
    required this.icon,
    this.maxLines = 1,
    this.iconSize = 22,
    this.gap = 10,
  });

  final String title;
  final IconData icon;
  final int maxLines;
  final double iconSize;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.midnight, size: iconSize),
        SizedBox(width: gap),
        Expanded(
          child: Text(
            title,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.midnight,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

class _ExcuseCard extends StatelessWidget {
  const _ExcuseCard({required this.excuse, required this.onTap});

  final Map<String, dynamic> excuse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final student = _map(excuse['student']);
    final attendance = _map(excuse['attendance']);
    final subject = _map(attendance['subject']);
    final status = _text(excuse, 'status');
    final color = _statusColor(status);
    final reason = _text(excuse, 'reason');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: Avatar + Info + Status Badge
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.royalBlue.withValues(
                                alpha: 0.15,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _getInitials(_text(student, 'name')),
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w900,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _text(student, 'name'),
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
                              'رقم القيد: ${_text(student, 'student_number', fallback: '-')}',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                color: AppColors.slate400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Premium Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: color.withValues(alpha: 0.15),
                          ),
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
                                fontSize: 10,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Horizontal Bento Capsules Wrap
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ExcuseMetaCapsule(
                        icon: Icons.menu_book_rounded,
                        text: _text(subject, 'name', fallback: '-'),
                      ),
                      _ExcuseMetaCapsule(
                        icon: Icons.calendar_month_rounded,
                        text: _formatCompactDate(_text(attendance, 'date')),
                      ),
                    ],
                  ),

                  // Reason Quote Preview
                  if (reason.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.format_quote_rounded,
                            color: AppColors.warning,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExcuseMetaCapsule extends StatelessWidget {
  const _ExcuseMetaCapsule({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.royalBlue),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.midnight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BentoInfoTile extends StatelessWidget {
  const _BentoInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.slate400,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: AppColors.midnight,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceSubjectCard extends StatelessWidget {
  const _AttendanceSubjectCard({
    required this.subject,
    required this.onStart,
    required this.onToggleDelegate,
  });

  final Map<String, dynamic> subject;
  final VoidCallback onStart;
  final VoidCallback onToggleDelegate;

  @override
  Widget build(BuildContext context) {
    final major = _map(subject['major']);
    final level = _map(subject['level']);
    final delegateEnabled = subject['allow_delegate_attendance'] == true;
    final majorName = _text(major, 'name', fallback: '-');
    final levelName = _text(level, 'name', fallback: '-');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate200.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _text(subject, 'name'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14.5,
              color: AppColors.midnight,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _AttendanceSubjectMetaChip(
                icon: Icons.layers_rounded,
                label: levelName,
              ),
              if (majorName != '-')
                _AttendanceSubjectMetaChip(
                  icon: Icons.apartment_rounded,
                  label: majorName,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onToggleDelegate,
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (delegateEnabled
                                  ? AppColors.success
                                  : AppColors.danger)
                              .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            (delegateEnabled
                                    ? AppColors.success
                                    : AppColors.danger)
                                .withValues(alpha: 0.22),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          delegateEnabled
                              ? Icons.person_rounded
                              : Icons.person_off_rounded,
                          size: 14,
                          color: delegateEnabled
                              ? AppColors.success
                              : AppColors.danger,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            delegateEnabled ? 'المندوب متاح' : 'المندوب مغلق',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: delegateEnabled
                                  ? AppColors.success
                                  : AppColors.danger,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onStart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.royalBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    minimumSize: const Size(0, 42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'بدء الرصد',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttendanceSubjectMetaChip extends StatelessWidget {
  const _AttendanceSubjectMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.slate400),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.slate600,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceSessionCard extends StatelessWidget {
  const _AttendanceSessionCard({
    required this.session,
    required this.onReport,
    required this.onEdit,
  });

  final Map<String, dynamic> session;
  final VoidCallback onReport;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final subject = _map(session['subject']);
    final lecture = _map(session['lecture']);

    final isQr =
        _text(session, 'attendance_method', fallback: 'manual') == 'qr';
    final dateRaw = _normalizeApiDate(_text(session, 'date'));
    final dateLabel = _formatCompactDate(
      _text(session, 'display_date', fallback: dateRaw),
    );

    final subjectName = _text(subject, 'name');
    final lectureTitle = _text(lecture, 'title', fallback: 'محاضرة غير محددة');
    final totalRecords = _int(session['total_records']);

    return InkWell(
      onTap: onReport,
      borderRadius: BorderRadius.circular(24),
      child: _GlassCard(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            // Circular method icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isQr
                      ? [AppColors.teal, Colors.tealAccent]
                      : [AppColors.royalBlue, Colors.blueAccent],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isQr ? Icons.qr_code_rounded : Icons.edit_calendar_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            // Session Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subjectName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: AppColors.midnight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$lectureTitle | $dateLabel | $totalRecords طالب',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.slate500,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Edit Session Action
            IconButton(
              onPressed: onEdit,
              icon: const Icon(
                Icons.edit_rounded,
                color: AppColors.royalBlue,
                size: 20,
              ),
              tooltip: 'تعديل السجل',
            ),
            const Icon(Icons.chevron_left_rounded, color: AppColors.slate300),
          ],
        ),
      ),
    );
  }
}

class _PremiumTabBar extends StatelessWidget {
  const _PremiumTabBar({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.slate100.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TabBar(
        controller: controller,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.slate600,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [AppColors.royalBlue, AppColors.teal],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.royalBlue.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
        tabs: const [
          Tab(
            height: 44,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_stories_rounded, size: 18),
                SizedBox(width: 8),
                Text('المواد الدراسية'),
              ],
            ),
          ),
          Tab(
            height: 44,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics_rounded, size: 18),
                SizedBox(width: 8),
                Text('تقارير السجلات'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryFiltersHeader extends StatelessWidget {
  const _HistoryFiltersHeader({
    required this.onSearch,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onClear,
  });

  final ValueChanged<String> onSearch;
  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onDateSelected;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        children: [
          TextField(
            onChanged: onSearch,
            style: const TextStyle(fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: 'بحث باسم المحاضرة أو المادة...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.royalBlue,
              ),
              filled: true,
              fillColor: AppColors.slate50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2023),
                      lastDate: DateTime.now(),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: AppColors.royalBlue,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) onDateSelected(picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.slate50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          size: 18,
                          color: AppColors.slate500,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          selectedDate == null
                              ? 'فلترة بالتاريخ'
                              : intl.DateFormat(
                                  'yMMMMEEEEd',
                                  'ar',
                                ).format(selectedDate!),
                          style: TextStyle(
                            color: selectedDate == null
                                ? AppColors.slate500
                                : AppColors.midnight,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (selectedDate != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8),
                  child: IconButton.filledTonal(
                    onPressed: onClear,
                    icon: const Icon(Icons.filter_list_off_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.danger.withValues(alpha: 0.1),
                      foregroundColor: AppColors.danger,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _AttendanceStudentTile extends StatelessWidget {
  const _AttendanceStudentTile({
    required this.student,
    required this.status,
    required this.onChanged,
  });

  final Map<String, dynamic> student;
  final String status;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: _workflowCard(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _text(student, 'name'),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  _text(student, 'student_number'),
                  style: const TextStyle(
                    color: AppColors.slate500,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          DropdownButton<String>(
            value: status,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: 'present', child: Text('حاضر')),
              DropdownMenuItem(value: 'absent', child: Text('غائب')),
              DropdownMenuItem(value: 'permitted', child: Text('مستأذن')),
              DropdownMenuItem(value: 'exempted', child: Text('إعفاء')),
            ],
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          ),
        ],
      ),
    );
  }
}

class _ReportSubjectCard extends StatelessWidget {
  const _ReportSubjectCard({required this.subject, required this.onTap});

  final Map<String, dynamic> subject;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rate = _int(subject['attendance_rate']);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.slate200),
          boxShadow: [
            BoxShadow(
              color: _rateColor(rate).withValues(alpha: 0.03),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.royalBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: AppColors.royalBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _text(subject, 'name'),
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.midnight,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${_text(subject, 'major')} • ${_text(subject, 'level')}',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _rateColor(rate).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _rateColor(rate).withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text(
                    '$rate%',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: _rateColor(rate),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: rate / 100,
                color: _rateColor(rate),
                backgroundColor: AppColors.slate100,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSubjectStatPill(
                    'طلاب',
                    _int(subject['students_count']),
                    AppColors.info,
                  ),
                  const SizedBox(width: 6),
                  _buildSubjectStatPill(
                    'محاضرات',
                    _int(subject['lectures_count']),
                    AppColors.royalBlue,
                  ),
                  const SizedBox(width: 6),
                  _buildSubjectStatPill(
                    'حاضر',
                    _int(subject['present_count']),
                    AppColors.success,
                  ),
                  const SizedBox(width: 6),
                  _buildSubjectStatPill(
                    'غائب',
                    _int(subject['absent_count']),
                    AppColors.danger,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectStatPill(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.slate200, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'Cairo',
              color: AppColors.slate500,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '$value',
            style: const TextStyle(
              fontFamily: 'Cairo',
              color: AppColors.midnight,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class TinyStat extends StatelessWidget {
  const TinyStat(this.label, this.value, this.color, {super.key});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _WorkflowEmpty extends StatelessWidget {
  const _WorkflowEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _workflowCard(),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.slate500,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _WorkflowError extends StatefulWidget {
  const _WorkflowError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  State<_WorkflowError> createState() => _WorkflowErrorState();
}

class _WorkflowErrorState extends State<_WorkflowError> {
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
        : widget.error.toString();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              subscriptionRequired
                  ? Icons.lock_rounded
                  : Icons.error_outline_rounded,
              color: subscriptionRequired
                  ? AppColors.goldDeep
                  : AppColors.danger,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: widget.onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('إعادة المحاولة'),
                ),
                if (subscriptionRequired)
                  FilledButton.icon(
                    onPressed: () =>
                        context.go(staffSubscriptionRouteFor(context)),
                    icon: const Icon(Icons.workspace_premium_rounded),
                    label: const Text('الاشتراك الآن'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _workflowCard() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: AppColors.slate100),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.02),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

List<Map<String, dynamic>> _list(Object? value) {
  if (value is! List) return const [];
  return value.whereType<Map>().map(_map).toList();
}

String _text(Map<String, dynamic> map, String key, {String fallback = ''}) {
  final value = map[key];
  if (value == null || value.toString().isEmpty) return fallback;
  return value.toString();
}

int _int(Object? value) => int.tryParse((value ?? 0).toString()) ?? 0;

String _normalizeApiDate(String value) {
  if (value.isEmpty) return value;
  final parsed = DateTime.tryParse(value);
  if (parsed != null) {
    return intl.DateFormat('yyyy-MM-dd').format(parsed.toLocal());
  }
  return value.length >= 10 ? value.substring(0, 10) : value;
}

String _formatCompactDate(String value) {
  if (value.isEmpty) return '-';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  try {
    return intl.DateFormat('d MMM yyyy', 'ar').format(parsed.toLocal());
  } catch (_) {
    return intl.DateFormat('yyyy-MM-dd').format(parsed.toLocal());
  }
}

String _normalizeAttendanceStatus(String status) => switch (status) {
  'confirmed_present' || 'scanned_present' => 'present',
  'confirmed_absent' || 'unscanned_absent' => 'absent',
  _ => status,
};

Color _statusColor(String status) => switch (status) {
  'accepted' || 'present' => AppColors.success,
  'rejected' || 'absent' => AppColors.danger,
  'pending' || 'late' => AppColors.warning,
  'excused' || 'permitted' || 'exempted' => AppColors.info,
  _ => AppColors.royalBlue,
};

String _statusLabel(String status) => switch (status) {
  'accepted' => 'مقبول',
  'rejected' => 'مرفوض',
  'pending' => 'قيد المراجعة',
  'present' => 'حاضر',
  'absent' => 'غائب',
  'late' => 'متأخر',
  'excused' => 'بعذر',
  'permitted' => 'مستأذن',
  'exempted' => 'إعفاء',
  _ => status.isEmpty ? '-' : status,
};

Color _rateColor(int rate) {
  if (rate >= 70) return AppColors.success;
  if (rate >= 50) return AppColors.warning;
  return AppColors.danger;
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child, this.margin, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.zero,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DoctorMoeenTextField extends StatelessWidget {
  const _DoctorMoeenTextField({
    required this.controller,
    required this.labelText,
    required this.prefixIcon,
    this.readOnly = false,
    this.onTap,
    this.keyboardType,
    this.maxLines = 1,
    this.alignLabelWithHint = false,
  });

  final TextEditingController controller;
  final String labelText;
  final Widget prefixIcon;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextInputType? keyboardType;
  final int? maxLines;
  final bool alignLabelWithHint;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(
        fontFamily: 'Cairo',
        fontWeight: FontWeight.w700,
        color: AppColors.midnight,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        alignLabelWithHint: alignLabelWithHint,
        prefixIcon: prefixIcon,
        labelStyle: const TextStyle(
          fontFamily: 'Cairo',
          color: AppColors.slate500,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: const TextStyle(
          fontFamily: 'Cairo',
          color: AppColors.royalBlue,
          fontWeight: FontWeight.w800,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.slate200, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.royalBlue, width: 2),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.slate200, width: 1.5),
        ),
      ),
    );
  }
}

class _DoctorMoeenDropdownField<T> extends StatelessWidget {
  const _DoctorMoeenDropdownField({
    required this.initialValue,
    required this.labelText,
    required this.prefixIcon,
    required this.items,
    required this.onChanged,
  });

  final T initialValue;
  final String labelText;
  final Widget prefixIcon;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: initialValue,
      style: const TextStyle(
        fontFamily: 'Cairo',
        fontWeight: FontWeight.w700,
        color: AppColors.midnight,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: prefixIcon,
        labelStyle: const TextStyle(
          fontFamily: 'Cairo',
          color: AppColors.slate500,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: const TextStyle(
          fontFamily: 'Cairo',
          color: AppColors.royalBlue,
          fontWeight: FontWeight.w800,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.slate200, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.royalBlue, width: 2),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.slate200, width: 1.5),
        ),
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}

String _getInitials(String name) {
  if (name.isEmpty) return 'ط';
  final parts = name.trim().split(' ');
  if (parts.length > 1) return '${parts[0][0]}${parts[1][0]}';
  return parts[0][0];
}
