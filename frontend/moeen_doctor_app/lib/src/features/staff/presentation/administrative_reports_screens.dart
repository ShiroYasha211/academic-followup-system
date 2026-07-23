part of 'administrative_operations_screens.dart';

enum AdministrativeLevelSelectorMode { summary, threshold }

class AdministrativeSubjectSelectorScreen extends StatelessWidget {
  const AdministrativeSubjectSelectorScreen({super.key});

  static const route = '/administrative/reports/select-subject';

  @override
  Widget build(BuildContext context) {
    return const _AdministrativeSubjectSelectorView();
  }
}

class AdministrativeLevelSelectorScreen extends StatelessWidget {
  const AdministrativeLevelSelectorScreen({super.key, required this.mode});

  static const route = '/administrative/reports/select-level';

  final AdministrativeLevelSelectorMode mode;

  static String path(AdministrativeLevelSelectorMode mode) {
    final value =
        mode == AdministrativeLevelSelectorMode.threshold ? 'threshold' : 'summary';
    return '$route?mode=$value';
  }

  @override
  Widget build(BuildContext context) {
    return _AdministrativeLevelSelectorView(mode: mode);
  }
}

class AdministrativeSubjectReportScreen extends StatelessWidget {
  const AdministrativeSubjectReportScreen({
    super.key,
    required this.subjectId,
    this.dateStart,
    this.dateEnd,
  });

  static const route = '/administrative/reports/subject';

  final int subjectId;
  final String? dateStart;
  final String? dateEnd;

  static String path(int subjectId, {String? dateStart, String? dateEnd}) {
    final query = <String, String>{'subject_id': '$subjectId'};
    if (dateStart != null) query['date_start'] = dateStart;
    if (dateEnd != null) query['date_end'] = dateEnd;
    return Uri(path: route, queryParameters: query).toString();
  }

  @override
  Widget build(BuildContext context) {
    return _AdministrativeSubjectReportView(
      subjectId: subjectId,
      initialRange: _ReportDateRange.fromStrings(dateStart, dateEnd),
    );
  }
}

class AdministrativeThresholdReportScreen extends StatelessWidget {
  const AdministrativeThresholdReportScreen({
    super.key,
    required this.levelId,
    required this.threshold,
    this.dateStart,
    this.dateEnd,
  });

  static const route = '/administrative/reports/threshold';

  final int levelId;
  final int threshold;
  final String? dateStart;
  final String? dateEnd;

  static String path(
    int levelId,
    int threshold, {
    String? dateStart,
    String? dateEnd,
  }) {
    final query = <String, String>{
      'level_id': '$levelId',
      'threshold': '$threshold',
    };
    if (dateStart != null) query['date_start'] = dateStart;
    if (dateEnd != null) query['date_end'] = dateEnd;
    return Uri(path: route, queryParameters: query).toString();
  }

  @override
  Widget build(BuildContext context) {
    return _AdministrativeThresholdReportView(
      levelId: levelId,
      threshold: threshold,
      initialRange: _ReportDateRange.fromStrings(dateStart, dateEnd),
    );
  }
}

class AdministrativeLevelSummaryReportScreen extends StatelessWidget {
  const AdministrativeLevelSummaryReportScreen({
    super.key,
    required this.levelId,
    this.dateStart,
    this.dateEnd,
  });

  static const route = '/administrative/reports/level-summary';

  final int levelId;
  final String? dateStart;
  final String? dateEnd;

  static String path(int levelId, {String? dateStart, String? dateEnd}) {
    final query = <String, String>{'level_id': '$levelId'};
    if (dateStart != null) query['date_start'] = dateStart;
    if (dateEnd != null) query['date_end'] = dateEnd;
    return Uri(path: route, queryParameters: query).toString();
  }

  @override
  Widget build(BuildContext context) {
    return _AdministrativeLevelSummaryReportView(
      levelId: levelId,
      initialRange: _ReportDateRange.fromStrings(dateStart, dateEnd),
    );
  }
}

class AdministrativeDoctorPerformanceReportScreen extends StatelessWidget {
  const AdministrativeDoctorPerformanceReportScreen({super.key});

  static const route = '/administrative/reports/doctor-performance';

  @override
  Widget build(BuildContext context) {
    return const _AdministrativeDoctorPerformanceReportView();
  }
}

class AdministrativeComparisonReportScreen extends StatelessWidget {
  const AdministrativeComparisonReportScreen({super.key});

  static const route = '/administrative/reports/comparison';

  @override
  Widget build(BuildContext context) {
    return const _AdministrativeComparisonReportView();
  }
}

class _AdministrativeSubjectSelectorView extends ConsumerStatefulWidget {
  const _AdministrativeSubjectSelectorView();

  @override
  ConsumerState<_AdministrativeSubjectSelectorView> createState() =>
      _AdministrativeSubjectSelectorViewState();
}

