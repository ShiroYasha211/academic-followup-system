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
            onRetry: () => setState(() => _future = _fetch()),
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
      onRefresh: () async => setState(() => _future = _fetch()),
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
            onRetry: () => setState(() => _future = _fetch()),
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
      onRefresh: () async => setState(() => _future = _fetch()),
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
            onRetry: () => setState(() => _future = _fetch()),
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
      onRefresh: () async => setState(() => _future = _fetch()),
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
          _ReportInfoGrid(
            items: [
              _ReportInfo('المادة الدراسية', subject['name']),
              _ReportInfo('التخصص', major['name']),
              _ReportInfo('المستوى الأكاديمي', level['name']),
              _ReportInfo('أستاذ المقرر', doctor['name'] ?? 'غير محدد'),
              _ReportInfo('حد الغياب', '${subject['max_absences'] ?? '-'} محاضرات'),
              _ReportInfo('الفترة الزمنية', _range.label),
            ],
          ),
          const SizedBox(height: 14),
          _SearchBox(controller: _search, onSearch: () => setState(() {})),
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
            onRetry: () => setState(() => _future = _fetch()),
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

    return RefreshIndicator(
      onRefresh: () async => setState(() => _future = _fetch()),
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
          const SizedBox(height: 12),
          _ReportInfoGrid(
            items: [
              _ReportInfo('التخصص', major['name']),
              _ReportInfo('المستوى', level['name']),
              _ReportInfo('عتبة الغياب', '${widget.threshold}%'),
              _ReportInfo('الفترة الزمنية', _range.label),
            ],
          ),
          const SizedBox(height: 12),
          _AdminActionButton(
            icon: Icons.campaign_rounded,
            label: _notifying ? 'جاري إرسال التنبيهات...' : 'إرسال تنبيهات تلقائية للطلاب',
            onPressed: _notifying || alerts.isEmpty ? null : _sendNotifications,
          ),
          const SizedBox(height: 14),
          _SearchBox(controller: _search, onSearch: () => setState(() {})),
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
            onRetry: () => setState(() => _future = _fetch()),
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

    return RefreshIndicator(
      onRefresh: () async => setState(() => _future = _fetch()),
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
              _SummaryItem('الطلاب', summary['students_count'] ?? 0, Icons.groups_rounded),
              _SummaryItem('المواد', summary['subjects_count'] ?? subjectStats.length, Icons.menu_book_rounded),
              _SummaryItem('متوسط الحضور', '${summary['average_attendance_rate'] ?? 0}%', Icons.trending_up_rounded),
              _SummaryItem('المندوب', delegate['name'] ?? 'غير معين', Icons.verified_user_rounded),
            ],
          ),
          const SizedBox(height: 16),
          const _SectionTitle('مصفوفة أداء المواد', Icons.stacked_bar_chart_rounded),
          const SizedBox(height: 12),
          if (subjectStats.isEmpty)
            const _EmptyState()
          else
            ...subjectStats.map(
              (stat) => _LevelSubjectPerformanceCard(stat: stat),
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
            onRetry: () => setState(() => _future = _fetch()),
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
      onRefresh: () async => setState(() => _future = _fetch()),
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
            ...doctors.map((doctor) => _DoctorPerformanceCard(doctor: doctor)),
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
            onRetry: () => setState(() => _future = _fetch()),
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
      onRefresh: () async => setState(() => _future = _fetch()),
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
            ...items.map(
              (item) => _ComparisonCard(item: item, type: _type),
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
                .map((item) => _ReportMetric(item.label, item.value, color))
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

class _AdminActionButton extends StatelessWidget {
  const _AdminActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w900,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.danger,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
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
    final color = selected ? AppColors.royalBlue : AppColors.slate500;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.royalBlue.withValues(alpha: 0.10)
              : AppColors.slate50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.royalBlue.withValues(alpha: 0.24)
                : AppColors.slate100,
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
            color: color,
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
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color),
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
                      color: AppColors.midnight,
                    ),
                  ),
                  const SizedBox(height: 4),
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
            _AdminChip(label: actionLabel, color: color),
          ],
        ),
      ),
    );
  }
}

class _ReportInfo {
  const _ReportInfo(this.label, this.value);

  final String label;
  final Object? value;
}

class _ReportInfoGrid extends StatelessWidget {
  const _ReportInfoGrid({required this.items});

