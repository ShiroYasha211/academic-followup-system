part of 'student_content_screens.dart';

class StudentClinicalScreen extends ConsumerWidget {
  const StudentClinicalScreen({super.key});

  static const route = '/student/clinical';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canAccess = _canAccessClinical(ref);
    if (!canAccess) {
      return const _ClinicalForbiddenShell();
    }
    final logbook = ref.watch(_clinicalLogbookProvider);
    return StudentShell(
      currentIndex: 34,
      title: 'القسم العملي والسريري',
      child: _AsyncBody(
        state: logbook,
        onRetry: () => ref.invalidate(_clinicalLogbookProvider),
        builder: (data) {
          final stats = asMap(data['stats']);
          final assignments = asList(data['assignments']);
          final logs = asList(data['logs']);
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_clinicalLogbookProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
              children: [
                _ClinicalHeader(
                  title: 'مسارك السريري',
                  subtitle:
                      'إدارة السجل العملي، مهام الإنجاز، تقييمات الدكتور، الاختبارات التدريبية والحالات النادرة من مكان واحد.',
                  icon: Icons.local_hospital_rounded,
                  colors: const [
                    AppColors.royalBlueDark,
                    AppColors.royalBlue,
                    AppColors.teal,
                  ],
                ),
                const SizedBox(height: 18),
                _ClinicalStatsRow(
                  items: [
                    _ClinicalStatItem(
                      'معتمدة',
                      text(stats, 'confirmed_logs', fallback: '0'),
                      Icons.verified_rounded,
                      AppColors.success,
                    ),
                    _ClinicalStatItem(
                      'بانتظار الاعتماد',
                      text(stats, 'pending_logs', fallback: '0'),
                      Icons.pending_actions_rounded,
                      AppColors.warning,
                    ),
                    _ClinicalStatItem(
                      'المهام',
                      assignments.length.toString(),
                      Icons.assignment_turned_in_rounded,
                      AppColors.teal,
                    ),
                    _ClinicalStatItem(
                      'السجلات',
                      logs.length.toString(),
                      Icons.menu_book_rounded,
                      AppColors.royalBlue,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _ClinicalActionGrid(
                  actions: [
                    _ClinicalActionItem(
                      'السجل العملي',
                      'إضافة ومتابعة سجلات اليوم واعتماد QR',
                      Icons.menu_book_rounded,
                      StudentClinicalLogbookScreen.route,
                      AppColors.royalBlue,
                    ),
                    _ClinicalActionItem(
                      'تقييماتي',
                      'نتائج تقييمات الدكتور ومهاراتك',
                      Icons.radar_rounded,
                      StudentClinicalEvaluationsScreen.route,
                      AppColors.success,
                    ),
                    _ClinicalActionItem(
                      'تدريب OSCE',
                      'تدرب على قوائم التقييم وأنشئ نماذجك',
                      Icons.fact_check_rounded,
                      StudentClinicalMockExamsScreen.route,
                      AppColors.goldDeep,
                    ),
                    _ClinicalActionItem(
                      'الحالات النادرة',
                      'حالات سريرية معلنة من الدكاترة',
                      Icons.emergency_rounded,
                      StudentClinicalRareCasesScreen.route,
                      AppColors.rose,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _ClinicalSectionTitle('آخر السجلات', Icons.history_rounded),
                const SizedBox(height: 10),
                if (logs.isEmpty)
                  const EmptyState(message: 'لا توجد سجلات عملية حتى الآن.')
                else
                  ...logs
                      .take(3)
                      .map((raw) => _ClinicalLogCard(log: asMap(raw))),
                const SizedBox(height: 18),
                _ClinicalSectionTitle(
                  'مهام إنجاز تحتاج متابعة',
                  Icons.task_alt_rounded,
                ),
                const SizedBox(height: 10),
                if (assignments.isEmpty)
                  const EmptyState(message: 'لا توجد مهام سريرية حالية.')
                else
                  ...assignments
                      .take(3)
                      .map((raw) => _ClinicalAssignmentCard(item: asMap(raw))),
              ],
            ),
          );
        },
      ),
    );
  }
}

class StudentClinicalLogbookScreen extends ConsumerWidget {
  const StudentClinicalLogbookScreen({super.key});

  static const route = '/student/clinical/logbook';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canAccess = _canAccessClinical(ref);
    if (!canAccess) {
      return const _ClinicalForbiddenShell();
    }
    final state = ref.watch(_clinicalLogbookProvider);
    return StudentShell(
      currentIndex: 34,
      title: 'السجل العملي',
      parentRoute: StudentClinicalScreen.route,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showClinicalLogSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('تسجيل اليوم'),
      ),
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_clinicalLogbookProvider),
        builder: (data) {
          final logs = asList(data['logs']);
          final assignments = asList(data['assignments']);
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_clinicalLogbookProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 96),
              children: [
                _ClinicalHeader(
                  title: 'سجل اليوم العملي',
                  subtitle:
                      'أدخل ما تم تنفيذه في اليوم، ثم اعرض QR للدكتور حتى يعتمد العناصر الفعلية والتشخيص.',
                  icon: Icons.qr_code_2_rounded,
                  colors: const [AppColors.royalBlue, AppColors.teal],
                ),
                const SizedBox(height: 20),
                _ClinicalSectionTitle('سجلاتك اليومية', Icons.event_available),
                const SizedBox(height: 10),
                if (logs.isEmpty)
                  const EmptyState(message: 'لا توجد سجلات عملية.')
                else
                  ...logs.map((raw) => _ClinicalLogCard(log: asMap(raw))),
                const SizedBox(height: 22),
                _ClinicalSectionTitle(
                  'مهام الإنجاز السريري',
                  Icons.assignment_turned_in_rounded,
                ),
                const SizedBox(height: 10),
                if (assignments.isEmpty)
                  const EmptyState(message: 'لا توجد مهام سريرية حالية.')
                else
                  ...assignments.map(
                    (raw) => _ClinicalAssignmentCard(item: asMap(raw)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class StudentClinicalEvaluationsScreen extends ConsumerWidget {
  const StudentClinicalEvaluationsScreen({super.key});

  static const route = '/student/clinical/evaluations';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canAccess = _canAccessClinical(ref);
    if (!canAccess) {
      return const _ClinicalForbiddenShell();
    }
    final state = ref.watch(_clinicalEvaluationsProvider);
    return StudentShell(
      currentIndex: 34,
      title: 'تقييماتي السريرية',
      parentRoute: StudentClinicalScreen.route,
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_clinicalEvaluationsProvider),
        builder: (data) {
          final stats = asMap(data['stats']);
          final radar = asList(data['radar_chart']);
          final evaluations = asList(data['evaluations']);
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_clinicalEvaluationsProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
              children: [
                _ClinicalHeader(
                  title: 'تقييمات الدكتور',
                  subtitle: 'اعرف نقاط قوتك وضعفك في المهارات السريرية.',
                  icon: Icons.radar_rounded,
                  colors: const [AppColors.success, AppColors.teal],
                ),
                const SizedBox(height: 18),
                _ClinicalStatsRow(
                  items: [
                    _ClinicalStatItem(
                      'المتوسط',
                      '${text(stats, 'average_percentage', fallback: '0')}%',
                      Icons.analytics_rounded,
                      AppColors.success,
                    ),
                    _ClinicalStatItem(
                      'التقييمات',
                      text(stats, 'total_evaluations', fallback: '0'),
                      Icons.fact_check_rounded,
                      AppColors.royalBlue,
                    ),
                    _ClinicalStatItem(
                      'ممتاز',
                      text(stats, 'excellent_count', fallback: '0'),
                      Icons.workspace_premium_rounded,
                      AppColors.goldDeep,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (radar.isNotEmpty) ...[
                  _ClinicalSectionTitle('تحليل المهارات', Icons.insights),
                  const SizedBox(height: 10),
                  ...radar.map((raw) => _ClinicalSkillBar(item: asMap(raw))),
                  const SizedBox(height: 20),
                ],
                _ClinicalSectionTitle('سجل التقييمات', Icons.history),
                const SizedBox(height: 10),
                if (evaluations.isEmpty)
                  const EmptyState(message: 'لا توجد تقييمات سريرية بعد.')
                else
                  ...evaluations.map(
                    (raw) => _ClinicalEvaluationCard(item: asMap(raw)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class StudentClinicalMockExamsScreen extends ConsumerWidget {
  const StudentClinicalMockExamsScreen({super.key});

  static const route = '/student/clinical/mock-exams';
  static String takePath(int id) => '/student/clinical/mock-exams/$id/take';
  static String resultPath(int id) =>
      '/student/clinical/mock-exams/results/$id';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canAccess = _canAccessClinical(ref);
    if (!canAccess) {
      return const _ClinicalForbiddenShell();
    }
    final state = ref.watch(_clinicalMockExamsProvider);
    return StudentShell(
      currentIndex: 34,
      title: 'تدريب OSCE',
      parentRoute: StudentClinicalScreen.route,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCustomChecklistSheet(context, ref),
        icon: const Icon(Icons.playlist_add_rounded),
        label: const Text('نموذج مخصص'),
      ),
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_clinicalMockExamsProvider),
        builder: (data) {
          final checklists = asList(data['available_checklists']);
          final attempts = asList(data['previous_attempts']);
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_clinicalMockExamsProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 96),
              children: [
                _ClinicalHeader(
                  title: 'اختبارات تدريبية',
                  subtitle:
                      'تدرب على قوائم التقييم العامة أو قوائم أنشأها الدكتور أو أنشئ نموذجك الخاص.',
                  icon: Icons.fact_check_rounded,
                  colors: const [AppColors.goldDeep, AppColors.royalBlue],
                ),
                const SizedBox(height: 20),
                _ClinicalSectionTitle('النماذج المتاحة', Icons.list_alt),
                const SizedBox(height: 10),
                if (checklists.isEmpty)
                  const EmptyState(message: 'لا توجد نماذج تدريبية متاحة.')
                else
                  ...checklists.map(
                    (raw) => _ClinicalChecklistCard(item: asMap(raw)),
                  ),
                const SizedBox(height: 22),
                _ClinicalSectionTitle('محاولاتك السابقة', Icons.history),
                const SizedBox(height: 10),
                if (attempts.isEmpty)
                  const EmptyState(message: 'لا توجد محاولات تدريبية بعد.')
                else
                  ...attempts.map(
                    (raw) => _ClinicalMockAttemptCard(item: asMap(raw)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class StudentClinicalMockTakeScreen extends ConsumerStatefulWidget {
  const StudentClinicalMockTakeScreen({super.key, required this.checklistId});

  final int checklistId;

  @override
  ConsumerState<StudentClinicalMockTakeScreen> createState() =>
      _StudentClinicalMockTakeScreenState();
}

class _StudentClinicalMockTakeScreenState
    extends ConsumerState<StudentClinicalMockTakeScreen> {
  final Map<int, String> _scores = {};
  final Map<int, TextEditingController> _notes = {};
  Timer? _timer;
  String _timerMode = 'official';
  int _customMinutes = 10;
  int _elapsedSeconds = 0;
  int? _secondsLeft;
  bool _started = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _notes.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canAccess = _canAccessClinical(ref);
    if (!canAccess) {
      return const _ClinicalForbiddenShell();
    }
    final state = ref.watch(_clinicalMockTakeProvider(widget.checklistId));
    return StudentShell(
      currentIndex: 34,
      title: 'حل تدريب OSCE',
      parentRoute: StudentClinicalMockExamsScreen.route,
      child: _AsyncBody(
        state: state,
        onRetry: () =>
            ref.invalidate(_clinicalMockTakeProvider(widget.checklistId)),
        builder: (data) {
          final items = asList(data['items']);
          final officialMinutes = number(
            data,
            'time_limit_minutes',
            fallback: 10,
          ).toInt().clamp(1, 240);
          if (!_started && _customMinutes == 10) {
            _customMinutes = officialMinutes;
          }
          if (!_started) {
            return _MockTimerSetup(
              title: text(data, 'title', fallback: 'نموذج تدريبي'),
              description: text(
                data,
                'description',
                fallback: 'اختر طريقة حساب الوقت قبل بدء التدريب.',
              ),
              officialMinutes: officialMinutes,
              timerMode: _timerMode,
              customMinutes: _customMinutes,
              onModeChanged: (value) => setState(() => _timerMode = value),
              onCustomMinutesChanged: (value) =>
                  setState(() => _customMinutes = value),
              onStart: () => _startMockExam(officialMinutes),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
            children: [
              _MockExamActiveHeader(
                title: text(data, 'title', fallback: 'نموذج تدريبي'),
                elapsedSeconds: _elapsedSeconds,
                secondsLeft: _secondsLeft,
                timerMode: _timerMode,
                totalItems: items.length,
                answeredItems: _scores.values
                    .where((value) => value != 'not_done')
                    .length,
              ),
              const SizedBox(height: 18),
              ...items.map((raw) {
                final item = asMap(raw);
                final id = number(item, 'id').toInt();
                _notes.putIfAbsent(id, TextEditingController.new);
                return _ClinicalScoreItem(
                  item: item,
                  value: _scores[id] ?? 'not_done',
                  notes: _notes[id]!,
                  onChanged: (value) => setState(() => _scores[id] = value),
                );
              }),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _submitting ? null : () => _submit(items),
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: const Text(
                  'إنهاء وتسليم التدريب',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _startMockExam(int officialMinutes) {
    final minutes = _timerMode == 'custom'
        ? (_customMinutes < 1 ? officialMinutes : _customMinutes)
        : officialMinutes;
    setState(() {
      _started = true;
      _elapsedSeconds = 0;
      _secondsLeft = _timerMode == 'free' ? null : minutes * 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _submitting) return;
      var shouldSubmit = false;
      setState(() {
        _elapsedSeconds++;
        if (_secondsLeft != null && _secondsLeft! > 0) {
          _secondsLeft = _secondsLeft! - 1;
          shouldSubmit = _secondsLeft == 0;
        }
      });
      if (shouldSubmit) {
        unawaited(_submitFromCurrentProvider(automatic: true));
      }
    });
  }

  Future<void> _submitFromCurrentProvider({bool automatic = false}) async {
    final data = await ref.read(
      _clinicalMockTakeProvider(widget.checklistId).future,
    );
    await _submit(asList(data['items']), automatic: automatic);
  }

  Future<void> _submit(List<dynamic> rawItems, {bool automatic = false}) async {
    if (_submitting) return;
    final scores = <String, dynamic>{};
    for (final raw in rawItems) {
      final item = asMap(raw);
      final id = number(item, 'id').toInt();
      scores[id.toString()] = {
        'score': _scores[id] ?? 'not_done',
        'notes': _notes[id]?.text.trim(),
      };
    }
    setState(() => _submitting = true);
    try {
      final result = await ref
          .read(studentContentRepositoryProvider)
          .submitClinicalMockExam(
            checklistId: widget.checklistId,
            timeTaken: _elapsedSeconds,
            scores: scores,
          );
      _timer?.cancel();
      ref.invalidate(_clinicalMockExamsProvider);
      final id = number(result, 'evaluation_id').toInt();
      if (mounted && id > 0) {
        if (automatic) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('انتهى وقت التدريب وتم تسليم النتيجة.'),
            ),
          );
        }
        context.go(StudentClinicalMockExamsScreen.resultPath(id));
      }
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
}

class _MockTimerSetup extends StatelessWidget {
  const _MockTimerSetup({
    required this.title,
    required this.description,
    required this.officialMinutes,
    required this.timerMode,
    required this.customMinutes,
    required this.onModeChanged,
    required this.onCustomMinutesChanged,
    required this.onStart,
  });

  final String title;
  final String description;
  final int officialMinutes;
  final String timerMode;
  final int customMinutes;
  final ValueChanged<String> onModeChanged;
  final ValueChanged<int> onCustomMinutesChanged;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
      children: [
        _ClinicalHeader(
          title: title,
          subtitle: description,
          icon: Icons.timer_rounded,
          colors: const [AppColors.royalBlue, AppColors.goldDeep],
        ),
        const SizedBox(height: 18),
        _ClinicalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'إعداد مؤقت التدريب',
                style: TextStyle(
                  color: AppColors.midnight,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              _MockTimerOption(
                value: 'official',
                groupValue: timerMode,
                title: 'الوقت الرسمي',
                subtitle: '$officialMinutes دقيقة مثل إعداد الويب',
                icon: Icons.school_rounded,
                onChanged: onModeChanged,
              ),
              _MockTimerOption(
                value: 'custom',
                groupValue: timerMode,
                title: 'وقت مخصص',
                subtitle: '$customMinutes دقيقة',
                icon: Icons.tune_rounded,
                onChanged: onModeChanged,
              ),
              if (timerMode == 'custom') ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.slate50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: customMinutes <= 1
                            ? null
                            : () => onCustomMinutesChanged(customMinutes - 1),
                        icon: const Icon(Icons.remove_rounded),
                        tooltip: 'تقليل الوقت',
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          initialValue: customMinutes.toString(),
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'الدقائق',
                            suffixText: 'دقيقة',
                          ),
                          onChanged: (value) {
                            final minutes = int.tryParse(value);
                            if (minutes != null) {
                              onCustomMinutesChanged(minutes);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filledTonal(
                        onPressed: () =>
                            onCustomMinutesChanged(customMinutes + 1),
                        icon: const Icon(Icons.add_rounded),
                        tooltip: 'زيادة الوقت',
                      ),
                    ],
                  ),
                ),
              ],
              _MockTimerOption(
                value: 'free',
                groupValue: timerMode,
                title: 'توقيت حر',
                subtitle: 'عد تصاعدي بدون تسليم تلقائي',
                icon: Icons.av_timer_rounded,
                onChanged: onModeChanged,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text(
                  'بدء التدريب',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MockTimerOption extends StatelessWidget {
  const _MockTimerOption({
    required this.value,
    required this.groupValue,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onChanged,
  });

  final String value;
  final String groupValue;
  final String title;
  final String subtitle;
  final IconData icon;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.royalBlue.withValues(alpha: 0.08)
              : AppColors.slate50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.royalBlue : AppColors.slate200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.royalBlue : AppColors.slate500,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.midnight,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.slate500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: (value) {
                if (value != null) onChanged(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MockExamActiveHeader extends StatelessWidget {
  const _MockExamActiveHeader({
    required this.title,
    required this.elapsedSeconds,
    required this.secondsLeft,
    required this.timerMode,
    required this.totalItems,
    required this.answeredItems,
  });

  final String title;
  final int elapsedSeconds;
  final int? secondsLeft;
  final String timerMode;
  final int totalItems;
  final int answeredItems;

  @override
  Widget build(BuildContext context) {
    final timerValue = timerMode == 'free' ? elapsedSeconds : secondsLeft ?? 0;
    final isLow = timerMode != 'free' && timerValue <= 60;
    return _ClinicalCard(
      child: Row(
        children: [
          _ClinicalIconBubble(Icons.fact_check_rounded, AppColors.royalBlue),
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
                    color: AppColors.midnight,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'تم تقييم $answeredItems من $totalItems بند',
                  style: const TextStyle(
                    color: AppColors.slate500,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: (isLow ? AppColors.danger : AppColors.royalBlue)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _formatClinicalSeconds(timerValue),
              style: TextStyle(
                color: isLow ? AppColors.danger : AppColors.royalBlue,
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatClinicalSeconds(int seconds) {
  final safe = seconds < 0 ? 0 : seconds;
  final minutes = safe ~/ 60;
  final secs = safe % 60;
  return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
}

class StudentClinicalMockResultScreen extends ConsumerWidget {
  const StudentClinicalMockResultScreen({
    super.key,
    required this.evaluationId,
  });

  final int evaluationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canAccess = _canAccessClinical(ref);
    if (!canAccess) {
      return const _ClinicalForbiddenShell();
    }
    final state = ref.watch(_clinicalMockResultProvider(evaluationId));
    return StudentShell(
      currentIndex: 34,
      title: 'نتيجة التدريب',
      parentRoute: StudentClinicalMockExamsScreen.route,
      child: _AsyncBody(
        state: state,
        onRetry: () =>
            ref.invalidate(_clinicalMockResultProvider(evaluationId)),
        builder: (data) {
          final evaluation = asMap(data['evaluation']);
          final radar = asList(data['radar_chart']);
          final scores = asList(evaluation['scores']);
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
            children: [
              _ClinicalHeader(
                title:
                    'نتيجتك: ${text(evaluation, 'percentage', fallback: '0')}%',
                subtitle:
                    'التقدير: ${text(evaluation, 'grade_label', fallback: _clinicalGrade(text(evaluation, 'grade')))}',
                icon: Icons.emoji_events_rounded,
                colors: const [AppColors.success, AppColors.royalBlue],
              ),
              const SizedBox(height: 12),
              _ClinicalCard(
                child: Row(
                  children: [
                    Expanded(
                      child: _ClinicalResultMiniStat(
                        label: 'الوقت',
                        value: text(
                          evaluation,
                          'formatted_time',
                          fallback: _formatClinicalSeconds(
                            number(evaluation, 'time_taken').toInt(),
                          ),
                        ),
                        icon: Icons.timer_rounded,
                        color: AppColors.royalBlue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ClinicalResultMiniStat(
                        label: 'التاريخ',
                        value: dateOnly(text(evaluation, 'created_at')),
                        icon: Icons.calendar_month_rounded,
                        color: AppColors.teal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ...radar.map((raw) => _ClinicalSkillBar(item: asMap(raw))),
              const SizedBox(height: 18),
              _ClinicalSectionTitle('تفاصيل العناصر', Icons.checklist_rounded),
              const SizedBox(height: 10),
              ...scores.map((raw) => _ClinicalMockScoreCard(item: asMap(raw))),
            ],
          );
        },
      ),
    );
  }
}

class StudentClinicalRareCasesScreen extends ConsumerWidget {
  const StudentClinicalRareCasesScreen({super.key});

  static const route = '/student/clinical/rare-cases';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canAccess = _canAccessClinical(ref);
    if (!canAccess) {
      return const _ClinicalForbiddenShell();
    }
    final state = ref.watch(_clinicalRareCasesProvider);
    return StudentShell(
      currentIndex: 34,
      title: 'الحالات النادرة',
      parentRoute: StudentClinicalScreen.route,
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_clinicalRareCasesProvider),
        builder: (data) {
          final items = asList(data['data']);
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_clinicalRareCasesProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
              children: [
                _ClinicalHeader(
                  title: 'مركز الحالات النادرة',
                  subtitle:
                      'حالات سريرية يعلنها الدكتور ليستفيد منها طلاب التخصص.',
                  icon: Icons.emergency_rounded,
                  colors: const [AppColors.rose, AppColors.orange],
                ),
                const SizedBox(height: 20),
                if (items.isEmpty)
                  const EmptyState(message: 'لا توجد حالات نادرة نشطة.')
                else
                  ...items.map((raw) => _RareCaseCard(item: asMap(raw))),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ClinicalHeader extends StatelessWidget {
  const _ClinicalHeader({
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
            color: colors.first.withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icon, color: AppColors.gold, size: 36),
          ),
        ],
      ),
    );
  }
}

class _ClinicalForbiddenShell extends ConsumerWidget {
  const _ClinicalForbiddenShell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StudentShell(
      currentIndex: 0,
      title: 'القسم العملي والسريري',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _ClinicalCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ClinicalIconBubble(Icons.lock_rounded, AppColors.slate400),
                const SizedBox(height: 16),
                const Text(
                  'القسم العملي غير متاح لهذا الحساب',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.midnight,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'يظهر هذا القسم فقط للطلاب المسجلين في تخصصات تحتوي على مسار عملي/سريري.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.slate500,
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => context.go(StudentDashboardScreen.route),
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('العودة للرئيسية'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClinicalStatsRow extends StatelessWidget {
  const _ClinicalStatsRow({required this.items});

  final List<_ClinicalStatItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items
              .map(
                (item) => SizedBox(
                  width: itemWidth,
                  child: _ClinicalCard(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 88),
                      child: Row(
                        children: [
                          _ClinicalIconBubble(item.icon, item.color),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item.value,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.midnight,
                                  ),
                                ),
                                Text(
                                  item.label,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.slate500,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _ClinicalActionGrid extends StatelessWidget {
  const _ClinicalActionGrid({required this.actions});

  final List<_ClinicalActionItem> actions;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: actions
          .map(
            (action) => _ClinicalCard(
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => context.push(action.route),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ClinicalIconBubble(action.icon, action.color),
                      const Spacer(),
                      Text(
                        action.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: AppColors.midnight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        action.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.slate500,
                          fontSize: 11,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ClinicalLogCard extends ConsumerWidget {
  const _ClinicalLogCard({required this.log});

  final Map<String, dynamic> log;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final center = asMap(log['training_center']);
    final department = asMap(log['department']);
    final doctor = asMap(log['doctor']);
    final activities = asList(log['activities']);
    final status = text(log, 'status', fallback: 'pending');
    final canChange = status == 'pending';
    return _ClinicalCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _showClinicalLogDetails(context, ref, log),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ClinicalIconBubble(
                  Icons.fact_check_rounded,
                  AppColors.royalBlue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text(department, 'name', fallback: 'قسم عملي'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.midnight,
                    ),
                  ),
                ),
                _ClinicalStatusBadge(status),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${text(center, 'name', fallback: 'مركز غير محدد')} | ${text(doctor, 'name', fallback: 'دكتور غير محدد')}',
              style: const TextStyle(
                color: AppColors.slate600,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ClinicalMiniBadge(
                  'قصص: ${text(log, 'history_count', fallback: '0')}',
                ),
                _ClinicalMiniBadge(
                  'فحوصات: ${text(log, 'exam_count', fallback: '0')}',
                ),
                _ClinicalMiniBadge(
                  'مرور: ${log['did_round'] == true ? 'نعم' : 'لا'}',
                ),
                _ClinicalMiniBadge('QR جاهز'),
              ],
            ),
            if (activities.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...activities.take(5).map((raw) {
                final activity = asMap(raw);
                final body = asMap(activity['body_system']);
                final confirmed = activity['is_confirmed'] == true;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        confirmed
                            ? Icons.verified_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: confirmed
                            ? AppColors.success
                            : AppColors.slate300,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${_clinicalActivityLabel(text(activity, 'activity_type'))}: ${text(body, 'name', fallback: text(activity, 'case_name', fallback: '-'))}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => _showClinicalLogDetails(context, ref, log),
                icon: const Icon(Icons.qr_code_2_rounded),
                label: const Text('عرض التفاصيل والباركود'),
              ),
            ),
            if (canChange) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _showClinicalLogSheet(context, ref, existing: log),
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('تعديل'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _deleteClinicalLog(context, ref, log),
                      icon: const Icon(Icons.delete_rounded),
                      label: const Text('حذف'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

void _showClinicalLogDetails(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> log,
) {
  showMoeenBottomSheet(
    context: context,
    title: 'تفاصيل السجل العملي',
    icon: Icons.qr_code_2_rounded,
    color: AppColors.royalBlue,
    child: _ClinicalLogDetailsPanel(initialLog: log),
  );
}

class _ClinicalLogDetailsPanel extends ConsumerStatefulWidget {
  const _ClinicalLogDetailsPanel({required this.initialLog});

  final Map<String, dynamic> initialLog;

  @override
  ConsumerState<_ClinicalLogDetailsPanel> createState() =>
      _ClinicalLogDetailsPanelState();
}

class _ClinicalLogDetailsPanelState
    extends ConsumerState<_ClinicalLogDetailsPanel> {
  late Map<String, dynamic> _log;
  bool _regenerating = false;

  @override
  void initState() {
    super.initState();
    _log = Map<String, dynamic>.from(widget.initialLog);
  }

  @override
  Widget build(BuildContext context) {
    final center = asMap(_log['training_center']);
    final department = asMap(_log['department']);
    final doctor = asMap(_log['doctor']);
    final status = text(_log, 'status', fallback: 'pending');
    final qrToken = text(_log, 'qr_token');
    final canRegenerate =
        boolValue(_log, 'can_regenerate_qr') &&
        status != 'confirmed' &&
        status != 'rejected';
    final groups = asList(_log['grouped_activities']).isNotEmpty
        ? asList(_log['grouped_activities']).map(asMap).toList()
        : _fallbackClinicalGroups(_log);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                text(department, 'name', fallback: 'قسم عملي'),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppColors.midnight,
                ),
              ),
            ),
            _ClinicalStatusBadge(status),
          ],
        ),
        const SizedBox(height: 14),
        if (qrToken.isNotEmpty && status != 'confirmed' && status != 'rejected')
          _ClinicalQrBox(
            key: ValueKey('$qrToken-${text(_log, 'qr_expires_at')}'),
            token: qrToken,
            expiresAt: text(_log, 'qr_expires_at'),
            expired: boolValue(_log, 'is_qr_expired'),
          )
        else
          _ClinicalApprovedBox(status: status),
        const SizedBox(height: 16),
        _ClinicalDetailRow('المركز', text(center, 'name', fallback: '-')),
        _ClinicalDetailRow('القسم', text(department, 'name', fallback: '-')),
        _ClinicalDetailRow('الدكتور', text(doctor, 'name', fallback: '-')),
        _ClinicalDetailRow('التاريخ', dateOnly(text(_log, 'log_date'))),
        if (text(_log, 'doctor_notes').isNotEmpty)
          _ClinicalDetailRow('ملاحظات الدكتور', text(_log, 'doctor_notes')),
        const SizedBox(height: 16),
        const Text(
          'تفاصيل الاعتماد',
          style: TextStyle(
            color: AppColors.midnight,
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        if (groups.isEmpty)
          const EmptyState(message: 'لا توجد أنشطة مسجلة في هذا السجل.')
        else
          ...groups.map((group) => _ClinicalLogGroupCard(group: group)),
        if (canRegenerate) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _regenerating ? null : _regenerateQr,
            icon: _regenerating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
            label: const Text(
              'تجديد الباركود',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _regenerateQr() async {
    final id = number(_log, 'id').toInt();
    if (id <= 0) return;
    setState(() => _regenerating = true);
    try {
      final updated = await ref
          .read(studentContentRepositoryProvider)
          .regenerateClinicalLogQr(id);
      setState(() => _log = Map<String, dynamic>.from(updated));
      ref.invalidate(_clinicalLogbookProvider);
    } on ApiException catch (error) {
      if (mounted) {
        await showMoeenInfoDialog(
          context: context,
          title: 'تعذر تجديد الباركود',
          message: error.message,
          icon: Icons.error_rounded,
          color: AppColors.danger,
        );
      }
    } finally {
      if (mounted) setState(() => _regenerating = false);
    }
  }
}

class _ClinicalQrBox extends StatelessWidget {
  const _ClinicalQrBox({
    super.key,
    required this.token,
    required this.expiresAt,
    required this.expired,
  });

  final String token;
  final String expiresAt;
  final bool expired;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.slate200),
            ),
            child: QrImageView(
              data: token,
              version: QrVersions.auto,
              size: 210,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(color: AppColors.midnight),
              dataModuleStyle: const QrDataModuleStyle(
                color: AppColors.midnight,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _ClinicalQrTimer(expiresAt: expiresAt, initiallyExpired: expired),
        ],
      ),
    );
  }
}

class _ClinicalQrTimer extends StatefulWidget {
  const _ClinicalQrTimer({
    required this.expiresAt,
    required this.initiallyExpired,
  });

  final String expiresAt;
  final bool initiallyExpired;

  @override
  State<_ClinicalQrTimer> createState() => _ClinicalQrTimerState();
}

class _ClinicalQrTimerState extends State<_ClinicalQrTimer> {
  Timer? _timer;
  late int _secondsLeft;

  @override
  void initState() {
    super.initState();
    _secondsLeft = _calculateSeconds();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft = _calculateSeconds());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _ClinicalQrTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiresAt != widget.expiresAt ||
        oldWidget.initiallyExpired != widget.initiallyExpired) {
      setState(() => _secondsLeft = _calculateSeconds());
    }
  }

  int _calculateSeconds() {
    final expiresAt = DateTime.tryParse(widget.expiresAt);
    if (expiresAt == null) return 0;
    final seconds = expiresAt.difference(DateTime.now()).inSeconds;
    return seconds.clamp(0, 999999).toInt();
  }

  @override
  Widget build(BuildContext context) {
    if (_secondsLeft <= 0) {
      return const _ClinicalMiniBadge('انتهت صلاحية الباركود');
    }
    final minutes = _secondsLeft ~/ 60;
    final seconds = _secondsLeft % 60;
    return _ClinicalMiniBadge(
      'ينتهي خلال ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
    );
  }
}

class _ClinicalApprovedBox extends StatelessWidget {
  const _ClinicalApprovedBox({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final confirmed = status == 'confirmed';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (confirmed ? AppColors.success : AppColors.slate400).withValues(
          alpha: 0.1,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            confirmed ? Icons.verified_rounded : Icons.info_outline_rounded,
            color: confirmed ? AppColors.success : AppColors.slate500,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              confirmed
                  ? 'هذا السجل معتمد بالكامل ولا يحتاج باركود جديد.'
                  : 'لا يتوفر باركود لهذا السجل حاليًا.',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.midnight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClinicalDetailRow extends StatelessWidget {
  const _ClinicalDetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.slate500,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                color: AppColors.midnight,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClinicalLogGroupCard extends StatelessWidget {
  const _ClinicalLogGroupCard({required this.group});

  final Map<String, dynamic> group;

  @override
  Widget build(BuildContext context) {
    final items = asList(group['items']).map(asMap).toList();
    final confirmed = boolValue(group, 'all_confirmed');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: confirmed
            ? AppColors.success.withValues(alpha: 0.08)
            : AppColors.slate50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: confirmed
              ? AppColors.success.withValues(alpha: 0.22)
              : AppColors.slate200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                confirmed ? Icons.verified_rounded : Icons.pending_rounded,
                color: confirmed ? AppColors.success : AppColors.warning,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${text(group, 'label', fallback: 'قسم')} (${items.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.midnight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: items.map((item) {
              final body = asMap(item['body_system']);
              return _ClinicalMiniBadge(
                text(
                  body,
                  'name',
                  fallback: text(item, 'case_name', fallback: '-'),
                ),
              );
            }).toList(),
          ),
          if (text(group, 'diagnosis').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'التشخيص: ${text(group, 'diagnosis')}',
              style: const TextStyle(
                color: AppColors.slate700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

List<Map<String, dynamic>> _fallbackClinicalGroups(Map<String, dynamic> log) {
  final activities = asList(log['activities']).map(asMap).toList();
  if (activities.isEmpty) return const [];
  final specs = [
    ('history_taking', 'القصص المرضية'),
    ('clinical_examination', 'الفحوصات السريرية'),
    ('round', 'المرور'),
  ];
  return specs
      .map((spec) {
        final items = activities.where(
          (item) => text(item, 'activity_type') == spec.$1,
        );
        final list = items.toList();
        return {
          'key': spec.$1,
          'label': spec.$2,
          'all_confirmed':
              list.isNotEmpty &&
              list.every((item) => boolValue(item, 'is_confirmed')),
          'diagnosis': list
              .map((item) => text(item, 'diagnosis'))
              .firstWhere((value) => value.isNotEmpty, orElse: () => ''),
          'items': list,
        };
      })
      .where((group) => asList(group['items']).isNotEmpty)
      .toList();
}

class _ClinicalAssignmentCard extends ConsumerWidget {
  const _ClinicalAssignmentCard({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clinicalCase = asMap(item['clinical_case']);
    final status = text(item, 'status', fallback: 'assigned');
    final canSubmit = status == 'assigned' || status == 'rejected';
    return _ClinicalCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ClinicalIconBubble(Icons.assignment_rounded, AppColors.teal),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text(
                    clinicalCase,
                    'patient_name',
                    fallback: text(item, 'task_type', fallback: 'مهمة سريرية'),
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              _ClinicalStatusBadge(status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _clinicalActivityLabel(text(item, 'task_type')),
            style: const TextStyle(
              color: AppColors.slate600,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (text(item, 'student_completion_message').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('رسالتك: ${text(item, 'student_completion_message')}'),
          ],
          if (text(item, 'review_notes').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'ملاحظة الدكتور: ${text(item, 'review_notes')}',
              style: const TextStyle(
                color: AppColors.rose,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          if (canSubmit) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _submitClinicalAssignment(context, ref, item),
                icon: const Icon(Icons.send_rounded),
                label: Text(
                  status == 'rejected' ? 'إعادة الإرسال' : 'إرسال إنجاز',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ClinicalSkillBar extends StatelessWidget {
  const _ClinicalSkillBar({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final percentage = number(item, 'percentage').toDouble().clamp(0, 100);
    return _ClinicalCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  text(item, 'label_ar', fallback: text(item, 'label_en')),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: AppColors.royalBlue,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: percentage / 100,
              backgroundColor: AppColors.slate100,
              valueColor: const AlwaysStoppedAnimation(AppColors.royalBlue),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClinicalEvaluationCard extends StatelessWidget {
  const _ClinicalEvaluationCard({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final checklist = asMap(item['checklist']);
    final doctor = asMap(item['doctor']);
    return _ClinicalCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _ClinicalIconBubble(Icons.rate_review_rounded, AppColors.success),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text(checklist, 'title', fallback: 'تقييم سريري'),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  '${text(doctor, 'name', fallback: 'الدكتور')} | ${text(item, 'percentage', fallback: '0')}%',
                ),
              ],
            ),
          ),
          _ClinicalStatusBadge(text(item, 'grade')),
        ],
      ),
    );
  }
}

class _ClinicalChecklistCard extends ConsumerWidget {
  const _ClinicalChecklistCard({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creatorId = text(asMap(item['creator']), 'id');
    final isCustom = creatorId.isNotEmpty;
    return _ClinicalCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _ClinicalIconBubble(
            Icons.playlist_add_check_rounded,
            AppColors.goldDeep,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text(item, 'title', fallback: 'نموذج تدريبي'),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  '${text(item, 'total_marks', fallback: '0')} درجة | ${text(item, 'time_limit_minutes', fallback: '10')} دقيقة',
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.push(
              StudentClinicalMockExamsScreen.takePath(
                number(item, 'id').toInt(),
              ),
            ),
            icon: const Icon(Icons.play_arrow_rounded),
            color: AppColors.royalBlue,
          ),
          if (isCustom)
            IconButton(
              onPressed: () async {
                await ref
                    .read(studentContentRepositoryProvider)
                    .deleteClinicalCustomChecklist(number(item, 'id').toInt());
                ref.invalidate(_clinicalMockExamsProvider);
              },
              icon: const Icon(Icons.delete_rounded),
              color: AppColors.danger,
            ),
        ],
      ),
    );
  }
}

class _ClinicalMockAttemptCard extends StatelessWidget {
  const _ClinicalMockAttemptCard({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final checklist = asMap(item['checklist']);
    return _ClinicalCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push(
          StudentClinicalMockExamsScreen.resultPath(number(item, 'id').toInt()),
        ),
        child: Row(
          children: [
            _ClinicalIconBubble(Icons.history_edu_rounded, AppColors.royalBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text(checklist, 'title', fallback: 'محاولة تدريبية'),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    '${text(item, 'percentage', fallback: '0')}% | ${_clinicalGrade(text(item, 'grade'))}',
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_left_rounded, color: AppColors.slate400),
          ],
        ),
      ),
    );
  }
}

class _ClinicalScoreItem extends StatelessWidget {
  const _ClinicalScoreItem({
    required this.item,
    required this.value,
    required this.notes,
    required this.onChanged,
  });

  final Map<String, dynamic> item;
  final String value;
  final TextEditingController notes;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final marks = text(item, 'marks', fallback: '1');
    return _ClinicalCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  text(item, 'description', fallback: 'عنصر تقييم'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: AppColors.midnight,
                  ),
                ),
              ),
              _ClinicalMiniBadge('$marks درجة'),
            ],
          ),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'done',
                icon: Icon(Icons.check_circle_rounded),
                label: Text('تم'),
              ),
              ButtonSegment(
                value: 'partial',
                icon: Icon(Icons.adjust_rounded),
                label: Text('جزئي'),
              ),
              ButtonSegment(
                value: 'not_done',
                icon: Icon(Icons.cancel_rounded),
                label: Text('لم يتم'),
              ),
            ],
            selected: {value},
            onSelectionChanged: (set) => onChanged(set.first),
            showSelectedIcon: false,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: notes,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'ملاحظات اختيارية'),
          ),
        ],
      ),
    );
  }
}

class _ClinicalMockScoreCard extends StatelessWidget {
  const _ClinicalMockScoreCard({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final checklistItem = asMap(item['checklist_item']);
    final obtained = number(item, 'marks_obtained').toDouble();
    final maxMarks = number(
      item,
      'max_marks',
      fallback: number(checklistItem, 'marks'),
    ).toDouble();
    final scoreLabel = _resolvedMockScoreLabel(
      item: item,
      obtained: obtained,
      maxMarks: maxMarks,
    );
    final color = switch (scoreLabel) {
      'done' => AppColors.success,
      'partial' => AppColors.warning,
      _ => AppColors.danger,
    };
    final label = switch (scoreLabel) {
      'done' => 'تم',
      'partial' => 'جزئي',
      _ => 'لم يتم',
    };
    return _ClinicalCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ClinicalIconBubble(Icons.check_rounded, color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text(checklistItem, 'description', fallback: 'عنصر'),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: color.withValues(alpha: 0.22)),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatClinicalMark(obtained)} / ${_formatClinicalMark(maxMarks)} درجة',
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
          if (text(item, 'notes').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'ملاحظات: ${text(item, 'notes')}',
              style: const TextStyle(
                color: AppColors.slate600,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _resolvedMockScoreLabel({
  required Map<String, dynamic> item,
  required double obtained,
  required double maxMarks,
}) {
  if (maxMarks > 0) {
    if (obtained >= maxMarks) return 'done';
    if (obtained > 0) return 'partial';
    return 'not_done';
  }
  final apiLabel = text(item, 'score_label');
  if (apiLabel == 'done' || apiLabel == 'partial' || apiLabel == 'not_done') {
    return apiLabel;
  }
  return 'not_done';
}

String _formatClinicalMark(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(1);
}

class _ClinicalResultMiniStat extends StatelessWidget {
  const _ClinicalResultMiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
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
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
              Text(
                value.isEmpty ? '-' : value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.midnight,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RareCaseCard extends StatelessWidget {
  const _RareCaseCard({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final doctor = asMap(item['doctor']);
    final diagnosis = text(
      item,
      'diagnosis',
      fallback: text(item, 'title', fallback: 'حالة نادرة'),
    );
    return InkWell(
      onTap: () => _showRareCaseDetails(context, number(item, 'id').toInt()),
      borderRadius: BorderRadius.circular(22),
      child: _ClinicalCard(
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ClinicalIconBubble(Icons.emergency_rounded, AppColors.rose),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    diagnosis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.slate400,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ClinicalMiniBadge(
                  text(item, 'hospital', fallback: 'مركز غير محدد'),
                ),
                _ClinicalMiniBadge(
                  text(item, 'department', fallback: 'قسم غير محدد'),
                ),
                if (text(item, 'room_number').isNotEmpty)
                  _ClinicalMiniBadge('غرفة ${text(item, 'room_number')}'),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              text(item, 'clinical_signs', fallback: text(item, 'description')),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(height: 1.45, color: AppColors.slate700),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.person_rounded,
                  size: 16,
                  color: AppColors.slate500,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'بواسطة: ${text(doctor, 'name', fallback: 'دكتور')}',
                    style: const TextStyle(
                      color: AppColors.slate500,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  dateOnly(text(item, 'created_at')),
                  style: const TextStyle(
                    color: AppColors.slate400,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
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

void _showRareCaseDetails(BuildContext context, int id) {
  if (id <= 0) return;
  showMoeenBottomSheet(
    context: context,
    title: 'تفاصيل الحالة النادرة',
    icon: Icons.emergency_rounded,
    color: AppColors.rose,
    child: _RareCaseDetailsPanel(id: id),
  );
}

class _RareCaseDetailsPanel extends ConsumerWidget {
  const _RareCaseDetailsPanel({required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_clinicalRareCaseProvider(id));
    return _AsyncBody(
      state: state,
      onRetry: () => ref.invalidate(_clinicalRareCaseProvider(id)),
      builder: (item) {
        final doctor = asMap(item['doctor']);
        final attachmentUrl = _rareCaseAttachmentUrl(
          text(item, 'attachment_url', fallback: text(item, 'attachment_path')),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              text(
                item,
                'diagnosis',
                fallback: text(item, 'title', fallback: 'حالة نادرة'),
              ),
              style: const TextStyle(
                color: AppColors.midnight,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ClinicalMiniBadge('د. ${text(doctor, 'name', fallback: '-')}'),
                _ClinicalMiniBadge(dateOnly(text(item, 'created_at'))),
              ],
            ),
            const SizedBox(height: 16),
            _ClinicalDetailRow(
              'المستشفى / المركز',
              text(item, 'hospital', fallback: '-'),
            ),
            _ClinicalDetailRow(
              'القسم',
              text(item, 'department', fallback: '-'),
            ),
            _ClinicalDetailRow(
              'رقم الغرفة / الموقع',
              text(item, 'room_number', fallback: 'غير متوفر'),
            ),
            if (text(item, 'clinical_signs').isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'العلامات السريرية والملاحظات',
                style: TextStyle(
                  color: AppColors.midnight,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Text(
                  text(item, 'clinical_signs'),
                  style: const TextStyle(
                    height: 1.6,
                    color: AppColors.slate700,
                  ),
                ),
              ),
            ],
            if (attachmentUrl.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'المرفقات التوضيحية',
                style: TextStyle(
                  color: AppColors.midnight,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  attachmentUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    padding: const EdgeInsets.all(16),
                    color: AppColors.slate50,
                    child: const Text(
                      'تعذر عرض المرفق.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

String _rareCaseAttachmentUrl(String path) {
  final trimmed = path.trim();
  if (trimmed.isEmpty) return '';
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  if (trimmed.startsWith('storage/') || trimmed.startsWith('/storage/')) {
    return absoluteUrl(trimmed);
  }
  return absoluteUrl('storage/$trimmed');
}

class _ClinicalCard extends StatelessWidget {
  const _ClinicalCard({required this.child, this.margin});

  final Widget child;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate200.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ClinicalIconBubble extends StatelessWidget {
  const _ClinicalIconBubble(this.icon, this.color);

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _ClinicalStatusBadge extends StatelessWidget {
  const _ClinicalStatusBadge(this.status);

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _clinicalStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _clinicalStatusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ClinicalMiniBadge extends StatelessWidget {
  const _ClinicalMiniBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.slate600,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ClinicalSectionTitle extends StatelessWidget {
  const _ClinicalSectionTitle(this.title, this.icon);

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
            color: AppColors.midnight,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

Future<void> _showClinicalLogSheet(
  BuildContext context,
  WidgetRef ref, {
  Map<String, dynamic>? existing,
}) async {
  final data = ref.read(_clinicalLogbookProvider).valueOrNull;
  if (data == null) return;
  final options = asMap(data['form_options']);
  final centers = asList(options['training_centers']);
  final departments = asList(options['departments']);
  final bodies = asList(options['body_systems']);
  final doctors = asList(options['doctors']);
  final activities = asList(existing?['activities']);
  int? centerId = number(asMap(existing?['training_center']), 'id').toInt();
  int? departmentId = number(asMap(existing?['department']), 'id').toInt();
  int? doctorId = number(asMap(existing?['doctor']), 'id').toInt();
  if (centerId == 0) centerId = null;
  if (departmentId == 0) departmentId = null;
  if (doctorId == 0) doctorId = null;
  final historyIds = activities
      .map(asMap)
      .where((item) => text(item, 'activity_type') == 'history_taking')
      .map((item) => number(asMap(item['body_system']), 'id').toInt())
      .where((id) => id > 0)
      .toSet();
  final examIds = activities
      .map(asMap)
      .where((item) => text(item, 'activity_type') == 'clinical_examination')
      .map((item) => number(asMap(item['body_system']), 'id').toInt())
      .where((id) => id > 0)
      .toSet();
  final roundCases = TextEditingController(
    text: activities
        .map(asMap)
        .where((item) => text(item, 'activity_type') == 'round')
        .map((item) => text(item, 'case_name'))
        .where((value) => value.isNotEmpty)
        .join(', '),
  );
  final notes = TextEditingController(
    text: text(existing ?? {}, 'round_notes'),
  );
  final formKey = GlobalKey<FormState>();

  await showMoeenBottomSheet<void>(
    context: context,
    title: existing == null ? 'تسجيل بيانات اليوم' : 'تعديل سجل اليوم',
    icon: Icons.local_hospital_rounded,
    color: AppColors.royalBlue,
    child: StatefulBuilder(
      builder: (sheetContext, setLocal) {
        return Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ClinicalDropdown(
                label: 'مركز التدريب',
                value: centerId,
                items: centers,
                onChanged: (value) => setLocal(() => centerId = value),
              ),
              const SizedBox(height: 12),
              _ClinicalDropdown(
                label: 'القسم',
                value: departmentId,
                items: departments,
                onChanged: (value) => setLocal(() => departmentId = value),
              ),
              const SizedBox(height: 12),
              _ClinicalDropdown(
                label: 'الدكتور',
                value: doctorId,
                items: doctors,
                onChanged: (value) => setLocal(() => doctorId = value),
              ),
              const SizedBox(height: 16),
              _ClinicalPickerGroup(
                title: 'القصص المرضية',
                bodies: bodies,
                selected: historyIds,
                onToggle: (id) => setLocal(() {
                  historyIds.contains(id)
                      ? historyIds.remove(id)
                      : historyIds.add(id);
                }),
              ),
              const SizedBox(height: 14),
              _ClinicalPickerGroup(
                title: 'الفحوصات السريرية',
                bodies: bodies,
                selected: examIds,
                onToggle: (id) => setLocal(() {
                  examIds.contains(id) ? examIds.remove(id) : examIds.add(id);
                }),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: roundCases,
                decoration: const InputDecoration(
                  labelText: 'حالات المرور السريري',
                  hintText: 'افصل بين الحالات بفاصلة',
                  prefixIcon: Icon(Icons.groups_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notes,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات المرور',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () async {
                  if (!(formKey.currentState?.validate() ?? false)) return;
                  final isOnline = await ref
                      .read(connectivityServiceProvider)
                      .isOnline();
                  if (!isOnline) {
                    if (!sheetContext.mounted) return;
                    await showMoeenInfoDialog(
                      context: sheetContext,
                      title: 'لا يوجد اتصال بالإنترنت',
                      message: 'يرجى الاتصال بالإنترنت لتنفيذ هذه العملية.',
                      icon: Icons.wifi_off_rounded,
                      color: AppColors.danger,
                    );
                    return;
                  }
                  final rounds = roundCases.text
                      .split(',')
                      .map((value) => value.trim())
                      .where((value) => value.isNotEmpty)
                      .map((value) => {'case_name': value})
                      .toList();
                  final payload = {
                    'training_center_id': centerId,
                    'department_id': departmentId,
                    'doctor_id': doctorId,
                    'histories': historyIds
                        .map((id) => {'body_system_id': id})
                        .toList(),
                    'exams': examIds
                        .map((id) => {'body_system_id': id})
                        .toList(),
                    'did_round': rounds.isNotEmpty,
                    'rounds': rounds,
                    'round_notes': notes.text.trim(),
                  };
                  try {
                    if (existing == null) {
                      await ref
                          .read(studentContentRepositoryProvider)
                          .createClinicalLog(payload);
                    } else {
                      await ref
                          .read(studentContentRepositoryProvider)
                          .updateClinicalLog(
                            number(existing, 'id').toInt(),
                            payload,
                          );
                    }
                    ref.invalidate(_clinicalLogbookProvider);
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  } on ApiException catch (error) {
                    if (sheetContext.mounted) {
                      await showMoeenInfoDialog(
                        context: sheetContext,
                        title: 'تعذر حفظ السجل',
                        message: error.message,
                        icon: error.isOffline
                            ? Icons.wifi_off_rounded
                            : Icons.error_outline_rounded,
                        color: AppColors.danger,
                      );
                    }
                  } catch (_) {
                    if (sheetContext.mounted) {
                      await showMoeenInfoDialog(
                        context: sheetContext,
                        title: 'تعذر حفظ السجل',
                        message: 'حدث خطأ غير متوقع. حاول مرة أخرى.',
                        icon: Icons.error_outline_rounded,
                        color: AppColors.danger,
                      );
                    }
                  }
                },
                icon: const Icon(Icons.save_rounded),
                label: const Text('حفظ السجل'),
              ),
            ],
          ),
        );
      },
    ),
  );
}

bool _canAccessClinical(WidgetRef ref) {
  final dashboardClinical = ref
      .watch(studentDashboardControllerProvider)
      .valueOrNull
      ?.overview
      .hasClinical;
  if (dashboardClinical != null) return dashboardClinical;
  return ref.watch(authControllerProvider).valueOrNull?.hasClinical == true;
}

class _ClinicalDropdown extends StatelessWidget {
  const _ClinicalDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final int? value;
  final List<dynamic> items;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      value: value,
      validator: (value) => value == null ? 'هذا الحقل مطلوب' : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: items
          .map(asMap)
          .map(
            (item) => DropdownMenuItem<int>(
              value: number(item, 'id').toInt(),
              child: Text(text(item, 'name')),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _ClinicalPickerGroup extends StatelessWidget {
  const _ClinicalPickerGroup({
    required this.title,
    required this.bodies,
    required this.selected,
    required this.onToggle,
  });

  final String title;
  final List<dynamic> bodies;
  final Set<int> selected;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.midnight,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: bodies.map(asMap).map((item) {
            final id = number(item, 'id').toInt();
            final active = selected.contains(id);
            return FilterChip(
              selected: active,
              label: Text(text(item, 'name')),
              onSelected: (_) => onToggle(id),
            );
          }).toList(),
        ),
      ],
    );
  }
}

Future<void> _deleteClinicalLog(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> log,
) async {
  final ok = await showMoeenConfirmDialog(
    context: context,
    title: 'حذف السجل العملي',
    message: 'هل تريد حذف هذا السجل؟ لا يمكن حذف السجل بعد اعتماده.',
    confirmLabel: 'حذف',
    icon: Icons.delete_rounded,
    color: AppColors.danger,
  );
  if (!ok) return;
  await ref
      .read(studentContentRepositoryProvider)
      .deleteClinicalLog(number(log, 'id').toInt());
  ref.invalidate(_clinicalLogbookProvider);
}

Future<void> _submitClinicalAssignment(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> assignment,
) async {
  final controller = TextEditingController();
  await showMoeenBottomSheet<void>(
    context: context,
    title: 'إرسال إنجاز المهمة',
    icon: Icons.send_rounded,
    color: AppColors.teal,
    child: Column(
      children: [
        TextField(
          controller: controller,
          minLines: 4,
          maxLines: 6,
          decoration: const InputDecoration(
            labelText: 'ماذا أنجزت؟',
            hintText: 'اكتب رسالة واضحة للدكتور قبل الاعتماد.',
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () async {
              final message = controller.text.trim();
              if (message.length < 5) return;
              await ref
                  .read(studentContentRepositoryProvider)
                  .submitClinicalAssignment(
                    assignmentId: number(assignment, 'id').toInt(),
                    message: message,
                  );
              ref.invalidate(_clinicalLogbookProvider);
              if (context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.send_rounded),
            label: const Text('إرسال للمراجعة'),
          ),
        ),
      ],
    ),
  );
}

Future<void> _showCustomChecklistSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final title = TextEditingController();
  final description = TextEditingController();
  final items =
      <({TextEditingController description, TextEditingController marks})>[
        (
          description: TextEditingController(),
          marks: TextEditingController(text: '1'),
        ),
      ];
  final formKey = GlobalKey<FormState>();
  await showMoeenBottomSheet<void>(
    context: context,
    title: 'نموذج تدريبي مخصص',
    icon: Icons.playlist_add_rounded,
    color: AppColors.goldDeep,
    child: StatefulBuilder(
      builder: (sheetContext, setLocal) => Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: title,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'اكتب عنوان النموذج'
                  : null,
              decoration: const InputDecoration(labelText: 'عنوان النموذج'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: description,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'الوصف'),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < items.length; i++) ...[
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: items[i].description,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'مطلوب'
                          : null,
                      decoration: InputDecoration(labelText: 'العنصر ${i + 1}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: items[i].marks,
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          (num.tryParse(value ?? '') ?? 0) <= 0 ? 'درجة' : null,
                      decoration: const InputDecoration(labelText: 'الدرجة'),
                    ),
                  ),
                  IconButton(
                    onPressed: items.length == 1
                        ? null
                        : () => setLocal(() => items.removeAt(i)),
                    icon: const Icon(Icons.remove_circle_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            OutlinedButton.icon(
              onPressed: () => setLocal(
                () => items.add((
                  description: TextEditingController(),
                  marks: TextEditingController(text: '1'),
                )),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة عنصر'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) return;
                await ref
                    .read(studentContentRepositoryProvider)
                    .createClinicalCustomChecklist({
                      'title': title.text.trim(),
                      'description': description.text.trim(),
                      'items': items
                          .map(
                            (item) => {
                              'description': item.description.text.trim(),
                              'marks': num.parse(item.marks.text),
                            },
                          )
                          .toList(),
                    });
                ref.invalidate(_clinicalMockExamsProvider);
                if (sheetContext.mounted) Navigator.pop(sheetContext);
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text('حفظ النموذج'),
            ),
          ],
        ),
      ),
    ),
  );
}

String _clinicalActivityLabel(String value) {
  return switch (value) {
    'history_taking' => 'أخذ قصة مرضية',
    'clinical_examination' => 'فحص سريري',
    'follow_up' => 'متابعة',
    'round' => 'مرور سريري',
    _ => value.isEmpty ? '-' : value,
  };
}

String _clinicalStatusLabel(String value) {
  return switch (value) {
    'pending' => 'قيد الانتظار',
    'partially_confirmed' => 'اعتماد جزئي',
    'confirmed' => 'معتمد',
    'rejected' => 'مرفوض',
    'assigned' => 'مسندة',
    'submitted_for_review' => 'قيد المراجعة',
    'approved' => 'منجزة',
    'excellent' => 'ممتاز',
    'vgood' => 'جيد جدًا',
    'good' => 'جيد',
    'pass' => 'ناجح',
    'fail' => 'راسب',
    _ => value.isEmpty ? '-' : value,
  };
}

String _clinicalGrade(String value) => _clinicalStatusLabel(value);

Color _clinicalStatusColor(String value) {
  return switch (value) {
    'confirmed' ||
    'approved' ||
    'excellent' ||
    'vgood' ||
    'good' ||
    'pass' => AppColors.success,
    'partially_confirmed' ||
    'submitted_for_review' ||
    'pending' => AppColors.warning,
    'rejected' || 'fail' => AppColors.danger,
    _ => AppColors.royalBlue,
  };
}

class _ClinicalStatItem {
  const _ClinicalStatItem(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _ClinicalActionItem {
  const _ClinicalActionItem(
    this.title,
    this.subtitle,
    this.icon,
    this.route,
    this.color,
  );
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final Color color;
}
