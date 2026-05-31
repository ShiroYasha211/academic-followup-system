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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              children: [
                _ClinicalHeader(
                  title: 'مسارك السريري',
                  subtitle:
                      'إدارة السجل العملي، مهام الإنجاز، تقييمات الدكتور، الاختبارات التدريبية والحالات النادرة من مكان واحد.',
                  icon: Icons.local_hospital_rounded,
                  colors: const [AppColors.teal, Color(0xFF0D5E57)],
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
                      'التكليفات السريرية',
                      'كل تكليفات الحالات ومحاولاتك والباركود في مكان واحد',
                      Icons.assignment_turned_in_rounded,
                      StudentClinicalAssignmentsScreen.route,
                      AppColors.teal,
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
                _ClinicalSectionTitle(
                  'آخر السجلات',
                  Icons.history_rounded,
                ),
                const SizedBox(height: 10),
                if (logs.isEmpty)
                  const EmptyState(
                    message:
                        'لا توجد سجلات عملية حتى الآن.',
                  )
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
                  const EmptyState(
                    message: 'لا توجد مهام سريرية حالية.',
                  )
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

class StudentClinicalLogbookScreen extends ConsumerStatefulWidget {
  const StudentClinicalLogbookScreen({super.key});

  static const route = '/student/clinical/logbook';

  @override
  ConsumerState<StudentClinicalLogbookScreen> createState() =>
      _StudentClinicalLogbookScreenState();
}

class _StudentClinicalLogbookScreenState
    extends ConsumerState<StudentClinicalLogbookScreen> {
  String _selectedFilter = 'all'; // 'all', 'confirmed', 'pending', 'rejected'

  @override
  Widget build(BuildContext context) {
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
        onPressed: () async {
          final changed = await context.push<bool>(
            StudentClinicalLogFormScreen.path(),
          );
          if (changed == true) {
            ref.invalidate(_clinicalLogbookProvider);
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('تسجيل اليوم'),
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.teal.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        extendedTextStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
      ),
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_clinicalLogbookProvider),
        builder: (data) {
          final rawLogs = asList(data['logs']);
          final assignments = asList(data['assignments']);

          // Filter logs locally
          final filteredLogs = rawLogs.where((raw) {
            final log = asMap(raw);
            final status = text(log, 'status', fallback: 'pending');
            if (_selectedFilter == 'all') return true;
            if (_selectedFilter == 'confirmed') return status == 'confirmed';
            if (_selectedFilter == 'pending')
              return status == 'pending' || status == 'submitted_for_review';
            if (_selectedFilter == 'rejected') return status == 'rejected';
            return true;
          }).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_clinicalLogbookProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              children: [
                _ClinicalHeader(
                  title: 'سجل اليوم العملي',
                  subtitle:
                      'أدخل ما تم تنفيذه في اليوم، ثم اعرض QR للدكتور حتى يعتمد العناصر الفعلية والتشخيص.',
                  icon: Icons.qr_code_2_rounded,
                  colors: const [AppColors.teal, Color(0xFF0D5E57)],
                ),
                const SizedBox(height: 20),

                // Horizontal Filter Chips
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip('all', 'الكل', rawLogs.length),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'confirmed',
                        'معتمدة',
                        rawLogs
                            .where(
                              (l) => text(asMap(l), 'status') == 'confirmed',
                            )
                            .length,
                        AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'pending',
                        'معلقة',
                        rawLogs.where((l) {
                          final s = text(asMap(l), 'status');
                          return s == 'pending' || s == 'submitted_for_review';
                        }).length,
                        AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'rejected',
                        'مرفوضة',
                        rawLogs
                            .where(
                              (l) => text(asMap(l), 'status') == 'rejected',
                            )
                            .length,
                        AppColors.danger,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                _ClinicalSectionTitle(
                  'سجلاتك اليومية',
                  Icons.event_available,
                ),
                const SizedBox(height: 10),
                if (filteredLogs.isEmpty)
                  const EmptyState(
                    message:
                        'لا توجد سجلات عملية تطابق خيار التصفية.',
                  )
                else
                  ...filteredLogs.map(
                    (raw) => _ClinicalLogCard(log: asMap(raw)),
                  ),
                const SizedBox(height: 22),
                _ClinicalSectionTitle(
                  'مهام الإنجاز السريري',
                  Icons.assignment_turned_in_rounded,
                ),
                const SizedBox(height: 10),
                if (assignments.isEmpty)
                  const EmptyState(
                    message: 'لا توجد مهام سريرية حالية.',
                  )
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

  Widget _buildFilterChip(
    String value,
    String label,
    int count, [
    Color? activeColor,
  ]) {
    final selected = _selectedFilter == value;
    final color = activeColor ?? AppColors.teal;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = value),
      borderRadius: BorderRadius.circular(99),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected ? color : AppColors.slate200,
            width: selected ? 1.4 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.1),
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
              Icon(Icons.check_rounded, color: color, size: 14),
              const SizedBox(width: 4),
            ],
            Text(
              '$label ($count)',
              style: TextStyle(
                color: selected ? color : AppColors.slate600,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                fontSize: 12.5,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StudentClinicalLogFormScreen extends ConsumerStatefulWidget {
  const StudentClinicalLogFormScreen({super.key, this.assignmentId});

  static const route = '/student/clinical/logbook/create';

  final int? assignmentId;

  static String path({int? assignmentId}) {
    if (assignmentId == null || assignmentId <= 0) return route;
    return '$route?assignmentId=$assignmentId';
  }

  @override
  ConsumerState<StudentClinicalLogFormScreen> createState() =>
      _StudentClinicalLogFormScreenState();
}

class _StudentClinicalLogFormScreenState
    extends ConsumerState<StudentClinicalLogFormScreen> {
  final _notesController = TextEditingController();
  final _activitySearchController = TextEditingController();
  final List<TextEditingController> _roundControllers = [];
  final Set<int> _historyIds = {};
  final Set<int> _examIds = {};
  final Map<String, String> _errors = {};

  Timer? _draftTimer;
  int _step = 0;
  int? _centerId;
  int? _departmentId;
  int? _doctorId;
  bool _initialized = false;
  bool _saving = false;
  String _activitySearch = '';

  String get _draftKey {
    final suffix = widget.assignmentId == null
        ? 'manual'
        : 'assignment.${widget.assignmentId}';
    return 'student.clinical.logbook.create.$suffix';
  }

  @override
  void initState() {
    super.initState();
    _notesController.addListener(_scheduleDraftSave);
    _activitySearchController.addListener(() {
      setState(() => _activitySearch = _activitySearchController.text.trim());
    });
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    _notesController.dispose();
    _activitySearchController.dispose();
    for (final controller in _roundControllers) {
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
    final state = ref.watch(_clinicalLogbookProvider);
    return StudentShell(
      currentIndex: 34,
      title: 'تسجيل اليوم العملي',
      parentRoute: StudentClinicalLogbookScreen.route,
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_clinicalLogbookProvider),
        builder: (data) {
          _ensureInitialized(data);
          final assignment = _assignmentFromData(data);
          final options = asMap(data['form_options']);
          final centers = asList(options['training_centers']);
          final departments = asList(options['departments']);
          final bodies = asList(options['body_systems']).map(asMap).toList();
          final doctors = asList(options['doctors']);
          final assignmentMissing =
              widget.assignmentId != null && assignment.isEmpty;

          if (assignmentMissing) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 96),
              children: [
                const EmptyState(
                  message:
                      'لم يتم العثور على التكليف السريري المطلوب.',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.pop(false),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('العودة'),
                ),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
            children: [
              _ClinicalHeader(
                title: widget.assignmentId == null
                    ? 'تسجيل يوم عملي جديد'
                    : 'تنفيذ تكليف سريري',
                subtitle:
                    'سجل المكان والأنشطة وحالات المرور، ثم راجع البيانات قبل الحفظ وعرض الباركود للدكتور.',
                icon: Icons.fact_check_rounded,
                colors: const [AppColors.teal, Color(0xFF0D5E57)],
              ),
              const SizedBox(height: 14),
              _ClinicalLogStepIndicator(step: _step),
              const SizedBox(height: 16),
              if (assignment.isNotEmpty) ...[
                _ClinicalAssignmentAttemptBanner(assignment: assignment),
                const SizedBox(height: 14),
              ],
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: switch (_step) {
                    0 => _buildLocationStep(
                      assignment: assignment,
                      centers: centers,
                      departments: departments,
                      doctors: doctors,
                    ),
                    1 => _buildActivitiesStep(bodies),
                    2 => _buildRoundsStep(),
                    _ => _buildReviewStep(
                      assignment: assignment,
                      centers: centers,
                      departments: departments,
                      doctors: doctors,
                      bodies: bodies,
                    ),
                  },
                ),
              ),
              const SizedBox(height: 20),
              _buildFooterActions(
                data: data,
                assignment: assignment,
                centers: centers,
                departments: departments,
                doctors: doctors,
              ),
            ],
          );
        },
      ),
    );
  }

  void _ensureInitialized(Map<String, dynamic> data) {
    if (_initialized) return;
    _initialized = true;
    final assignment = _assignmentFromData(data);
    final clinicalCase = asMap(assignment['clinical_case']);
    _centerId = _idOrNull(asMap(clinicalCase['training_center']));
    _departmentId = _idOrNull(asMap(clinicalCase['clinical_department']));
    _doctorId = _idOrNull(asMap(assignment['assigner']));

    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreDraft());
  }

  Map<String, dynamic> _assignmentFromData(Map<String, dynamic> data) {
    final id = widget.assignmentId;
    if (id == null || id <= 0) return const {};
    for (final raw in asList(data['assignments'])) {
      final item = asMap(raw);
      if (number(item, 'id').toInt() == id) return item;
    }
    return const {};
  }

  int? _idOrNull(Map<String, dynamic> item) {
    final id = number(item, 'id').toInt();
    return id > 0 ? id : null;
  }

  Widget _buildLocationStep({
    required Map<String, dynamic> assignment,
    required List<dynamic> centers,
    required List<dynamic> departments,
    required List<dynamic> doctors,
  }) {
    final fixed = assignment.isNotEmpty;
    return _ClinicalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ClinicalFormTitle(
            icon: Icons.location_on_rounded,
            title: 'بيانات المكان والدكتور',
            subtitle: fixed
                ? 'تم تعبئة هذه البيانات من التكليف ولا يمكن تعديلها.'
                : 'اختر مكان التدريب والدكتور الذي سيعتمد السجل.',
          ),
          const SizedBox(height: 16),
          _ClinicalDropdown(
            label: 'مركز التدريب',
            value: _centerId,
            items: centers,
            onChanged: fixed ? null : (value) => _setLocation(center: value),
          ),
          _InlineFieldError(_errors['center']),
          const SizedBox(height: 12),
          _ClinicalDropdown(
            label: 'القسم',
            value: _departmentId,
            items: departments,
            onChanged: fixed
                ? null
                : (value) => _setLocation(department: value),
          ),
          _InlineFieldError(_errors['department']),
          const SizedBox(height: 12),
          _ClinicalDropdown(
            label: 'الدكتور',
            value: _doctorId,
            items: doctors,
            onChanged: fixed ? null : (value) => _setLocation(doctor: value),
          ),
          _InlineFieldError(_errors['doctor']),
        ],
      ),
    );
  }

  Widget _buildActivitiesStep(List<Map<String, dynamic>> bodies) {
    final filtered = _filteredBodies(bodies);
    return Column(
      children: [
        _ClinicalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _ClinicalFormTitle(
                icon: Icons.checklist_rounded,
                title: 'الأنشطة المنفذة',
                subtitle:
                    'اختر القصص المرضية والفحوصات السريرية التي أنجزتها اليوم.',
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _activitySearchController,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  labelText: 'بحث داخل أنظمة الجسم',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.teal,
                  ),
                  filled: true,
                  fillColor: AppColors.slate50,
                  floatingLabelStyle: const TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.teal,
                    fontWeight: FontWeight.w800,
                  ),
                  labelStyle: const TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.slate500,
                    fontSize: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.slate200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.teal,
                      width: 1.6,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ClinicalCounterChip(
                    label: 'قصص مرضية',
                    value: _historyIds.length,
                    color: AppColors.royalBlue,
                  ),
                  _ClinicalCounterChip(
                    label: 'فحوصات سريرية',
                    value: _examIds.length,
                    color: AppColors.teal,
                  ),
                  _ClinicalCounterChip(
                    label: 'حالات مرور',
                    value: _activeRounds.length,
                    color: AppColors.goldDeep,
                  ),
                ],
              ),
              _InlineFieldError(_errors['activities']),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ActivitySelectionPanel(
          title: 'القصص المرضية',
          icon: Icons.history_edu_rounded,
          bodies: filtered,
          selected: _historyIds,
          color: AppColors.royalBlue,
          onToggle: _toggleHistory,
        ),
        const SizedBox(height: 12),
        _ActivitySelectionPanel(
          title: 'الفحوصات السريرية',
          icon: Icons.health_and_safety_rounded,
          bodies: filtered,
          selected: _examIds,
          color: AppColors.teal,
          onToggle: _toggleExam,
        ),
      ],
    );
  }

  Widget _buildRoundsStep() {
    return _ClinicalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ClinicalFormTitle(
            icon: Icons.groups_rounded,
            title: 'حالات المرور والملاحظات',
            subtitle:
                'أضف كل حالة مرور في حقل مستقل بدل الكتابة بفواصل، ثم اكتب أي ملاحظات مهمة.',
          ),
          const SizedBox(height: 14),
          if (_roundControllers.isEmpty)
            const EmptyState(
              message: 'لم تتم إضافة حالات مرور بعد.',
            )
          else
            ..._roundControllers.asMap().entries.map((entry) {
              final index = entry.key;
              final controller = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        onChanged: (_) => _scheduleDraftSave(),
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          labelText: 'حالة مرور ${index + 1}',
                          prefixIcon: const Icon(
                            Icons.person_search_rounded,
                            color: AppColors.teal,
                          ),
                          filled: true,
                          fillColor: AppColors.slate50,
                          floatingLabelStyle: const TextStyle(
                            fontFamily: 'Cairo',
                            color: AppColors.teal,
                            fontWeight: FontWeight.w800,
                          ),
                          labelStyle: const TextStyle(
                            fontFamily: 'Cairo',
                            color: AppColors.slate500,
                            fontSize: 12,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.slate200,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.teal,
                              width: 1.6,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: () => _removeRound(index),
                      icon: const Icon(Icons.close_rounded),
                      color: AppColors.danger,
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: _addRound,
            icon: const Icon(Icons.add_rounded),
            label: const Text('إضافة حالة مرور'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'ملاحظات المرور',
              prefixIcon: Icon(Icons.notes_rounded),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep({
    required Map<String, dynamic> assignment,
    required List<dynamic> centers,
    required List<dynamic> departments,
    required List<dynamic> doctors,
    required List<Map<String, dynamic>> bodies,
  }) {
    final historyNames = _namesForIds(bodies, _historyIds);
    final examNames = _namesForIds(bodies, _examIds);
    return Column(
      children: [
        _ClinicalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _ClinicalFormTitle(
                icon: Icons.fact_check_rounded,
                title: 'مراجعة قبل الحفظ',
                subtitle:
                    'تأكد من البيانات. بعد الحفظ سيظهر سجل اليوم والباركود مباشرة.',
              ),
              const SizedBox(height: 14),
              _ClinicalDetailRow(
                'مركز التدريب',
                _optionName(centers, _centerId),
              ),
              _ClinicalDetailRow(
                'القسم',
                _optionName(departments, _departmentId),
              ),
              _ClinicalDetailRow(
                'الدكتور',
                _optionName(doctors, _doctorId),
              ),
              if (assignment.isNotEmpty)
                _ClinicalDetailRow(
                  'التكليف',
                  text(
                    asMap(assignment['clinical_case']),
                    'patient_name',
                    fallback: text(
                      assignment,
                      'task_type_label',
                      fallback: '-',
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ReviewListCard(
          title: 'القصص المرضية',
          icon: Icons.history_edu_rounded,
          values: historyNames,
        ),
        const SizedBox(height: 12),
        _ReviewListCard(
          title: 'الفحوصات السريرية',
          icon: Icons.health_and_safety_rounded,
          values: examNames,
        ),
        const SizedBox(height: 12),
        _ReviewListCard(
          title: 'حالات المرور',
          icon: Icons.groups_rounded,
          values: _activeRounds,
        ),
        if (_notesController.text.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          _ClinicalCard(
            child: _ClinicalDetailRow(
              'ملاحظات المرور',
              _notesController.text.trim(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFooterActions({
    required Map<String, dynamic> data,
    required Map<String, dynamic> assignment,
    required List<dynamic> centers,
    required List<dynamic> departments,
    required List<dynamic> doctors,
  }) {
    return Row(
      children: [
        if (_step > 0)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _saving ? null : () => setState(() => _step--),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text(
                'السابق',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: const BorderSide(color: AppColors.slate300),
                foregroundColor: AppColors.slate600,
              ),
            ),
          ),
        if (_step > 0) const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: _saving
                ? null
                : _step < 3
                ? _goNext
                : () => _save(data, assignment),
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    _step < 3
                        ? Icons.arrow_forward_rounded
                        : Icons.save_rounded,
                    size: 18,
                  ),
            label: Text(
              _step < 3 ? 'التالي' : 'حفظ وعرض الباركود',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _filteredBodies(
    List<Map<String, dynamic>> bodies,
  ) {
    final query = _activitySearch.toLowerCase();
    if (query.isEmpty) return bodies;
    return bodies
        .where((body) => text(body, 'name').toLowerCase().contains(query))
        .toList();
  }

  List<String> _namesForIds(List<Map<String, dynamic>> bodies, Set<int> ids) {
    return bodies
        .where((body) => ids.contains(number(body, 'id').toInt()))
        .map((body) => text(body, 'name'))
        .where((name) => name.isNotEmpty)
        .toList();
  }

  List<String> get _activeRounds => _roundControllers
      .map((controller) => controller.text.trim())
      .where((value) => value.isNotEmpty)
      .toList();

  String _optionName(List<dynamic> items, int? id) {
    if (id == null) return '-';
    for (final raw in items) {
      final item = asMap(raw);
      if (number(item, 'id').toInt() == id)
        return text(item, 'name', fallback: '-');
    }
    return '-';
  }

  void _setLocation({int? center, int? department, int? doctor}) {
    setState(() {
      if (center != null) _centerId = center;
      if (department != null) _departmentId = department;
      if (doctor != null) _doctorId = doctor;
      _errors.remove('center');
      _errors.remove('department');
      _errors.remove('doctor');
    });
    _scheduleDraftSave();
  }

  void _toggleHistory(int id) {
    setState(() {
      _historyIds.contains(id) ? _historyIds.remove(id) : _historyIds.add(id);
      _errors.remove('activities');
    });
    _scheduleDraftSave();
  }

  void _toggleExam(int id) {
    setState(() {
      _examIds.contains(id) ? _examIds.remove(id) : _examIds.add(id);
      _errors.remove('activities');
    });
    _scheduleDraftSave();
  }

  void _addRound([String value = '']) {
    final controller = TextEditingController(text: value);
    controller.addListener(_scheduleDraftSave);
    setState(() {
      _roundControllers.add(controller);
      _errors.remove('activities');
    });
    _scheduleDraftSave();
  }

  void _removeRound(int index) {
    final controller = _roundControllers.removeAt(index);
    controller.dispose();
    setState(() {});
    _scheduleDraftSave();
  }

  void _goNext() {
    if (_step == 0 && !_validateLocation()) return;
    if (_step == 1 && !_validateActivities()) return;
    setState(() => _step++);
  }

  bool _validateLocation() {
    final nextErrors = <String, String>{};
    if (_centerId == null)
      nextErrors['center'] = 'اختر مركز التدريب.';
    if (_departmentId == null)
      nextErrors['department'] = 'اختر القسم.';
    if (_doctorId == null) nextErrors['doctor'] = 'اختر الدكتور.';
    setState(() {
      _errors
        ..remove('center')
        ..remove('department')
        ..remove('doctor')
        ..addAll(nextErrors);
    });
    return nextErrors.isEmpty;
  }

  bool _validateActivities() {
    final ok =
        _historyIds.isNotEmpty ||
        _examIds.isNotEmpty ||
        _activeRounds.isNotEmpty;
    setState(() {
      if (ok) {
        _errors.remove('activities');
      } else {
        _errors['activities'] =
            'اختر نشاطًا واحدًا على الأقل أو أضف حالة مرور.';
      }
    });
    return ok;
  }

  Future<void> _save(
    Map<String, dynamic> data,
    Map<String, dynamic> assignment,
  ) async {
    if (!_validateLocation() || !_validateActivities()) return;
    final isOnline = await ref.read(connectivityServiceProvider).isOnline();
    if (!isOnline) {
      if (!mounted) return;
      await showMoeenInfoDialog(
        context: context,
        title: 'لا يوجد اتصال بالإنترنت',
        message:
            'يرجى الاتصال بالإنترنت لحفظ سجل اليوم العملي.',
        icon: Icons.wifi_off_rounded,
        color: AppColors.danger,
      );
      return;
    }

    setState(() => _saving = true);
    final rounds = _activeRounds.map((value) => {'case_name': value}).toList();
    final payload = {
      if (widget.assignmentId != null)
        'case_assignment_id': widget.assignmentId,
      'training_center_id': _centerId,
      'department_id': _departmentId,
      'doctor_id': _doctorId,
      'histories': _historyIds.map((id) => {'body_system_id': id}).toList(),
      'exams': _examIds.map((id) => {'body_system_id': id}).toList(),
      'did_round': rounds.isNotEmpty,
      'rounds': rounds,
      'round_notes': _notesController.text.trim(),
    };

    try {
      final saved = await ref
          .read(studentContentRepositoryProvider)
          .createClinicalLog(payload);
      await _clearDraft();
      ref.invalidate(_clinicalLogbookProvider);
      if (!mounted) return;
      await showMoeenBottomSheet<void>(
        context: context,
        title: 'تفاصيل السجل العملي',
        icon: Icons.qr_code_2_rounded,
        color: AppColors.royalBlue,
        child: _ClinicalLogDetailsPanel(initialLog: saved),
      );
      if (mounted) context.pop(true);
    } on ApiException catch (error) {
      if (mounted) {
        await showMoeenInfoDialog(
          context: context,
          title: 'تعذر حفظ السجل',
          message: error.message,
          icon: error.isOffline
              ? Icons.wifi_off_rounded
              : Icons.error_outline_rounded,
          color: AppColors.danger,
        );
      }
    } catch (_) {
      if (mounted) {
        await showMoeenInfoDialog(
          context: context,
          title: 'تعذر حفظ السجل',
          message: 'حدث خطأ غير متوقع. حاول مرة أخرى.',
          icon: Icons.error_outline_rounded,
          color: AppColors.danger,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _scheduleDraftSave() {
    if (!_initialized || _saving) return;
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 450), _saveDraft);
  }

  Future<void> _restoreDraft() async {
    try {
      final raw = await ref.read(secureStorageProvider).read(key: _draftKey);
      if (raw == null || raw.isEmpty || !mounted) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      setState(() {
        if (widget.assignmentId == null) {
          _centerId = decoded['center_id'] as int? ?? _centerId;
          _departmentId = decoded['department_id'] as int? ?? _departmentId;
          _doctorId = decoded['doctor_id'] as int? ?? _doctorId;
        }
        _historyIds
          ..clear()
          ..addAll(
            asList(decoded['histories'])
                .map((value) => int.tryParse(value.toString()) ?? 0)
                .where((id) => id > 0),
          );
        _examIds
          ..clear()
          ..addAll(
            asList(decoded['exams'])
                .map((value) => int.tryParse(value.toString()) ?? 0)
                .where((id) => id > 0),
          );
        for (final controller in _roundControllers) {
          controller.dispose();
        }
        _roundControllers.clear();
        for (final value in asList(decoded['rounds'])) {
          final text = value.toString().trim();
          if (text.isNotEmpty)
            _roundControllers.add(
              TextEditingController(text: text)
                ..addListener(_scheduleDraftSave),
            );
        }
        _notesController.text = decoded['notes']?.toString() ?? '';
      });
    } catch (_) {
      // A broken draft should never block the student from creating a log.
    }
  }

  Future<void> _saveDraft() async {
    final payload = {
      'center_id': _centerId,
      'department_id': _departmentId,
      'doctor_id': _doctorId,
      'histories': _historyIds.toList(),
      'exams': _examIds.toList(),
      'rounds': _activeRounds,
      'notes': _notesController.text,
      'updated_at': DateTime.now().toIso8601String(),
    };
    await ref
        .read(secureStorageProvider)
        .write(key: _draftKey, value: jsonEncode(payload));
  }

  Future<void> _clearDraft() {
    _draftTimer?.cancel();
    return ref.read(secureStorageProvider).delete(key: _draftKey);
  }
}

class _ClinicalLogStepIndicator extends StatelessWidget {
  const _ClinicalLogStepIndicator({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final steps = const [
      ('المكان', Icons.location_on_rounded),
      ('الأنشطة', Icons.checklist_rounded),
      ('المرور', Icons.groups_rounded),
      ('المراجعة', Icons.fact_check_rounded),
    ];
    return Row(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final active = index == step;
        final done = index < step;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: EdgeInsetsDirectional.only(
              end: index == steps.length - 1 ? 0 : 6,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: active || done
                  ? AppColors.teal.withValues(alpha: 0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active || done ? AppColors.teal : AppColors.slate200,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  done ? Icons.check_circle_rounded : item.$2,
                  size: 18,
                  color: active || done ? AppColors.teal : AppColors.slate400,
                ),
                const SizedBox(height: 4),
                Text(
                  item.$1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Cairo',
                    color: active || done ? AppColors.teal : AppColors.slate500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ClinicalFormTitle extends StatelessWidget {
  const _ClinicalFormTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ClinicalIconBubble(icon, AppColors.teal),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.midnight,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.slate600,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InlineFieldError extends StatelessWidget {
  const _InlineFieldError(this.message);

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        message!,
        style: const TextStyle(
          color: AppColors.danger,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }
}

class _ClinicalCounterChip extends StatelessWidget {
  const _ClinicalCounterChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }
}

class _ActivitySelectionPanel extends StatelessWidget {
  const _ActivitySelectionPanel({
    required this.title,
    required this.icon,
    required this.bodies,
    required this.selected,
    required this.color,
    required this.onToggle,
  });

  final String title;
  final IconData icon;
  final List<Map<String, dynamic>> bodies;
  final Set<int> selected;
  final Color color;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return _ClinicalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.midnight,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              _ClinicalCounterChip(
                label: 'المحدد',
                value: selected.length,
                color: color,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (bodies.isEmpty)
            const EmptyState(
              message: 'لا توجد نتائج مطابقة للبحث.',
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: bodies.map((item) {
                final id = number(item, 'id').toInt();
                final active = selected.contains(id);
                return FilterChip(
                  selected: active,
                  showCheckmark: true,
                  label: Text(text(item, 'name')),
                  onSelected: (_) => onToggle(id),
                  selectedColor: color.withValues(alpha: 0.14),
                  checkmarkColor: color,
                  side: BorderSide(color: active ? color : AppColors.slate200),
                  labelStyle: TextStyle(
                    color: active ? color : AppColors.slate700,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Cairo',
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _ReviewListCard extends StatelessWidget {
  const _ReviewListCard({
    required this.title,
    required this.icon,
    required this.values,
  });

  final String title;
  final IconData icon;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return _ClinicalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ClinicalSectionTitle('$title (${values.length})', icon),
          const SizedBox(height: 10),
          if (values.isEmpty)
            const Text(
              'لا توجد عناصر.',
              style: TextStyle(
                color: AppColors.slate500,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            ...values.map(
              (value) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        value,
                        style: const TextStyle(
                          color: AppColors.slate800,
                          fontWeight: FontWeight.w800,
                        ),
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
}

class StudentClinicalAssignmentsScreen extends ConsumerWidget {
  const StudentClinicalAssignmentsScreen({super.key});

  static const route = '/student/clinical/assignments';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canAccess = _canAccessClinical(ref);
    if (!canAccess) {
      return const _ClinicalForbiddenShell();
    }
    final state = ref.watch(_clinicalLogbookProvider);
    return StudentShell(
      currentIndex: 34,
      title: 'التكليفات السريرية',
      parentRoute: StudentClinicalScreen.route,
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_clinicalLogbookProvider),
        builder: (data) {
          final assignments = asList(data['assignments']).map(asMap).toList();
          final pending = assignments
              .where((item) => text(item, 'status') != 'approved')
              .length;
          final approved = assignments
              .where((item) => text(item, 'status') == 'approved')
              .length;
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_clinicalLogbookProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              children: [
                _ClinicalHeader(
                  title: 'تكليفات الحالات السريرية',
                  subtitle:
                      'راجع التكليف، نفذ المحاولة العملية، ثم اعرض الباركود للدكتور للاعتماد.',
                  icon: Icons.assignment_turned_in_rounded,
                  colors: const [AppColors.teal, Color(0xFF0D5E57)],
                ),
                const SizedBox(height: 18),
                _ClinicalStatsRow(
                  items: [
                    _ClinicalStatItem(
                      'كل التكليفات',
                      '${assignments.length}',
                      Icons.assignment_rounded,
                      AppColors.royalBlue,
                    ),
                    _ClinicalStatItem(
                      'تحتاج متابعة',
                      '$pending',
                      Icons.pending_actions_rounded,
                      AppColors.warning,
                    ),
                    _ClinicalStatItem(
                      'معتمدة',
                      '$approved',
                      Icons.verified_rounded,
                      AppColors.success,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (assignments.isEmpty)
                  const EmptyState(
                    message:
                        'لا توجد تكليفات سريرية حاليًا.',
                  )
                else
                  ...assignments.map(
                    (item) => _ClinicalAssignmentCard(item: item),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class StudentClinicalEvaluationsScreen extends ConsumerStatefulWidget {
  const StudentClinicalEvaluationsScreen({super.key});

  static const route = '/student/clinical/evaluations';
  static String detailsPath(int id) => '/student/clinical/evaluations/$id';

  @override
  ConsumerState<StudentClinicalEvaluationsScreen> createState() =>
      _StudentClinicalEvaluationsScreenState();
}

class _StudentClinicalEvaluationsScreenState
    extends ConsumerState<StudentClinicalEvaluationsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _grade = 'all';
  String _doctor = 'all';
  String _sort = 'latest';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          final radar = asList(data['radar_chart']).map(asMap).toList();
          final allEvaluations = asList(
            data['evaluations'],
          ).map(asMap).toList();
          final evaluations = _filteredEvaluations(allEvaluations);
          final doctors = _doctorOptions(allEvaluations);
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_clinicalEvaluationsProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              children: [
                _ClinicalHeader(
                  title: 'تقييمات الدكتور',
                  subtitle:
                      'تابع درجاتك وملاحظات الدكاترة وتفاصيل كل بند في التقييم السريري.',
                  icon: Icons.radar_rounded,
                  colors: const [AppColors.teal, Color(0xFF0D5E57)],
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
                _ClinicalSkillsOverview(radar: radar),
                const SizedBox(height: 20),
                _ClinicalEvaluationFilters(
                  searchController: _searchController,
                  grade: _grade,
                  doctor: _doctor,
                  sort: _sort,
                  doctors: doctors,
                  onGradeChanged: (value) => setState(() => _grade = value),
                  onDoctorChanged: (value) => setState(() => _doctor = value),
                  onSortChanged: (value) => setState(() => _sort = value),
                ),
                const SizedBox(height: 18),
                _ClinicalSectionTitle('سجل التقييمات', Icons.history),
                const SizedBox(height: 10),
                if (allEvaluations.isEmpty)
                  const _ClinicalEmptyEvaluationsState()
                else if (evaluations.isEmpty)
                  const EmptyState(
                    message: 'لا توجد تقييمات تطابق خيارات البحث الحالية.',
                  )
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

  List<Map<String, dynamic>> _filteredEvaluations(
    List<Map<String, dynamic>> evaluations,
  ) {
    final filtered = evaluations.where((item) {
      final checklist = asMap(item['checklist']);
      final doctor = asMap(item['doctor']);
      final matchesQuery =
          _query.isEmpty ||
          text(checklist, 'title').toLowerCase().contains(_query) ||
          text(doctor, 'name').toLowerCase().contains(_query);
      final matchesGrade = _grade == 'all' || text(item, 'grade') == _grade;
      final doctorId = number(doctor, 'id').toInt().toString();
      final matchesDoctor = _doctor == 'all' || doctorId == _doctor;
      return matchesQuery && matchesGrade && matchesDoctor;
    }).toList();

    filtered.sort((a, b) {
      final aDate = DateTime.tryParse(text(a, 'created_at')) ?? DateTime(1900);
      final bDate = DateTime.tryParse(text(b, 'created_at')) ?? DateTime(1900);
      return _sort == 'oldest'
          ? aDate.compareTo(bDate)
          : bDate.compareTo(aDate);
    });
    return filtered;
  }

  List<MapEntry<String, String>> _doctorOptions(
    List<Map<String, dynamic>> evaluations,
  ) {
    final map = <String, String>{};
    for (final item in evaluations) {
      final doctor = asMap(item['doctor']);
      final id = number(doctor, 'id').toInt();
      if (id > 0) map[id.toString()] = text(doctor, 'name', fallback: '-');
    }
    final options = map.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return options;
  }
}

class StudentClinicalEvaluationDetailsScreen extends ConsumerWidget {
  const StudentClinicalEvaluationDetailsScreen({
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
    final state = ref.watch(_clinicalEvaluationProvider(evaluationId));
    return StudentShell(
      currentIndex: 34,
      title: 'تفاصيل التقييم',
      parentRoute: StudentClinicalEvaluationsScreen.route,
      child: _AsyncBody(
        state: state,
        onRetry: () =>
            ref.invalidate(_clinicalEvaluationProvider(evaluationId)),
        builder: (data) {
          final evaluation = asMap(data['evaluation']);
          final checklist = asMap(evaluation['checklist']);
          final doctor = asMap(evaluation['doctor']);
          final scores = asList(evaluation['scores']).map(asMap).toList();
          final color = _clinicalStatusColor(text(evaluation, 'grade'));
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(_clinicalEvaluationProvider(evaluationId)),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              children: [
                _ClinicalHeader(
                  title: text(checklist, 'title', fallback: 'تفاصيل التقييم'),
                  subtitle: 'د. ${text(doctor, 'name', fallback: '-')}',
                  icon: Icons.fact_check_rounded,
                  colors: const [AppColors.teal, Color(0xFF0D5E57)],
                ),
                const SizedBox(height: 16),
                _ClinicalCard(
                  child: Column(
                    children: [
                      Text(
                        '${text(evaluation, 'percentage', fallback: '0')}%',
                        style: TextStyle(
                          color: color,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 8),
                      _ClinicalStatusBadge(text(evaluation, 'grade')),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _ClinicalInfoPill(
                            label: 'الدرجة',
                            value:
                                '${_formatClinicalMark(number(evaluation, 'total_score').toDouble())} / ${_formatClinicalMark(number(evaluation, 'max_score').toDouble())}',
                          ),
                          _ClinicalInfoPill(
                            label: 'الوقت',
                            value: text(
                              evaluation,
                              'formatted_time',
                              fallback: '-',
                            ),
                          ),
                          _ClinicalInfoPill(
                            label: 'التاريخ',
                            value: dateOnly(text(evaluation, 'created_at')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (text(evaluation, 'doctor_feedback').trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _ClinicalCard(
                    child: _ClinicalDetailRow(
                      'ملاحظات الدكتور',
                      text(evaluation, 'doctor_feedback'),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                _ClinicalSectionTitle('بنود التقييم', Icons.checklist_rounded),
                const SizedBox(height: 10),
                if (scores.isEmpty)
                  const EmptyState(
                    message: 'لا توجد بنود تفصيلية لهذا التقييم.',
                  )
                else
                  ...scores.asMap().entries.map(
                    (entry) => _ClinicalEvaluationScoreCard(
                      index: entry.key + 1,
                      item: entry.value,
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
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.teal.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        extendedTextStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              children: [
                _ClinicalHeader(
                  title: 'اختبارات تدريبية',
                  subtitle:
                      'تدرب على قوائم التقييم العامة أو قوائم أنشأها الدكتور أو أنشئ نموذجك الخاص.',
                  icon: Icons.fact_check_rounded,
                  colors: const [AppColors.teal, Color(0xFF0D5E57)],
                ),
                const SizedBox(height: 20),
                _ClinicalSectionTitle(
                  'النماذج المتاحة',
                  Icons.list_alt,
                ),
                const SizedBox(height: 10),
                if (checklists.isEmpty)
                  const EmptyState(
                    message:
                        'لا توجد نماذج تدريبية متاحة.',
                  )
                else
                  ...checklists.map(
                    (raw) => _ClinicalChecklistCard(item: asMap(raw)),
                  ),
                const SizedBox(height: 22),
                _ClinicalSectionTitle(
                  'محاولاتك السابقة',
                  Icons.history,
                ),
                const SizedBox(height: 10),
                if (attempts.isEmpty)
                  const EmptyState(
                    message:
                        'لا توجد محاولات تدريبية بعد.',
                  )
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
  final Set<int> _expandedNotes = {};
  double _fontSizeScale = 1.0;
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

  List<Map<String, dynamic>> _buildItemsTree(List<dynamic> flatItems) {
    final Map<int, Map<String, dynamic>> itemsMap = {};
    final List<Map<String, dynamic>> rootItems = [];

    for (final raw in flatItems) {
      final item = Map<String, dynamic>.from(asMap(raw));
      item['sub_items'] = <Map<String, dynamic>>[];
      final id = number(item, 'id').toInt();
      itemsMap[id] = item;
    }

    for (final item in itemsMap.values) {
      final parentId = number(item, 'parent_id').toInt();
      if (parentId > 0 && itemsMap.containsKey(parentId)) {
        final parent = itemsMap[parentId]!;
        final List<Map<String, dynamic>> subs = List<Map<String, dynamic>>.from(
          parent['sub_items'],
        );
        subs.add(item);
        parent['sub_items'] = subs;
      } else {
        rootItems.add(item);
      }
    }

    return rootItems;
  }

  Widget _evaluationGroup(int index, Map<String, dynamic> parent) {
    final subs = asList(parent['sub_items']);
    final children = subs.isEmpty ? [parent] : subs;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  'المجموعة ${index + 1}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.teal,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text(
                    parent,
                    'description',
                    fallback: 'عنصر التقييم',
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.midnight,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20, thickness: 1, color: AppColors.slate200),
          ...children.map((raw) => _scoreableItem(asMap(raw))),
        ],
      ),
    );
  }

  Widget _scoreableItem(Map<String, dynamic> item) {
    final id = number(item, 'id').toInt();
    final current = _scores[id] ?? 'not_done';
    final note = _notes.putIfAbsent(id, () => TextEditingController());
    final isExpanded = _expandedNotes.contains(id);
    final hasNote = note.text.trim().isNotEmpty;
    final description = text(
      item,
      'description',
      fallback: 'عنصر فرعي',
    );
    final adaptiveIcon = _getAdaptiveIcon(description);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(adaptiveIcon, size: 13, color: AppColors.teal),
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
              _ClinicalMiniBadge(
                '${number(item, 'marks', fallback: 1).toInt()} درجة',
              ),
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
                  color: hasNote ? AppColors.teal : AppColors.slate400,
                ),
                label: Text(
                  hasNote
                      ? 'تعديل الملاحظة'
                      : 'إضافة ملاحظة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: hasNote ? AppColors.teal : AppColors.slate500,
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
                  borderSide: const BorderSide(color: AppColors.teal),
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
        t.contains('ط¶ط؛ط·') ||
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
          final itemsTree = _buildItemsTree(items);
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
                fallback:
                    'اختر طريقة حساب الوقت قبل بدء التدريب.',
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'بنود التقييم السريري',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppColors.midnight,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
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
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
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
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
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
              const SizedBox(height: 10),
              if (itemsTree.isEmpty)
                const EmptyState(
                  message: 'لا توجد بنود في هذا النموذج.',
                )
              else
                ...itemsTree.asMap().entries.map((entry) {
                  return _evaluationGroup(entry.key, entry.value);
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
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
              content: Text(
                'انتهى وقت التدريب وتم تسليم النتيجة.',
              ),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
      children: [
        _ClinicalHeader(
          title: title,
          subtitle: description,
          icon: Icons.timer_rounded,
          colors: const [AppColors.teal, Color(0xFF0D5E57)],
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
                subtitle:
                    '$officialMinutes دقيقة مثل إعداد الويب',
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
              _ClinicalSectionTitle(
                'تفاصيل العناصر',
                Icons.checklist_rounded,
              ),
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
                  const EmptyState(
                    message: 'لا توجد حالات نادرة نشطة.',
                  )
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
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
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    height: 1.45,
                    fontFamily: 'Cairo',
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
                  height: 98,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: item.color.withValues(alpha: 0.15),
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: item.color.withValues(alpha: 0.055),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        children: [
                          Positioned(
                            left: -18,
                            top: -18,
                            child: Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: item.color.withValues(alpha: 0.12),
                                    blurRadius: 22,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 20,
                            right: 20,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: item.color,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(3),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.slate500,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.value,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.midnight,
                                          fontSize: 23,
                                          fontWeight: FontWeight.w900,
                                          height: 1.2,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: item.color.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    item.icon,
                                    color: item.color,
                                    size: 20,
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
            (action) => Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: action.color.withValues(alpha: 0.12),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: action.color.withValues(alpha: 0.03),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.push(action.route),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: action.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              action.icon,
                              color: action.color,
                              size: 20,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            action.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Cairo',
                              color: AppColors.slate900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            action.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.slate500,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              height: 1.35,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

void _showQuickQrDialog(BuildContext context, Map<String, dynamic> log) {
  final qrToken = text(log, 'qr_token');
  final expiresAt = text(log, 'qr_expires_at');
  final expired = boolValue(log, 'is_qr_expired');
  final dept = asMap(log['department']);
  final doctor = asMap(log['doctor']);

  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'مسح سريع - ${text(dept, 'name', fallback: 'سجل عملي')}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      fontFamily: 'Cairo',
                      color: AppColors.midnight,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'الدكتور: ${text(doctor, 'name', fallback: '-')}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                fontFamily: 'Cairo',
                color: AppColors.slate600,
              ),
            ),
            const SizedBox(height: 16),
            _ClinicalQrBox(
              token: qrToken,
              expiresAt: expiresAt,
              expired: expired,
            ),
          ],
        ),
      ),
    ),
  );
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
    final qrToken = text(log, 'qr_token');

    final statusColor = switch (status) {
      'confirmed' || 'approved' => AppColors.success,
      'rejected' => AppColors.danger,
      'pending' || 'submitted_for_review' => AppColors.warning,
      _ => AppColors.slate300,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.15),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showClinicalLogDetails(context, ref, log),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.fact_check_rounded,
                          color: statusColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          text(department, 'name', fallback: 'قسم عملي'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Cairo',
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
                      fontSize: 12,
                      fontFamily: 'Cairo',
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
                      if (qrToken.isNotEmpty &&
                          status != 'confirmed' &&
                          status != 'rejected')
                        const _ClinicalMiniBadge('QR جاهز'),
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () =>
                            _showClinicalLogDetails(context, ref, log),
                        icon: const Icon(Icons.info_outline_rounded, size: 16),
                        label: const Text(
                          'التفاصيل والملخص',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (qrToken.isNotEmpty &&
                          status != 'confirmed' &&
                          status != 'rejected')
                        FilledButton.icon(
                          onPressed: () => _showQuickQrDialog(context, log),
                          icon: const Icon(
                            Icons.qr_code_scanner_rounded,
                            size: 16,
                          ),
                          label: const Text(
                            'مسح سريع',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (canChange) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showClinicalLogSheet(
                              context,
                              ref,
                              existing: log,
                            ),
                            icon: const Icon(Icons.edit_rounded, size: 16),
                            label: const Text(
                              'تعديل',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _deleteClinicalLog(context, ref, log),
                            icon: const Icon(Icons.delete_rounded, size: 16),
                            label: const Text(
                              'حذف',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side: const BorderSide(color: AppColors.danger),
                            ),
                          ),
                        ),
                      ],
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

void _showClinicalLogDetails(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> log,
) {
  showMoeenBottomSheet(
    context: context,
    title: 'تفاصيل السجل العملي',
    icon: Icons.qr_code_2_rounded,
    color: AppColors.teal,
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
                  fontFamily: 'Cairo',
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.slate50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Column(
            children: [
              _ClinicalDetailRow(
                'المركز',
                text(center, 'name', fallback: '-'),
              ),
              const Divider(height: 16, color: AppColors.slate200),
              _ClinicalDetailRow(
                'القسم',
                text(department, 'name', fallback: '-'),
              ),
              const Divider(height: 16, color: AppColors.slate200),
              _ClinicalDetailRow(
                'الدكتور',
                text(doctor, 'name', fallback: '-'),
              ),
              const Divider(height: 16, color: AppColors.slate200),
              _ClinicalDetailRow(
                'التاريخ',
                dateOnly(text(_log, 'log_date')),
              ),
              if (text(_log, 'doctor_notes').isNotEmpty) ...[
                const Divider(height: 16, color: AppColors.slate200),
                _ClinicalDetailRow(
                  'ملاحظات الدكتور',
                  text(_log, 'doctor_notes'),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ClinicalSectionTitle(
          'تفاصيل الاعتماد والأنشطة',
          Icons.assignment_rounded,
        ),
        const SizedBox(height: 10),
        if (groups.isEmpty)
          const EmptyState(
            message:
                'لا توجد أنشطة مسجلة في هذا السجل.',
          )
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
                : const Icon(Icons.refresh_rounded, size: 18),
            label: const Text(
              'تجديد الباركود',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
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
      return const _ClinicalMiniBadge(
        'انتهت صلاحية الباركود',
      );
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
                fontFamily: 'Cairo',
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                color: AppColors.midnight,
                fontWeight: FontWeight.w800,
                fontFamily: 'Cairo',
                fontSize: 13,
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
    final hasRejected =
        boolValue(group, 'has_rejected') ||
        items.any((item) => text(item, 'review_status') == 'rejected');
    final statusColor = confirmed
        ? AppColors.success
        : hasRejected
        ? AppColors.danger
        : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                confirmed
                    ? Icons.verified_rounded
                    : hasRejected
                    ? Icons.cancel_rounded
                    : Icons.pending_rounded,
                color: statusColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${text(group, 'label', fallback: 'قسم')} (${items.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.midnight,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
              _ClinicalMiniBadge(
                confirmed
                    ? 'معتمد'
                    : hasRejected
                    ? 'به عناصر مرفوضة'
                    : 'بانتظار',
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map((item) {
            final body = asMap(item['body_system']);
            final reviewStatus = text(
              item,
              'review_status',
              fallback: boolValue(item, 'is_confirmed')
                  ? 'approved'
                  : 'pending',
            );
            final label = text(
              body,
              'name',
              fallback: text(item, 'case_name', fallback: '-'),
            );
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.86),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _clinicalReviewStatusIcon(reviewStatus),
                    color: _clinicalReviewStatusColor(reviewStatus),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            color: AppColors.midnight,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Cairo',
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _clinicalReviewStatusLabel(reviewStatus),
                          style: TextStyle(
                            color: _clinicalReviewStatusColor(reviewStatus),
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Cairo',
                            fontSize: 12,
                          ),
                        ),
                        if (text(item, 'diagnosis').isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'التشخيص: ${text(item, 'diagnosis')}',
                            style: const TextStyle(
                              color: AppColors.slate700,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Cairo',
                              fontSize: 12,
                            ),
                          ),
                        ],
                        if (text(item, 'review_notes').isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'ملاحظة: ${text(item, 'review_notes')}',
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Cairo',
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          if (text(group, 'diagnosis').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'التشخيص العام: ${text(group, 'diagnosis')}',
              style: const TextStyle(
                color: AppColors.slate700,
                fontWeight: FontWeight.w700,
                fontFamily: 'Cairo',
                fontSize: 12.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

IconData _clinicalReviewStatusIcon(String status) {
  return switch (status) {
    'approved' => Icons.check_circle_rounded,
    'rejected' => Icons.cancel_rounded,
    _ => Icons.radio_button_unchecked_rounded,
  };
}

Color _clinicalReviewStatusColor(String status) {
  return switch (status) {
    'approved' => AppColors.success,
    'rejected' => AppColors.danger,
    _ => AppColors.warning,
  };
}

String _clinicalReviewStatusLabel(String status) {
  return switch (status) {
    'approved' => 'تم الاعتماد',
    'rejected' => 'مرفوض ويحتاج محاولة جديدة',
    _ => 'بانتظار مراجعة الدكتور',
  };
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
          'has_rejected': list.any(
            (item) => text(item, 'review_status') == 'rejected',
          ),
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
    final canSubmit =
        item['can_start_attempt'] == true ||
        status == 'assigned' ||
        status == 'rejected';
    final latestAttempt = asMap(item['latest_attempt']);
    final attemptGroups = asList(latestAttempt['grouped_activities']).isNotEmpty
        ? asList(latestAttempt['grouped_activities']).map(asMap).toList()
        : _fallbackClinicalGroups(latestAttempt);
    return InkWell(
      onTap: () => _showClinicalAssignmentDetails(context, ref, item),
      borderRadius: BorderRadius.circular(22),
      child: _ClinicalCard(
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
                      fallback: text(
                        item,
                        'task_type',
                        fallback: 'مهمة سريرية',
                      ),
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
            if (latestAttempt.isNotEmpty) ...[
              const SizedBox(height: 10),
              _ClinicalAttemptSummary(
                attempt: latestAttempt,
                groups: attemptGroups,
              ),
            ],
            if (canSubmit) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    final changed = await context.push<bool>(
                      StudentClinicalLogFormScreen.path(
                        assignmentId: number(item, 'id').toInt(),
                      ),
                    );
                    if (changed == true) {
                      ref.invalidate(_clinicalLogbookProvider);
                    }
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: Text(
                    status == 'rejected'
                        ? 'إعادة تنفيذ المحاولة'
                        : 'بدء تنفيذ التكليف',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

void _showClinicalAssignmentDetails(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> assignment,
) {
  showMoeenBottomSheet(
    context: context,
    title: 'تفاصيل التكليف السريري',
    icon: Icons.assignment_turned_in_rounded,
    color: AppColors.teal,
    fullScreen: true,
    child: _ClinicalAssignmentDetailsPanel(assignment: assignment),
  );
}

class _ClinicalAssignmentDetailsPanel extends ConsumerWidget {
  const _ClinicalAssignmentDetailsPanel({required this.assignment});

  final Map<String, dynamic> assignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clinicalCase = asMap(assignment['clinical_case']);
    final assigner = asMap(assignment['assigner']);
    final latestAttempt = asMap(assignment['latest_attempt']);
    final attempts = asList(assignment['attempts']).map(asMap).toList();
    final canStart =
        assignment['can_start_attempt'] == true ||
        text(assignment, 'status') == 'assigned' ||
        text(assignment, 'status') == 'rejected';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ClinicalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _ClinicalIconBubble(
                    Icons.medical_information_rounded,
                    AppColors.teal,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text(
                        clinicalCase,
                        'patient_name',
                        fallback: text(
                          clinicalCase,
                          'diagnosis_or_description',
                          fallback: 'تكليف سريري',
                        ),
                      ),
                      style: const TextStyle(
                        color: AppColors.midnight,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                  _ClinicalStatusBadge(text(assignment, 'status')),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Column(
                  children: [
                    _ClinicalDetailRow(
                      'نوع المهمة',
                      _clinicalActivityLabel(text(assignment, 'task_type')),
                    ),
                    const Divider(height: 16, color: AppColors.slate200),
                    _ClinicalDetailRow(
                      'الدكتور',
                      text(assigner, 'name', fallback: '-'),
                    ),
                    const Divider(height: 16, color: AppColors.slate200),
                    _ClinicalDetailRow(
                      'المركز',
                      text(
                        asMap(clinicalCase['training_center']),
                        'name',
                        fallback: '-',
                      ),
                    ),
                    const Divider(height: 16, color: AppColors.slate200),
                    _ClinicalDetailRow(
                      'القسم',
                      text(
                        asMap(clinicalCase['clinical_department']),
                        'name',
                        fallback: '-',
                      ),
                    ),
                    if (text(assignment, 'instructions').isNotEmpty) ...[
                      const Divider(height: 16, color: AppColors.slate200),
                      _ClinicalDetailRow(
                        'التعليمات',
                        text(assignment, 'instructions'),
                      ),
                    ],
                    if (text(assignment, 'review_notes').isNotEmpty) ...[
                      const Divider(height: 16, color: AppColors.slate200),
                      _ClinicalDetailRow(
                        'ملاحظة الدكتور',
                        text(assignment, 'review_notes'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (latestAttempt.isNotEmpty) ...[
          _ClinicalSectionTitle(
            'الباركود وآخر محاولة',
            Icons.qr_code_2_rounded,
          ),
          const SizedBox(height: 10),
          _ClinicalLogDetailsPanel(initialLog: latestAttempt),
        ] else
          _ClinicalCard(
            child: Column(
              children: [
                const Icon(
                  Icons.qr_code_2_rounded,
                  color: AppColors.slate400,
                  size: 42,
                ),
                const SizedBox(height: 10),
                const Text(
                  'لا يوجد باركود بعد. ابدأ تنفيذ التكليف ثم احفظ المحاولة.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.slate600,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Cairo',
                    fontSize: 13,
                  ),
                ),
                if (canStart) ...[
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () async {
                      final changed = await context.push<bool>(
                        StudentClinicalLogFormScreen.path(
                          assignmentId: number(assignment, 'id').toInt(),
                        ),
                      );
                      if (changed == true) {
                        ref.invalidate(_clinicalLogbookProvider);
                      }
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: const Text(
                      'بدء تنفيذ التكليف',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        if (attempts.length > 1) ...[
          const SizedBox(height: 18),
          _ClinicalSectionTitle(
            'المحاولات السابقة',
            Icons.history_rounded,
          ),
          const SizedBox(height: 10),
          ...attempts.skip(1).map((attempt) {
            final groups = asList(attempt['grouped_activities']).isNotEmpty
                ? asList(attempt['grouped_activities']).map(asMap).toList()
                : _fallbackClinicalGroups(attempt);
            return _ClinicalAttemptSummary(attempt: attempt, groups: groups);
          }),
        ],
      ],
    );
  }
}

class _ClinicalAttemptSummary extends StatelessWidget {
  const _ClinicalAttemptSummary({required this.attempt, required this.groups});

  final Map<String, dynamic> attempt;
  final List<Map<String, dynamic>> groups;

  @override
  Widget build(BuildContext context) {
    final status = text(attempt, 'status', fallback: 'pending');
    final done = groups
        .where((group) => boolValue(group, 'all_confirmed'))
        .length;
    final rejected = groups
        .where(
          (group) =>
              boolValue(group, 'has_rejected') ||
              asList(
                group['items'],
              ).any((item) => text(asMap(item), 'review_status') == 'rejected'),
        )
        .length;
    final remaining = groups.length - done;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                status == 'rejected'
                    ? Icons.cancel_rounded
                    : status == 'confirmed'
                    ? Icons.verified_rounded
                    : Icons.pending_actions_rounded,
                color: _clinicalStatusColor(status),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'آخر محاولة: ${_clinicalStatusLabel(status)}',
                  style: const TextStyle(
                    color: AppColors.midnight,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Cairo',
                    fontSize: 13,
                  ),
                ),
              ),
              _ClinicalMiniBadge(
                rejected > 0
                    ? 'تم $done / مرفوض $rejected'
                    : 'تم $done / متبقي $remaining',
              ),
            ],
          ),
          if (groups.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: groups.map((group) {
                final confirmed = boolValue(group, 'all_confirmed');
                final rejected =
                    boolValue(group, 'has_rejected') ||
                    asList(group['items']).any(
                      (item) =>
                          text(asMap(item), 'review_status') == 'rejected',
                    );
                return _ClinicalMiniBadge(
                  '${text(group, 'label', fallback: '-')} ${confirmed
                      ? 'تم'
                      : rejected
                      ? 'مرفوض'
                      : 'بانتظار'}',
                );
              }).toList(),
            ),
          ],
          if (text(attempt, 'doctor_notes').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'ملاحظة الدكتور: ${text(attempt, 'doctor_notes')}',
              style: const TextStyle(
                color: AppColors.rose,
                fontWeight: FontWeight.w800,
                fontFamily: 'Cairo',
                fontSize: 12,
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

class _ClinicalSkillsOverview extends StatelessWidget {
  const _ClinicalSkillsOverview({required this.radar});

  final List<Map<String, dynamic>> radar;

  @override
  Widget build(BuildContext context) {
    if (radar.isEmpty) {
      return _ClinicalCard(
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ClinicalSectionTitle('تحليل المهارات', Icons.insights),
            SizedBox(height: 10),
            Text(
              'سيظهر تحليل المهارات بعد توفر بنود تقييم كافية.',
              style: TextStyle(
                color: AppColors.slate600,
                fontWeight: FontWeight.w700,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      );
    }

    final sorted = [...radar]
      ..sort(
        (a, b) => number(b, 'percentage').compareTo(number(a, 'percentage')),
      );
    final strongest = sorted.first;
    final weakest = sorted.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ClinicalSectionTitle('تحليل المهارات', Icons.insights),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ClinicalSkillSummaryCard(
                label: 'أقوى مهارة',
                item: strongest,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ClinicalSkillSummaryCard(
                label: 'تحتاج تركيز',
                item: weakest,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...radar.map((item) => _ClinicalSkillBar(item: item)),
      ],
    );
  }
}

class _ClinicalSkillSummaryCard extends StatelessWidget {
  const _ClinicalSkillSummaryCard({
    required this.label,
    required this.item,
    required this.color,
  });

  final String label;
  final Map<String, dynamic> item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text(item, 'label_ar', fallback: text(item, 'label_en')),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.midnight,
              fontWeight: FontWeight.w900,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${number(item, 'percentage').toStringAsFixed(0)}%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}

class _ClinicalEvaluationFilters extends StatelessWidget {
  const _ClinicalEvaluationFilters({
    required this.searchController,
    required this.grade,
    required this.doctor,
    required this.sort,
    required this.doctors,
    required this.onGradeChanged,
    required this.onDoctorChanged,
    required this.onSortChanged,
  });

  final TextEditingController searchController;
  final String grade;
  final String doctor;
  final String sort;
  final List<MapEntry<String, String>> doctors;
  final ValueChanged<String> onGradeChanged;
  final ValueChanged<String> onDoctorChanged;
  final ValueChanged<String> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return _ClinicalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: searchController,
            decoration: const InputDecoration(
              labelText: 'بحث باسم التقييم أو الدكتور',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _EvaluationFilterChip(
                label: 'الكل',
                selected: grade == 'all',
                onTap: () => onGradeChanged('all'),
              ),
              _EvaluationFilterChip(
                label: 'ممتاز',
                selected: grade == 'excellent',
                onTap: () => onGradeChanged('excellent'),
              ),
              _EvaluationFilterChip(
                label: 'جيد',
                selected: grade == 'good',
                onTap: () => onGradeChanged('good'),
              ),
              _EvaluationFilterChip(
                label: 'مقبول',
                selected: grade == 'acceptable',
                onTap: () => onGradeChanged('acceptable'),
              ),
              _EvaluationFilterChip(
                label: 'ضعيف',
                selected: grade == 'weak',
                onTap: () => onGradeChanged('weak'),
              ),
              _EvaluationFilterChip(
                label: 'راسب',
                selected: grade == 'fail',
                onTap: () => onGradeChanged('fail'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: doctor,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'الدكتور'),
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('الكل')),
                    ...doctors.map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    ),
                  ],
                  onChanged: (value) => onDoctorChanged(value ?? 'all'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: sort,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'الترتيب'),
                  items: const [
                    DropdownMenuItem(value: 'latest', child: Text('الأحدث')),
                    DropdownMenuItem(value: 'oldest', child: Text('الأقدم')),
                  ],
                  onChanged: (value) => onSortChanged(value ?? 'latest'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EvaluationFilterChip extends StatelessWidget {
  const _EvaluationFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.teal.withValues(alpha: 0.14),
      labelStyle: TextStyle(
        color: selected ? AppColors.teal : AppColors.slate600,
        fontWeight: FontWeight.w900,
        fontFamily: 'Cairo',
      ),
      side: BorderSide(color: selected ? AppColors.teal : AppColors.slate200),
    );
  }
}

class _ClinicalEmptyEvaluationsState extends StatelessWidget {
  const _ClinicalEmptyEvaluationsState();

  @override
  Widget build(BuildContext context) {
    return _ClinicalCard(
      child: Column(
        children: [
          const Icon(
            Icons.fact_check_outlined,
            size: 42,
            color: AppColors.slate400,
          ),
          const SizedBox(height: 10),
          const Text(
            'لا توجد تقييمات سريرية بعد.',
            style: TextStyle(
              color: AppColors.midnight,
              fontWeight: FontWeight.w900,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'ستظهر هنا تقييمات الدكتور بعد التدريب السريري، ويمكنك التدرب مسبقًا عبر OSCE.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.slate600,
              fontWeight: FontWeight.w700,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => context.go(StudentClinicalMockExamsScreen.route),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('الانتقال إلى تدريب OSCE'),
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
    final grade = text(item, 'grade');
    final color = _clinicalStatusColor(grade);
    final feedback = text(item, 'doctor_feedback').trim();
    return _ClinicalCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push(
          StudentClinicalEvaluationsScreen.detailsPath(
            number(item, 'id').toInt(),
          ),
        ),
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ClinicalIconBubble(Icons.rate_review_rounded, color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text(checklist, 'title', fallback: 'تقييم سريري'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.midnight,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'د. ${text(doctor, 'name', fallback: '-')}',
                        style: const TextStyle(
                          color: AppColors.slate600,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
                _ClinicalStatusBadge(grade),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                minHeight: 8,
                value:
                    (number(item, 'percentage').toDouble().clamp(0, 100)) / 100,
                backgroundColor: AppColors.slate100,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ClinicalInfoPill(
                  label: 'النسبة',
                  value: '${text(item, 'percentage', fallback: '0')}%',
                ),
                _ClinicalInfoPill(
                  label: 'الدرجة',
                  value:
                      '${_formatClinicalMark(number(item, 'total_score').toDouble())}/${_formatClinicalMark(number(item, 'max_score').toDouble())}',
                ),
                _ClinicalInfoPill(
                  label: 'الوقت',
                  value: text(item, 'formatted_time', fallback: '-'),
                ),
                _ClinicalInfoPill(
                  label: 'التاريخ',
                  value: dateOnly(text(item, 'created_at')),
                ),
              ],
            ),
            if (feedback.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                feedback.length > 110
                    ? '${feedback.substring(0, 110)}...'
                    : feedback,
                style: const TextStyle(
                  color: AppColors.slate700,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  height: 1.5,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                Text(
                  'عرض التفاصيل',
                  style: TextStyle(
                    color: AppColors.teal,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Cairo',
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.chevron_left_rounded, color: AppColors.teal),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ClinicalInfoPill extends StatelessWidget {
  const _ClinicalInfoPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.slate500,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(
              color: AppColors.midnight,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}

class _ClinicalEvaluationScoreCard extends StatelessWidget {
  const _ClinicalEvaluationScoreCard({required this.index, required this.item});

  final int index;
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final checklistItem = asMap(item['checklist_item']);
    final score = text(item, 'score');
    final color = switch (score) {
      'done' => AppColors.success,
      'partial' => AppColors.goldDeep,
      _ => AppColors.danger,
    };
    final obtained = number(item, 'marks_obtained').toDouble();
    final maxMarks = number(
      checklistItem,
      'marks',
      fallback: number(item, 'max_marks'),
    ).toDouble();
    final note = text(item, 'note').trim();
    return _ClinicalCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              index.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontFamily: 'Cairo',
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text(checklistItem, 'description', fallback: 'بند تقييم'),
                  style: const TextStyle(
                    color: AppColors.midnight,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_formatClinicalMark(obtained)} من ${_formatClinicalMark(maxMarks)} درجة',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    fontFamily: 'Cairo',
                  ),
                ),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    note,
                    style: const TextStyle(
                      color: AppColors.slate600,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _ClinicalStatusBadge(score),
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
                    text(
                      checklist,
                      'title',
                      fallback: 'محاولة تدريبية',
                    ),
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
      'partial' => AppColors.gold,
      _ => AppColors.danger,
    };
    final label = switch (scoreLabel) {
      'done' => 'تم بالكامل',
      'partial' => 'تم جزئياً',
      _ => 'لم يتم',
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  scoreLabel == 'done'
                      ? Icons.check_circle_rounded
                      : scoreLabel == 'partial'
                      ? Icons.adjust_rounded
                      : Icons.cancel_rounded,
                  color: color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text(
                        checklistItem,
                        'description',
                        fallback: 'عنصر تقييم',
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: AppColors.midnight,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatClinicalMark(obtained)} من ${_formatClinicalMark(maxMarks)} درجة',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.15)),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ),
          if (text(item, 'notes').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.slate100),
              ),
              child: Text(
                'ملاحظات: ${text(item, 'notes')}',
                style: const TextStyle(
                  color: AppColors.slate600,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                  height: 1.45,
                  fontFamily: 'Cairo',
                ),
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
                      color: AppColors.midnight,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
                _ClinicalMiniBadge(
                  'ًں‘پï¸ڈ ${text(item, 'views_count', fallback: '0')}',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              text(item, 'clinical_signs', fallback: text(item, 'description')),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                height: 1.45,
                color: AppColors.slate700,
                fontWeight: FontWeight.w700,
                fontFamily: 'Cairo',
              ),
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
                    'بواسطة: د. ${text(doctor, 'name', fallback: 'دكتور')}',
                    style: const TextStyle(
                      color: AppColors.slate500,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
                Text(
                  timeAgo(text(item, 'created_at')),
                  style: const TextStyle(
                    color: AppColors.slate400,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    fontFamily: 'Cairo',
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
        final diagnosis = text(
          item,
          'diagnosis',
          fallback: text(item, 'title', fallback: 'حالة نادرة'),
        );
        final createdAt = text(item, 'created_at');
        final updatedAt = text(item, 'updated_at');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _RareCaseBentoSection(
              title: 'البيانات الطبية والتشخيص',
              icon: Icons.medical_information_rounded,
              iconColor: AppColors.rose,
              children: [
                _ClinicalDetailRow('التشخيص', diagnosis),
                _ClinicalDetailRow(
                  'اسم المريض',
                  text(item, 'patient_name', fallback: '-'),
                ),
                _ClinicalDetailRow(
                  'الدكتور المعلن',
                  text(doctor, 'name', fallback: '-'),
                ),
                _ClinicalDetailRow(
                  'حالة الإعلان',
                  'منشورة ونشطة',
                ),
                _ClinicalDetailRow(
                  'عدد المشاهدات',
                  '${text(item, 'views_count', fallback: '0')} مشاهدة',
                ),
                _ClinicalDetailRow(
                  'تاريخ النشر',
                  dateOnly(createdAt),
                ),
                if (updatedAt.isNotEmpty && updatedAt != createdAt)
                  _ClinicalDetailRow('آخر تعديل', dateOnly(updatedAt)),
                if (text(item, 'internal_notes').isNotEmpty)
                  _ClinicalDetailRow(
                    'ملاحظات إضافية',
                    text(item, 'internal_notes'),
                  ),
              ],
            ),
            _RareCaseBentoSection(
              title: 'موقع الإقامة والسرير',
              icon: Icons.local_hospital_rounded,
              iconColor: AppColors.teal,
              children: [
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
                  text(item, 'room_number', fallback: 'غير محدد'),
                ),
              ],
            ),
            _RareCaseBentoSection(
              title: 'العلامات السريرية والملاحظات',
              icon: Icons.biotech_rounded,
              iconColor: AppColors.orange,
              children: [
                Text(
                  text(
                    item,
                    'clinical_signs',
                    fallback:
                        'لا توجد علامات سريرية مضافة.',
                  ),
                  style: const TextStyle(
                    height: 1.6,
                    fontSize: 13,
                    color: AppColors.slate700,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
            if (attachmentUrl.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(
                  'المرفقات التوضيحية',
                  style: TextStyle(
                    color: AppColors.midnight,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.slate200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () => MoeenDialogs.showImage(context, attachmentUrl),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Image.network(
                        attachmentUrl,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 220,
                            color: AppColors.slate50,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.teal,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 120,
                            color: AppColors.slate50,
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image_rounded,
                                  color: AppColors.slate400,
                                  size: 36,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'تعذر تحميل الصورة المرفقة',
                                  style: TextStyle(
                                    color: AppColors.slate500,
                                    fontFamily: 'Cairo',
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: _ImageOverlayButton(
                          icon: Icons.open_in_full_rounded,
                          onPressed: () =>
                              MoeenDialogs.showImage(context, attachmentUrl),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: _ImageOverlayButton(
                          icon: Icons.download_rounded,
                          onPressed: () async {
                            final fileName = _extractFileName(
                              attachmentUrl,
                              id,
                            );
                            await _downloadUrlToFile(
                              context,
                              attachmentUrl,
                              fileName.split('.').first,
                              section: 'RareCases',
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }
}

class _RareCaseBentoSection extends StatelessWidget {
  const _RareCaseBentoSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.children,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.midnight,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const Divider(height: 20, thickness: 1, color: AppColors.slate100),
          ...children,
        ],
      ),
    );
  }
}

class _ImageOverlayButton extends StatelessWidget {
  const _ImageOverlayButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: AppColors.teal, size: 20),
        ),
      ),
    );
  }
}

String _extractFileName(String url, int id) {
  try {
    final uri = Uri.parse(url);
    final lastSegment = uri.pathSegments.last;
    if (lastSegment.isNotEmpty && lastSegment.contains('.')) {
      return lastSegment;
    }
  } catch (_) {}
  return 'rare_case_$id.jpg';
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
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.teal, size: 16),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: AppColors.slate800,
            fontFamily: 'Cairo',
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
  Map<String, dynamic>? assignment,
}) async {
  final data = ref.read(_clinicalLogbookProvider).valueOrNull;
  if (data == null) return;
  final options = asMap(data['form_options']);
  final centers = asList(options['training_centers']);
  final departments = asList(options['departments']);
  final bodies = asList(options['body_systems']);
  final doctors = asList(options['doctors']);
  final assignmentCase = asMap(assignment?['clinical_case']);
  final latestAttempt = asMap(assignment?['latest_attempt']);
  final rejectedAttemptActivities = asList(latestAttempt['grouped_activities'])
      .map(asMap)
      .expand((group) => asList(group['items']).map(asMap))
      .where((item) => text(item, 'review_status') == 'rejected')
      .toList();
  final activities = existing != null
      ? asList(existing['activities'])
      : rejectedAttemptActivities;
  int? centerId = number(
    existing != null
        ? asMap(existing['training_center'])
        : asMap(assignmentCase['training_center']),
    'id',
  ).toInt();
  int? departmentId = number(
    existing != null
        ? asMap(existing['department'])
        : asMap(assignmentCase['clinical_department']),
    'id',
  ).toInt();
  int? doctorId = number(
    existing != null
        ? asMap(existing['doctor'])
        : asMap(assignment?['assigner']),
    'id',
  ).toInt();
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

  bool submitting = false;

  await showMoeenBottomSheet<void>(
    context: context,
    title: existing == null
        ? 'تسجيل بيانات اليوم'
        : 'تعديل سجل اليوم',
    icon: Icons.local_hospital_rounded,
    color: AppColors.teal,
    child: StatefulBuilder(
      builder: (sheetContext, setLocal) {
        return Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ClinicalFormSection(
                title: 'البيانات الأساسية',
                icon: Icons.local_hospital_rounded,
                children: [
                  _ClinicalDropdown(
                    label: 'مركز التدريب',
                    value: centerId,
                    items: centers,
                    onChanged: assignment == null
                        ? (value) => setLocal(() => centerId = value)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _ClinicalDropdown(
                    label: 'القسم',
                    value: departmentId,
                    items: departments,
                    onChanged: assignment == null
                        ? (value) => setLocal(() => departmentId = value)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _ClinicalDropdown(
                    label: 'الدكتور',
                    value: doctorId,
                    items: doctors,
                    onChanged: assignment == null
                        ? (value) => setLocal(() => doctorId = value)
                        : null,
                  ),
                ],
              ),
              if (assignment != null) ...[
                _ClinicalAssignmentAttemptBanner(assignment: assignment),
                const SizedBox(height: 16),
              ],
              _ClinicalFormSection(
                title: 'الأنشطة والمهارات السريرية',
                icon: Icons.checklist_rounded,
                children: [
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
                  const SizedBox(height: 16),
                  _ClinicalPickerGroup(
                    title: 'الفحوصات السريرية',
                    bodies: bodies,
                    selected: examIds,
                    onToggle: (id) => setLocal(() {
                      examIds.contains(id)
                          ? examIds.remove(id)
                          : examIds.add(id);
                    }),
                  ),
                ],
              ),
              _ClinicalFormSection(
                title: 'المرور السريري والملاحظات',
                icon: Icons.groups_rounded,
                children: [
                  TextField(
                    controller: roundCases,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      labelText: 'حالات المرور السريري',
                      hintText: 'افصل بين الحالات بفاصلة',
                      prefixIcon: const Icon(
                        Icons.groups_rounded,
                        color: AppColors.teal,
                      ),
                      filled: true,
                      fillColor: AppColors.slate50,
                      floatingLabelStyle: const TextStyle(
                        fontFamily: 'Cairo',
                        color: AppColors.teal,
                        fontWeight: FontWeight.w800,
                      ),
                      labelStyle: const TextStyle(
                        fontFamily: 'Cairo',
                        color: AppColors.slate500,
                        fontSize: 12,
                      ),
                      hintStyle: const TextStyle(
                        fontFamily: 'Cairo',
                        color: AppColors.slate400,
                        fontSize: 11,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.slate200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.teal,
                          width: 1.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notes,
                    minLines: 2,
                    maxLines: 4,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      labelText: 'ملاحظات المرور',
                      prefixIcon: const Icon(
                        Icons.notes_rounded,
                        color: AppColors.teal,
                      ),
                      filled: true,
                      fillColor: AppColors.slate50,
                      floatingLabelStyle: const TextStyle(
                        fontFamily: 'Cairo',
                        color: AppColors.teal,
                        fontWeight: FontWeight.w800,
                      ),
                      labelStyle: const TextStyle(
                        fontFamily: 'Cairo',
                        color: AppColors.slate500,
                        fontSize: 12,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.slate200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.teal,
                          width: 1.6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: submitting
                    ? null
                    : () async {
                        if (!(formKey.currentState?.validate() ?? false))
                          return;
                        final isOnline = await ref
                            .read(connectivityServiceProvider)
                            .isOnline();
                        if (!isOnline) {
                          if (!sheetContext.mounted) return;
                          await showMoeenInfoDialog(
                            context: sheetContext,
                            title:
                                'لا يوجد اتصال بالإنترنت',
                            message:
                                'يرجى الاتصال بالإنترنت لتنفيذ هذه العملية.',
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
                          if (assignment != null)
                            'case_assignment_id': number(
                              assignment,
                              'id',
                            ).toInt(),
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
                        setLocal(() => submitting = true);
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
                              message:
                                  'حدث خطأ غير متوقع. حاول مرة أخرى.',
                              icon: Icons.error_outline_rounded,
                              color: AppColors.danger,
                            );
                          }
                        } finally {
                          if (sheetContext.mounted) {
                            setLocal(() => submitting = false);
                          }
                        }
                      },
                icon: submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save_rounded),
                label: const Text(
                  'حفظ السجل العملي',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
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

class _ClinicalAssignmentAttemptBanner extends StatelessWidget {
  const _ClinicalAssignmentAttemptBanner({required this.assignment});

  final Map<String, dynamic> assignment;

  @override
  Widget build(BuildContext context) {
    final clinicalCase = asMap(assignment['clinical_case']);
    final task = _clinicalActivityLabel(text(assignment, 'task_type'));
    final patient = text(
      clinicalCase,
      'patient_name',
      fallback: text(
        clinicalCase,
        'diagnosis_or_description',
        fallback: 'تكليف سريري',
      ),
    );
    final instructions = text(assignment, 'instructions');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.assignment_turned_in_rounded,
                color: AppColors.teal,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$task - $patient',
                  style: const TextStyle(
                    color: AppColors.midnight,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          if (instructions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              instructions,
              style: const TextStyle(
                color: AppColors.slate700,
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 8),
          const Text(
            'اختر العناصر التي نفذتها، ثم احفظ المحاولة وسيظهر الباركود لاعتماد الدكتور.',
            style: TextStyle(
              color: AppColors.slate600,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClinicalFormSection extends StatelessWidget {
  const _ClinicalFormSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.teal, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: AppColors.midnight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
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
  final ValueChanged<int?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      value: value,
      validator: (value) =>
          value == null ? 'هذا الحقل مطلوب' : null,
      isExpanded: true,
      style: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: AppColors.midnight,
      ),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.slate50,
        floatingLabelStyle: const TextStyle(
          fontFamily: 'Cairo',
          color: AppColors.teal,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Cairo',
          color: AppColors.slate500,
          fontSize: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.slate200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      items: items
          .map(asMap)
          .map(
            (item) => DropdownMenuItem<int>(
              value: number(item, 'id').toInt(),
              child: Text(
                text(item, 'name'),
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
            fontFamily: 'Cairo',
            fontSize: 13.5,
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
              showCheckmark: true,
              label: Text(text(item, 'name')),
              onSelected: (_) => onToggle(id),
              selectedColor: AppColors.teal.withValues(alpha: 0.12),
              checkmarkColor: AppColors.teal,
              side: BorderSide(
                color: active ? AppColors.teal : AppColors.slate200,
                width: active ? 1.4 : 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              labelStyle: TextStyle(
                color: active ? AppColors.teal : AppColors.slate700,
                fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                fontFamily: 'Cairo',
                fontSize: 12,
              ),
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
    message:
        'هل تريد حذف هذا السجل؟ لا يمكن حذف السجل بعد اعتماده.',
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
              decoration: const InputDecoration(
                labelText: 'عنوان النموذج',
              ),
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
                      decoration: InputDecoration(
                        labelText: 'العنصر ${i + 1}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: items[i].marks,
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          (num.tryParse(value ?? '') ?? 0) <= 0
                          ? 'درجة'
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'الدرجة',
                      ),
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
    'acceptable' => 'مقبول',
    'weak' => 'ضعيف',
    'pass' => 'ناجح',
    'fail' => 'راسب',
    'done' => 'تم',
    'partial' => 'جزئي',
    'not_done' => 'لم يتم',
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
    'done' ||
    'pass' => AppColors.success,
    'partially_confirmed' ||
    'submitted_for_review' ||
    'acceptable' ||
    'partial' ||
    'pending' => AppColors.warning,
    'rejected' || 'weak' || 'fail' || 'not_done' => AppColors.danger,
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