  final List<_ReportInfo> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 520 ? 1 : 2;
        final width = (constraints.maxWidth - ((columns - 1) * 10)) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items.map((item) {
            return SizedBox(
              width: width,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.slate100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: AppColors.slate500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (item.value ?? '-').toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5,
                        color: AppColors.midnight,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
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
              _ReportMetric('حاضر', row['present'], AppColors.success),
              _ReportMetric('غائب', row['absent'], AppColors.danger),
              _ReportMetric('متأخر', row['late'], AppColors.goldDeep),
              _ReportMetric('أعذار', row['excused'], AppColors.royalBlue),
              _ReportMetric('النسبة', '${row['absence_percentage'] ?? 0}%', color),
            ],
          ),
        ],
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReportIndexBadge(index: index, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (student['name'] ?? '-').toString(),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    color: AppColors.midnight,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${subject['name'] ?? '-'} • ${student['student_number'] ?? '-'}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                    color: AppColors.slate500,
                  ),
                ),
                const SizedBox(height: 10),
                _ReportMetricStrip(
                  metrics: [
                    _ReportMetric('الغيابات', row['absent_count'], AppColors.danger),
                    _ReportMetric('الجلسات', row['total_sessions'], AppColors.royalBlue),
                    _ReportMetric('النسبة', '$percentage%', color),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _AdminChip(label: row['action_label'] ?? (severe ? 'حرمان' : 'إنذار'), color: color),
        ],
      ),
    );
  }
}

class _LevelSubjectPerformanceCard extends StatelessWidget {
  const _LevelSubjectPerformanceCard({required this.stat});

  final Map<String, dynamic> stat;

  @override
  Widget build(BuildContext context) {
    final subject = _map(stat['subject']);
    final doctor = _map(subject['doctor']);
    final rate = double.tryParse('${stat['attendance_rate'] ?? 0}') ?? 0;
    final color = rate >= 70
        ? AppColors.success
        : rate >= 45
            ? AppColors.goldDeep
            : AppColors.danger;
    return _RateCard(
      title: (subject['name'] ?? '-').toString(),
      subtitle:
          'أستاذ المقرر: ${doctor['name'] ?? '-'} • سجلات الرصد: ${stat['total_records'] ?? 0}',
      rate: rate,
      color: color,
    );
  }
}

class _DoctorPerformanceCard extends StatelessWidget {
  const _DoctorPerformanceCard({required this.doctor});

  final Map<String, dynamic> doctor;

  @override
  Widget build(BuildContext context) {
    final rate = double.tryParse('${doctor['attendance_rate'] ?? 0}') ?? 0;
    final color = rate >= 75
        ? AppColors.success
        : rate >= 50
            ? AppColors.goldDeep
            : AppColors.danger;
    return _RateCard(
      title: (doctor['name'] ?? '-').toString(),
      subtitle:
          '${doctor['email'] ?? 'عضو هيئة تدريس'} • جلسات مكتملة: ${doctor['qr_sessions_count'] ?? 0} • مواد: ${doctor['subjects_count'] ?? 0}',
      rate: rate,
      color: color,
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.item, required this.type});

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
    final subtitle = type == 'levels'
        ? '${major['name'] ?? '-'} • مواد: ${item['subjects_count'] ?? 0} • سجلات: ${item['total_records'] ?? 0}'
        : '${major['name'] ?? '-'} • ${level['name'] ?? '-'} • ${doctor['name'] ?? '-'}';
    return _RateCard(
      title: (item['name'] ?? '-').toString(),
      subtitle: subtitle,
      rate: rate,
      color: color,
    );
  }
}

class _RateCard extends StatelessWidget {
  const _RateCard({
    required this.title,
    required this.subtitle,
    required this.rate,
    required this.color,
  });

  final String title;
  final String subtitle;
  final double rate;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    color: AppColors.midnight,
                  ),
                ),
              ),
              _AdminChip(label: '${rate.toStringAsFixed(1)}%', color: color),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
              color: AppColors.slate500,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (rate / 100).clamp(0, 1),
              minHeight: 8,
              color: color,
              backgroundColor: AppColors.slate100,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportMetric {
  const _ReportMetric(this.label, this.value, this.color);

  final String label;
  final Object? value;
  final Color color;
}

class _ReportMetricStrip extends StatelessWidget {
  const _ReportMetricStrip({required this.metrics});

  final List<_ReportMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            (constraints.maxWidth - ((metrics.length - 1) * 8)) / metrics.length;
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
                    Text(
                      metric.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (metric.value ?? '-').toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: metric.color,
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