class _AdministrativeSubjectSelectorViewState
    extends ConsumerState<_AdministrativeSubjectSelectorView> {
  late Future<Map<String, dynamic>> _future;
  final _search = TextEditingController();
  String _query = '';
  int? _majorId;
  int? _levelId;
  _ReportDateRange _range = _ReportDateRange.all();

  @override
  void initState() {
    super.initState();
    _future = _fetch();
    _search.addListener(() => setState(() => _query = _search.text.trim()));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetch() {
    return ref.read(_adminOpsRepositoryProvider).get('/administrative/reports');
  }

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'اختيار المادة',
      currentRoute: AdministrativeReportsScreen.route,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          return _ScaffoldBody(
            loading: snapshot.connectionState == ConnectionState.waiting,
            error: snapshot.error,
            onRetry: () => setState(() {
              _future = _fetch();
            }),
            child: _buildContent(_map(snapshot.data?['data'])),
          );
        },
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> data) {
    final majors = _list(data['majors']);
    final selectedMajor = majors.firstWhere(
      (major) => _int(major['id']) == _majorId,
      orElse: () => const {},
    );
    final subjects = _list(data['subjects']).where((subject) {
      final major = _map(subject['major']);
      final level = _map(subject['level']);
      final doctor = _map(subject['doctor']);
      final matchesMajor = _majorId == null || _int(major['id']) == _majorId;
      final matchesLevel = _levelId == null || _int(level['id']) == _levelId;
      if (!matchesMajor || !matchesLevel) return false;
      if (_query.isEmpty) return true;
      final text =
          '${subject['name'] ?? ''} ${major['name'] ?? ''} ${level['name'] ?? ''} ${doctor['name'] ?? ''}'
              .toLowerCase();
      return text.contains(_query.toLowerCase());
    }).toList();

    return RefreshIndicator(
      onRefresh: () {
        final future = _fetch();
        setState(() {
          _future = future;
        });
        return future;
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          const _ReportPageHero(
            title: 'اختيار المادة الدراسية',
            subtitle:
                'ابحث وفلتر المواد حسب التخصص والمستوى قبل استخراج كشف الحضور.',
            icon: Icons.menu_book_rounded,
            color: AppColors.royalBlue,
          ),
          const SizedBox(height: 16),
          _SearchBox(controller: _search, onSearch: () => setState(() {})),
          const SizedBox(height: 12),
          _ReportDateRangePicker(
            value: _range,
            onChanged: (range) => setState(() => _range = range),
          ),
          const SizedBox(height: 12),
          _ReportChoiceSection(
            title: 'التخصص',
            icon: Icons.account_tree_rounded,
            child: _ReportChoiceWrap(
              selectedId: _majorId,
              items: majors,
              onChanged: (value) => setState(() {
                _majorId = value;
                _levelId = null;
              }),
            ),
          ),
          if (_majorId != null) ...[
            const SizedBox(height: 12),
            _ReportChoiceSection(
              title: 'المستوى',
              icon: Icons.layers_rounded,
              child: _ReportChoiceWrap(
                selectedId: _levelId,
                items: _list(selectedMajor['levels']),
                onChanged: (value) => setState(() => _levelId = value),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _SectionTitle('المواد المطابقة (${subjects.length})', Icons.fact_check_rounded),
          const SizedBox(height: 12),
          if (subjects.isEmpty)
            const _EmptyState()
          else
            ...subjects.map(
              (subject) => _SubjectSelectorCard(
                subject: subject,
                onTap: () => context.push(
                  AdministrativeSubjectReportScreen.path(
                    _int(subject['id']),
                    dateStart: _range.queryString['date_start'],
                    dateEnd: _range.queryString['date_end'],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AdministrativeLevelSelectorView extends ConsumerStatefulWidget {
  const _AdministrativeLevelSelectorView({required this.mode});

  final AdministrativeLevelSelectorMode mode;

  @override
  ConsumerState<_AdministrativeLevelSelectorView> createState() =>
      _AdministrativeLevelSelectorViewState();
}

class _AdministrativeLevelSelectorViewState
    extends ConsumerState<_AdministrativeLevelSelectorView> {
  late Future<Map<String, dynamic>> _future;
  int? _majorId;
  int _threshold = 25;
  _ReportDateRange _range = _ReportDateRange.all();

  bool get _isThreshold =>
      widget.mode == AdministrativeLevelSelectorMode.threshold;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<Map<String, dynamic>> _fetch() {
    return ref.read(_adminOpsRepositoryProvider).get('/administrative/reports');
  }

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: _isThreshold ? 'اختيار مستوى للإنذارات' : 'اختيار الدفعة',
      currentRoute: AdministrativeReportsScreen.route,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          return _ScaffoldBody(
            loading: snapshot.connectionState == ConnectionState.waiting,
            error: snapshot.error,
            onRetry: () => setState(() {
              _future = _fetch();
            }),
            child: _buildContent(_map(snapshot.data?['data'])),
          );
        },
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> data) {
    final majors = _list(data['majors']);
    final selectedMajor = majors.firstWhere(
      (major) => _int(major['id']) == _majorId,
      orElse: () => const {},
    );
    final levels =
        _majorId == null ? const <Map<String, dynamic>>[] : _list(selectedMajor['levels']);
    final color = _isThreshold ? AppColors.danger : AppColors.teal;

    return RefreshIndicator(
      onRefresh: () {
        final future = _fetch();
        setState(() {
          _future = future;
        });
        return future;
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          _ReportPageHero(
            title: _isThreshold ? 'تقرير الإنذارات' : 'ملخص الدفعات',
            subtitle: _isThreshold
                ? 'اختر التخصص والمستوى وحدد عتبة الغياب المطلوبة.'
                : 'اختر التخصص والمستوى لعرض ملخص الدفعة الأكاديمي.',
            icon: _isThreshold ? Icons.warning_rounded : Icons.layers_rounded,
            color: color,
          ),
          const SizedBox(height: 16),
          _ReportDateRangePicker(
            value: _range,
            onChanged: (range) => setState(() => _range = range),
          ),
          const SizedBox(height: 12),
          _ReportChoiceSection(
            title: 'التخصص',
            icon: Icons.account_tree_rounded,
            child: _ReportChoiceWrap(
              selectedId: _majorId,
              items: majors,
              onChanged: (value) => setState(() => _majorId = value),
            ),
          ),
          if (_isThreshold) ...[
            const SizedBox(height: 12),
            _ReportChoiceSection(
              title: 'نسبة الغياب',
              icon: Icons.percent_rounded,
              child: Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _threshold.toDouble(),
                      min: 1,
                      max: 100,
                      divisions: 99,
                      activeColor: AppColors.danger,
                      onChanged: (value) =>
                          setState(() => _threshold = value.round()),
                    ),
                  ),
                  _AdminChip(label: '$_threshold%', color: AppColors.danger),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _SectionTitle(
            _majorId == null ? 'اختر تخصصًا أولًا' : 'المستويات المتاحة',
            Icons.layers_rounded,
          ),
          const SizedBox(height: 12),
          if (_majorId == null)
            const _AdminEmptyDetailsNote(
              icon: Icons.touch_app_rounded,
              message: 'اختر التخصص من الأعلى لعرض المستويات التابعة له فقط.',
            )
          else if (levels.isEmpty)
            const _EmptyState()
          else
            ...levels.map(
              (level) => _LevelSelectorCard(
                level: level,
                major: selectedMajor,
                color: color,
                actionLabel: _isThreshold ? 'فحص التجاوزات' : 'عرض الملخص',
                onTap: () {
                  final levelId = _int(level['id']);
                  if (_isThreshold) {
                    context.push(
                      AdministrativeThresholdReportScreen.path(
                        levelId,
                        _threshold,
                        dateStart: _range.queryString['date_start'],
                        dateEnd: _range.queryString['date_end'],
                      ),
                    );
                  } else {
                    context.push(
                      AdministrativeLevelSummaryReportScreen.path(
                        levelId,
                        dateStart: _range.queryString['date_start'],
                        dateEnd: _range.queryString['date_end'],
                      ),
                    );
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _AdministrativeSubjectReportView extends ConsumerStatefulWidget {
  const _AdministrativeSubjectReportView({
    required this.subjectId,
    required this.initialRange,
  });

  final int subjectId;
  final _ReportDateRange initialRange;

  @override
  ConsumerState<_AdministrativeSubjectReportView> createState() =>
      _AdministrativeSubjectReportViewState();
}

class _AdministrativeSubjectReportViewState
    extends ConsumerState<_AdministrativeSubjectReportView> {
  late Future<Map<String, dynamic>> _future;
  late _ReportDateRange _range;
  final _search = TextEditingController();
  String _query = '';
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _range = widget.initialRange;
    _future = _fetch();
    _search.addListener(() => setState(() => _query = _search.text.trim()));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _queryParams => {
        'subject_id': widget.subjectId,
        ..._range.query,
      };

  Future<Map<String, dynamic>> _fetch() {
    return ref.read(_adminOpsRepositoryProvider).get(
      '/administrative/reports/subject',
      query: _queryParams,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'تقرير المادة',
      currentRoute: AdministrativeReportsScreen.route,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          return _ScaffoldBody(
            loading: snapshot.connectionState == ConnectionState.waiting,
            error: snapshot.error,
            onRetry: () => setState(() {
              _future = _fetch();
            }),
            child: _buildReport(_map(snapshot.data?['data'])),
          );
        },
      ),
    );
  }

  Widget _buildReport(Map<String, dynamic> data) {
    final subject = _map(data['subject']);
    final major = _map(subject['major']);
    final level = _map(subject['level']);
    final doctor = _map(subject['doctor']);
    final summary = _map(data['summary']);
    final rows = _list(data['report']).where((row) {
      if (_query.isEmpty) return true;
      final student = _map(row['student']);
      final text = '${student['name'] ?? ''} ${student['student_number'] ?? ''}'
          .toLowerCase();
      return text.contains(_query.toLowerCase());
    }).toList();

    return RefreshIndicator(
      onRefresh: () {
        final future = _fetch();
        setState(() {
          _future = future;
        });
        return future;
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          _ReportPageHero(
            title: 'كشف حضور وغياب الطلاب',
            subtitle: (subject['name'] ?? 'تقرير المادة').toString(),
            icon: Icons.file_copy_rounded,
            color: AppColors.royalBlue,
            trailing: _ReportExportActions(
              loading: _downloading,
              color: AppColors.royalBlue,
              onPdf: () => _download('/administrative/reports/subject/pdf', 'pdf'),
              onExcel: () =>
                  _download('/administrative/reports/subject/excel', 'csv'),
            ),
          ),
          const SizedBox(height: 16),
          _ReportDateRangePicker(
            value: _range,
            onChanged: (range) => setState(() {
              _range = range;
              _future = _fetch();
            }),
          ),
          const SizedBox(height: 12),
          _ExecutiveSummaryPanel(
            color: AppColors.royalBlue,
            items: [
              _SummaryItem('الطلاب', summary['students_count'] ?? rows.length, Icons.groups_rounded),
              _SummaryItem('إنذارات', summary['warning_count'] ?? 0, Icons.warning_rounded),
              _SummaryItem('حرمان', summary['deprived_count'] ?? 0, Icons.block_rounded),
              _SummaryItem('متوسط الغياب', '${summary['average_absence_percentage'] ?? 0}%', Icons.percent_rounded),
            ],
          ),
          const SizedBox(height: 14),
          _SubjectIdentityCard(
            subject: subject,
            major: major,
            level: level,
            doctor: doctor,
            range: _range,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SearchBox(
                  controller: _search,
                  onSearch: () => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.16)),
                ),
                child: Text(
                  '${rows.length} طالب',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    color: AppColors.royalBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (rows.isEmpty)
            const _EmptyState()
          else
            ...rows.asMap().entries.map(
                  (entry) => _SubjectStudentReportCard(
                    index: entry.key + 1,
                    row: entry.value,
                    subject: subject,
                  ),
                ),
        ],
      ),
    );
  }

  Future<void> _download(String endpoint, String extension) async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final bytes = await ref
          .read(_adminOpsRepositoryProvider)
          .download(endpoint, query: _queryParams);
      final result = await DownloadService.saveBytes(
        bytes: bytes,
        fileName:
            'administrative_subject_report_${widget.subjectId}_${DateTime.now().millisecondsSinceEpoch}.$extension',
        section: 'AdministrativeReports',
      );
      if (!mounted) return;
      await _showDownloadResult(context, result);
    } catch (error) {
      if (!mounted) return;
      await _showError(context, error is ApiException ? error.message : error.toString());
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }
}

class _AdministrativeThresholdReportView extends ConsumerStatefulWidget {
  const _AdministrativeThresholdReportView({
    required this.levelId,
    required this.threshold,
    required this.initialRange,
  });

  final int levelId;
  final int threshold;
  final _ReportDateRange initialRange;

  @override
  ConsumerState<_AdministrativeThresholdReportView> createState() =>
      _AdministrativeThresholdReportViewState();
}

class _AdministrativeThresholdReportViewState
    extends ConsumerState<_AdministrativeThresholdReportView> {
  late Future<Map<String, dynamic>> _future;
  late _ReportDateRange _range;
  final _search = TextEditingController();
  String _query = '';
  bool _downloading = false;
  bool _notifying = false;

  @override
  void initState() {
    super.initState();
    _range = widget.initialRange;
    _future = _fetch();
    _search.addListener(() => setState(() => _query = _search.text.trim()));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _queryParams => {
        'level_id': widget.levelId,
        'threshold': widget.threshold,
        ..._range.query,
      };

  Future<Map<String, dynamic>> _fetch() {
    return ref.read(_adminOpsRepositoryProvider).get(
      '/administrative/reports/threshold',
      query: _queryParams,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'تقرير الإنذارات',
      currentRoute: AdministrativeReportsScreen.route,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          return _ScaffoldBody(
            loading: snapshot.connectionState == ConnectionState.waiting,
            error: snapshot.error,
            onRetry: () => setState(() {
              _future = _fetch();
            }),
            child: _buildReport(_map(snapshot.data?['data'])),
          );
        },
      ),
    );
  }

  Widget _buildReport(Map<String, dynamic> data) {
    final level = _map(data['level']);
    final major = _map(level['major']);
    final summary = _map(data['summary']);
    final alerts = _list(data['alerts']).where((row) {
      if (_query.isEmpty) return true;
      final student = _map(row['student']);
      final subject = _map(row['subject']);
      final text =
          '${student['name'] ?? ''} ${student['student_number'] ?? ''} ${subject['name'] ?? ''}'
              .toLowerCase();
      return text.contains(_query.toLowerCase());
    }).toList();

    final criticalCount = _int(summary['critical_count']);
    final warningCount = _int(summary['warning_count']);

    return RefreshIndicator(
      onRefresh: () {
        final future = _fetch();
        setState(() {
          _future = future;
        });
        return future;
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          _ReportPageHero(
            title: 'كشف حالات تجاوز الغياب',
            subtitle: '${major['name'] ?? '-'} - ${level['name'] ?? '-'}',
            icon: Icons.warning_rounded,
            color: AppColors.danger,
            trailing: _ReportExportActions(
              loading: _downloading,
              color: AppColors.danger,
              onPdf: () => _download('/administrative/reports/threshold/pdf', 'pdf'),
              onExcel: () =>
                  _download('/administrative/reports/threshold/excel', 'csv'),
            ),
          ),
          const SizedBox(height: 16),
          _ReportDateRangePicker(
            value: _range,
            onChanged: (range) => setState(() {
              _range = range;
              _future = _fetch();
            }),
          ),
          const SizedBox(height: 12),
          _ExecutiveSummaryPanel(
            color: AppColors.danger,
            items: [
              _SummaryItem('الحالات', summary['alerts_count'] ?? alerts.length, Icons.warning_rounded),
              _SummaryItem('حرمان', summary['critical_count'] ?? 0, Icons.block_rounded),
              _SummaryItem('إنذار', summary['warning_count'] ?? 0, Icons.notification_important_rounded),
              _SummaryItem('أعلى نسبة', '${summary['highest_percentage'] ?? 0}%', Icons.trending_up_rounded),
            ],
          ),
          const SizedBox(height: 14),
          // Level identity card
          _LevelIdentityCard(
            major: major,
            level: level,
            threshold: widget.threshold,
            range: _range,
          ),
          const SizedBox(height: 14),
          // Notification action card
          _ThresholdNotificationCard(
            criticalCount: criticalCount,
            warningCount: warningCount,
            alertsCount: alerts.length,
            loading: _notifying,
            onSend: _notifying || alerts.isEmpty ? null : _sendNotifications,
          ),
          const SizedBox(height: 14),
          // Search + count row
          Row(
            children: [
              Expanded(
                child: _SearchBox(
                  controller: _search,
                  onSearch: () => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.16)),
                ),
                child: Text(
                  '${alerts.length} حالة',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    color: AppColors.danger,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (alerts.isEmpty)
            const _AdminEmptyDetailsNote(
              icon: Icons.verified_rounded,
              message: 'لا توجد حالات تجاوزت الحد المحدد في هذا المستوى.',
            )
          else
            ...alerts.asMap().entries.map(
                  (entry) => _ThresholdAlertCard(index: entry.key + 1, row: entry.value),
                ),
        ],
      ),
    );
  }

  Future<void> _download(String endpoint, String extension) async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final bytes = await ref
          .read(_adminOpsRepositoryProvider)
          .download(endpoint, query: _queryParams);
      final result = await DownloadService.saveBytes(
        bytes: bytes,
        fileName:
            'administrative_threshold_report_${widget.levelId}_${widget.threshold}_${DateTime.now().millisecondsSinceEpoch}.$extension',
        section: 'AdministrativeReports',
      );
      if (!mounted) return;
      await _showDownloadResult(context, result);
    } catch (error) {
      if (!mounted) return;
      await _showError(context, error is ApiException ? error.message : error.toString());
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _sendNotifications() async {
    final confirmed = await showMoeenConfirmDialog(
      context: context,
      title: 'إرسال تنبيهات الغياب؟',
      message:
          'سيتم إرسال تنبيه داخل التطبيق لكل طالب تجاوز نسبة الغياب المحددة لهذا التقرير.',
      confirmLabel: 'إرسال التنبيهات',
      cancelLabel: 'إلغاء',
      icon: Icons.campaign_rounded,
      color: AppColors.danger,
    );
    if (!confirmed || !mounted) return;
    setState(() => _notifying = true);
    try {
      final response = await ref
          .read(_adminOpsRepositoryProvider)
          .post('/administrative/reports/threshold/notify', _queryParams);
      if (!mounted) return;
      final data = _map(response['data']);
      await showMoeenInfoDialog(
        context: context,
        title: 'تم إرسال التنبيهات',
        message: 'عدد الطلاب الذين تم تنبيههم: ${data['recipients_count'] ?? 0}',
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
      );
    } catch (error) {
      if (!mounted) return;
      await _showError(context, error is ApiException ? error.message : error.toString());
    } finally {
      if (mounted) setState(() => _notifying = false);
    }
  }
}

class _AdministrativeLevelSummaryReportView extends ConsumerStatefulWidget {
  const _AdministrativeLevelSummaryReportView({
    required this.levelId,
    required this.initialRange,
  });

  final int levelId;
  final _ReportDateRange initialRange;

  @override
  ConsumerState<_AdministrativeLevelSummaryReportView> createState() =>
      _AdministrativeLevelSummaryReportViewState();
}

class _AdministrativeLevelSummaryReportViewState
    extends ConsumerState<_AdministrativeLevelSummaryReportView> {
  late Future<Map<String, dynamic>> _future;
  late _ReportDateRange _range;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _range = widget.initialRange;
    _future = _fetch();
  }

  Map<String, dynamic> get _queryParams => {
        'level_id': widget.levelId,
        ..._range.query,
      };

  Future<Map<String, dynamic>> _fetch() {
    return ref.read(_adminOpsRepositoryProvider).get(
      '/administrative/reports/level-summary',
      query: _queryParams,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'ملخص الدفعة',
      currentRoute: AdministrativeReportsScreen.route,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          return _ScaffoldBody(
            loading: snapshot.connectionState == ConnectionState.waiting,
            error: snapshot.error,
            onRetry: () => setState(() {
              _future = _fetch();
            }),
            child: _buildReport(_map(snapshot.data?['data'])),
          );
        },
      ),
    );
  }

  Widget _buildReport(Map<String, dynamic> data) {
    final level = _map(data['level']);
    final major = _map(level['major']);
    final delegate = _map(data['delegate']);
    final summary = _map(data['summary']);
    final subjectStats = _list(data['subject_stats']);

    final avgRate = double.tryParse('${summary['average_attendance_rate'] ?? 0}') ?? 0;
    final avgColor = avgRate >= 70
        ? AppColors.success
        : avgRate >= 45
            ? AppColors.goldDeep
            : AppColors.danger;

    return RefreshIndicator(
      onRefresh: () {
        final future = _fetch();
        setState(() {
          _future = future;
        });
        return future;
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          _ReportPageHero(
            title: 'ملخص الدفعة الدراسية',
            subtitle: '${major['name'] ?? '-'} - ${level['name'] ?? '-'}',
            icon: Icons.layers_rounded,
            color: AppColors.teal,
            trailing: _ReportExportActions(
              loading: _downloading,
              color: AppColors.teal,
              onPdf: () => _download('/administrative/reports/level-summary/pdf', 'pdf'),
              onExcel: () =>
                  _download('/administrative/reports/level-summary/excel', 'csv'),
            ),
          ),
          const SizedBox(height: 16),
          _ReportDateRangePicker(
            value: _range,
            onChanged: (range) => setState(() {
              _range = range;
              _future = _fetch();
            }),
          ),
          const SizedBox(height: 12),
          _ExecutiveSummaryPanel(
            color: AppColors.teal,
            items: [
              _SummaryItem('\u0627\u0644\u0637\u0644\u0627\u0628', summary['students_count'] ?? 0, Icons.groups_rounded),
              _SummaryItem('\u0627\u0644\u0645\u0648\u0627\u062f', summary['subjects_count'] ?? subjectStats.length, Icons.menu_book_rounded),
              _SummaryItem('\u0645\u062a\u0648\u0633\u0637 \u0627\u0644\u062d\u0636\u0648\u0631', '${summary['average_attendance_rate'] ?? 0}%', Icons.trending_up_rounded),
              _SummaryItem('\u0625\u0646\u0630\u0627\u0631\u0627\u062a', summary['warning_count'] ?? 0, Icons.warning_rounded),
            ],
          ),
          const SizedBox(height: 14),
          // Level identity card
          _LevelSummaryIdentityCard(
            major: major,
            level: level,
            delegate: delegate,
            range: _range,
            avgRate: avgRate,
            avgColor: avgColor,
          ),
          const SizedBox(height: 16),
          // Section header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.stacked_bar_chart_rounded, color: AppColors.teal, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  '\u0645\u0635\u0641\u0648\u0641\u0629 \u0623\u062f\u0627\u0621 \u0627\u0644\u0645\u0648\u0627\u062f',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: AppColors.midnight,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.teal.withValues(alpha: 0.16)),
                ),
                child: Text(
                  '${subjectStats.length} \u0645\u0627\u062f\u0629',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    fontSize: 11.5,
                    color: AppColors.teal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (subjectStats.isEmpty)
            const _EmptyState()
          else
            ...subjectStats.asMap().entries.map(
              (entry) => _LevelSubjectPerformanceCard(
                stat: entry.value,
                index: entry.key + 1,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _download(String endpoint, String extension) async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final bytes = await ref
          .read(_adminOpsRepositoryProvider)
          .download(endpoint, query: _queryParams);
      final result = await DownloadService.saveBytes(
        bytes: bytes,
        fileName:
            'administrative_level_summary_${widget.levelId}_${DateTime.now().millisecondsSinceEpoch}.$extension',
        section: 'AdministrativeReports',
      );
      if (!mounted) return;
      await _showDownloadResult(context, result);
    } catch (error) {
      if (!mounted) return;
      await _showError(context, error is ApiException ? error.message : error.toString());
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }
}

class _AdministrativeDoctorPerformanceReportView extends ConsumerStatefulWidget {
  const _AdministrativeDoctorPerformanceReportView();

  @override
  ConsumerState<_AdministrativeDoctorPerformanceReportView> createState() =>
      _AdministrativeDoctorPerformanceReportViewState();
}

class _AdministrativeDoctorPerformanceReportViewState
    extends ConsumerState<_AdministrativeDoctorPerformanceReportView> {
  late Future<Map<String, dynamic>> _future;
  _ReportDateRange _range = _ReportDateRange.all();
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Map<String, dynamic> get _queryParams => _range.query;

  Future<Map<String, dynamic>> _fetch() {
    return ref
        .read(_adminOpsRepositoryProvider)
        .get('/administrative/reports/doctor-performance', query: _queryParams);
  }

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'أداء الكادر',
      currentRoute: AdministrativeReportsScreen.route,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          return _ScaffoldBody(
            loading: snapshot.connectionState == ConnectionState.waiting,
            error: snapshot.error,
            onRetry: () => setState(() {
              _future = _fetch();
            }),
            child: _buildReport(_map(snapshot.data?['data'])),
          );
        },
      ),
    );
  }

  Widget _buildReport(Map<String, dynamic> data) {
    final summary = _map(data['summary']);
    final doctors = _list(data['doctors']);

    return RefreshIndicator(
      onRefresh: () {
        final future = _fetch();
        setState(() {
          _future = future;
        });
        return future;
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          _ReportPageHero(
            title: 'أداء الكادر التعليمي',
            subtitle: 'متابعة نشاط جلسات التحضير ونسب حضور الطلاب لكل دكتور.',
            icon: Icons.school_rounded,
            color: AppColors.violet,
            trailing: _ReportExportActions(
              loading: _downloading,
              color: AppColors.violet,
              onPdf: () =>
                  _download('/administrative/reports/doctor-performance/pdf', 'pdf'),
              onExcel: () => _download(
                '/administrative/reports/doctor-performance/excel',
                'csv',
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ReportDateRangePicker(
            value: _range,
            onChanged: (range) => setState(() {
              _range = range;
              _future = _fetch();
            }),
          ),
          const SizedBox(height: 12),
          _ExecutiveSummaryPanel(
            color: AppColors.violet,
            items: [
              _SummaryItem('الدكاترة', summary['doctors_count'] ?? doctors.length, Icons.groups_rounded),
              _SummaryItem('نشطون', summary['active_doctors_count'] ?? 0, Icons.qr_code_rounded),
              _SummaryItem('متوسط الحضور', '${summary['average_attendance_rate'] ?? 0}%', Icons.trending_up_rounded),
            ],
          ),
          const SizedBox(height: 16),
          if (doctors.isEmpty)
            const _EmptyState()
          else
            ...doctors.asMap().entries.map(
                  (entry) => _DoctorPerformanceCard(
                    index: entry.key + 1,
                    doctor: entry.value,
                  ),
                ),
        ],
      ),
    );
  }

  Future<void> _download(String endpoint, String extension) async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final bytes = await ref
          .read(_adminOpsRepositoryProvider)
          .download(endpoint, query: _queryParams);
      final result = await DownloadService.saveBytes(
        bytes: bytes,
        fileName:
            'administrative_doctor_performance_${DateTime.now().millisecondsSinceEpoch}.$extension',
        section: 'AdministrativeReports',
      );
      if (!mounted) return;
      await _showDownloadResult(context, result);
    } catch (error) {
      if (!mounted) return;
      await _showError(context, error is ApiException ? error.message : error.toString());
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }
}

class _AdministrativeComparisonReportView extends ConsumerStatefulWidget {
  const _AdministrativeComparisonReportView();

  @override
  ConsumerState<_AdministrativeComparisonReportView> createState() =>
      _AdministrativeComparisonReportViewState();
}

class _AdministrativeComparisonReportViewState
    extends ConsumerState<_AdministrativeComparisonReportView> {
  late Future<Map<String, dynamic>> _future;
  _ReportDateRange _range = _ReportDateRange.all();
  String _type = 'subjects';
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Map<String, dynamic> get _queryParams => {
        'type': _type,
        ..._range.query,
      };

  Future<Map<String, dynamic>> _fetch() {
    return ref
        .read(_adminOpsRepositoryProvider)
        .get('/administrative/reports/comparison', query: _queryParams);
  }

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'مقارنة التقارير',
      currentRoute: AdministrativeReportsScreen.route,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          return _ScaffoldBody(
            loading: snapshot.connectionState == ConnectionState.waiting,
            error: snapshot.error,
            onRetry: () => setState(() {
              _future = _fetch();
            }),
            child: _buildReport(_map(snapshot.data?['data'])),
          );
        },
      ),
    );
  }

  Widget _buildReport(Map<String, dynamic> data) {
    final summary = _map(data['summary']);
    final items = _list(data['items']);
    return RefreshIndicator(
      onRefresh: () {
        final future = _fetch();
        setState(() {
          _future = future;
        });
        return future;
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          _ReportPageHero(
            title: 'مقارنة المستويات والمواد',
            subtitle: 'قارن نسب الحضور لاكتشاف أفضل وأضعف نقاط الأداء الأكاديمي.',
            icon: Icons.compare_arrows_rounded,
            color: AppColors.goldDeep,
            trailing: _ReportExportActions(
              loading: _downloading,
              color: AppColors.goldDeep,
              onPdf: null,
              onExcel: () =>
                  _download('/administrative/reports/comparison/excel', 'csv'),
            ),
          ),
          const SizedBox(height: 16),
          _ReportChoiceSection(
            title: 'نوع المقارنة',
            icon: Icons.compare_rounded,
            child: Wrap(
              spacing: 8,
              children: [
                _ReportChoiceChip(
                  label: 'المواد',
                  selected: _type == 'subjects',
                  onTap: () => setState(() {
                    _type = 'subjects';
                    _future = _fetch();
                  }),
                ),
                _ReportChoiceChip(
                  label: 'المستويات',
                  selected: _type == 'levels',
                  onTap: () => setState(() {
                    _type = 'levels';
                    _future = _fetch();
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ReportDateRangePicker(
            value: _range,
            onChanged: (range) => setState(() {
              _range = range;
              _future = _fetch();
            }),
          ),
          const SizedBox(height: 12),
          _ExecutiveSummaryPanel(
            color: AppColors.goldDeep,
            items: [
              _SummaryItem('العناصر', summary['items_count'] ?? items.length, Icons.list_alt_rounded),
              _SummaryItem('المتوسط', '${summary['average_attendance_rate'] ?? 0}%', Icons.trending_up_rounded),
              _SummaryItem('الأفضل', _map(summary['best'])['name'] ?? '-', Icons.emoji_events_rounded),
              _SummaryItem('الأضعف', _map(summary['weakest'])['name'] ?? '-', Icons.trending_down_rounded),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const _EmptyState()
          else
            ...items.asMap().entries.map(
                  (entry) => _ComparisonCard(
                    index: entry.key + 1,
                    item: entry.value,
                    type: _type,
                  ),
                ),
        ],
      ),
    );
  }

  Future<void> _download(String endpoint, String extension) async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final bytes = await ref
          .read(_adminOpsRepositoryProvider)
          .download(endpoint, query: _queryParams);
      final result = await DownloadService.saveBytes(
        bytes: bytes,
        fileName:
            'administrative_comparison_${_type}_${DateTime.now().millisecondsSinceEpoch}.$extension',
        section: 'AdministrativeReports',
      );
      if (!mounted) return;
      await _showDownloadResult(context, result);
    } catch (error) {
      if (!mounted) return;
      await _showError(context, error is ApiException ? error.message : error.toString());
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }
}

class _ReportDateRange {
  const _ReportDateRange._(this.label, this.start, this.end);

  final String label;
  final DateTime? start;
  final DateTime? end;

  factory _ReportDateRange.all() => const _ReportDateRange._('كل الفترات', null, null);

  factory _ReportDateRange.fromStrings(String? start, String? end) {
    final parsedStart = start == null ? null : DateTime.tryParse(start);
    final parsedEnd = end == null ? null : DateTime.tryParse(end);
    if (parsedStart == null && parsedEnd == null) return _ReportDateRange.all();
    return _ReportDateRange._(
      _rangeLabel(parsedStart, parsedEnd),
      parsedStart,
      parsedEnd,
    );
  }

  Map<String, dynamic> get query => {
        if (start != null) 'date_start': _formatDateYmd(start),
        if (end != null) 'date_end': _formatDateYmd(end),
      };

  Map<String, String> get queryString => {
        if (start != null) 'date_start': _formatDateYmd(start),
        if (end != null) 'date_end': _formatDateYmd(end),
      };
}

class _ReportDateRangePicker extends StatelessWidget {
  const _ReportDateRangePicker({
    required this.value,
    required this.onChanged,
  });

  final _ReportDateRange value;
  final ValueChanged<_ReportDateRange> onChanged;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return _ReportChoiceSection(
      title: 'الفترة الزمنية',
      icon: Icons.date_range_rounded,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _ReportChoiceChip(
            label: 'كل الفترات',
            selected: value.start == null && value.end == null,
            onTap: () => onChanged(_ReportDateRange.all()),
          ),
          _ReportChoiceChip(
            label: 'آخر 7 أيام',
            selected: value.label == 'آخر 7 أيام',
            onTap: () => onChanged(
              _ReportDateRange._(
                'آخر 7 أيام',
                now.subtract(const Duration(days: 7)),
                now,
              ),
            ),
          ),
          _ReportChoiceChip(
            label: 'هذا الشهر',
            selected: value.label == 'هذا الشهر',
            onTap: () => onChanged(
              _ReportDateRange._(
                'هذا الشهر',
                DateTime(now.year, now.month, 1),
                now,
              ),
            ),
          ),
          _ReportChoiceChip(
            label: 'مخصص: ${value.label}',
            selected: value.start != null &&
                value.label != 'آخر 7 أيام' &&
                value.label != 'هذا الشهر',
            onTap: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(now.year - 5),
                lastDate: DateTime(now.year + 1),
                initialDateRange: value.start != null && value.end != null
                    ? DateTimeRange(start: value.start!, end: value.end!)
                    : null,
              );
              if (picked == null) return;
              onChanged(
                _ReportDateRange._(
                  _rangeLabel(picked.start, picked.end),
                  picked.start,
                  picked.end,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReportPageHero extends StatelessWidget {
  const _ReportPageHero({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: Colors.white, size: 25),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.78),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _ReportExportActions extends StatelessWidget {
  const _ReportExportActions({
    required this.loading,
    required this.color,
    required this.onPdf,
    required this.onExcel,
  });

  final bool loading;
  final Color color;
  final VoidCallback? onPdf;
  final VoidCallback onExcel;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(
        width: 38,
        height: 38,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
    }
    return Wrap(
      spacing: 6,
      children: [
        if (onPdf != null)
          IconButton.filled(
            onPressed: onPdf,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: color,
            ),
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'تحميل PDF',
          ),
        IconButton.filled(
          onPressed: onExcel,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.success,
          ),
          icon: const Icon(Icons.table_chart_rounded),
          tooltip: 'تصدير Excel',
        ),
      ],
    );
  }
}

class _ExecutiveSummaryPanel extends StatelessWidget {
  const _ExecutiveSummaryPanel({
    required this.items,
    required this.color,
  });

  final List<_SummaryItem> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.summarize_rounded, color: color, size: 18),
              const SizedBox(width: 8),
              const Text(
                'ملخص تنفيذي',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w900,
                  color: AppColors.midnight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ReportMetricStrip(
            metrics: items
                .map((item) => _ReportMetric(item.label, item.value, color, item.icon))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem {
  const _SummaryItem(this.label, this.value, this.icon);

  final String label;
  final Object? value;
  final IconData icon;
}



class _ReportChoiceSection extends StatelessWidget {
  const _ReportChoiceSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.royalBlue, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w900,
                  color: AppColors.midnight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ReportChoiceWrap extends StatelessWidget {
  const _ReportChoiceWrap({
    required this.selectedId,
    required this.items,
    required this.onChanged,
  });

  final int? selectedId;
  final List<Map<String, dynamic>> items;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ReportChoiceChip(
          label: 'الكل',
          selected: selectedId == null,
          onTap: () => onChanged(null),
        ),
        ...items.map((item) {
          final id = _int(item['id']);
          return _ReportChoiceChip(
            label: (item['name'] ?? '-').toString(),
            selected: selectedId == id,
            onTap: () => onChanged(id),
          );
        }),
      ],
    );
  }
}

class _ReportChoiceChip extends StatelessWidget {
  const _ReportChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const color = AppColors.royalBlue;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? color : AppColors.slate50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : AppColors.slate100,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w900,
            fontSize: 12,
            color: selected ? Colors.white : AppColors.slate500,
          ),
        ),
      ),
    );
  }
}

class _SubjectSelectorCard extends StatelessWidget {
  const _SubjectSelectorCard({
    required this.subject,
    required this.onTap,
  });

  final Map<String, dynamic> subject;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final major = _map(subject['major']);
    final level = _map(subject['level']);
    final doctor = _map(subject['doctor']);
    return _NavigationCard(
      icon: Icons.menu_book_rounded,
      color: AppColors.royalBlue,
      title: (subject['name'] ?? '-').toString(),
      subtitle:
          '${major['name'] ?? '-'} • ${level['name'] ?? '-'}${doctor.isEmpty ? '' : ' • ${doctor['name'] ?? ''}'}',
      actionLabel: 'فتح التقرير',
      onTap: onTap,
    );
  }
}

class _SubjectIdentityCard extends StatelessWidget {
  const _SubjectIdentityCard({
    required this.subject,
    required this.major,
    required this.level,
    required this.doctor,
    required this.range,
  });

  final Map<String, dynamic> subject;
  final Map<String, dynamic> major;
  final Map<String, dynamic> level;
  final Map<String, dynamic> doctor;
  final _ReportDateRange range;

  @override
  Widget build(BuildContext context) {
    final maxAbsences = subject['max_absences'];
    final items = [
      _SubjectInfoItem(Icons.account_tree_rounded, '\u0627\u0644\u062a\u062e\u0635\u0635', (major['name'] ?? '-').toString(), AppColors.violet),
      _SubjectInfoItem(Icons.layers_rounded, '\u0627\u0644\u0645\u0633\u062a\u0648\u0649', (level['name'] ?? '-').toString(), AppColors.teal),
      _SubjectInfoItem(Icons.person_rounded, '\u0623\u0633\u062a\u0627\u0630 \u0627\u0644\u0645\u0642\u0631\u0631', (doctor['name'] ?? '\u063a\u064a\u0631 \u0645\u062d\u062f\u062f').toString(), AppColors.royalBlue),
      _SubjectInfoItem(Icons.block_rounded, '\u062d\u062f \u0627\u0644\u063a\u064a\u0627\u0628', maxAbsences != null ? '$maxAbsences \u0645\u062d\u0627\u0636\u0631\u0627\u062a' : '-', AppColors.danger),
      _SubjectInfoItem(Icons.date_range_rounded, '\u0627\u0644\u0641\u062a\u0631\u0629 \u0627\u0644\u0632\u0645\u0646\u064a\u0629', range.label, AppColors.goldDeep),
      _SubjectInfoItem(Icons.menu_book_rounded, '\u0627\u0633\u0645 \u0627\u0644\u0645\u0627\u062f\u0629', (subject['name'] ?? '-').toString(), AppColors.royalBlue),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header strip
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.royalBlue.withValues(alpha: 0.05),
                border: Border(
                  bottom: BorderSide(color: AppColors.royalBlue.withValues(alpha: 0.10)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.royalBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.info_rounded, color: AppColors.royalBlue, size: 17),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    '\u0628\u064a\u0627\u0646\u0627\u062a \u0627\u0644\u0645\u0627\u062f\u0629 \u0627\u0644\u062f\u0631\u0627\u0633\u064a\u0629',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: AppColors.midnight,
                    ),
                  ),
                ],
              ),
            ),
            // Info grid
            Padding(
              padding: const EdgeInsets.all(14),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = (constraints.maxWidth - 10) / 2;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: items.take(5).map((item) {
                      return SizedBox(
                        width: width,
                        child: _SubjectInfoTile(item: item),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectInfoItem {
  const _SubjectInfoItem(this.icon, this.label, this.value, this.color);
  final IconData icon;
  final String label;
  final String value;
  final Color color;
}

class _SubjectInfoTile extends StatelessWidget {
  const _SubjectInfoTile({required this.item});
  final _SubjectInfoItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: item.color.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    color: AppColors.slate500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                    color: AppColors.midnight,
                    height: 1.3,
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

class _LevelIdentityCard extends StatelessWidget {
  const _LevelIdentityCard({
    required this.major,
    required this.level,
    required this.threshold,
    required this.range,
  });

  final Map<String, dynamic> major;
  final Map<String, dynamic> level;
  final int threshold;
  final _ReportDateRange range;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.danger.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.05),
                border: Border(
                  bottom: BorderSide(color: AppColors.danger.withValues(alpha: 0.10)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.layers_rounded, color: AppColors.danger, size: 17),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    '\u0628\u064a\u0627\u0646\u0627\u062a \u0627\u0644\u062a\u0642\u0631\u064a\u0631',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: AppColors.midnight,
                    ),
                  ),
                  const Spacer(),
                  // Threshold badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '\u0639\u062a\u0628\u0629 $threshold%',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                        fontSize: 11.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = (constraints.maxWidth - 10) / 2;
                  final items = [
                    _SubjectInfoItem(Icons.account_tree_rounded, '\u0627\u0644\u062a\u062e\u0635\u0635', (major['name'] ?? '-').toString(), AppColors.violet),
                    _SubjectInfoItem(Icons.layers_rounded, '\u0627\u0644\u0645\u0633\u062a\u0648\u0649 \u0627\u0644\u062f\u0631\u0627\u0633\u064a', (level['name'] ?? '-').toString(), AppColors.teal),
                    _SubjectInfoItem(Icons.percent_rounded, '\u0639\u062a\u0628\u0629 \u0627\u0644\u063a\u064a\u0627\u0628', '$threshold\u066a \u0641\u0623\u0643\u062b\u0631', AppColors.danger),
                    _SubjectInfoItem(Icons.date_range_rounded, '\u0627\u0644\u0641\u062a\u0631\u0629 \u0627\u0644\u0632\u0645\u0646\u064a\u0629', range.label, AppColors.goldDeep),
                  ];
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: items.map((item) {
                      return SizedBox(
                        width: width,
                        child: _SubjectInfoTile(item: item),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThresholdNotificationCard extends StatelessWidget {
  const _ThresholdNotificationCard({
    required this.criticalCount,
    required this.warningCount,
    required this.alertsCount,
    required this.loading,
    required this.onSend,
  });

  final int criticalCount;
  final int warningCount;
  final int alertsCount;
  final bool loading;
  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: AppColors.danger.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.05),
                border: Border(
                  bottom: BorderSide(color: AppColors.danger.withValues(alpha: 0.10)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(Icons.campaign_rounded, color: AppColors.danger, size: 17),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      '\u0625\u0634\u0639\u0627\u0631\u0627\u062a \u062a\u0644\u0642\u0627\u0626\u064a\u0629',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: AppColors.midnight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats row
                  Row(
                    children: [
                      Expanded(
                        child: _ThresholdStatBadge(
                          label: '\u062d\u0631\u0645\u0627\u0646',
                          value: criticalCount,
                          icon: Icons.block_rounded,
                          color: AppColors.danger,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ThresholdStatBadge(
                          label: '\u0625\u0646\u0630\u0627\u0631',
                          value: warningCount,
                          icon: Icons.warning_rounded,
                          color: AppColors.goldDeep,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ThresholdStatBadge(
                          label: '\u0625\u062c\u0645\u0627\u0644\u064a',
                          value: alertsCount,
                          icon: Icons.people_rounded,
                          color: AppColors.royalBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    alertsCount == 0
                        ? '\u0644\u0627 \u062a\u0648\u062c\u062f \u062d\u0627\u0644\u0627\u062a \u062a\u0633\u062a\u062d\u0642 \u0627\u0644\u0625\u0634\u0639\u0627\u0631.'
                        : '\u0633\u064a\u062a\u0645 \u0625\u0631\u0633\u0627\u0644 \u062a\u0646\u0628\u064a\u0647 \u062f\u0627\u062e\u0644 \u0627\u0644\u062a\u0637\u0628\u064a\u0642 \u0644\u0640 $alertsCount \u0637\u0627\u0644\u0628 \u062a\u062c\u0627\u0648\u0632\u0648\u0627 \u0639\u062a\u0628\u0629 \u0627\u0644\u063a\u064a\u0627\u0628.',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                      color: AppColors.slate500,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: loading
                        ? Container(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.danger,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  '\u062c\u0627\u0631\u064a \u0625\u0631\u0633\u0627\u0644 \u0627\u0644\u062a\u0646\u0628\u064a\u0647\u0627\u062a...',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12.5,
                                    color: AppColors.danger,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : DecoratedBox(
                            decoration: BoxDecoration(
                              color: onSend != null ? AppColors.danger : AppColors.slate200,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: InkWell(
                              onTap: onSend,
                              borderRadius: BorderRadius.circular(14),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.send_rounded,
                                      size: 16,
                                      color: onSend != null ? Colors.white : AppColors.slate500,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '\u0625\u0631\u0633\u0627\u0644 \u062a\u0646\u0628\u064a\u0647\u0627\u062a \u062a\u0644\u0642\u0627\u0626\u064a\u0629 \u0644\u0644\u0637\u0644\u0627\u0628',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                        color: onSend != null ? Colors.white : AppColors.slate500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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

class _ThresholdStatBadge extends StatelessWidget {
  const _ThresholdStatBadge({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
              fontSize: 10,
              color: AppColors.slate500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelSelectorCard extends StatelessWidget {
  const _LevelSelectorCard({
    required this.level,
    required this.major,
    required this.color,
    required this.actionLabel,
    required this.onTap,
  });

  final Map<String, dynamic> level;
  final Map<String, dynamic> major;
  final Color color;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _NavigationCard(
      icon: Icons.layers_rounded,
      color: color,
      title: (level['name'] ?? '-').toString(),
      subtitle: (major['name'] ?? '-').toString(),
      actionLabel: actionLabel,
      onTap: onTap,
    );
  }
}

class _NavigationCard extends StatelessWidget {
  const _NavigationCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.slate200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Row(
            children: [
              // Left accent strip
              Container(
                width: 4,
                height: 68,
                color: color,
              ),
              const SizedBox(width: 12),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5,
                        color: AppColors.midnight,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: _AdminChip(label: actionLabel, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




class _SubjectStudentReportCard extends StatelessWidget {
  const _SubjectStudentReportCard({
    required this.index,
    required this.row,
    required this.subject,
  });

  final int index;
  final Map<String, dynamic> row;
  final Map<String, dynamic> subject;

  @override
  Widget build(BuildContext context) {
    final student = _map(row['student']);
    final decision = (row['decision'] ?? _subjectDecision(row, subject)).toString();
    final color = decision == 'محروم'
        ? AppColors.danger
        : decision == 'إنذار'
            ? AppColors.goldDeep
            : AppColors.success;
    final absencePercentage = double.tryParse('${row['absence_percentage'] ?? 0}') ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: decision == 'محروم'
              ? AppColors.danger.withValues(alpha: 0.18)
              : AppColors.slate200,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left accent strip colored by decision
            Container(
              width: 4,
              color: color,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _ReportIndexBadge(index: index, color: color),
                        const SizedBox(width: 10),
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
                                  color: AppColors.midnight,
                                ),
                              ),
                              Text(
                                (student['student_number'] ?? '-').toString(),
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  color: AppColors.slate500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _AdminChip(label: decision == '-' ? 'سليم' : decision, color: color),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _ReportMetricStrip(
                      metrics: [
                        _ReportMetric('حاضر', row['present'], AppColors.success, Icons.check_circle_rounded),
                        _ReportMetric('غائب', row['absent'], AppColors.danger, Icons.cancel_rounded),
                        _ReportMetric('متأخر', row['late'], AppColors.goldDeep, Icons.schedule_rounded),
                        _ReportMetric('أعذار', row['excused'], AppColors.royalBlue, Icons.verified_rounded),
                        _ReportMetric('النسبة', '${row['absence_percentage'] ?? 0}%', color, Icons.percent_rounded),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Absence progress bar
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: (absencePercentage / 100).clamp(0.0, 1.0),
                              minHeight: 7,
                              color: color,
                              backgroundColor: AppColors.slate100,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'غياب ${absencePercentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w900,
                            fontSize: 10.5,
                            color: color,
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
      ),
    );
  }
}

class _ThresholdAlertCard extends StatelessWidget {
  const _ThresholdAlertCard({required this.index, required this.row});

  final int index;
  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final student = _map(row['student']);
    final subject = _map(row['subject']);
    final percentage = double.tryParse('${row['absence_percentage'] ?? 0}') ?? 0;
    final severe = (row['severity'] ?? '') == 'critical' || percentage >= 25;
    final color = severe ? AppColors.danger : AppColors.goldDeep;
    final label = row['action_label'] ?? (severe ? 'حرمان' : 'إنذار');
    final absentCount = _int(row['absent_count']);
    final totalSessions = _int(row['total_sessions']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: severe ? AppColors.danger.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: severe
              ? AppColors.danger.withValues(alpha: 0.22)
              : AppColors.slate200,
          width: severe ? 1.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.09),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Top color strip ───
            Container(
              height: 4,
              width: double.infinity,
              color: color,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Header: index + name + verdict badge ───
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Index circle
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$index',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
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
                                fontSize: 15,
                                color: AppColors.midnight,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              (student['student_number'] ?? '-').toString(),
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                                color: AppColors.slate500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Verdict badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // ─── Subject row ───
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.slate50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.slate100),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.menu_book_rounded, size: 14, color: AppColors.slate500),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            (subject['name'] ?? '-').toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: AppColors.midnight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ─── Percentage progress bar (centrepiece) ───
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'نسبة الغياب',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w700,
                                fontSize: 10.5,
                                color: AppColors.slate500,
                              ),
                            ),
                            const SizedBox(height: 5),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: (percentage / 100).clamp(0.0, 1.0),
                                minHeight: 10,
                                color: color,
                                backgroundColor: color.withValues(alpha: 0.12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Large percentage number
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          color: color,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // ─── Bottom metrics strip ───
                  Row(
                    children: [
                      Expanded(
                        child: _AlertMetricTile(
                          icon: Icons.cancel_rounded,
                          label: 'غياب',
                          value: '$absentCount',
                          color: AppColors.danger,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _AlertMetricTile(
                          icon: Icons.event_note_rounded,
                          label: 'جلسات',
                          value: '$totalSessions',
                          color: AppColors.royalBlue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _AlertMetricTile(
                          icon: Icons.stacked_bar_chart_rounded,
                          label: 'حضور',
                          value: '${totalSessions - absentCount}',
                          color: AppColors.success,
                        ),
                      ),
                    ],
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

class _AlertMetricTile extends StatelessWidget {
  const _AlertMetricTile({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: color,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  color: AppColors.slate500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}



class _LevelSummaryIdentityCard extends StatelessWidget {
  const _LevelSummaryIdentityCard({
    required this.major,
    required this.level,
    required this.delegate,
    required this.range,
    required this.avgRate,
    required this.avgColor,
  });

  final Map<String, dynamic> major;
  final Map<String, dynamic> level;
  final Map<String, dynamic> delegate;
  final _ReportDateRange range;
  final double avgRate;
  final Color avgColor;

  @override
  Widget build(BuildContext context) {
    final delegateName = (delegate['name'] ?? '\u063a\u064a\u0631 \u0645\u0639\u064a\u0646').toString();
    final items = [
      _SubjectInfoItem(Icons.account_tree_rounded, '\u0627\u0644\u062a\u062e\u0635\u0635', (major['name'] ?? '-').toString(), AppColors.violet),
      _SubjectInfoItem(Icons.layers_rounded, '\u0627\u0644\u062f\u0641\u0639\u0629 / \u0627\u0644\u0645\u0633\u062a\u0648\u0649', (level['name'] ?? '-').toString(), AppColors.teal),
      _SubjectInfoItem(Icons.verified_user_rounded, '\u0645\u0646\u062f\u0648\u0628 \u0627\u0644\u0645\u0633\u062a\u0648\u0649', delegateName, AppColors.royalBlue),
      _SubjectInfoItem(Icons.date_range_rounded, '\u0627\u0644\u0641\u062a\u0631\u0629 \u0627\u0644\u0632\u0645\u0646\u064a\u0629', range.label, AppColors.goldDeep),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.05),
                border: Border(
                  bottom: BorderSide(color: AppColors.teal.withValues(alpha: 0.10)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.layers_rounded, color: AppColors.teal, size: 17),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      '\u0628\u064a\u0627\u0646\u0627\u062a \u0627\u0644\u062f\u0641\u0639\u0629',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: AppColors.midnight,
                      ),
                    ),
                  ),
                  // Avg rate badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: avgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '\u062d\u0636\u0648\u0631 ${avgRate.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                        fontSize: 11.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = (constraints.maxWidth - 10) / 2;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: items.map((item) {
                      return SizedBox(
                        width: width,
                        child: _SubjectInfoTile(item: item),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelSubjectPerformanceCard extends StatelessWidget {
  const _LevelSubjectPerformanceCard({
    required this.stat,
    required this.index,
  });

  final Map<String, dynamic> stat;
  final int index;

  @override
  Widget build(BuildContext context) {
    final subject = _map(stat['subject']);
    final doctor = _map(subject['doctor']);
    final rate = double.tryParse('${stat['attendance_rate'] ?? 0}') ?? 0;
    final totalRecords = _int(stat['total_records']);
    final color = rate >= 70
        ? AppColors.success
        : rate >= 45
            ? AppColors.goldDeep
            : AppColors.danger;

    final rateLabel = rate >= 70 ? '\u062c\u064a\u062f' : rate >= 45 ? '\u0645\u062a\u0648\u0633\u0637' : '\u0645\u0646\u062e\u0641\u0636';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top accent strip
            Container(height: 4, width: double.infinity, color: color),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row: index + name + rate badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Index
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.teal.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$index',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: AppColors.teal,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (subject['name'] ?? '-').toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: AppColors.midnight,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$totalRecords \u0633\u062c\u0644 \u0631\u0635\u062f',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                                color: AppColors.slate500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Rate display
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${rate.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w900,
                              fontSize: 26,
                              color: color,
                              letterSpacing: -1,
                              height: 1,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              rateLabel,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Doctor row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.slate50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.slate100),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_rounded, size: 14, color: AppColors.slate500),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            (doctor['name'] ?? '\u063a\u064a\u0631 \u0645\u062d\u062f\u062f').toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: AppColors.midnight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Progress bar
                  Row(
                    children: [
                      const Text(
                        '\u0646\u0633\u0628\u0629 \u0627\u0644\u062d\u0636\u0648\u0631',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w700,
                          fontSize: 10.5,
                          color: AppColors.slate500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${(100 - rate).toStringAsFixed(1)}% \u063a\u064a\u0627\u0628',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w700,
                          fontSize: 10.5,
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: (rate / 100).clamp(0.0, 1.0),
                      minHeight: 12,
                      color: color,
                      backgroundColor: color.withValues(alpha: 0.10),
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


class _DoctorPerformanceCard extends StatelessWidget {
  const _DoctorPerformanceCard({required this.index, required this.doctor});

  final int index;
  final Map<String, dynamic> doctor;

  @override
  Widget build(BuildContext context) {
    final rate = double.tryParse('${doctor['attendance_rate'] ?? 0}') ?? 0;
    final color = rate >= 75
        ? AppColors.success
        : rate >= 50
            ? AppColors.goldDeep
            : AppColors.danger;

    final email = doctor['email'] ?? 'عضو هيئة تدريس';
    final qrSessionsCount = doctor['qr_sessions_count'] ?? 0;
    final subjectsCount = doctor['subjects_count'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate200, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate300.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: 4),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReportIndexBadge(index: index, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (doctor['name'] ?? '-').toString(),
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: AppColors.midnight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            color: AppColors.slate500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${rate.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          color: color,
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          rate >= 75
                              ? 'ممتاز'
                              : rate >= 50
                                  ? 'متوسط'
                                  : 'ضعيف',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w900,
                            fontSize: 9,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _infoChip(
                    icon: Icons.menu_book_rounded,
                    label: 'المواد: $subjectsCount',
                    color: AppColors.royalBlue,
                  ),
                  const SizedBox(width: 8),
                  _infoChip(
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'جلسات التحضير: $qrSessionsCount',
                    color: AppColors.violet,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'متوسط حضور الطلاب',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      color: AppColors.slate500,
                    ),
                  ),
                  Text(
                    '${(100 - rate).toStringAsFixed(1)}% غياب',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: (rate / 100).clamp(0.0, 1.0),
                  minHeight: 10,
                  color: color,
                  backgroundColor: AppColors.slate100,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
              fontSize: 11,
              color: AppColors.midnight,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({
    required this.index,
    required this.item,
    required this.type,
  });

  final int index;
  final Map<String, dynamic> item;
  final String type;

  @override
  Widget build(BuildContext context) {
    final rate = double.tryParse('${item['attendance_rate'] ?? 0}') ?? 0;
    final color = rate >= 75
        ? AppColors.success
        : rate >= 50
            ? AppColors.goldDeep
            : AppColors.danger;

    final major = _map(item['major']);
    final level = _map(item['level']);
    final doctor = _map(item['doctor']);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate200, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate300.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: 4),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReportIndexBadge(index: index, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (item['name'] ?? '-').toString(),
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: AppColors.midnight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          major['name'] ?? '-',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            color: AppColors.slate500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${rate.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          color: color,
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          rate >= 75
                              ? 'مرتفع'
                              : rate >= 50
                                  ? 'متوسط'
                                  : 'منخفض',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w900,
                            fontSize: 9,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (type == 'levels') ...[
                Row(
                  children: [
                    _infoChip(
                      icon: Icons.menu_book_rounded,
                      label: 'المواد: ${item['subjects_count'] ?? 0}',
                      color: AppColors.royalBlue,
                    ),
                    const SizedBox(width: 8),
                    _infoChip(
                      icon: Icons.analytics_rounded,
                      label: 'سجلات الرصد: ${item['total_records'] ?? 0}',
                      color: AppColors.success,
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    if (level['name'] != null) ...[
                      _infoChip(
                        icon: Icons.layers_rounded,
                        label: level['name'].toString(),
                        color: AppColors.royalBlue,
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (doctor['name'] != null)
                      Expanded(
                        child: _infoChip(
                          icon: Icons.person_rounded,
                          label: doctor['name'].toString(),
                          color: AppColors.violet,
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'معدل الحضور العام',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      color: AppColors.slate500,
                    ),
                  ),
                  Text(
                    '${(100 - rate).toStringAsFixed(1)}% غياب',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: (rate / 100).clamp(0.0, 1.0),
                  minHeight: 10,
                  color: color,
                  backgroundColor: AppColors.slate100,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: AppColors.midnight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}




class _ReportMetric {
  const _ReportMetric(this.label, this.value, this.color, [this.icon]);

  final String label;
  final Object? value;
  final Color color;
  final IconData? icon;
}

class _ReportMetricStrip extends StatelessWidget {
  const _ReportMetricStrip({required this.metrics});

  final List<_ReportMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = metrics.length;
        if (metrics.length == 4) {
          if (constraints.maxWidth < 380) {
            columns = 2;
          }
        } else if (metrics.length == 5) {
          if (constraints.maxWidth < 420) {
            columns = 3;
          }
        } else if (metrics.length > 5) {
          if (constraints.maxWidth < 480) {
            columns = 3;
          }
        }

        final width =
            (constraints.maxWidth - ((columns - 1) * 8)) / columns;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: metrics.map((metric) {
            return SizedBox(
              width: width < 74 ? 74 : width,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                decoration: BoxDecoration(
                  color: metric.color.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: metric.color.withValues(alpha: 0.12)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (metric.icon != null) ...[
                      Icon(metric.icon!, color: metric.color, size: 14),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      (metric.value ?? '-').toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: metric.color,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      metric.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate500,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ReportIndexBadge extends StatelessWidget {
  const _ReportIndexBadge({required this.index, required this.color});

  final int index;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          '$index',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ),
    );
  }
}

String _subjectDecision(Map<String, dynamic> row, Map<String, dynamic> subject) {
  final absent = _int(row['absent']);
  final maxAbsences = _int(subject['max_absences'], fallback: 4);
  if (absent >= maxAbsences) return 'محروم';
  if (maxAbsences > 2 && absent >= maxAbsences - 2) return 'إنذار';
  return '-';
}

String _rangeLabel(DateTime? start, DateTime? end) {
  if (start == null && end == null) return 'كل الفترات';
  if (start != null && end != null) {
    return '${_formatDateYmd(start)} إلى ${_formatDateYmd(end)}';
  }
  if (start != null) return 'من ${_formatDateYmd(start)}';
  return 'حتى ${_formatDateYmd(end)}';
}

Future<void> _showDownloadResult(
  BuildContext context,
  DownloadSaveResult result,
) {
  return showMoeenInfoDialog(
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
}
