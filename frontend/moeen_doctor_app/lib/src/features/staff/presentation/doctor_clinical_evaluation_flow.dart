part of 'staff_screens.dart';

class _ClinicalEvaluationForm extends ConsumerStatefulWidget {
  const _ClinicalEvaluationForm({required this.data, required this.onSubmit});

  final _Json data;
  final Future<void> Function(Map<String, dynamic> payload) onSubmit;

  @override
  ConsumerState<_ClinicalEvaluationForm> createState() =>
      _ClinicalEvaluationFormState();
}

class _ClinicalEvaluationFormState
    extends ConsumerState<_ClinicalEvaluationForm> {
  final _search = TextEditingController();
  final _feedback = TextEditingController();
  final _customTimerMinutes = TextEditingController();
  final Map<int, String> _scores = {};
  final Map<int, TextEditingController> _notes = {};
  final Set<int> _expandedNotes = {};
  double _fontSizeScale = 1.0;

  Timer? _searchDebounce;
  Timer? _ticker;
  int _step = 0;
  int? _studentId;
  int? _majorId;
  int? _levelId;
  int? _checklistId;
  int? _bodySystemId;
  int? _caseId;
  String _timerType = 'fixed';
  DateTime? _startedAt;
  int? _finishedElapsedSeconds;
  DateTime _now = DateTime.now();
  bool _lockedByTimeLimit = false;
  bool _loadingStudents = false;
  bool _saving = false;
  List<_Json> _students = const [];
  _Json? _checklistDetails;
  List<_Json> _itemsTree = const [];

  @override
  void initState() {
    super.initState();
    _students = _docList(widget.data['students']);
    _search.addListener(_queueStudentSearch);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _search.dispose();
    _feedback.dispose();
    _customTimerMinutes.dispose();
    _ticker?.cancel();
    for (final controller in _notes.values) {
      controller.dispose();
    }
    super.dispose();
  }

  _Json? get _selectedStudent => _students
      .where((item) => _docInt(item['id']) == _studentId)
      .cast<_Json?>()
      .firstWhere((item) => item != null, orElse: () => null);

  _Json? get _selectedChecklist {
    final details = _checklistDetails;
    if (details != null) return details;
    return _docList(widget.data['checklists'])
        .where((item) => _docInt(item['id']) == _checklistId)
        .cast<_Json?>()
        .firstWhere((item) => item != null, orElse: () => null);
  }

  List<_Json> get _scoreableItems {
    final leaves = <_Json>[];
    for (final parent in _itemsTree) {
      final subs = _docList(parent['sub_items']);
      if (subs.isEmpty) {
        leaves.add(parent);
      } else {
        leaves.addAll(subs);
      }
    }
    if (leaves.isNotEmpty) return leaves;
    return _docList(_selectedChecklist?['items']);
  }

  int get _evaluatedCount => _scoreableItems
      .where((item) => _scores.containsKey(_docInt(item['id'])))
      .length;

  int get _totalMarks =>
      _scoreableItems.fold<int>(0, (sum, item) => sum + _docInt(item['marks']));

  int get _obtainedMarks {
    var sum = 0;
    for (final item in _scoreableItems) {
      final id = _docInt(item['id']);
      final value = _scores[id] ?? 'not_done';
      final marks = _docInt(item['marks']);
      if (value == 'done') sum += marks;
      if (value == 'partial') sum += (marks / 2).round();
    }
    return sum;
  }

  int get _officialLimitSeconds {
    final minutes = _docInt(_selectedChecklist?['time_limit_minutes']);
    return minutes > 0 ? minutes * 60 : 0;
  }

  int? get _activeLimitSeconds {
    if (_timerType == 'open') return null;
    if (_timerType == 'custom') {
      final minutes = int.tryParse(_customTimerMinutes.text.trim()) ?? 0;
      return minutes > 0 ? minutes * 60 : null;
    }
    return _officialLimitSeconds > 0 ? _officialLimitSeconds : null;
  }

  int get _elapsedSeconds {
    final finished = _finishedElapsedSeconds;
    if (finished != null) return finished;
    final startedAt = _startedAt;
    if (startedAt == null) return 0;
    return _now.difference(startedAt).inSeconds.clamp(0, 1 << 31);
  }

  int? get _remainingSeconds {
    final limit = _activeLimitSeconds;
    if (limit == null) return null;
    return limit - _elapsedSeconds;
  }

  String get _timerSummary {
    final limit = _activeLimitSeconds;
    if (_timerType == 'open' || limit == null) return 'وقت مفتوح';
    final label = _timerType == 'custom' ? 'وقت مخصص' : 'المؤقت الرسمي';
    return '$label: ${_formatDuration(limit)}';
  }

  bool get _canStartEvaluation {
    if (_checklistId == null || _itemsTree.isEmpty) return false;
    if (_timerType == 'custom') {
      final minutes = int.tryParse(_customTimerMinutes.text.trim()) ?? 0;
      return minutes > 0;
    }
    return true;
  }

  void _ensureTicker() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _startedAt == null) return;
      final limit = _activeLimitSeconds;
      final now = DateTime.now();
      final elapsed = now.difference(_startedAt!).inSeconds.clamp(0, 1 << 31);
      if (limit != null && elapsed >= limit) {
        _finishEvaluationByTimeLimit();
        return;
      }
      setState(() => _now = now);
    });
  }

  void _freezeTimerForReview({bool lockedByTimeLimit = false}) {
    final limit = _activeLimitSeconds;
    _finishedElapsedSeconds ??= lockedByTimeLimit && limit != null
        ? limit
        : _elapsedSeconds;
    _lockedByTimeLimit = _lockedByTimeLimit || lockedByTimeLimit;
    _ticker?.cancel();
    _ticker = null;
  }

  void _resumeTimerFromReview() {
    if (_lockedByTimeLimit) return;
    final frozen = _finishedElapsedSeconds;
    if (frozen != null) {
      _startedAt = DateTime.now().subtract(Duration(seconds: frozen));
      _finishedElapsedSeconds = null;
      _now = DateTime.now();
    }
    _ensureTicker();
  }

  void _finishEvaluationByTimeLimit() {
    if (_lockedByTimeLimit) return;
    _ticker?.cancel();
    _ticker = null;
    if (!mounted) return;
    setState(() {
      _now = DateTime.now();
      _freezeTimerForReview(lockedByTimeLimit: true);
      _step = 4;
    });
  }

  void _clearItemNotes() {
    for (final controller in _notes.values) {
      controller.dispose();
    }
    _notes.clear();
    _expandedNotes.clear();
  }

  void _queueStudentSearch() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _loadStudents);
  }

  Future<void> _loadStudents() async {
    if (!mounted) return;
    setState(() => _loadingStudents = true);
    try {
      final response = await ref
          .read(staffRepositoryProvider)
          .get(
            '/doctor/clinical/evaluations/students',
            query: {
              'per_page': 50,
              if (_search.text.trim().isNotEmpty) 'search': _search.text.trim(),
              if (_majorId != null) 'major_id': _majorId,
              if (_levelId != null) 'level_id': _levelId,
            },
          );
      final data = _docMap(_docData(response));
      if (!mounted) return;
      setState(() => _students = _docList(data['students']));
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    } finally {
      if (mounted) setState(() => _loadingStudents = false);
    }
  }

  Future<void> _selectChecklist(int id) async {
    setState(() {
      _checklistId = id;
      _checklistDetails = null;
      _itemsTree = const [];
      _scores.clear();
      _clearItemNotes();
      _timerType = 'fixed';
      _customTimerMinutes.clear();
      _startedAt = null;
      _now = DateTime.now();
      _finishedElapsedSeconds = null;
      _lockedByTimeLimit = false;
      _ticker?.cancel();
      _ticker = null;
    });
    try {
      final response = await ref
          .read(staffRepositoryProvider)
          .get('/doctor/clinical/evaluations/checklists/$id/take');
      final data = _docMap(_docData(response));
      if (!mounted) return;
      setState(() {
        _checklistDetails = _docMap(data['checklist']);
        _itemsTree = _docList(data['items_tree']);
        if (_officialLimitSeconds <= 0) {
          _timerType = 'open';
        }
      });
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  IconData _getAdaptiveIcon(String text) {
    final t = text.toLowerCase();
    if (t.contains('غسل') ||
        t.contains('تعقيم') ||
        t.contains('يد') ||
        t.contains('wash') ||
        t.contains('sanitize') ||
        t.contains('hand')) {
      return Icons.clean_hands_rounded;
    }
    if (t.contains('سماع') ||
        t.contains('فحص') ||
        t.contains('صدر') ||
        t.contains('قلب') ||
        t.contains('سماعة') ||
        t.contains('stethoscope') ||
        t.contains('examine') ||
        t.contains('heart') ||
        t.contains('chest')) {
      return Icons.hearing_rounded;
    }
    if (t.contains('تحدث') ||
        t.contains('شرح') ||
        t.contains('سؤال') ||
        t.contains('تواصل') ||
        t.contains('مريض') ||
        t.contains('explain') ||
        t.contains('ask') ||
        t.contains('communicate')) {
      return Icons.forum_rounded;
    }
    if (t.contains('كتابة') ||
        t.contains('تسجيل') ||
        t.contains('ملاحظة') ||
        t.contains('ملف') ||
        t.contains('تقرير') ||
        t.contains('write') ||
        t.contains('record') ||
        t.contains('note') ||
        t.contains('file')) {
      return Icons.rate_review_rounded;
    }
    if (t.contains('إبرة') ||
        t.contains('حقن') ||
        t.contains('سحب') ||
        t.contains('دم') ||
        t.contains('عينة') ||
        t.contains('needle') ||
        t.contains('injection') ||
        t.contains('blood')) {
      return Icons.vaccines_rounded;
    }
    if (t.contains('نبض') ||
        t.contains('ضغط') ||
        t.contains('حرارة') ||
        t.contains('تنفس') ||
        t.contains('pulse') ||
        t.contains('blood pressure') ||
        t.contains('temperature')) {
      return Icons.monitor_heart_rounded;
    }
    return Icons.subdirectory_arrow_left_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildProgressHeader(),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: switch (_step) {
            0 => _buildStudentStep(),
            1 => _buildContextStep(),
            2 => _buildChecklistStep(),
            3 => _buildLiveEvaluationStep(),
            _ => _buildReviewStep(),
          },
        ),
      ],
    );
  }

  Widget _buildProgressHeader() {
    final labels = ['الطالب', 'السياق', 'القائمة', 'التقييم', 'المراجعة'];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final active = index == _step;
          final done = index < _step;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: active || done
                          ? AppColors.royalBlue.withValues(
                              alpha: active ? 0.12 : 0.07,
                            )
                          : AppColors.slate50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: active
                            ? AppColors.royalBlue
                            : AppColors.slate100,
                      ),
                    ),
                    child: Text(
                      labels[index],
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: active || done
                            ? AppColors.royalBlue
                            : AppColors.slate500,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ),
                if (index != labels.length - 1) const SizedBox(width: 6),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStudentStep() {
    final majors = _docList(widget.data['majors']);
    final levels = _docList(widget.data['levels']);
    return _stageCard(
      title: 'اختيار الطالب',
      subtitle:
          'ابحث بالاسم أو رقم القيد، واستخدم الفلاتر بدل القوائم الطويلة.',
      icon: Icons.person_search_rounded,
      children: [
        TextField(
          controller: _search,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
          decoration: InputDecoration(
            labelText: 'بحث سريع عن الطالب بالاسم أو القيد',
            labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.slate400,
            ),
            filled: true,
            fillColor: AppColors.slate50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.slate200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.slate200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.royalBlue),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _optionDropdown(
                label: 'التخصص',
                items: majors,
                value: _majorId,
                onChanged: (value) {
                  setState(() => _majorId = value);
                  _loadStudents();
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _optionDropdown(
                label: 'المستوى',
                items: levels,
                value: _levelId,
                onChanged: (value) {
                  setState(() => _levelId = value);
                  _loadStudents();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_loadingStudents)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_students.isEmpty)
          const _DocEmpty('لا توجد نتائج مطابقة للبحث الحالي.')
        else
          ..._students.map(_studentCard),
        const SizedBox(height: 12),
        _nextButton(
          label: 'متابعة إلى سياق التقييم',
          enabled: _studentId != null,
          onPressed: () => setState(() => _step = 1),
        ),
      ],
    );
  }

  Widget _buildContextStep() {
    final systems = _docList(widget.data['body_systems']);
    final cases = _docList(widget.data['cases']);
    return _stageCard(
      title: 'سياق التقييم',
      subtitle: 'اربط التقييم بنظام جسم أو حالة سريرية عند الحاجة.',
      icon: Icons.medical_information_rounded,
      children: [
        _selectedSummary(),
        const SizedBox(height: 14),
        _optionDropdown(
          label: 'نظام الجسم المعتمد',
          items: systems,
          value: _bodySystemId,
          onChanged: (value) => setState(() => _bodySystemId = value),
        ),
        const SizedBox(height: 12),
        _optionDropdown(
          label: 'الحالة السريرية التوضيحية (اختياري)',
          items: cases,
          value: _caseId,
          titleKey: 'diagnosis',
          fallbackKey: 'patient_name',
          onChanged: (value) => setState(() => _caseId = value),
        ),
        const SizedBox(height: 16),
        _navigationButtons(
          canNext: true,
          onBack: () => setState(() => _step = 0),
          onNext: () => setState(() => _step = 2),
        ),
      ],
    );
  }

  Widget _buildChecklistStep() {
    final checklists = _docList(widget.data['checklists']);
    return _stageCard(
      title: 'اختيار قائمة OSCE',
      subtitle:
          'اختر القائمة المناسبة، ويمكن معاينة عدد البنود والدرجات قبل البدء.',
      icon: Icons.fact_check_rounded,
      children: [
        if (checklists.isEmpty)
          const _DocEmpty('لا توجد قوائم تقييم متاحة.')
        else
          ...checklists.map(_checklistCard),
        if (_checklistId != null) ...[
          const SizedBox(height: 12),
          _timerSetupPanel(),
        ],
        const SizedBox(height: 16),
        _navigationButtons(
          canNext: _canStartEvaluation,
          onBack: () => setState(() => _step = 1),
          onNext: () {
            setState(() {
              _startedAt ??= DateTime.now();
              _now = DateTime.now();
              _finishedElapsedSeconds = null;
              _lockedByTimeLimit = false;
              _step = 3;
            });
            _ensureTicker();
          },
        ),
      ],
    );
  }

  Widget _buildLiveEvaluationStep() {
    return _stageCard(
      title: 'جلسة التقييم السريري المباشر',
      subtitle:
          'قم بتقييم البنود الفرعية بشكل مباشر، ويمكنك تكبير الخط أو كتابة ملاحظات مفصلة.',
      icon: Icons.play_circle_rounded,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'بيانات وإحصائيات الجلسة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppColors.midnight,
              ),
            ),
            // Font zoom controls in live evaluation step
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (_fontSizeScale > 0.85) {
                        setState(() => _fontSizeScale -= 0.15);
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Icon(
                        Icons.zoom_out,
                        size: 14,
                        color: AppColors.slate600,
                      ),
                    ),
                  ),
                  Text(
                    '${(_fontSizeScale * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate700,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (_fontSizeScale < 1.3) {
                        setState(() => _fontSizeScale += 0.15);
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Icon(
                        Icons.zoom_in,
                        size: 14,
                        color: AppColors.slate600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _sessionStats(),
        if ((_remainingSeconds ?? 1) <= 0) ...[
          const SizedBox(height: 10),
          _warningBox(
            'انتهى وقت التقييم. يمكنك مراجعة البنود ثم حفظ النتيجة النهائية.',
          ),
        ],
        const SizedBox(height: 14),
        if (_itemsTree.isEmpty)
          const _DocEmpty('لم يتم تحميل بنود التقييم.')
        else
          ..._itemsTree.asMap().entries.map(
            (entry) => _evaluationGroup(entry.key, entry.value),
          ),
        const SizedBox(height: 14),
        TextField(
          controller: _feedback,
          minLines: 3,
          maxLines: 5,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
          decoration: InputDecoration(
            labelText: 'توصيات وملاحظات الطبيب العامة للطالب',
            labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
            prefixIcon: const Icon(
              Icons.comment_rounded,
              color: AppColors.slate400,
            ),
            alignLabelWithHint: true,
            filled: true,
            fillColor: AppColors.slate50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.slate200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.slate200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.royalBlue),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _navigationButtons(
          canNext: _scoreableItems.isNotEmpty,
          onBack: () => setState(() => _step = 2),
          onNext: () {
            _freezeTimerForReview();
            setState(() => _step = 4);
          },
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    final percentage = _totalMarks == 0
        ? 0
        : ((_obtainedMarks / _totalMarks) * 100).round();

    Color gradeColor = AppColors.danger;
    String gradeLabel = 'راسب';
    if (percentage >= 90) {
      gradeColor = AppColors.success;
      gradeLabel = 'ممتاز';
    } else if (percentage >= 80) {
      gradeColor = AppColors.royalBlue;
      gradeLabel = 'جيد جداً';
    } else if (percentage >= 70) {
      gradeColor = Colors.teal;
      gradeLabel = 'جيد';
    } else if (percentage >= 60) {
      gradeColor = AppColors.gold;
      gradeLabel = 'مقبول';
    }

    return _stageCard(
      title: 'مراجعة واعتماد النتيجة',
      subtitle: 'راجع ملخص التقييم السريري والزمني قبل الحفظ النهائي.',
      icon: Icons.verified_rounded,
      children: [
        _selectedSummary(),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Row(
            children: [
              Container(
                width: 74,
                height: 74,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: gradeColor.withValues(alpha: 0.08),
                  border: Border.all(color: gradeColor, width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: gradeColor,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    Text(
                      gradeLabel,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: gradeColor,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'قائمة OSCE الطبية',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.slate500,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _docText(_selectedChecklist?['title'], 'قائمة التقييم'),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.midnight,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _reviewMetricTile(
                label: 'الدرجة الكلية',
                value: '$_obtainedMarks / $_totalMarks د',
                icon: Icons.grade_rounded,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _reviewMetricTile(
                label: 'المؤقت الفعال',
                value: _timerSummary,
                icon: Icons.timer_rounded,
                color: AppColors.royalBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _reviewMetricTile(
                label: 'الوقت المستغرق',
                value: _formatDuration(_elapsedSeconds),
                icon: Icons.access_time_filled_rounded,
                color: Colors.teal,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _reviewMetricTile(
                label: 'البنود المقيمة',
                value: '$_evaluatedCount / ${_scoreableItems.length}',
                icon: Icons.assignment_turned_in_rounded,
                color: Colors.purple,
              ),
            ),
          ],
        ),
        if (_remainingSeconds != null) ...[
          const SizedBox(height: 10),
          _reviewMetricTile(
            label: _remainingSeconds! >= 0
                ? 'الوقت المتبقي للتقييم'
                : 'مدة تجاوز المؤقت',
            value: _formatDuration(_remainingSeconds!.abs()),
            icon: Icons.hourglass_bottom_rounded,
            color: _remainingSeconds! >= 0
                ? AppColors.success
                : AppColors.danger,
          ),
        ],
        if (_evaluatedCount < _scoreableItems.length) ...[
          const SizedBox(height: 12),
          _warningBox(
            'تنبيه: يوجد بنود لم يتم تقييمها بعد، سيتم احتسابها تلقائياً "لم يتم".',
          ),
        ],
        if (_lockedByTimeLimit) ...[
          const SizedBox(height: 12),
          _warningBox(
            'انتهى وقت التقييم، وتم قفل الإجابات الحالية. احفظ النتيجة النهائية أو اخرج من التقييم.',
          ),
        ],
        const SizedBox(height: 16),
        _navigationButtons(
          canNext: !_saving,
          nextLabel: 'حفظ التقييم النهائي',
          nextIcon: Icons.save_rounded,
          showBack: !_lockedByTimeLimit,
          onBack: () {
            _resumeTimerFromReview();
            setState(() => _step = 3);
          },
          onNext: _submit,
        ),
      ],
    );
  }

  Widget _stageCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      key: ValueKey(title),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.035),
            blurRadius: 18,
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: AppColors.royalBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: _titleStyle),
                    const SizedBox(height: 3),
                    Text(subtitle, style: _subtitleStyle),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _studentCard(_Json student) {
    final id = _docInt(student['id']);
    final active = _studentId == id;
    final name = _docText(student['name'], 'طالب');
    final code = _docText(student['student_number'], '-');
    final major = _docText(_docMap(student['major'])['name'], '-');
    final level = _docText(_docMap(student['level'])['name'], '-');
    final initial = name.isNotEmpty ? name[0] : 'S';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _studentId = id),
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.royalBlue.withValues(alpha: 0.06)
                  : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: active ? AppColors.royalBlue : AppColors.slate100,
                width: active ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: active
                      ? AppColors.royalBlue.withValues(alpha: 0.06)
                      : AppColors.midnight.withValues(alpha: 0.015),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
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
                    color: active
                        ? AppColors.royalBlue.withValues(alpha: 0.12)
                        : AppColors.slate50,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: active ? AppColors.royalBlue : AppColors.slate600,
                      fontFamily: 'Cairo',
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
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.midnight,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _tagPill(code, AppColors.slate500, AppColors.slate50),
                          _tagPill(
                            major,
                            AppColors.royalBlue,
                            AppColors.royalBlue.withValues(alpha: 0.06),
                          ),
                          _tagPill(
                            level,
                            Colors.purple,
                            Colors.purple.withValues(alpha: 0.06),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  active
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: active ? AppColors.royalBlue : AppColors.slate300,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tagPill(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }

  Widget _checklistCard(_Json item) {
    final id = _docInt(item['id']);
    final active = _checklistId == id;
    final officialMinutes = _docInt(item['time_limit_minutes']);
    final title = _docText(item['title'], 'قائمة تقييم');
    final rawSkill = _docText(item['skill_type']);
    final marks = _docText(item['total_marks'], '0');

    Color skillColor = AppColors.royalBlue;
    switch (rawSkill) {
      case 'history_taking':
        skillColor = Colors.teal;
        break;
      case 'clinical_examination':
        skillColor = AppColors.royalBlue;
        break;
      case 'procedure':
        skillColor = AppColors.gold;
        break;
      case 'communication':
        skillColor = Colors.purple;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectChecklist(id),
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: active ? skillColor.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: active ? skillColor : AppColors.slate100,
                width: active ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: active
                      ? skillColor.withValues(alpha: 0.06)
                      : AppColors.midnight.withValues(alpha: 0.015),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: skillColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    rawSkill == 'communication'
                        ? Icons.forum_rounded
                        : rawSkill == 'procedure'
                        ? Icons.vaccines_rounded
                        : rawSkill == 'history_taking'
                        ? Icons.rate_review_rounded
                        : Icons.hearing_rounded,
                    color: skillColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.midnight,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _tagPill(
                            _skillLabel(rawSkill),
                            skillColor,
                            skillColor.withValues(alpha: 0.06),
                          ),
                          _tagPill(
                            '$marks درجة',
                            AppColors.gold,
                            AppColors.gold.withValues(alpha: 0.06),
                          ),
                          _tagPill(
                            officialMinutes > 0
                                ? '$officialMinutes دقيقة'
                                : 'وقت مفتوح',
                            AppColors.royalBlue,
                            AppColors.royalBlue.withValues(alpha: 0.06),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  active
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: active ? skillColor : AppColors.slate300,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _evaluationGroup(int index, _Json parent) {
    final subs = _docList(parent['sub_items']);
    final children = subs.isEmpty ? [parent] : subs;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  'المجموعة ${index + 1}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.royalBlue,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _docText(parent['description']),
                  style: _cardTitleStyle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children.map(_scoreableItem),
        ],
      ),
    );
  }

  Widget _scoreableItem(_Json item) {
    final id = _docInt(item['id']);
    final current = _scores[id] ?? 'not_done';
    final note = _notes.putIfAbsent(id, () => TextEditingController());
    final isExpanded = _expandedNotes.contains(id);
    final hasNote = note.text.trim().isNotEmpty;
    final description = _docText(item['description']);
    final adaptiveIcon = _getAdaptiveIcon(description);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(adaptiveIcon, size: 13, color: AppColors.royalBlue),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  description,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12 * _fontSizeScale,
                    fontWeight: FontWeight.bold,
                    color: AppColors.midnight,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _miniBadge('${_docInt(item['marks'])} د'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _scorePill(
                  id,
                  'done',
                  'تم بالكامل',
                  AppColors.success,
                  current,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _scorePill(
                  id,
                  'partial',
                  'تم جزئياً',
                  AppColors.gold,
                  current,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _scorePill(
                  id,
                  'not_done',
                  'لم يتم',
                  AppColors.danger,
                  current,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedNotes.remove(id);
                    } else {
                      _expandedNotes.add(id);
                    }
                  });
                },
                icon: Icon(
                  hasNote ? Icons.note_alt_rounded : Icons.add_comment_rounded,
                  size: 13,
                  color: hasNote ? AppColors.royalBlue : AppColors.slate400,
                ),
                label: Text(
                  hasNote ? 'تعديل الملاحظة' : 'إضافة ملاحظة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: hasNote ? AppColors.royalBlue : AppColors.slate500,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          if (isExpanded) ...[
            const SizedBox(height: 8),
            TextField(
              controller: note,
              minLines: 1,
              maxLines: 3,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'ملاحظة على هذا البند الفرعي',
                labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 11),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                fillColor: AppColors.slate50,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.slate200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.slate200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.royalBlue),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _scorePill(
    int id,
    String value,
    String label,
    Color color,
    String current,
  ) {
    final active = current == value;
    IconData icon = Icons.check_circle_rounded;
    if (value == 'partial') {
      icon = Icons.hourglass_empty_rounded;
    } else if (value == 'not_done') {
      icon = Icons.cancel_rounded;
    }

    return InkWell(
      onTap: () => setState(() => _scores[id] = value),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: active ? color : color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: active ? 1.0 : 0.15),
            width: active ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: active ? Colors.white : color),
            const SizedBox(width: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: active ? Colors.white : color,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sessionStats() {
    final remaining = _remainingSeconds;
    final progressVal = _scoreableItems.isNotEmpty
        ? (_evaluatedCount / _scoreableItems.length)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: AppColors.midnight.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _statBox(
                  label: 'البنود المقيمة',
                  value: '$_evaluatedCount / ${_scoreableItems.length}',
                  icon: Icons.checklist_rounded,
                  color: AppColors.royalBlue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statBox(
                  label: 'الدرجة اللحظية',
                  value: '$_obtainedMarks / $_totalMarks د',
                  icon: Icons.star_rounded,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _statBox(
                  label: 'الوقت المنقضي',
                  value: _formatDuration(_elapsedSeconds),
                  icon: Icons.play_arrow_rounded,
                  color: Colors.teal,
                ),
              ),
              if (remaining != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _statBox(
                    label: remaining >= 0 ? 'المتبقي' : 'تجاوز الوقت',
                    value: _formatDuration(remaining.abs()),
                    icon: Icons.timer_rounded,
                    color: remaining >= 0
                        ? (remaining < 30
                              ? AppColors.danger
                              : AppColors.royalBlue)
                        : AppColors.danger,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressVal,
              backgroundColor: AppColors.slate100,
              color: AppColors.royalBlue,
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.slate500,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: color == AppColors.danger
                        ? AppColors.danger
                        : AppColors.midnight,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectedSummary() {
    final student = _selectedStudent;
    if (student == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.1)),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_rounded, color: AppColors.danger),
            SizedBox(width: 10),
            Text(
              'لم يتم اختيار طالب للتقييم',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: AppColors.danger,
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    final name = _docText(student['name']);
    final code = _docText(student['student_number'], '-');
    final major = _docText(_docMap(student['major'])['name'], '-');
    final level = _docText(_docMap(student['level'])['name'], '-');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.royalBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.school_rounded,
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
                  name,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.midnight,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'قيد: $code  •  $major  •  $level',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.slate600,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionDropdown({
    required String label,
    required List<_Json> items,
    required int? value,
    required ValueChanged<int?> onChanged,
    String titleKey = 'name',
    String fallbackKey = 'name',
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<int>(
          isExpanded: true,
          initialValue: value,
          decoration: InputDecoration(
            labelText: label,
            border: InputBorder.none,
            labelStyle: const TextStyle(
              fontFamily: 'Cairo',
              color: AppColors.slate500,
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
            ),
            alignLabelWithHint: true,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.slate500,
          ),
          style: const TextStyle(
            fontFamily: 'Cairo',
            color: AppColors.midnight,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          items: [
            const DropdownMenuItem<int>(
              value: null,
              child: Text(
                'الكل / بدون تحديد',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            ...items.map(
              (item) => DropdownMenuItem<int>(
                value: _docInt(item['id']),
                child: Text(
                  _docText(item[titleKey], _docText(item[fallbackKey], '-')),
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _timerSetupPanel() {
    final official = _officialLimitSeconds;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_rounded, color: AppColors.royalBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  official > 0
                      ? 'المؤقت الرسمي لهذه القائمة: ${_formatDuration(official)}'
                      : 'لا يوجد مؤقت رسمي محدد لهذه القائمة',
                  style: _cardTitleStyle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _timerChoice(
                  'fixed',
                  official > 0 ? 'رسمي' : 'رسمي غير محدد',
                  Icons.timer_rounded,
                  enabled: official > 0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _timerChoice(
                  'custom',
                  'مخصص',
                  Icons.edit_calendar_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _timerChoice('open', 'مفتوح', Icons.av_timer_rounded),
              ),
            ],
          ),
          if (_timerType == 'custom') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _customTimerMinutes,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'الوقت المخصص بالدقائق',
                labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                prefixIcon: const Icon(
                  Icons.timer_10_rounded,
                  color: AppColors.slate400,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.slate200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.slate200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.royalBlue),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _timerChoice(
    String type,
    String label,
    IconData icon, {
    bool enabled = true,
  }) {
    final active = _timerType == type;
    return InkWell(
      onTap: enabled ? () => setState(() => _timerType = type) : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: active
              ? AppColors.royalBlue
              : enabled
              ? Colors.white
              : AppColors.slate100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? AppColors.royalBlue : AppColors.slate200,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: active
                  ? Colors.white
                  : enabled
                  ? AppColors.slate600
                  : AppColors.slate400,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: active
                    ? Colors.white
                    : enabled
                    ? AppColors.slate700
                    : AppColors.slate400,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navigationButtons({
    required bool canNext,
    required VoidCallback onBack,
    required VoidCallback onNext,
    String nextLabel = 'التالي',
    IconData nextIcon = Icons.arrow_back_rounded,
    bool showBack = true,
  }) {
    return Row(
      children: [
        if (showBack) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('رجوع'),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: FilledButton.icon(
            onPressed: canNext ? onNext : null,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(nextIcon),
            label: Text(nextLabel),
          ),
        ),
      ],
    );
  }

  Widget _nextButton({
    required String label,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return FilledButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: const Icon(Icons.arrow_back_rounded),
      label: Text(label),
    );
  }

  Widget _reviewMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.slate500,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.midnight,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _warningBox(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Cairo',
          color: AppColors.warning,
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
        ),
      ),
    );
  }

  Widget _miniBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: _subtitleStyle),
    );
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      final elapsed = _elapsedSeconds;
      await widget.onSubmit({
        'checklist_id': _checklistId,
        'student_id': _studentId,
        'body_system_id': _bodySystemId,
        'clinical_case_id': _caseId,
        'timer_type': _timerType,
        'time_limit_seconds': _activeLimitSeconds,
        'time_taken_seconds': elapsed,
        'doctor_feedback': _feedback.text.trim(),
        'scores': {
          for (final item in _scoreableItems)
            '${_docInt(item['id'])}': {
              'score': _scores[_docInt(item['id'])] ?? 'not_done',
              if ((_notes[_docInt(item['id'])]?.text.trim() ?? '').isNotEmpty)
                'note': _notes[_docInt(item['id'])]!.text.trim(),
            },
        },
      });
      if (!mounted) return;
      context.go(DoctorClinicalSectionScreen.path('results'));
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatDuration(int seconds) {
    final safe = seconds < 0 ? 0 : seconds;
    final minutes = safe ~/ 60;
    final remainingSeconds = safe % 60;
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours > 0) {
      return '$hours:${remainingMinutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
    return '$remainingMinutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _skillLabel(String type) => switch (type) {
    'history_taking' => 'أخذ قصة مرضية',
    'clinical_examination' => 'فحص سريري',
    'procedure' => 'إجراء سريري',
    'communication' => 'مهارات تواصل',
    _ => 'مهارة سريرية',
  };

  static const _titleStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w900,
    color: AppColors.midnight,
    fontFamily: 'Cairo',
  );

  static const _cardTitleStyle = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w900,
    color: AppColors.midnight,
    fontFamily: 'Cairo',
  );

  static const _subtitleStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.slate500,
    fontFamily: 'Cairo',
    height: 1.35,
  );
}
