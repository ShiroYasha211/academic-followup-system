part of 'staff_screens.dart';

class DoctorEvaluationPortfoliosScreen extends ConsumerStatefulWidget {
  const DoctorEvaluationPortfoliosScreen({super.key});

  static const route = '/doctor/clinical/evaluation-portfolios';

  @override
  ConsumerState<DoctorEvaluationPortfoliosScreen> createState() =>
      _DoctorEvaluationPortfoliosScreenState();
}

class _DoctorEvaluationPortfoliosScreenState
    extends ConsumerState<DoctorEvaluationPortfoliosScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  late Future<_Json> _future = _fetch();
  int _page = 1;
  int? _majorId;
  int? _levelId;
  String _sort = 'latest';

  @override
  void initState() {
    super.initState();
    _search.addListener(_scheduleSearch);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search
      ..removeListener(_scheduleSearch)
      ..dispose();
    super.dispose();
  }

  void _scheduleSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _reload(resetPage: true);
    });
  }

  Future<_Json> _fetch() async {
    final response = await ref
        .read(staffRepositoryProvider)
        .get(
          '/doctor/clinical/evaluations/portfolios',
          query: {
            'page': _page,
            'per_page': 50,
            'sort': _sort,
            if (_search.text.trim().isNotEmpty) 'search': _search.text.trim(),
            if (_majorId != null) 'major_id': _majorId,
            if (_levelId != null) 'level_id': _levelId,
          },
        );
    return _docMap(_docData(response));
  }

  void _reload({bool resetPage = false}) {
    setState(() {
      if (resetPage) _page = 1;
      _future = _fetch();
    });
  }

  Future<void> _openFilters(_Json data) async {
    final filters = _docMap(data['filters']);
    final majors = _docList(filters['majors']);
    final levels = _docList(filters['levels']);
    var majorId = _majorId;
    var levelId = _levelId;
    var sort = _sort;

    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            20 + MediaQuery.viewPaddingOf(context).bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.slate200,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'تصفية كشوف الطلاب',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.midnight,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int?>(
                initialValue: majorId,
                decoration: const InputDecoration(
                  labelText: 'التخصص',
                  prefixIcon: Icon(Icons.school_rounded),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('كل التخصصات'),
                  ),
                  ...majors.map(
                    (item) => DropdownMenuItem<int?>(
                      value: _docInt(item['id']),
                      child: Text(_docText(item['name'], '-')),
                    ),
                  ),
                ],
                onChanged: (value) => setSheetState(() => majorId = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: levelId,
                decoration: const InputDecoration(
                  labelText: 'المستوى',
                  prefixIcon: Icon(Icons.layers_rounded),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('كل المستويات'),
                  ),
                  ...levels.map(
                    (item) => DropdownMenuItem<int?>(
                      value: _docInt(item['id']),
                      child: Text(_docText(item['name'], '-')),
                    ),
                  ),
                ],
                onChanged: (value) => setSheetState(() => levelId = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: sort,
                decoration: const InputDecoration(
                  labelText: 'الترتيب',
                  prefixIcon: Icon(Icons.sort_rounded),
                ),
                items: const [
                  DropdownMenuItem(value: 'latest', child: Text('آخر تقييم')),
                  DropdownMenuItem(
                    value: 'attempts',
                    child: Text('عدد المحاولات'),
                  ),
                  DropdownMenuItem(value: 'average', child: Text('أعلى متوسط')),
                  DropdownMenuItem(value: 'name', child: Text('اسم الطالب')),
                ],
                onChanged: (value) {
                  if (value != null) setSheetState(() => sort = value);
                },
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.tune_rounded),
                label: const Text('تطبيق الفلاتر'),
              ),
            ],
          ),
        ),
      ),
    );

    if (applied != true || !mounted) return;
    setState(() {
      _majorId = majorId;
      _levelId = levelId;
      _sort = sort;
      _page = 1;
      _future = _fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'كشوف التقييمات السريرية',
      currentRoute: DoctorClinicalSectionScreen.path('results'),
      child: FutureBuilder<_Json>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return StatusMessage(
              title: 'تعذر تحميل كشوف الطلاب',
              message: snapshot.error.toString(),
              icon: Icons.error_outline_rounded,
              action: FilledButton.icon(
                onPressed: _reload,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
              ),
            );
          }

          final data = snapshot.data ?? const <String, dynamic>{};
          final students = _docList(data['students']);
          final pagination = _docMap(data['pagination']);
          final lastPage = _docInt(pagination['last_page']);
          final total = _docInt(pagination['total']);
          final filtersActive = _majorId != null || _levelId != null;

          return RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
              children: [
                _EvaluationPortfolioListHero(total: total),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _search,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'ابحث بالاسم أو الرقم الجامعي',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _search.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'مسح البحث',
                                  onPressed: _search.clear,
                                  icon: const Icon(Icons.close_rounded),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Badge(
                      isLabelVisible: filtersActive,
                      child: IconButton.filledTonal(
                        tooltip: 'الفلاتر والترتيب',
                        onPressed: () => _openFilters(data),
                        icon: const Icon(Icons.tune_rounded),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (students.isEmpty)
                  const _DocEmpty(
                    'لا توجد تقييمات سريرية مطابقة للبحث أو الفلاتر الحالية.',
                  )
                else
                  ...students.map(
                    (student) => _EvaluationPortfolioStudentCard(
                      student: student,
                      onTap: () => context.push(
                        DoctorEvaluationPortfolioDetailsScreen.path(
                          _docInt(student['id']),
                        ),
                      ),
                    ),
                  ),
                if (lastPage > 1) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.outlined(
                        tooltip: 'الصفحة السابقة',
                        onPressed: _page > 1
                            ? () {
                                setState(() {
                                  _page--;
                                  _future = _fetch();
                                });
                              }
                            : null,
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '$_page من $lastPage',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w900,
                            color: AppColors.midnight,
                          ),
                        ),
                      ),
                      IconButton.outlined(
                        tooltip: 'الصفحة التالية',
                        onPressed: _page < lastPage
                            ? () {
                                setState(() {
                                  _page++;
                                  _future = _fetch();
                                });
                              }
                            : null,
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class DoctorEvaluationPortfolioDetailsScreen extends ConsumerStatefulWidget {
  const DoctorEvaluationPortfolioDetailsScreen({
    super.key,
    required this.studentId,
  });

  static const route = '/doctor/clinical/evaluation-portfolios/:studentId';

  static String path(int studentId) =>
      '/doctor/clinical/evaluation-portfolios/$studentId';

  final int studentId;

  @override
  ConsumerState<DoctorEvaluationPortfolioDetailsScreen> createState() =>
      _DoctorEvaluationPortfolioDetailsScreenState();
}

class _DoctorEvaluationPortfolioDetailsScreenState
    extends ConsumerState<DoctorEvaluationPortfolioDetailsScreen> {
  late Future<_Json> _future = _fetch();
  bool _exporting = false;

  Future<_Json> _fetch() async {
    final response = await ref
        .read(staffRepositoryProvider)
        .get('/doctor/clinical/evaluations/portfolios/${widget.studentId}');
    return _docMap(_docData(response));
  }

  Future<void> _export(_Json portfolio) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final student = _docMap(portfolio['student']);
      final bytes = await ref
          .read(staffRepositoryProvider)
          .download(
            '/doctor/clinical/evaluations/portfolios/${widget.studentId}/excel',
          );
      final result = await DownloadService.saveBytes(
        bytes: bytes,
        fileName:
            'clinical_evaluations_${_docText(student['student_number'], '${widget.studentId}')}_${DateTime.now().toIso8601String().substring(0, 10)}.xlsx',
        section: 'ClinicalReports',
      );
      if (!mounted) return;
      await showMoeenInfoDialog(
        context: context,
        title: 'تم تحميل كشف التقييمات',
        message: result.opened
            ? 'تم حفظ الملف وفتحه بنجاح.'
            : 'تم حفظ الملف في:\n${result.path}',
        icon: Icons.file_download_done_rounded,
        color: AppColors.success,
      );
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'كشف التقييم السريري',
      currentRoute: DoctorClinicalSectionScreen.path('results'),
      child: FutureBuilder<_Json>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return StatusMessage(
              title: 'تعذر تحميل كشف الطالب',
              message: snapshot.error.toString(),
              icon: Icons.error_outline_rounded,
              action: FilledButton.icon(
                onPressed: () => setState(() => _future = _fetch()),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
              ),
            );
          }

          final portfolio = snapshot.data ?? const <String, dynamic>{};
          final student = _docMap(portfolio['student']);
          final summary = _docMap(portfolio['summary']);
          final checklists = _docList(portfolio['checklists']);
          final attempts = _docList(portfolio['attempts']);

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _future = _fetch());
              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
              children: [
                _EvaluationPortfolioHero(
                  student: student,
                  summary: summary,
                  exporting: _exporting,
                  onExport: () => _export(portfolio),
                ),
                const SizedBox(height: 18),
                const _EvaluationPortfolioSectionTitle(
                  title: 'القوائم التي اختبرها الطالب',
                  subtitle:
                      'عدد المحاولات والدكاترة ومتوسط الطالب في كل قائمة.',
                  icon: Icons.fact_check_rounded,
                ),
                const SizedBox(height: 10),
                if (checklists.isEmpty)
                  const _DocEmpty('لا توجد قوائم ضمن الفلاتر الحالية.')
                else
                  ...checklists.map(
                    (item) => _EvaluationChecklistSummaryCard(item: item),
                  ),
                const SizedBox(height: 20),
                _EvaluationPortfolioSectionTitle(
                  title: 'سجل المحاولات',
                  subtitle: '${attempts.length} محاولة مسجلة بالتفصيل.',
                  icon: Icons.history_rounded,
                ),
                const SizedBox(height: 10),
                if (attempts.isEmpty)
                  const _DocEmpty('لا توجد محاولات مسجلة.')
                else
                  ...attempts.map(
                    (item) => _EvaluationPortfolioAttemptCard(item: item),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EvaluationPortfolioListHero extends StatelessWidget {
  const _EvaluationPortfolioListHero({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.midnight, AppColors.royalBlue, AppColors.teal],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.assessment_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'كشوف الطلاب السريرية',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'تابع المحاولات والقوائم والدكاترة لكل طالب في كشف واحد.',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: .78),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '$total طالب',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvaluationPortfolioStudentCard extends StatelessWidget {
  const _EvaluationPortfolioStudentCard({
    required this.student,
    required this.onTap,
  });

  final _Json student;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final summary = _docMap(student['summary']);
    final name = _docText(student['name'], 'طالب');
    final major = _docText(_docMap(student['major'])['name'], '-');
    final level = _docText(_docMap(student['level'])['name'], '-');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.slate100),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 23,
                    backgroundColor: AppColors.royalBlue.withValues(alpha: .1),
                    child: Text(
                      name.isEmpty ? 'ط' : name.substring(0, 1),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                        color: AppColors.royalBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            color: AppColors.midnight,
                          ),
                        ),
                        Text(
                          '${_docText(student['student_number'], '-')} · $major · $level',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.slate500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${_docDouble(summary['average_percentage']).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.teal,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 15,
                    color: AppColors.slate400,
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  _EvaluationMetricChip(
                    label: 'المحاولات',
                    value: _docText(summary['attempts_count'], '0'),
                    color: AppColors.royalBlue,
                  ),
                  _EvaluationMetricChip(
                    label: 'القوائم',
                    value: _docText(summary['checklists_count'], '0'),
                    color: AppColors.teal,
                  ),
                  _EvaluationMetricChip(
                    label: 'الدكاترة',
                    value: _docText(summary['doctors_count'], '0'),
                    color: AppColors.goldDeep,
                  ),
                  _EvaluationMetricChip(
                    label: 'النجاح',
                    value:
                        '${_docDouble(summary['pass_rate']).toStringAsFixed(0)}%',
                    color: AppColors.success,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EvaluationPortfolioHero extends StatelessWidget {
  const _EvaluationPortfolioHero({
    required this.student,
    required this.summary,
    required this.exporting,
    required this.onExport,
  });

  final _Json student;
  final _Json summary;
  final bool exporting;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final name = _docText(student['name'], 'طالب');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.midnight, AppColors.royalBlue, AppColors.teal],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: Colors.white.withValues(alpha: .16),
                child: Text(
                  name.isEmpty ? 'ط' : name.substring(0, 1),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${_docText(student['student_number'], '-')} · ${_docText(_docMap(student['major'])['name'], '-')} · ${_docText(_docMap(student['level'])['name'], '-')}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: .76),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'تصدير Excel',
                onPressed: exporting ? null : onExport,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: .14),
                  foregroundColor: Colors.white,
                ),
                icon: exporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.table_view_rounded),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _EvaluationHeroStat(
                label: 'المحاولات',
                value: _docText(summary['attempts_count'], '0'),
              ),
              _EvaluationHeroStat(
                label: 'القوائم',
                value: _docText(summary['checklists_count'], '0'),
              ),
              _EvaluationHeroStat(
                label: 'المتوسط',
                value:
                    '${_docDouble(summary['average_percentage']).toStringAsFixed(1)}%',
              ),
              _EvaluationHeroStat(
                label: 'النجاح',
                value:
                    '${_docDouble(summary['pass_rate']).toStringAsFixed(1)}%',
              ),
              _EvaluationHeroStat(
                label: 'الوقت',
                value: _docText(summary['formatted_total_time'], '0:00'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EvaluationChecklistSummaryCard extends StatelessWidget {
  const _EvaluationChecklistSummaryCard({required this.item});

  final _Json item;

  @override
  Widget build(BuildContext context) {
    final doctors = _docList(item['doctors'])
        .map((doctor) => _docText(doctor['name']))
        .where((name) => name.isNotEmpty)
        .join('، ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.fact_check_rounded,
                  color: AppColors.teal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _docText(item['title'], 'قائمة تقييم'),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.midnight,
                      ),
                    ),
                    Text(
                      _docText(item['skill_label'], 'مهارة سريرية'),
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
              Text(
                '${_docDouble(item['average_percentage']).toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.royalBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _EvaluationMetricChip(
                label: 'المحاولات',
                value: _docText(item['attempts_count'], '0'),
                color: AppColors.royalBlue,
              ),
              _EvaluationMetricChip(
                label: 'الأعلى',
                value:
                    '${_docDouble(item['highest_percentage']).toStringAsFixed(0)}%',
                color: AppColors.success,
              ),
              _EvaluationMetricChip(
                label: 'آخر تقدير',
                value: _docText(item['latest_grade_label'], '-'),
                color: AppColors.goldDeep,
              ),
            ],
          ),
          if (doctors.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'الدكاترة: $doctors',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.slate600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EvaluationPortfolioAttemptCard extends StatelessWidget {
  const _EvaluationPortfolioAttemptCard({required this.item});

  final _Json item;

  @override
  Widget build(BuildContext context) {
    final grade = _docText(item['grade']);
    final color = _evaluationGradeColor(grade);
    final checklist = _docMap(item['checklist']);
    final doctor = _docMap(item['doctor']);
    final bodySystem = _docMap(item['body_system']);
    final clinicalCase = _docMap(item['clinical_case']);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _docText(checklist['title'], 'قائمة تقييم'),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.midnight,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '${_docDouble(item['percentage']).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            '${_docText(doctor['name'], 'دكتور غير محدد')} · ${_docText(item['display_date'], '-')}',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.slate500,
            ),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _EvaluationMetricChip(
                label: 'الدرجة',
                value:
                    '${_docText(item['total_score'], '0')} / ${_docText(item['max_score'], '0')}',
                color: color,
              ),
              _EvaluationMetricChip(
                label: 'التقدير',
                value: _docText(item['grade_label'], '-'),
                color: color,
              ),
              _EvaluationMetricChip(
                label: 'الوقت',
                value: _docText(item['formatted_time'], '0:00'),
                color: AppColors.royalBlue,
              ),
            ],
          ),
          if (_docText(bodySystem['name']).isNotEmpty ||
              _docText(clinicalCase['name']).isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              [
                _docText(bodySystem['name']),
                _docText(clinicalCase['name']),
              ].where((value) => value.isNotEmpty).join(' · '),
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.slate600,
              ),
            ),
          ],
          if (_docText(item['doctor_feedback']).isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _docText(item['doctor_feedback']),
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11.5,
                  height: 1.55,
                  color: AppColors.slate700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EvaluationPortfolioSectionTitle extends StatelessWidget {
  const _EvaluationPortfolioSectionTitle({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.royalBlue, size: 21),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.midnight,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EvaluationMetricChip extends StatelessWidget {
  const _EvaluationMetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: .14)),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _EvaluationHeroStat extends StatelessWidget {
  const _EvaluationHeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: .72),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _EvaluationPortfoliosEntryCard extends StatelessWidget {
  const _EvaluationPortfoliosEntryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.royalBlue.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.royalBlue.withValues(alpha: .16)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.royalBlue,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(Icons.assessment_rounded, color: Colors.white),
        ),
        title: const Text(
          'كشوف الطلاب التراكمية',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w900,
            color: AppColors.midnight,
          ),
        ),
        subtitle: const Text(
          'اعرض قوائم كل طالب ومحاولاته ودكاترته وصدّر الكشف إلى Excel.',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.slate500,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 16,
          color: AppColors.royalBlue,
        ),
      ),
    );
  }
}
