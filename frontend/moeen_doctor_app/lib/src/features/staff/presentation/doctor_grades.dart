part of 'staff_screens.dart';

class DoctorGradesScreen extends ConsumerStatefulWidget {
  const DoctorGradesScreen({super.key});

  static const route = '/doctor/grades';

  @override
  ConsumerState<DoctorGradesScreen> createState() => _DoctorGradesScreenState();
}

class _DoctorGradesScreenState extends ConsumerState<DoctorGradesScreen> {
  late Future<Map<String, dynamic>> _future = _fetch();

  Future<Map<String, dynamic>> _fetch() {
    return ref.read(staffRepositoryProvider).get('/doctor/grades');
  }

  void _reload() => setState(() {
    _future = _fetch();
  });

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'إدارة الدرجات',
      currentRoute: DoctorGradesScreen.route,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
          final subjects = _docList(_docData(snapshot.data ?? const {}));
          final totalStudents = subjects.fold<int>(
            0,
            (sum, subject) => sum + _docInt(subject['students_count']),
          );
          final graded = subjects.fold<int>(
            0,
            (sum, subject) => sum + _docInt(subject['graded_students']),
          );

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              children: [
                const _DocHero(
                  title: 'إدارة الدرجات',
                  subtitle: 'إدخال الدرجات والتصنيفات والتفويضات والاعتمادات.',
                  icon: Icons.grade_rounded,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _DocMetric(
                      label: 'المواد',
                      value: subjects.length.toString(),
                      color: AppColors.royalBlue,
                      icon: Icons.menu_book_rounded,
                    ),
                    _DocMetric(
                      label: 'الطلاب',
                      value: totalStudents.toString(),
                      color: AppColors.info,
                      icon: Icons.groups_rounded,
                    ),
                    _DocMetric(
                      label: 'مدخل لهم',
                      value: graded.toString(),
                      color: AppColors.success,
                      icon: Icons.done_all_rounded,
                    ),
                    _DocMetric(
                      label: 'نسبة الإنجاز',
                      value: totalStudents == 0
                          ? '0%'
                          : '${((graded / totalStudents) * 100).round()}%',
                      color: AppColors.warning,
                      icon: Icons.trending_up_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (subjects.isEmpty)
                  const _DocEmpty('لا توجد مواد مرتبطة بحسابك.')
                else
                  ...subjects.map(
                    (subject) => _GradeSubjectCard(
                      subject: subject,
                      onTap: () => _openSubject(subject),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openSubject(_Json subject) async {
    await context.push(
      DoctorGradeSubjectScreen.path(_docInt(subject['id'])),
      extra: subject,
    );
    _reload();
  }
}

class DoctorGradeSubjectScreen extends StatelessWidget {
  const DoctorGradeSubjectScreen({
    super.key,
    required this.subjectId,
    this.subject,
  });

  static const route = '/doctor/grades/:subjectId';

  final int subjectId;
  final Map<String, dynamic>? subject;

  static String path(int subjectId) => '/doctor/grades/$subjectId';

  @override
  Widget build(BuildContext context) {
    final subjectData = subject ?? <String, dynamic>{'id': subjectId};

    return StaffShell(
      title: 'تفاصيل الدرجات',
      currentRoute: DoctorGradesScreen.route,
      child: _GradeSubjectPanel(subject: subjectData, fillAvailable: true),
    );
  }
}

_Json _gradeSettingsFrom(_Json subject) {
  final settings = _docMap(subject['grade_settings']);
  return {
    'total_max_score': _docNum(settings['total_max_score'], 100),
    'continuous_max_score': _docNum(settings['continuous_max_score'], 40),
    'final_max_score': _docNum(settings['final_max_score'], 60),
    'passing_score': _docNum(settings['passing_score'], 50),
  };
}

String _gradeLimitLabel(num value) {
  return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
}

class _GradeSubjectCard extends StatelessWidget {
  const _GradeSubjectCard({required this.subject, required this.onTap});

  final _Json subject;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final students = _docInt(subject['students_count']);
    final graded = _docInt(subject['graded_students']);
    final progress = students == 0 ? 0.0 : graded / students;
    final progressColor = progress >= 0.8
        ? AppColors.success
        : progress >= 0.45
        ? AppColors.warning
        : AppColors.royalBlue;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.slate100),
          boxShadow: [
            BoxShadow(
              color: progressColor.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: progressColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: progressColor.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.grade_rounded,
                    color: progressColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _docText(subject['name'], 'مادة'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.midnight,
                          fontSize: 16,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w900,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${_docText(subject['major'], '-')} • ${_docText(subject['level'], '-')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.slate500,
                          fontSize: 12,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: progressColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: progressColor.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Text(
                    '${(progress * 100).round()}%',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: progressColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                boxShadow: [
                  BoxShadow(
                    color: progressColor.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress.clamp(0, 1),
                  minHeight: 10,
                  color: progressColor,
                  backgroundColor: AppColors.slate100,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DocPill(
                  '$students طالب',
                  AppColors.info,
                  icon: Icons.groups_rounded,
                ),
                _DocPill(
                  '$graded رصد',
                  AppColors.success,
                  icon: Icons.check_circle_rounded,
                ),
                _DocPill(
                  'متوسط: ${_docText(subject['average_grade'], '-')}',
                  AppColors.warning,
                  icon: Icons.stars_rounded,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GradeSubjectPanel extends ConsumerStatefulWidget {
  const _GradeSubjectPanel({required this.subject, this.fillAvailable = false});

  final _Json subject;
  final bool fillAvailable;

  @override
  ConsumerState<_GradeSubjectPanel> createState() => _GradeSubjectPanelState();
}

class _GradeSubjectPanelState extends ConsumerState<_GradeSubjectPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late Future<Map<String, dynamic>> _future = _fetch();
  String _search = '';
  String _entryFilter = 'all';
  bool _saving = false;
  final Set<int> _expandedGradeStudents = {};
  final Map<int, TextEditingController> _continuous = {};
  final Map<int, TextEditingController> _final = {};
  final Map<String, TextEditingController> _categoryScores = {};
  final Map<String, String> _initialGradeValues = {};

  int get _subjectId => _docInt(widget.subject['id']);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    for (final controller in _continuous.values) {
      controller.dispose();
    }
    for (final controller in _final.values) {
      controller.dispose();
    }
    for (final controller in _categoryScores.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetch() {
    return ref.read(staffRepositoryProvider).get('/doctor/grades/$_subjectId');
  }

  void _reload() => setState(() {
    _future = _fetch();
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
        final data = _docMap(_docData(snapshot.data ?? const {}));
        final subjectDetails = _docMap(data['subject']);
        final gradeSettings = _gradeSettingsFrom(
          subjectDetails.isEmpty ? widget.subject : subjectDetails,
        );
        final students = _docList(data['students']);
        final categories = _docList(data['categories']);
        final stats = _docMap(data['stats']);
        _ensureGradeControllers(students, categories);
        if (widget.fillAvailable) {
          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DocHero(
                        title: _docText(
                          widget.subject['name'],
                          'تفاصيل الدرجات',
                        ),
                        subtitle:
                            'إدخال الدرجات والتصنيفات والتفويضات وتقرير المادة في مساحة واحدة.',
                        icon: Icons.grade_rounded,
                      ),
                      const SizedBox(height: 14),
                      _buildGradeMetrics(stats, data, students),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _DocStickyHeaderDelegate(
                  minHeight: 64,
                  maxHeight: 64,
                  child: Container(
                    color: AppColors.cream,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: _buildGradeTabBar(),
                  ),
                ),
              ),
            ],
            body: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: _buildGradeTabView(students, categories, gradeSettings),
            ),
          );
        }

        final content = Column(
          children: [
            _buildGradeMetrics(stats, data, students),
            const SizedBox(height: 14),
            _buildGradeTabBar(),
            const SizedBox(height: 12),
            Expanded(
              child: _buildGradeTabView(students, categories, gradeSettings),
            ),
          ],
        );

        return SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.78,
          child: content,
        );
      },
    );
  }

  Widget _buildGradeMetrics(_Json stats, _Json data, List<_Json> students) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _buildGradeCompactMetric(
          label: 'الطلاب',
          value: _docText(stats['total_students'], students.length.toString()),
          color: AppColors.info,
          icon: Icons.groups_rounded,
        ),
        _buildGradeCompactMetric(
          label: 'المتوسط',
          value: _docText(stats['average'], '0'),
          color: AppColors.royalBlue,
          icon: Icons.analytics_rounded,
        ),
        _buildGradeCompactMetric(
          label: 'أعلى درجة',
          value: _docText(stats['highest'], '0'),
          color: AppColors.success,
          icon: Icons.trending_up_rounded,
        ),
        _buildGradeCompactMetric(
          label: 'بانتظار الاعتماد',
          value: _docText(data['pending_count'], '0'),
          color: AppColors.warning,
          icon: Icons.pending_actions_rounded,
        ),
      ],
    );
  }

  Widget _buildGradeCompactMetric({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Builder(
      builder: (context) {
        final width = (MediaQuery.sizeOf(context).width - 50) / 2;
        return Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.12),
              width: 1.2,
            ),
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
      },
    );
  }

  Widget _buildGradeTabBar() {
    return _DocPanelTabBar(
      controller: _tabs,
      tabs: const [
        Tab(
          height: 42,
          child: Row(
            children: [
              Icon(Icons.edit_note_rounded, size: 17),
              SizedBox(width: 6),
              Text(
                'إدخال الدرجات',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        Tab(
          height: 42,
          child: Row(
            children: [
              Icon(Icons.category_rounded, size: 17),
              SizedBox(width: 6),
              Text(
                'التصنيفات',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        Tab(
          height: 42,
          child: Row(
            children: [
              Icon(Icons.verified_user_rounded, size: 17),
              SizedBox(width: 6),
              Text(
                'التفويضات',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        Tab(
          height: 42,
          child: Row(
            children: [
              Icon(Icons.fact_check_rounded, size: 17),
              SizedBox(width: 6),
              Text(
                'الاعتمادات',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        Tab(
          height: 42,
          child: Row(
            children: [
              Icon(Icons.analytics_rounded, size: 17),
              SizedBox(width: 6),
              Text(
                'التقرير',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        Tab(
          height: 42,
          child: Row(
            children: [
              Icon(Icons.tune_rounded, size: 17),
              SizedBox(width: 6),
              Text(
                'الإعدادات',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGradeTabView(
    List<_Json> students,
    List<_Json> categories,
    _Json gradeSettings,
  ) {
    return TabBarView(
      controller: _tabs,
      children: [
        _buildEntryTab(students, categories, gradeSettings),
        _GradeCategoriesTabV2(
          subjectId: _subjectId,
          categories: categories,
          continuousMaxScore: _docNum(
            gradeSettings['continuous_max_score'],
            40,
          ),
          onChanged: _reload,
        ),
        _GradeDelegationsTabV2(subjectId: _subjectId),
        _GradeApprovalsTabV2(subjectId: _subjectId, onChanged: _reload),
        _GradeReportTabV2(subjectId: _subjectId),
        _GradeSettingsTab(
          subjectId: _subjectId,
          settings: gradeSettings,
          onChanged: _reload,
        ),
      ],
    );
  }

  void _ensureGradeControllers(List<_Json> students, List<_Json> categories) {
    for (final student in students) {
      final id = _docInt(student['id']);
      _continuous.putIfAbsent(
        id,
        () => TextEditingController(text: _docText(student['continuous'])),
      );
      _initialGradeValues.putIfAbsent(
        _gradeFieldKey(id, 'continuous'),
        () => _continuous[id]!.text.trim(),
      );
      _final.putIfAbsent(
        id,
        () => TextEditingController(text: _docText(student['final'])),
      );
      _initialGradeValues.putIfAbsent(
        _gradeFieldKey(id, 'final'),
        () => _final[id]!.text.trim(),
      );
      final categoryGrades = {
        for (final grade in _docList(student['category_grades']))
          _docInt(grade['category_id']): _docText(grade['score']),
      };
      for (final category in categories) {
        final catId = _docInt(category['id']);
        _categoryScores.putIfAbsent(
          '$id:$catId',
          () => TextEditingController(text: categoryGrades[catId] ?? ''),
        );
        _initialGradeValues.putIfAbsent(
          _gradeFieldKey(id, 'category', catId),
          () => _categoryScores['$id:$catId']!.text.trim(),
        );
      }
    }
  }

  Widget _buildEntryTab(
    List<_Json> students,
    List<_Json> categories,
    _Json gradeSettings,
  ) {
    final continuousMaxScore = _docNum(
      gradeSettings['continuous_max_score'],
      40,
    );
    final finalMaxScore = _docNum(gradeSettings['final_max_score'], 60);
    final filtered = students.where((student) {
      final q = _search.toLowerCase();
      final matchesSearch =
          _search.isEmpty ||
          _docText(student['name']).toLowerCase().contains(q) ||
          _docText(student['student_number']).toLowerCase().contains(q);
      if (!matchesSearch) return false;
      return switch (_entryFilter) {
        'missing' => _isStudentIncomplete(student, categories),
        'dirty' => _isStudentDirty(student, categories),
        'errors' => _studentErrorCount(student, categories, gradeSettings) > 0,
        _ => true,
      };
    }).toList();
    final completed = students
        .where((student) => !_isStudentIncomplete(student, categories))
        .length;
    final dirty = students
        .where((student) => _isStudentDirty(student, categories))
        .length;
    final errors = students.fold<int>(
      0,
      (sum, student) =>
          sum + _studentErrorCount(student, categories, gradeSettings),
    );
    final itemCount = 1 + (filtered.isEmpty ? 1 : filtered.length) + 1;

    return Stack(
      children: [
        ListView.builder(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom + 146,
          ),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _GradeEntryHeader(
                search: _search,
                filter: _entryFilter,
                total: students.length,
                shown: filtered.length,
                completed: completed,
                dirty: dirty,
                errors: errors,
                onSearchChanged: (value) => setState(() => _search = value),
                onFilterChanged: (value) =>
                    setState(() => _entryFilter = value),
              );
            }
            if (index == itemCount - 1) return const SizedBox(height: 8);
            if (filtered.isEmpty) {
              return const _DocEmpty('لا يوجد طلاب مطابقون للفلاتر الحالية.');
            }
            final student = filtered[index - 1];
            final studentId = _docInt(student['id']);
            final expanded = _expandedGradeStudents.contains(studentId);
            return _GradeStudentCard(
              student: student,
              categories: categories,
              continuous: _continuous[studentId]!,
              finalGrade: _final[studentId]!,
              categoryControllers: {
                for (final category in categories)
                  _docInt(category['id']):
                      _categoryScores['$studentId:${_docInt(category['id'])}']!,
              },
              expanded: expanded,
              dirty: _isStudentDirty(student, categories),
              incomplete: _isStudentIncomplete(student, categories),
              errorCount: _studentErrorCount(
                student,
                categories,
                gradeSettings,
              ),
              total: _studentEditedTotal(student, categories),
              showContinuous: categories.isEmpty,
              continuousMaxScore: continuousMaxScore,
              finalMaxScore: finalMaxScore,
              onToggle: () => setState(() {
                if (expanded) {
                  _expandedGradeStudents.remove(studentId);
                } else {
                  _expandedGradeStudents.add(studentId);
                }
              }),
              onChanged: () => setState(() {}),
              onNote: () => _addNote(student),
            );
          },
        ),
        if (dirty > 0 || errors > 0)
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 10,
            child: _GradeSaveBar(
              dirty: dirty,
              errors: errors,
              saving: _saving,
              onReset: _saving
                  ? null
                  : () => _resetGradeChanges(students, categories),
              onSave: _saving || errors > 0
                  ? null
                  : () => _confirmSaveGrades(students, categories, dirty),
            ),
          ),
      ],
    );
  }

  String _gradeFieldKey(int studentId, String field, [int? categoryId]) {
    return categoryId == null
        ? '$studentId:$field'
        : '$studentId:$field:$categoryId';
  }

  bool _isStudentDirty(_Json student, List<_Json> categories) {
    final id = _docInt(student['id']);
    if (categories.isEmpty &&
        _isFieldDirty(_gradeFieldKey(id, 'continuous'), _continuous[id])) {
      return true;
    }
    if (_isFieldDirty(_gradeFieldKey(id, 'final'), _final[id])) return true;
    for (final category in categories) {
      final catId = _docInt(category['id']);
      if (_isFieldDirty(
        _gradeFieldKey(id, 'category', catId),
        _categoryScores['$id:$catId'],
      )) {
        return true;
      }
    }
    return false;
  }

  bool _isFieldDirty(String key, TextEditingController? controller) {
    return (controller?.text.trim() ?? '') != (_initialGradeValues[key] ?? '');
  }

  bool _isStudentIncomplete(_Json student, List<_Json> categories) {
    final id = _docInt(student['id']);
    if (categories.isEmpty && (_continuous[id]?.text.trim() ?? '').isEmpty) {
      return true;
    }
    if ((_final[id]?.text.trim() ?? '').isEmpty) return true;
    for (final category in categories) {
      final catId = _docInt(category['id']);
      if ((_categoryScores['$id:$catId']?.text.trim() ?? '').isEmpty) {
        return true;
      }
    }
    return false;
  }

  int _studentErrorCount(
    _Json student,
    List<_Json> categories,
    _Json gradeSettings,
  ) {
    final id = _docInt(student['id']);
    final continuousMaxScore = _docNum(
      gradeSettings['continuous_max_score'],
      40,
    );
    final finalMaxScore = _docNum(gradeSettings['final_max_score'], 60);
    var count = 0;
    if (categories.isEmpty &&
        _gradeInputError(_continuous[id], max: continuousMaxScore) != null) {
      count++;
    }
    if (_gradeInputError(_final[id], max: finalMaxScore) != null) count++;
    for (final category in categories) {
      final catId = _docInt(category['id']);
      final max = _docNum(category['max_score']);
      if (_gradeInputError(_categoryScores['$id:$catId'], max: max) != null) {
        count++;
      }
    }
    return count;
  }

  String? _gradeInputError(TextEditingController? controller, {num? max}) {
    final raw = controller?.text.trim() ?? '';
    if (raw.isEmpty) return null;
    final value = num.tryParse(raw.replaceAll(',', '.'));
    if (value == null) return 'رقم غير صحيح';
    if (value < 0) return 'لا يقبل أقل من صفر';
    if (max != null && max > 0 && value > max) return 'أكبر من الحد الأعلى';
    return null;
  }

  String _studentEditedTotal(_Json student, List<_Json> categories) {
    final id = _docInt(student['id']);
    var total = _gradeValue(_final[id]);
    if (categories.isEmpty) {
      total += _gradeValue(_continuous[id]);
    }
    for (final category in categories) {
      total += _gradeValue(_categoryScores['$id:${_docInt(category['id'])}']);
    }
    if (total == 0) return _docText(student['total'], '0');
    return total % 1 == 0 ? total.toInt().toString() : total.toStringAsFixed(1);
  }

  num _gradeValue(TextEditingController? controller) {
    return num.tryParse((controller?.text.trim() ?? '').replaceAll(',', '.')) ??
        0;
  }

  void _resetGradeChanges(List<_Json> students, List<_Json> categories) {
    for (final student in students) {
      final id = _docInt(student['id']);
      _continuous[id]?.text =
          _initialGradeValues[_gradeFieldKey(id, 'continuous')] ?? '';
      _final[id]?.text = _initialGradeValues[_gradeFieldKey(id, 'final')] ?? '';
      for (final category in categories) {
        final catId = _docInt(category['id']);
        _categoryScores['$id:$catId']?.text =
            _initialGradeValues[_gradeFieldKey(id, 'category', catId)] ?? '';
      }
    }
    setState(() {});
  }

  Future<void> _confirmSaveGrades(
    List<_Json> students,
    List<_Json> categories,
    int dirty,
  ) async {
    final ok = await showMoeenConfirmDialog(
      context: context,
      title: 'حفظ تعديلات الدرجات؟',
      message:
          'سيتم حفظ تعديلات $dirty طالب. تأكد من مراجعة القيم قبل الاعتماد.',
      confirmLabel: 'حفظ الآن',
      cancelLabel: 'مراجعة',
      icon: Icons.save_rounded,
      color: AppColors.success,
    );
    if (ok != true) return;
    await _saveGrades(students, categories);
  }

  // ignore: unused_element
  Widget _buildEntryTabLegacy(List<_Json> students, List<_Json> categories) {
    final filtered = students.where((student) {
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return _docText(student['name']).toLowerCase().contains(q) ||
          _docText(student['student_number']).toLowerCase().contains(q);
    }).toList();

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom + 96,
      ),
      children: [
        _DocFilterPanel(
          title: 'البحث داخل الطلاب',
          icon: Icons.search_rounded,
          children: [
            TextField(
              onChanged: (value) => setState(() => _search = value),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'ابحث باسم الطالب أو رقم القيد...',
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
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.royalBlue,
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          const _DocEmpty('لا يوجد طلاب مطابقون للبحث.')
        else
          ...filtered.map(
            (student) => _GradeStudentCard(
              student: student,
              categories: categories,
              continuous: _continuous[_docInt(student['id'])]!,
              finalGrade: _final[_docInt(student['id'])]!,
              categoryControllers: {
                for (final category in categories)
                  _docInt(
                    category['id'],
                  ): _categoryScores['${_docInt(student['id'])}:${_docInt(category['id'])}']!,
              },
              continuousMaxScore: 40,
              finalMaxScore: 60,
              onNote: () => _addNote(student),
            ),
          ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.slate100),
            boxShadow: [
              BoxShadow(
                color: AppColors.royalBlue.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FilledButton.icon(
            onPressed: _saving ? null : () => _saveGrades(students, categories),
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded),
            label: const Text('حفظ الدرجات'),
          ),
        ),
      ],
    );
  }

  Future<void> _saveGrades(List<_Json> students, List<_Json> categories) async {
    setState(() => _saving = true);
    try {
      final grades = students.map((student) {
        final id = _docInt(student['id']);
        return {
          'student_id': id,
          'continuous': categories.isEmpty
              ? _continuous[id]?.text.trim()
              : null,
          'final': _final[id]?.text.trim(),
          'categories': {
            for (final category in categories)
              '${_docInt(category['id'])}':
                  _categoryScores['$id:${_docInt(category['id'])}']?.text
                      .trim(),
          },
        };
      }).toList();
      await ref.read(staffRepositoryProvider).post(
        '/doctor/grades/$_subjectId',
        {'grades': grades},
      );
      if (!mounted) return;
      _initialGradeValues.clear();
      _reload();
      await showMoeenInfoDialog(
        context: context,
        title: 'تم حفظ الدرجات',
        message: 'تم تحديث درجات الطلاب بنجاح.',
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
      );
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addNote(_Json student) async {
    final note = TextEditingController();
    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: 'ملاحظة للطالب',
      icon: Icons.note_add_rounded,
      color: AppColors.royalBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_docText(student['name'])),
          const SizedBox(height: 12),
          TextField(
            controller: note,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'الملاحظة'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
    if (ok != true || note.text.trim().isEmpty) return;
    try {
      await ref.read(staffRepositoryProvider).post(
        '/doctor/grades/$_subjectId/note/${student['id']}',
        {'note': note.text.trim()},
      );
      if (!mounted) return;
      _reload();
      _docSnack(context, 'تم إرسال الملاحظة.', color: AppColors.success);
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }
}

class _DocStickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _DocStickyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: AppColors.cream,
      elevation: overlapsContent ? 4 : 0,
      shadowColor: AppColors.midnight.withValues(alpha: 0.08),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _DocStickyHeaderDelegate oldDelegate) {
    return minHeight != oldDelegate.minHeight ||
        maxHeight != oldDelegate.maxHeight ||
        child != oldDelegate.child;
  }
}

class _GradeEntryHeader extends StatelessWidget {
  const _GradeEntryHeader({
    required this.search,
    required this.filter,
    required this.total,
    required this.shown,
    required this.completed,
    required this.dirty,
    required this.errors,
    required this.onSearchChanged,
    required this.onFilterChanged,
  });

  final String search;
  final String filter;
  final int total;
  final int shown;
  final int completed;
  final int dirty;
  final int errors;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : completed / total;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: onSearchChanged,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    hintText: 'ابحث باسم الطالب أو رقم القيد...',
                    hintStyle: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate400,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.royalBlue,
                    ),
                    filled: true,
                    fillColor: AppColors.slate50,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.royalBlue,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _GradeProgressBadge(
                value: '${(progress * 100).round()}%',
                label: 'مكتمل',
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _GradeFilterChip(
                  label: 'الكل',
                  selected: filter == 'all',
                  onTap: () => onFilterChanged('all'),
                ),
                const SizedBox(width: 8),
                _GradeFilterChip(
                  label: 'ناقص',
                  selected: filter == 'missing',
                  onTap: () => onFilterChanged('missing'),
                  color: AppColors.warning,
                ),
                const SizedBox(width: 8),
                _GradeFilterChip(
                  label: 'معدل',
                  selected: filter == 'dirty',
                  onTap: () => onFilterChanged('dirty'),
                ),
                const SizedBox(width: 8),
                _GradeFilterChip(
                  label: 'أخطاء',
                  selected: filter == 'errors',
                  onTap: () => onFilterChanged('errors'),
                  color: AppColors.danger,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _GradeMiniStat(label: 'المعروض', value: '$shown'),
                ),
                Container(width: 1, height: 24, color: AppColors.slate200),
                Expanded(
                  child: _GradeMiniStat(label: 'الطلاب', value: '$total'),
                ),
                Container(width: 1, height: 24, color: AppColors.slate200),
                Expanded(
                  child: _GradeMiniStat(label: 'تعديلات', value: '$dirty'),
                ),
                Container(width: 1, height: 24, color: AppColors.slate200),
                Expanded(
                  child: _GradeMiniStat(
                    label: 'أخطاء',
                    value: '$errors',
                    color: errors > 0 ? AppColors.danger : AppColors.slate600,
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

class _GradeProgressBadge extends StatelessWidget {
  const _GradeProgressBadge({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeMiniStat extends StatelessWidget {
  const _GradeMiniStat({
    required this.label,
    required this.value,
    this.color = AppColors.midnight,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Cairo',
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            color: AppColors.slate500,
            fontWeight: FontWeight.w800,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _GradeFilterChip extends StatelessWidget {
  const _GradeFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = AppColors.royalBlue,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : AppColors.slate50,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected ? color : AppColors.slate200,
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            color: selected ? color : AppColors.slate700,
            fontWeight: FontWeight.w900,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}

class _GradeSaveBar extends StatelessWidget {
  const _GradeSaveBar({
    required this.dirty,
    required this.errors,
    required this.saving,
    required this.onReset,
    required this.onSave,
  });

  final int dirty;
  final int errors;
  final bool saving;
  final VoidCallback? onReset;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final hasErrors = errors > 0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: hasErrors
              ? AppColors.danger.withValues(alpha: 0.28)
              : AppColors.royalBlue.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.midnight.withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            hasErrors ? Icons.error_rounded : Icons.edit_note_rounded,
            color: hasErrors ? AppColors.danger : AppColors.royalBlue,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasErrors
                  ? 'يوجد $errors خطأ قبل الحفظ'
                  : 'لديك تعديلات على $dirty طالب',
              style: TextStyle(
                color: hasErrors ? AppColors.danger : AppColors.midnight,
                fontWeight: FontWeight.w900,
                fontSize: 12.5,
              ),
            ),
          ),
          TextButton(onPressed: onReset, child: const Text('تراجع')),
          const SizedBox(width: 6),
          FilledButton.icon(
            onPressed: onSave,
            icon: saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded, size: 18),
            label: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

class _GradeStudentCard extends StatelessWidget {
  const _GradeStudentCard({
    required this.student,
    required this.categories,
    required this.continuous,
    required this.finalGrade,
    required this.categoryControllers,
    required this.onNote,
    required this.continuousMaxScore,
    required this.finalMaxScore,
    this.expanded = true,
    this.dirty = false,
    this.incomplete = false,
    this.errorCount = 0,
    this.total,
    this.showContinuous = true,
    this.onToggle,
    this.onChanged,
  });

  final _Json student;
  final List<_Json> categories;
  final TextEditingController continuous;
  final TextEditingController finalGrade;
  final Map<int, TextEditingController> categoryControllers;
  final VoidCallback onNote;
  final num continuousMaxScore;
  final num finalMaxScore;
  final bool expanded;
  final bool dirty;
  final bool incomplete;
  final int errorCount;
  final String? total;
  final bool showContinuous;
  final VoidCallback? onToggle;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final statusColor = errorCount > 0
        ? AppColors.danger
        : incomplete
        ? AppColors.warning
        : dirty
        ? AppColors.royalBlue
        : AppColors.success;
    final statusText = errorCount > 0
        ? 'يحتاج مراجعة'
        : incomplete
        ? 'ناقص'
        : dirty
        ? 'معدل'
        : 'مكتمل';

    final studentName = _docText(student['name'], 'طالب');
    final avatarLetter = studentName.isNotEmpty
        ? studentName.characters.first
        : '?';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: statusColor.withValues(alpha: expanded ? 0.28 : 0.12),
          width: expanded ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: expanded ? 0.06 : 0.02),
            blurRadius: expanded ? 22 : 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: statusColor.withValues(alpha: 0.08),
                      child: Text(
                        avatarLetter,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: statusColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            studentName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              color: AppColors.midnight,
                              fontWeight: FontWeight.w900,
                              fontSize: 14.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _docText(student['student_number'], '-'),
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              color: AppColors.slate500,
                              fontWeight: FontWeight.w700,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _GradeProgressBadge(
                      value: total ?? _docText(student['total'], '0'),
                      label: 'المجموع',
                      color: statusColor,
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.slate500,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  _DocPill(statusText, statusColor),
                  if (errorCount > 0) ...[
                    const SizedBox(width: 8),
                    _DocPill('$errorCount خطأ', AppColors.danger),
                  ],
                  const Spacer(),
                  TextButton.icon(
                    onPressed: onNote,
                    icon: const Icon(Icons.note_add_rounded, size: 17),
                    label: const Text(
                      'ملاحظة للطالب',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.royalBlue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Container(
                color: AppColors.slate50.withValues(alpha: 0.7),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (showContinuous)
                      Row(
                        children: [
                          Expanded(
                            child: _QuickGradeField(
                              label: 'أعمال السنة',
                              helper:
                                  'الحد الأعلى ${_gradeLimitLabel(continuousMaxScore)}',
                              max: continuousMaxScore,
                              controller: continuous,
                              icon: Icons.edit_rounded,
                              onChanged: onChanged,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickGradeField(
                              label: 'النهائي',
                              helper:
                                  'الحد الأعلى ${_gradeLimitLabel(finalMaxScore)}',
                              max: finalMaxScore,
                              controller: finalGrade,
                              icon: Icons.school_rounded,
                              onChanged: onChanged,
                            ),
                          ),
                        ],
                      )
                    else
                      _QuickGradeField(
                        label: 'الدرجة النهائية',
                        helper:
                            'الحد الأعلى ${_gradeLimitLabel(finalMaxScore)}',
                        max: finalMaxScore,
                        controller: finalGrade,
                        icon: Icons.school_rounded,
                        onChanged: onChanged,
                      ),
                    if (categories.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      const _GradeSectionLabel(
                        title: 'أعمال السنة التفصيلية',
                        subtitle:
                            'يتم حساب الإجمالي تلقائياً من التصنيفات المدخلة أدناه',
                      ),
                      const SizedBox(height: 12),
                      ...categories.map((category) {
                        final catId = _docInt(category['id']);
                        final max = _docNum(category['max_score']);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _QuickGradeField(
                            label: _docText(category['name']),
                            helper: max > 0 ? 'الحد الأعلى $max' : null,
                            max: max,
                            controller: categoryControllers[catId]!,
                            icon: Icons.category_rounded,
                            onChanged: onChanged,
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
              crossFadeState: expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradeSectionLabel extends StatelessWidget {
  const _GradeSectionLabel({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.royalBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.fact_check_rounded,
            color: AppColors.royalBlue,
            size: 19,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.midnight,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.slate500,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
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

class _QuickGradeField extends StatelessWidget {
  const _QuickGradeField({
    required this.label,
    required this.controller,
    required this.icon,
    this.helper,
    this.max,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? helper;
  final num? max;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final error = _errorText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          onChanged: (_) => onChanged?.call(),
          onTap: () => controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: controller.text.length,
          ),
          scrollPadding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom + 190,
          ),
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w900,
            fontSize: 15,
            color: AppColors.midnight,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
            ),
            helperText: error == null ? helper : null,
            helperStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 11),
            errorText: error,
            errorStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 11),
            prefixIcon: Icon(icon, size: 19, color: AppColors.royalBlue),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.slate200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.slate200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.royalBlue,
                width: 2,
              ),
            ),
            suffixIcon: Container(
              margin: const EdgeInsetsDirectional.only(end: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _GradeStepButton(
                    icon: Icons.remove_rounded,
                    onTap: () => _step(-1),
                  ),
                  const SizedBox(width: 4),
                  _GradeStepButton(
                    icon: Icons.add_rounded,
                    onTap: () => _step(1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String? get _errorText {
    final raw = controller.text.trim();
    if (raw.isEmpty) return null;
    final value = num.tryParse(raw.replaceAll(',', '.'));
    if (value == null) return 'رقم غير صحيح';
    if (value < 0) return 'أقل من صفر';
    if (max != null && max! > 0 && value > max!) return 'أكبر من $max';
    return null;
  }

  void _step(num delta) {
    final current =
        num.tryParse(controller.text.trim().replaceAll(',', '.')) ?? 0;
    var next = current + delta;
    if (next < 0) next = 0;
    if (max != null && max! > 0 && next > max!) next = max!;
    controller.text = next % 1 == 0
        ? next.toInt().toString()
        : next.toStringAsFixed(1);
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );
    onChanged?.call();
  }
}

class _GradeStepButton extends StatelessWidget {
  const _GradeStepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.slate50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.slate200),
        ),
        child: Icon(icon, size: 18, color: AppColors.royalBlue),
      ),
    );
  }
}

// ignore: unused_element
class _GradeStudentCardLegacy extends StatelessWidget {
  const _GradeStudentCardLegacy({
    required this.student,
    required this.categories,
    required this.continuous,
    required this.finalGrade,
    required this.categoryControllers,
    required this.onNote,
  });

  final _Json student;
  final List<_Json> categories;
  final TextEditingController continuous;
  final TextEditingController finalGrade;
  final Map<int, TextEditingController> categoryControllers;
  final VoidCallback onNote;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: AppColors.royalBlue.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.royalBlue,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _docText(student['name']),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.midnight,
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                      ),
                    ),
                    Text(
                      _docText(student['student_number'], '-'),
                      style: const TextStyle(
                        color: AppColors.slate500,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _DocPill(
                'المجموع ${_docText(student['total'], '0')}',
                AppColors.royalBlue,
                icon: Icons.functions_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: continuous,
                  keyboardType: TextInputType.number,
                  scrollPadding: EdgeInsets.only(
                    bottom: MediaQuery.viewInsetsOf(context).bottom + 160,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'أعمال السنة',
                    prefixIcon: Icon(Icons.edit_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: finalGrade,
                  keyboardType: TextInputType.number,
                  scrollPadding: EdgeInsets.only(
                    bottom: MediaQuery.viewInsetsOf(context).bottom + 160,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'النهائي',
                    prefixIcon: Icon(Icons.school_rounded),
                  ),
                ),
              ),
            ],
          ),
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...categories.map(
              (category) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextField(
                  controller: categoryControllers[_docInt(category['id'])],
                  keyboardType: TextInputType.number,
                  scrollPadding: EdgeInsets.only(
                    bottom: MediaQuery.viewInsetsOf(context).bottom + 160,
                  ),
                  decoration: InputDecoration(
                    labelText:
                        '${_docText(category['name'])} / ${_docText(category['max_score'])}',
                  ),
                ),
              ),
            ),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onNote,
              icon: const Icon(Icons.note_add_rounded),
              label: const Text('إضافة ملاحظة'),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeCategoriesTab extends ConsumerStatefulWidget {
  const _GradeCategoriesTab({
    required this.subjectId,
    required this.categories,
    required this.onChanged,
  });

  final int subjectId;
  final List<_Json> categories;
  final VoidCallback onChanged;

  @override
  ConsumerState<_GradeCategoriesTab> createState() =>
      _GradeCategoriesTabState();
}

class _GradeCategoriesTabState extends ConsumerState<_GradeCategoriesTab> {
  Future<void> _add() async {
    final name = TextEditingController();
    final score = TextEditingController();
    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: 'تصنيف جديد',
      icon: Icons.category_rounded,
      color: AppColors.royalBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'الاسم'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: score,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'الدرجة العظمى'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(staffRepositoryProvider).post(
        '/doctor/grades/${widget.subjectId}/categories',
        {
          'name': name.text.trim(),
          'max_score': num.tryParse(score.text.trim()),
        },
      );
      widget.onChanged();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  Future<void> _delete(_Json category) async {
    final ok = await showMoeenConfirmDialog(
      context: context,
      title: 'حذف التصنيف',
      message: 'هل تريد حذف هذا التصنيف؟',
      confirmLabel: 'حذف',
      color: AppColors.danger,
      icon: Icons.delete_rounded,
    );
    if (!ok) return;
    try {
      await ref
          .read(staffRepositoryProvider)
          .delete('/doctor/grades/categories/${category['id']}');
      widget.onChanged();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.categories.fold<num>(
      0,
      (sum, item) => sum + _docNum(item['max_score']),
    );
    return ListView(
      children: [
        _DocMetric(
          label: 'مجموع التصنيفات',
          value: '$total / 40',
          color: total > 40 ? AppColors.danger : AppColors.royalBlue,
          icon: Icons.calculate_rounded,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _add,
          icon: const Icon(Icons.add_rounded),
          label: const Text('إضافة تصنيف'),
        ),
        const SizedBox(height: 12),
        if (widget.categories.isEmpty)
          const _DocEmpty('لا توجد تصنيفات بعد.')
        else
          ...widget.categories.map(
            (category) => ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              tileColor: Colors.white,
              title: Text(_docText(category['name'])),
              subtitle: Text('الدرجة: ${_docText(category['max_score'])}'),
              trailing: IconButton(
                onPressed: () => _delete(category),
                icon: const Icon(Icons.delete_rounded, color: AppColors.danger),
              ),
            ),
          ),
      ],
    );
  }
}

class _GradeDelegationsTab extends ConsumerStatefulWidget {
  const _GradeDelegationsTab({required this.subjectId});

  final int subjectId;

  @override
  ConsumerState<_GradeDelegationsTab> createState() =>
      _GradeDelegationsTabState();
}

class _GradeDelegationsTabState extends ConsumerState<_GradeDelegationsTab> {
  late Future<Map<String, dynamic>> _future = _fetch();

  Future<Map<String, dynamic>> _fetch() => ref
      .read(staffRepositoryProvider)
      .get('/doctor/grades/${widget.subjectId}/delegations');

  void _reload() => setState(() {
    _future = _fetch();
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
        final data = _docMap(_docData(snapshot.data ?? const {}));
        final categories = _docList(data['categories']);
        final students = _docList(data['students']);
        if (categories.isEmpty) {
          return const _DocEmpty('أنشئ تصنيفات الدرجات قبل التفويض.');
        }
        return ListView(
          children: categories
              .map(
                (category) => _DelegationCategoryCard(
                  category: category,
                  students: students,
                  onChanged: _reload,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _DelegationCategoryCard extends ConsumerStatefulWidget {
  const _DelegationCategoryCard({
    required this.category,
    required this.students,
    required this.onChanged,
  });

  final _Json category;
  final List<_Json> students;
  final VoidCallback onChanged;

  @override
  ConsumerState<_DelegationCategoryCard> createState() =>
      _DelegationCategoryCardState();
}

class _DelegationCategoryCardState
    extends ConsumerState<_DelegationCategoryCard> {
  int? _studentId;

  @override
  Widget build(BuildContext context) {
    final permissions = _docList(widget.category['permissions']);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _docText(widget.category['name']),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            initialValue: _studentId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'اختر الطالب/المندوب'),
            items: widget.students
                .map(
                  (student) => DropdownMenuItem(
                    value: _docInt(student['id']),
                    child: Text(
                      '${_docText(student['name'])} - ${_docText(student['student_number'])}',
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _studentId = value),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _studentId == null ? null : _delegate,
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('إضافة التفويض'),
          ),
          if (permissions.isNotEmpty) ...[
            const Divider(height: 24),
            ...permissions.map((permission) {
              final user = _docMap(permission['authorized_user']);
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(_docText(user['name'])),
                subtitle: Text(_docText(user['student_number'])),
                trailing: IconButton(
                  onPressed: () => _revoke(_docInt(user['id'])),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.danger,
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Future<void> _delegate() async {
    try {
      await ref.read(staffRepositoryProvider).post(
        '/doctor/grades/categories/${widget.category['id']}/delegate',
        {'authorized_user_id': _studentId},
      );
      widget.onChanged();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  Future<void> _revoke(int userId) async {
    try {
      await ref.read(staffRepositoryProvider).post(
        '/doctor/grades/categories/${widget.category['id']}/revoke',
        {'authorized_user_id': userId},
      );
      widget.onChanged();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }
}

class _GradeApprovalsTab extends ConsumerStatefulWidget {
  const _GradeApprovalsTab({required this.subjectId, required this.onChanged});

  final int subjectId;
  final VoidCallback onChanged;

  @override
  ConsumerState<_GradeApprovalsTab> createState() => _GradeApprovalsTabState();
}

class _GradeApprovalsTabState extends ConsumerState<_GradeApprovalsTab> {
  late Future<Map<String, dynamic>> _future = _fetch();
  final Set<int> _selected = {};

  Future<Map<String, dynamic>> _fetch() => ref
      .read(staffRepositoryProvider)
      .get('/doctor/grades/${widget.subjectId}/approvals');

  void _reload() => setState(() {
    _future = _fetch();
  });

  Future<void> _bulk(String action) async {
    if (_selected.isEmpty) return;
    try {
      await ref.read(staffRepositoryProvider).post(
        '/doctor/grades/approvals/bulk-action',
        {'grade_ids': _selected.toList(), 'action': action},
      );
      _selected.clear();
      _reload();
      widget.onChanged();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
        final data = _docMap(_docData(snapshot.data ?? const {}));
        final pending = _docList(data['pending_grades']);
        return ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _selected.isEmpty
                        ? null
                        : () => _bulk('approve'),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('اعتماد'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selected.isEmpty ? null : () => _bulk('reject'),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('رفض'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (pending.isEmpty)
              const _DocEmpty('لا توجد درجات معلقة.')
            else
              ...pending.map((grade) {
                final id = _docInt(grade['id']);
                final student = _docMap(grade['student']);
                final category = _docMap(grade['grade_category']);
                return CheckboxListTile(
                  value: _selected.contains(id),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selected.add(id);
                      } else {
                        _selected.remove(id);
                      }
                    });
                  },
                  title: Text(_docText(student['name'])),
                  subtitle: Text(
                    '${_docText(category['name'], 'درجة')} - ${_docText(grade['score'])}',
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}

// ignore: unused_element
class _GradeReportTab extends ConsumerWidget {
  const _GradeReportTab({required this.subjectId});

  final int subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ref
          .read(staffRepositoryProvider)
          .get('/doctor/grades/$subjectId/report'),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
        final data = _docMap(_docData(snapshot.data ?? const {}));
        final stats = _docMap(data['stats']);
        final students = _docList(data['students']);
        return ListView(
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _DocMetric(
                  label: 'المتوسط',
                  value: _docText(stats['average'], '0'),
                  color: AppColors.royalBlue,
                  icon: Icons.analytics_rounded,
                ),
                _DocMetric(
                  label: 'النجاح',
                  value: '${_docText(stats['pass_rate'], '0')}%',
                  color: AppColors.success,
                  icon: Icons.verified_rounded,
                ),
                _DocMetric(
                  label: 'الأعلى',
                  value: _docText(stats['highest'], '0'),
                  color: AppColors.warning,
                  icon: Icons.trending_up_rounded,
                ),
                _DocMetric(
                  label: 'الأدنى',
                  value: _docText(stats['lowest'], '0'),
                  color: AppColors.danger,
                  icon: Icons.trending_down_rounded,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...students.map(
              (student) => ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(_docText(student['name'])),
                subtitle: Text(_docText(student['student_number'])),
                trailing: Text(
                  _docText(student['total'], '0'),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GradeCategoriesTabV2 extends ConsumerStatefulWidget {
  const _GradeCategoriesTabV2({
    required this.subjectId,
    required this.categories,
    required this.continuousMaxScore,
    required this.onChanged,
  });

  final int subjectId;
  final List<_Json> categories;
  final num continuousMaxScore;
  final VoidCallback onChanged;

  @override
  ConsumerState<_GradeCategoriesTabV2> createState() =>
      _GradeCategoriesTabV2State();
}

class _GradeCategoriesTabV2State extends ConsumerState<_GradeCategoriesTabV2> {
  Future<void> _openForm({_Json? category}) async {
    final isEdit = category != null;
    final currentScore = isEdit ? _docNum(category['max_score']) : 0;
    final usedWithoutCurrent = widget.categories.fold<num>(0, (sum, item) {
      if (isEdit && _docInt(item['id']) == _docInt(category['id'])) {
        return sum;
      }
      return sum + _docNum(item['max_score']);
    });
    final allowedMax = (widget.continuousMaxScore - usedWithoutCurrent).clamp(
      0,
      widget.continuousMaxScore,
    );

    if (!isEdit && allowedMax <= 0) {
      await showMoeenInfoDialog(
        context: context,
        title: 'اكتمل توزيع أعمال السنة',
        message:
            'تم توزيع كامل درجات أعمال السنة. عدّل تصنيفًا موجودًا أولًا إذا أردت إعادة التوزيع.',
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: _docText(category?['name']));
    final score = TextEditingController(
      text: category == null ? '' : _docText(category['max_score']),
    );

    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: isEdit ? 'تعديل التصنيف' : 'تصنيف جديد',
      icon: Icons.category_rounded,
      color: AppColors.royalBlue,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.royalBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.royalBlue.withValues(alpha: 0.14),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.royalBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'المتاح لهذا التصنيف: ${_gradeLimitLabel(allowedMax)} درجة',
                      style: const TextStyle(
                        color: AppColors.midnight,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: name,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'اسم التصنيف مطلوب';
                }
                return null;
              },
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.midnight,
              ),
              decoration: InputDecoration(
                labelText: 'اسم التصنيف',
                labelStyle: const TextStyle(
                  color: AppColors.slate500,
                  fontWeight: FontWeight.w600,
                ),
                prefixIcon: const Icon(
                  Icons.label_important_outline_rounded,
                  color: AppColors.royalBlue,
                ),
                filled: true,
                fillColor: AppColors.slate50,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.slate200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.royalBlue,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: score,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                final parsed = num.tryParse(
                  (value ?? '').trim().replaceAll(',', '.'),
                );
                if (parsed == null) return 'أدخل درجة صحيحة';
                if (parsed <= 0) return 'الدرجة يجب أن تكون أكبر من صفر';
                if (parsed > allowedMax) {
                  return 'أكبر من المتاح: ${_gradeLimitLabel(allowedMax)}';
                }
                return null;
              },
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.midnight,
              ),
              decoration: InputDecoration(
                labelText: 'الدرجة العظمى',
                helperText: isEdit && currentScore > 0
                    ? 'درجة التصنيف الحالية ${_gradeLimitLabel(currentScore)}'
                    : null,
                labelStyle: const TextStyle(
                  color: AppColors.slate500,
                  fontWeight: FontWeight.w600,
                ),
                prefixIcon: const Icon(
                  Icons.score_outlined,
                  color: AppColors.royalBlue,
                ),
                filled: true,
                fillColor: AppColors.slate50,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.slate200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.royalBlue,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() != true) return;
                  Navigator.pop(context, true);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.royalBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isEdit ? 'حفظ التعديل' : 'إضافة التصنيف',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      final payload = {
        'name': name.text.trim(),
        'max_score': num.tryParse(score.text.trim().replaceAll(',', '.')),
      };
      if (isEdit) {
        await ref
            .read(staffRepositoryProvider)
            .put('/doctor/grades/categories/${category['id']}', payload);
      } else {
        await ref
            .read(staffRepositoryProvider)
            .post('/doctor/grades/${widget.subjectId}/categories', payload);
      }
      widget.onChanged();
    } catch (error) {
      if (!mounted) return;
      final invalidStudents = _invalidStudentsFrom(error);
      if (invalidStudents.isNotEmpty) {
        await _showInvalidStudents(invalidStudents);
      } else {
        await _docErrorDialog(context, error);
      }
    }
  }

  List<_Json> _invalidStudentsFrom(Object error) {
    if (error is! ApiException) return const [];
    final errors = error.errors;
    if (errors is Map) return _docList(errors['invalid_students']);
    return const [];
  }

  Future<void> _showInvalidStudents(List<_Json> students) async {
    await showMoeenBottomSheet<void>(
      context: context,
      title: 'درجات تحتاج تعديلًا أولًا',
      icon: Icons.warning_amber_rounded,
      color: AppColors.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'لا يمكن تخفيض الدرجة العظمى لأن الطلاب التاليين لديهم درجات أعلى من الحد الجديد.',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ...students.map(
            (student) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _docText(student['name']),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  Text(
                    _docText(student['score']),
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(_Json category) async {
    final ok = await showMoeenConfirmDialog(
      context: context,
      title: 'حذف التصنيف',
      message: 'هل تريد حذف هذا التصنيف؟',
      confirmLabel: 'حذف',
      color: AppColors.danger,
      icon: Icons.delete_rounded,
    );
    if (!ok) return;
    try {
      await ref
          .read(staffRepositoryProvider)
          .delete('/doctor/grades/categories/${category['id']}');
      widget.onChanged();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.categories.fold<num>(
      0,
      (sum, item) => sum + _docNum(item['max_score']),
    );
    final continuousMaxScore = widget.continuousMaxScore;
    final remaining = (continuousMaxScore - total).clamp(0, continuousMaxScore);
    final progress = continuousMaxScore > 0
        ? (total / continuousMaxScore).clamp(0, 1).toDouble()
        : 0.0;
    final isOverLimit = total > continuousMaxScore;
    final canAddCategory = remaining > 0 && !isOverLimit;
    final accent = isOverLimit ? AppColors.danger : AppColors.royalBlue;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isOverLimit
                  ? AppColors.danger.withValues(alpha: 0.3)
                  : AppColors.slate200,
              width: isOverLimit ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: (isOverLimit ? AppColors.danger : AppColors.royalBlue)
                    .withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.pie_chart_rounded,
                      color: accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'توزيع أعمال السنة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.midnight,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isOverLimit
                              ? 'تنبيه: تجاوزت الحد الأقصى لأعمال السنة'
                              : 'توزيع الدرجات على تصنيفات المادة',
                          style: TextStyle(
                            fontSize: 12,
                            color: isOverLimit
                                ? AppColors.danger
                                : AppColors.slate500,
                            fontWeight: isOverLimit
                                ? FontWeight.w800
                                : FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: canAddCategory ? () => _openForm() : null,
                    icon: Icon(
                      canAddCategory
                          ? Icons.add_rounded
                          : Icons.check_circle_rounded,
                      size: 18,
                    ),
                    label: Text(
                      canAddCategory ? 'إضافة' : 'اكتمل',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.royalBlue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  minHeight: 12,
                  value: progress,
                  color: accent,
                  backgroundColor: AppColors.slate100,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.slate50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.slate100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'الموزع الفعلي',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.slate500,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_gradeLimitLabel(total)} من ${_gradeLimitLabel(continuousMaxScore)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: accent,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.slate50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.slate100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'المتبقي للتوزيع',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.slate500,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _gradeLimitLabel(remaining),
                            style: TextStyle(
                              fontSize: 14,
                              color: isOverLimit
                                  ? AppColors.danger
                                  : AppColors.success,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (isOverLimit) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.danger,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'إجمالي التصنيفات تجاوز الحد المسموح لأعمال السنة.',
                          style: TextStyle(
                            color: AppColors.danger,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
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
        const SizedBox(height: 12),
        if (widget.categories.isEmpty)
          const _DocEmpty('لا توجد تصنيفات بعد.')
        else
          ...widget.categories.map(
            (category) => _GradeCategoryWorkCardV2(
              category: category,
              continuousMaxScore: continuousMaxScore,
              onEdit: () => _openForm(category: category),
              onDelete: () => _delete(category),
            ),
          ),
      ],
    );
  }
}

class _GradeCategoryWorkCardV2 extends StatelessWidget {
  const _GradeCategoryWorkCardV2({
    required this.category,
    required this.continuousMaxScore,
    required this.onEdit,
    required this.onDelete,
  });

  final _Json category;
  final num continuousMaxScore;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final maxScore = _docNum(category['max_score']);
    final ratio = continuousMaxScore > 0
        ? (maxScore / continuousMaxScore).clamp(0, 1).toDouble()
        : 0.0;
    final gradesCount = _docInt(category['grades_count']);
    final name = _docText(category['name']);

    IconData categoryIcon = Icons.category_rounded;
    Color accentColor = AppColors.royalBlue;

    if (name.contains('اختبار') ||
        name.contains('امتحان') ||
        name.toLowerCase().contains('quiz') ||
        name.toLowerCase().contains('exam')) {
      categoryIcon = Icons.quiz_rounded;
      accentColor = AppColors.warning;
    } else if (name.contains('واجب') ||
        name.contains('عملي') ||
        name.toLowerCase().contains('assignment') ||
        name.toLowerCase().contains('project') ||
        name.contains('مشروع')) {
      categoryIcon = Icons.assignment_rounded;
      accentColor = AppColors.success;
    } else if (name.contains('حضور') ||
        name.contains('مشاركة') ||
        name.toLowerCase().contains('attendance') ||
        name.contains('تفاعل')) {
      categoryIcon = Icons.co_present_rounded;
      accentColor = AppColors.info;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(categoryIcon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.midnight,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _DocPill('$maxScore درجة', accentColor),
                        _DocPill('$gradesCount رصد', AppColors.royalBlue),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.slate50,
                  foregroundColor: AppColors.slate700,
                  padding: const EdgeInsets.all(8),
                  minimumSize: const Size(36, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_rounded, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.danger.withValues(alpha: 0.08),
                  foregroundColor: AppColors.danger,
                  padding: const EdgeInsets.all(8),
                  minimumSize: const Size(36, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: ratio,
                    color: accentColor,
                    backgroundColor: AppColors.slate100,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(ratio * 100).round()}%',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GradeSettingsTab extends ConsumerStatefulWidget {
  const _GradeSettingsTab({
    required this.subjectId,
    required this.settings,
    required this.onChanged,
  });

  final int subjectId;
  final _Json settings;
  final VoidCallback onChanged;

  @override
  ConsumerState<_GradeSettingsTab> createState() => _GradeSettingsTabState();
}

class _GradeSettingsTabState extends ConsumerState<_GradeSettingsTab> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _total;
  late final TextEditingController _continuous;
  late final TextEditingController _final;
  late final TextEditingController _passing;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _total = TextEditingController(
      text: _gradeLimitLabel(_docNum(widget.settings['total_max_score'], 100)),
    );
    _continuous = TextEditingController(
      text: _gradeLimitLabel(
        _docNum(widget.settings['continuous_max_score'], 40),
      ),
    );
    _final = TextEditingController(
      text: _gradeLimitLabel(_docNum(widget.settings['final_max_score'], 60)),
    );
    _passing = TextEditingController(
      text: _gradeLimitLabel(_docNum(widget.settings['passing_score'], 50)),
    );
  }

  @override
  void dispose() {
    _total.dispose();
    _continuous.dispose();
    _final.dispose();
    _passing.dispose();
    super.dispose();
  }

  num? _parse(TextEditingController controller) {
    return num.tryParse(controller.text.trim().replaceAll(',', '.'));
  }

  String? _numberValidator(String? value) {
    final parsed = num.tryParse((value ?? '').trim().replaceAll(',', '.'));
    if (parsed == null) return 'أدخل رقمًا صحيحًا';
    if (parsed < 0) return 'لا يقبل قيمة أقل من صفر';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final total = _parse(_total) ?? 0;
    final continuous = _parse(_continuous) ?? 0;
    final finalScore = _parse(_final) ?? 0;
    final passing = _parse(_passing) ?? 0;

    if ((continuous + finalScore - total).abs() > 0.01) {
      await showMoeenInfoDialog(
        context: context,
        title: 'إعدادات غير صحيحة',
        message:
            'مجموع أعمال السنة والاختبار النهائي يجب أن يساوي الدرجة النهائية.',
        icon: Icons.warning_amber_rounded,
        color: AppColors.warning,
      );
      return;
    }
    if (passing > total) {
      await showMoeenInfoDialog(
        context: context,
        title: 'إعدادات غير صحيحة',
        message: 'درجة النجاح لا يمكن أن تتجاوز الدرجة النهائية.',
        icon: Icons.warning_amber_rounded,
        color: AppColors.warning,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(staffRepositoryProvider)
          .put('/doctor/grades/${widget.subjectId}/settings', {
            'total_max_score': total,
            'continuous_max_score': continuous,
            'final_max_score': finalScore,
            'passing_score': passing,
          });
      if (!mounted) return;
      widget.onChanged();
      await showMoeenInfoDialog(
        context: context,
        title: 'تم حفظ الإعدادات',
        message: 'تم تحديث إعدادات درجات المادة بنجاح.',
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
      );
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom + 28,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.slate200),
            boxShadow: [
              BoxShadow(
                color: AppColors.royalBlue.withValues(alpha: 0.03),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
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
                        Icons.tune_rounded,
                        color: AppColors.royalBlue,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إعدادات الدرجات',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              color: AppColors.midnight,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'اضبط توزيع المادة ودرجة النجاح حسب نظام الكلية.',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              color: AppColors.slate500,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _GradeSettingsField(
                  controller: _total,
                  label: 'الدرجة النهائية',
                  icon: Icons.functions_rounded,
                  validator: _numberValidator,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _GradeSettingsField(
                        controller: _continuous,
                        label: 'أعمال السنة',
                        icon: Icons.category_rounded,
                        validator: _numberValidator,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _GradeSettingsField(
                        controller: _final,
                        label: 'الاختبار النهائي',
                        icon: Icons.school_rounded,
                        validator: _numberValidator,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _GradeSettingsField(
                  controller: _passing,
                  label: 'درجة النجاح',
                  icon: Icons.verified_rounded,
                  validator: _numberValidator,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.16),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.warning,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'عند تقليل الحدود، لن يتم الحفظ إذا كانت هناك درجات طلاب أو تصنيفات تتجاوز الحدود الجديدة.',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: AppColors.slate700,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.royalBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
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
                      : const Icon(Icons.save_rounded, size: 20),
                  label: Text(_saving ? 'جاري الحفظ...' : 'حفظ الإعدادات'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GradeSettingsField extends StatelessWidget {
  const _GradeSettingsField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: validator,
      scrollPadding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom + 190,
      ),
      style: const TextStyle(
        fontFamily: 'Cairo',
        color: AppColors.midnight,
        fontWeight: FontWeight.w800,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: 'Cairo',
          color: AppColors.slate500,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        floatingLabelStyle: const TextStyle(
          fontFamily: 'Cairo',
          color: AppColors.royalBlue,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, size: 19, color: AppColors.slate500),
        suffixText: 'درجة',
        suffixStyle: const TextStyle(
          fontFamily: 'Cairo',
          color: AppColors.slate400,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
        filled: true,
        fillColor: AppColors.slate50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.slate200, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.royalBlue, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.8),
        ),
        errorStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _GradeDelegationsTabV2 extends ConsumerStatefulWidget {
  const _GradeDelegationsTabV2({required this.subjectId});

  final int subjectId;

  @override
  ConsumerState<_GradeDelegationsTabV2> createState() =>
      _GradeDelegationsTabV2State();
}

class _GradeDelegationsTabV2State
    extends ConsumerState<_GradeDelegationsTabV2> {
  late Future<Map<String, dynamic>> _future = _fetch();
  int? _selectedCategoryId;
  String _search = '';

  Future<Map<String, dynamic>> _fetch() => ref
      .read(staffRepositoryProvider)
      .get('/doctor/grades/${widget.subjectId}/delegations');

  void _reload() => setState(() {
    _future = _fetch();
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
        final data = _docMap(_docData(snapshot.data ?? const {}));
        final categories = _docList(data['categories']);
        final students = _docList(data['students']);
        if (categories.isEmpty) {
          return const _DocEmpty('أنشئ تصنيفات الدرجات قبل التفويض.');
        }
        final selectedId =
            categories.any(
              (category) => _docInt(category['id']) == _selectedCategoryId,
            )
            ? _selectedCategoryId!
            : _docInt(categories.first['id']);
        final selectedCategory = categories.firstWhere(
          (category) => _docInt(category['id']) == selectedId,
          orElse: () => categories.first,
        );
        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.slate200),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.royalBlue.withValues(alpha: 0.03),
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
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.royalBlue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.vpn_key_rounded,
                          color: AppColors.royalBlue,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'اختر التصنيف لإدارة وتفويض الصلاحيات:',
                          style: TextStyle(
                            color: AppColors.midnight,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((category) {
                        final id = _docInt(category['id']);
                        final isSelected = id == selectedId;
                        return Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: ChoiceChip(
                            selected: isSelected,
                            label: Text(
                              _docText(category['name']),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.slate700,
                              ),
                            ),
                            selectedColor: AppColors.royalBlue,
                            backgroundColor: AppColors.slate50,
                            elevation: 0,
                            pressElevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.royalBlue
                                    : AppColors.slate200,
                              ),
                            ),
                            onSelected: (_) =>
                                setState(() => _selectedCategoryId = id),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _DelegationCategoryCardV2(
              category: selectedCategory,
              students: students,
              search: _search,
              onSearchChanged: (value) => setState(() => _search = value),
              onChanged: _reload,
            ),
          ],
        );
      },
    );
  }
}

class _DelegationCategoryCardV2 extends ConsumerStatefulWidget {
  const _DelegationCategoryCardV2({
    required this.category,
    required this.students,
    required this.search,
    required this.onSearchChanged,
    required this.onChanged,
  });

  final _Json category;
  final List<_Json> students;
  final String search;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onChanged;

  @override
  ConsumerState<_DelegationCategoryCardV2> createState() =>
      _DelegationCategoryCardV2State();
}

class _DelegationCategoryCardV2State
    extends ConsumerState<_DelegationCategoryCardV2> {
  @override
  Widget build(BuildContext context) {
    final permissions = _docList(widget.category['permissions']);
    final delegatedIds = permissions
        .map(
          (permission) => _docInt(_docMap(permission['authorized_user'])['id']),
        )
        .toSet();
    final query = widget.search.trim().toLowerCase();
    final candidates = widget.students.where((student) {
      final id = _docInt(student['id']);
      if (delegatedIds.contains(id)) return false;
      if (query.isEmpty) return true;
      final haystack =
          '${_docText(student['name'])} ${_docText(student['student_number'])} ${_docText(student['role'])}'
              .toLowerCase();
      return haystack.contains(query);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.04),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _docText(widget.category['name']),
                      style: const TextStyle(
                        color: AppColors.midnight,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      permissions.isEmpty
                          ? 'لا يوجد مفوضون حاليًا'
                          : '${permissions.length} مفوض حاليًا لإدخال درجات هذا التصنيف',
                      style: TextStyle(
                        color: permissions.isEmpty
                            ? AppColors.slate500
                            : AppColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              _DocPill(
                '${_docText(widget.category['max_score'])} درجة',
                AppColors.royalBlue,
              ),
            ],
          ),
          if (permissions.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text(
              'المفوضون الحاليون',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: AppColors.midnight,
              ),
            ),
            const SizedBox(height: 8),
            ...permissions.map((permission) {
              final user = _docMap(permission['authorized_user']);
              return _DelegateUserCardV2(
                user: user,
                onRevoke: () => _revoke(_docInt(user['id'])),
              );
            }),
          ],
          const SizedBox(height: 12),
          const Divider(height: 24, color: AppColors.slate200),
          const SizedBox(height: 8),
          const Text(
            'تفويض مستخدم جديد',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.midnight,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            onChanged: widget.onSearchChanged,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.midnight,
            ),
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.royalBlue,
              ),
              labelText: 'بحث بالاسم أو رقم القيد للتفويض...',
              labelStyle: const TextStyle(
                color: AppColors.slate500,
                fontWeight: FontWeight.w600,
              ),
              filled: true,
              fillColor: AppColors.slate50,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.slate200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.royalBlue,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (candidates.isEmpty)
            const _DocEmpty('لا يوجد مرشحون متاحون لهذا التصنيف.')
          else
            ...candidates
                .take(20)
                .map(
                  (student) => _CandidateDelegateCardV2(
                    user: student,
                    onDelegate: () => _delegateStudent(
                      _docInt(student['id']),
                      _docText(student['name']),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Future<void> _delegateStudent(int userId, String name) async {
    final ok = await showMoeenConfirmDialog(
      context: context,
      title: 'تأكيد التفويض',
      message: 'هل تريد تفويض المستخدم "$name" لإدخال درجات هذا التصنيف؟',
      confirmLabel: 'تفويض',
      color: AppColors.royalBlue,
      icon: Icons.person_add_rounded,
    );
    if (!ok) return;
    try {
      await ref.read(staffRepositoryProvider).post(
        '/doctor/grades/categories/${widget.category['id']}/delegate',
        {'authorized_user_id': userId},
      );
      widget.onChanged();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  Future<void> _revoke(int userId) async {
    final ok = await showMoeenConfirmDialog(
      context: context,
      title: 'سحب التفويض',
      message: 'هل تريد سحب التفويض من هذا المستخدم؟',
      confirmLabel: 'سحب التفويض',
      color: AppColors.danger,
      icon: Icons.person_remove_rounded,
    );
    if (!ok) return;
    try {
      await ref.read(staffRepositoryProvider).post(
        '/doctor/grades/categories/${widget.category['id']}/revoke',
        {'authorized_user_id': userId},
      );
      widget.onChanged();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }
}

class _DelegateUserCardV2 extends StatelessWidget {
  const _DelegateUserCardV2({required this.user, required this.onRevoke});

  final _Json user;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final name = _docText(user['name']);
    final role = _docText(user['role']);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildUserAvatar(name, role),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: AppColors.midnight,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _docText(user['student_number'], '-'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.slate500,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildRoleBadge(role),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRevoke,
            icon: const Icon(Icons.person_remove_rounded, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.danger.withValues(alpha: 0.08),
              foregroundColor: AppColors.danger,
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(36, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CandidateDelegateCardV2 extends StatelessWidget {
  const _CandidateDelegateCardV2({
    required this.user,
    required this.onDelegate,
  });

  final _Json user;
  final VoidCallback onDelegate;

  @override
  Widget build(BuildContext context) {
    final name = _docText(user['name']);
    final role = _docText(user['role']);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate500.withValues(alpha: 0.01),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildUserAvatar(name, role),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: AppColors.midnight,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _docText(user['student_number'], '-'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.slate500,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildRoleBadge(role),
                  ],
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: onDelegate,
            icon: const Icon(Icons.person_add_rounded, size: 16),
            label: const Text(
              'تفويض',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.royalBlue,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildUserAvatar(String name, String role) {
  final firstChar = name.trim().isNotEmpty ? name.trim().substring(0, 1) : '?';
  Color roleColor = AppColors.royalBlue;
  if (role == 'delegate') {
    roleColor = AppColors.warning;
  } else if (role == 'practical_delegate') {
    roleColor = AppColors.success;
  } else if (role == 'student') {
    roleColor = AppColors.info;
  }

  return Container(
    width: 38,
    height: 38,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [roleColor.withValues(alpha: 0.85), roleColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: roleColor.withValues(alpha: 0.15),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    alignment: Alignment.center,
    child: Text(
      firstChar,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

Widget _buildRoleBadge(Object? role) {
  final roleStr = _docText(role);
  Color badgeColor = AppColors.royalBlue;
  if (roleStr == 'delegate') {
    badgeColor = AppColors.warning;
  } else if (roleStr == 'practical_delegate') {
    badgeColor = AppColors.success;
  } else if (roleStr == 'student') {
    badgeColor = AppColors.info;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: badgeColor.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: badgeColor.withValues(alpha: 0.12)),
    ),
    child: Text(
      _doctorRoleLabelV2(roleStr),
      style: TextStyle(
        color: badgeColor,
        fontSize: 10,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

String _doctorRoleLabelV2(Object? role) {
  switch (_docText(role)) {
    case 'delegate':
      return 'مندوب';
    case 'practical_delegate':
      return 'مندوب عملي';
    case 'student':
      return 'طالب';
    default:
      return _docText(role, 'مستخدم');
  }
}

class _GradeApprovalsTabV2 extends ConsumerStatefulWidget {
  const _GradeApprovalsTabV2({
    required this.subjectId,
    required this.onChanged,
  });

  final int subjectId;
  final VoidCallback onChanged;

  @override
  ConsumerState<_GradeApprovalsTabV2> createState() =>
      _GradeApprovalsTabV2State();
}

class _GradeApprovalsTabV2State extends ConsumerState<_GradeApprovalsTabV2> {
  late Future<Map<String, dynamic>> _future = _fetch();
  final Set<int> _selected = {};
  String _search = '';
  String? _categoryFilter;
  String? _creatorFilter;

  Future<Map<String, dynamic>> _fetch() => ref
      .read(staffRepositoryProvider)
      .get('/doctor/grades/${widget.subjectId}/approvals');

  void _reload() => setState(() {
    _future = _fetch();
  });

  Future<void> _bulk(String action, {List<int>? ids}) async {
    final targetIds = ids ?? _selected.toList();
    if (targetIds.isEmpty) return;
    final ok = await showMoeenConfirmDialog(
      context: context,
      title: action == 'approve' ? 'اعتماد الدرجات' : 'رفض الدرجات',
      message: action == 'approve'
          ? 'سيتم اعتماد ${targetIds.length} درجة معلقة.'
          : 'سيتم رفض ${targetIds.length} درجة معلقة.',
      confirmLabel: action == 'approve' ? 'اعتماد' : 'رفض',
      color: action == 'approve' ? AppColors.success : AppColors.danger,
      icon: action == 'approve' ? Icons.verified_rounded : Icons.cancel_rounded,
    );
    if (!ok) return;
    try {
      await ref.read(staffRepositoryProvider).post(
        '/doctor/grades/approvals/bulk-action',
        {'grade_ids': targetIds, 'action': action},
      );
      _selected.clear();
      _reload();
      widget.onChanged();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  List<_Json> _filtered(List<_Json> pending) {
    final query = _search.trim().toLowerCase();
    return pending.where((grade) {
      final student = _docMap(grade['student']);
      final category = _docText(
        _docMap(grade['grade_category'])['name'],
        'درجة',
      );
      final creator = _docText(_docMap(grade['creator'])['name'], 'غير محدد');
      if (_categoryFilter != null && category != _categoryFilter) return false;
      if (_creatorFilter != null && creator != _creatorFilter) return false;
      if (query.isEmpty) return true;
      final haystack =
          '${_docText(student['name'])} ${_docText(student['student_number'])} $category $creator'
              .toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
        final data = _docMap(_docData(snapshot.data ?? const {}));
        final pending = _docList(data['pending_grades']);
        final filtered = _filtered(pending);
        final categories = pending
            .map(
              (grade) =>
                  _docText(_docMap(grade['grade_category'])['name'], 'درجة'),
            )
            .toSet()
            .toList();
        final creators = pending
            .map(
              (grade) =>
                  _docText(_docMap(grade['creator'])['name'], 'غير محدد'),
            )
            .toSet()
            .toList();
        return Stack(
          children: [
            ListView(
              padding: EdgeInsets.fromLTRB(
                0,
                16,
                0,
                _selected.isEmpty ? 24 : 100,
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.slate200),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.royalBlue.withValues(alpha: 0.03),
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
                          Expanded(
                            child: _GradeMiniStatV2(
                              label: 'المعلقة',
                              value: '${pending.length}',
                              color: AppColors.warning,
                              icon: Icons.pending_actions_rounded,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _GradeMiniStatV2(
                              label: 'المحدد',
                              value: '${_selected.length}',
                              color: AppColors.royalBlue,
                              icon: Icons.checklist_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        onChanged: (value) => setState(() => _search = value),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.midnight,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppColors.royalBlue,
                          ),
                          labelText: 'بحث باسم الطالب أو رقم القيد...',
                          labelStyle: const TextStyle(
                            color: AppColors.slate500,
                            fontWeight: FontWeight.w600,
                          ),
                          filled: true,
                          fillColor: AppColors.slate50,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.slate200,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.royalBlue,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'تصفية حسب التصنيف:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppColors.midnight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ChoiceChip(
                              selected: _categoryFilter == null,
                              label: Text(
                                'كل التصنيفات',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: _categoryFilter == null
                                      ? Colors.white
                                      : AppColors.slate700,
                                ),
                              ),
                              selectedColor: AppColors.royalBlue,
                              backgroundColor: AppColors.slate50,
                              elevation: 0,
                              pressElevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: _categoryFilter == null
                                      ? AppColors.royalBlue
                                      : AppColors.slate200,
                                ),
                              ),
                              onSelected: (_) =>
                                  setState(() => _categoryFilter = null),
                            ),
                            ...categories.map((category) {
                              final isSelected = _categoryFilter == category;
                              return Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  start: 6,
                                ),
                                child: ChoiceChip(
                                  selected: isSelected,
                                  label: Text(
                                    category,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.slate700,
                                    ),
                                  ),
                                  selectedColor: AppColors.royalBlue,
                                  backgroundColor: AppColors.slate50,
                                  elevation: 0,
                                  pressElevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: isSelected
                                          ? AppColors.royalBlue
                                          : AppColors.slate200,
                                    ),
                                  ),
                                  onSelected: (_) => setState(
                                    () => _categoryFilter = category,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      if (creators.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'تصفية حسب المدخل:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: AppColors.midnight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ChoiceChip(
                                selected: _creatorFilter == null,
                                label: Text(
                                  'كل المدخلين',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: _creatorFilter == null
                                        ? Colors.white
                                        : AppColors.slate700,
                                  ),
                                ),
                                selectedColor: AppColors.royalBlue,
                                backgroundColor: AppColors.slate50,
                                elevation: 0,
                                pressElevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: _creatorFilter == null
                                        ? AppColors.royalBlue
                                        : AppColors.slate200,
                                  ),
                                ),
                                onSelected: (_) =>
                                    setState(() => _creatorFilter = null),
                              ),
                              ...creators.map((creator) {
                                final isSelected = _creatorFilter == creator;
                                return Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    start: 6,
                                  ),
                                  child: ChoiceChip(
                                    selected: isSelected,
                                    label: Text(
                                      creator,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.slate700,
                                      ),
                                    ),
                                    selectedColor: AppColors.royalBlue,
                                    backgroundColor: AppColors.slate50,
                                    elevation: 0,
                                    pressElevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: isSelected
                                            ? AppColors.royalBlue
                                            : AppColors.slate200,
                                      ),
                                    ),
                                    onSelected: (_) => setState(
                                      () => _creatorFilter = creator,
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  const _DocEmpty('لا توجد درجات معلقة مطابقة للفلاتر.')
                else
                  ...filtered.map((grade) {
                    final id = _docInt(grade['id']);
                    return _ApprovalGradeCardV2(
                      grade: grade,
                      selected: _selected.contains(id),
                      onSelected: (value) {
                        setState(() {
                          if (value) {
                            _selected.add(id);
                          } else {
                            _selected.remove(id);
                          }
                        });
                      },
                      onApprove: () => _bulk('approve', ids: [id]),
                      onReject: () => _bulk('reject', ids: [id]),
                    );
                  }),
              ],
            ),
            if (_selected.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.slate200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _bulk('approve'),
                          icon: const Icon(Icons.verified_rounded, size: 18),
                          label: Text(
                            'اعتماد ${_selected.length}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _bulk('reject'),
                          icon: const Icon(Icons.cancel_rounded, size: 18),
                          label: const Text(
                            'رفض المحدد',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.danger.withValues(
                              alpha: 0.08,
                            ),
                            foregroundColor: AppColors.danger,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _GradeMiniStatV2 extends StatelessWidget {
  const _GradeMiniStatV2({
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.slate500,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.midnight,
                    fontSize: 18,
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
}

class _ApprovalGradeCardV2 extends StatelessWidget {
  const _ApprovalGradeCardV2({
    required this.grade,
    required this.selected,
    required this.onSelected,
    required this.onApprove,
    required this.onReject,
  });

  final _Json grade;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final student = _docMap(grade['student']);
    final category = _docMap(grade['grade_category']);
    final creator = _docMap(grade['creator']);
    final maxScore = _docText(grade['max_score'] ?? category['max_score'], '-');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.royalBlue.withValues(alpha: 0.04)
            : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: selected
              ? AppColors.royalBlue.withValues(alpha: 0.2)
              : AppColors.slate200,
          width: selected ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (selected ? AppColors.royalBlue : AppColors.slate500)
                .withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: selected,
                onChanged: (value) => onSelected(value == true),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _docText(student['name']),
                      style: const TextStyle(
                        color: AppColors.midnight,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _docText(student['student_number'], '-'),
                      style: const TextStyle(
                        color: AppColors.slate500,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.15),
                  ),
                ),
                child: Text(
                  '${_docText(grade['score'])} / $maxScore',
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _DocPill(
                _docText(category['name'], 'درجة'),
                AppColors.royalBlue,
                icon: Icons.category_rounded,
              ),
              _DocPill(
                _docText(creator['name'], 'غير محدد'),
                AppColors.slate500,
                icon: Icons.person_rounded,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  _docDate(grade['created_at']),
                  style: const TextStyle(
                    color: AppColors.slate400,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onReject,
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text(
                  'رفض',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  backgroundColor: AppColors.danger.withValues(alpha: 0.06),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: onApprove,
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text(
                  'اعتماد',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success.withValues(alpha: 0.08),
                  foregroundColor: AppColors.success,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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

class _GradeReportTabV2 extends ConsumerStatefulWidget {
  const _GradeReportTabV2({required this.subjectId});

  final int subjectId;

  @override
  ConsumerState<_GradeReportTabV2> createState() => _GradeReportTabV2State();
}

class _GradeReportTabV2State extends ConsumerState<_GradeReportTabV2> {
  late final Future<Map<String, dynamic>> _future = _fetch();
  String _search = '';
  bool _printing = false;

  Future<Map<String, dynamic>> _fetch() => ref
      .read(staffRepositoryProvider)
      .get('/doctor/grades/${widget.subjectId}/report');

  Future<void> _downloadPdf() async {
    if (_printing) return;
    setState(() => _printing = true);
    try {
      final bytes = await ref
          .read(staffRepositoryProvider)
          .download('/doctor/grades/${widget.subjectId}/report/pdf');
      final result = await DownloadService.saveBytes(
        bytes: bytes,
        fileName: 'grade_report_${widget.subjectId}.pdf',
        section: 'GradeReports',
      );
      if (!mounted) return;
      await showMoeenInfoDialog(
        context: context,
        title: 'تم تجهيز التقرير',
        message: 'تم حفظ تقرير الدرجات في:\n${result.path}',
        icon: Icons.picture_as_pdf_rounded,
        color: AppColors.success,
      );
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
        final data = _docMap(_docData(snapshot.data ?? const {}));
        final stats = _docMap(data['stats']);
        final allStudents = _docList(data['students']);
        final query = _search.trim().toLowerCase();
        final students = allStudents.where((student) {
          if (query.isEmpty) return true;
          final haystack =
              '${_docText(student['name'])} ${_docText(student['student_number'])}'
                  .toLowerCase();
          return haystack.contains(query);
        }).toList();
        final distribution = _docMap(stats['distribution']);
        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: _GradeMiniStatV2(
                    label: 'الطلاب',
                    value: _docText(
                      stats['students_count'] ?? stats['total_students'],
                      '0',
                    ),
                    color: AppColors.royalBlue,
                    icon: Icons.groups_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _GradeMiniStatV2(
                    label: 'المتوسط',
                    value: _docText(stats['average'], '0'),
                    color: AppColors.success,
                    icon: Icons.analytics_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _GradeMiniStatV2(
                    label: 'الأعلى',
                    value: _docText(stats['highest'], '0'),
                    color: AppColors.warning,
                    icon: Icons.trending_up_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _GradeMiniStatV2(
                    label: 'النجاح',
                    value: '${_docText(stats['pass_rate'], '0')}%',
                    color: AppColors.success,
                    icon: Icons.verified_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.slate200),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.royalBlue.withValues(alpha: 0.03),
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
                      const Expanded(
                        child: Text(
                          'توزيع النتائج',
                          style: TextStyle(
                            color: AppColors.midnight,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _printing ? null : _downloadPdf,
                        icon: _printing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.print_rounded, size: 18),
                        label: const Text(
                          'طباعة التقرير',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.royalBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _GradeDistributionBarV2(
                    distribution: distribution,
                    total: _docInt(stats['graded']),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              onChanged: (value) => setState(() => _search = value),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.midnight,
              ),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.royalBlue),
                labelText: 'بحث بالاسم أو رقم القيد في التقرير...',
                labelStyle: const TextStyle(
                  color: AppColors.slate500,
                  fontWeight: FontWeight.w600,
                ),
                filled: true,
                fillColor: AppColors.slate50,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.slate200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.royalBlue, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            if (students.isEmpty)
              const _DocEmpty('لا توجد نتائج مطابقة للبحث.')
            else
              ...students.map(
                (student) => _ReportStudentCardV2(student: student),
              ),
          ],
        );
      },
    );
  }
}

class _GradeDistributionBarV2 extends StatelessWidget {
  const _GradeDistributionBarV2({
    required this.distribution,
    required this.total,
  });

  final _Json distribution;
  final int total;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('ممتاز', _docInt(distribution['excellent']), AppColors.success),
      ('جيد جدًا', _docInt(distribution['very_good']), AppColors.royalBlue),
      ('جيد', _docInt(distribution['good']), AppColors.warning),
      ('مقبول', _docInt(distribution['pass']), AppColors.goldDeep),
      ('راسب', _docInt(distribution['fail']), AppColors.danger),
    ];
    return Column(
      children: items.map((item) {
        final ratio = total == 0
            ? 0.0
            : (item.$2 / total).clamp(0, 1).toDouble();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 58,
                child: Text(
                  item.$1,
                  style: const TextStyle(
                    color: AppColors.slate600,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: ratio,
                    color: item.$3,
                    backgroundColor: AppColors.slate100,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 26,
                child: Text(
                  '${item.$2}',
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ReportStudentCardV2 extends StatelessWidget {
  const _ReportStudentCardV2({required this.student});

  final _Json student;

  @override
  Widget build(BuildContext context) {
    final name = _docText(student['name']);
    final passed = _docText(student['status']) == 'passed';
    final rankText = _docText(student['rank'], '-');
    final rankInt = int.tryParse(rankText) ?? 999;

    Color rankBgColor = AppColors.royalBlue.withValues(alpha: 0.08);
    Color rankTextColor = AppColors.royalBlue;

    if (rankInt == 1) {
      rankBgColor = const Color(0xFFFFD700).withValues(alpha: 0.12);
      rankTextColor = const Color(0xFFD4AF37); // Gold
    } else if (rankInt == 2) {
      rankBgColor = const Color(0xFFC0C0C0).withValues(alpha: 0.12);
      rankTextColor = const Color(0xFF8C8C8C); // Silver
    } else if (rankInt == 3) {
      rankBgColor = const Color(0xFFCD7F32).withValues(alpha: 0.12);
      rankTextColor = const Color(0xFFB06D28); // Bronze
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: (passed ? AppColors.success : AppColors.danger)
                .withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rankBgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '#$rankText',
              style: TextStyle(
                color: rankTextColor,
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
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: AppColors.midnight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_docText(student['student_number'], '-')} • أعمال السنة ${_docText(student['continuous'], '0')} • النهائي ${_docText(student['final'], '-')}',
                  style: const TextStyle(
                    color: AppColors.slate500,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _docText(student['total'], '0'),
                style: const TextStyle(
                  color: AppColors.midnight,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              _DocPill(
                _docText(student['grade_label'], passed ? 'ناجح' : 'راسب'),
                passed ? AppColors.success : AppColors.danger,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
