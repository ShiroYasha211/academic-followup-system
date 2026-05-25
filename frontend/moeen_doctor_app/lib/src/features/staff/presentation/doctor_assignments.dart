part of 'staff_screens.dart';

class DoctorAssignmentsScreen extends ConsumerStatefulWidget {
  const DoctorAssignmentsScreen({super.key});

  static const route = '/doctor/assignments';

  @override
  ConsumerState<DoctorAssignmentsScreen> createState() =>
      _DoctorAssignmentsScreenState();
}

class _DoctorAssignmentsScreenState
    extends ConsumerState<DoctorAssignmentsScreen> {
  String _status = 'all';
  int? _subjectId;
  late Future<Map<String, dynamic>> _future = _fetch();

  Future<Map<String, dynamic>> _fetch() {
    return ref
        .read(staffRepositoryProvider)
        .get('/doctor/assignments', query: const {'all': true});
  }

  void _reload() {
    setState(() {
      _future = _fetch();
    });
  }

  List<Map<String, dynamic>> _filteredAssignments(
    List<Map<String, dynamic>> assignments,
  ) {
    return assignments.where((assignment) {
      if (_subjectId != null) {
        final subject = _docMap(assignment['subject']);
        final subjectId = _docInt(assignment['subject_id']);
        final nestedSubjectId = _docInt(subject['id']);
        if (subjectId != _subjectId && nestedSubjectId != _subjectId) {
          return false;
        }
      }

      if (_status != 'all') {
        final due = DateTime.tryParse(_docText(assignment['due_date']));
        final isOverdue = due != null && due.isBefore(DateTime.now());
        if (_status == 'overdue' && !isOverdue) return false;
        if (_status == 'upcoming' && isOverdue) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'التكاليف',
      currentRoute: DoctorAssignmentsScreen.route,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.royalBlue,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onPressed: () async {
          final data = await _future;
          if (!context.mounted) return;
          final subjects = _docList(
            _docMap(_docMap(_docData(data))['filters'])['subjects'],
          );
          await _showAssignmentForm(subjects: subjects);
        },
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'تكليف جديد',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900),
        ),
      ),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorView(error: snapshot.error!);
          }
          final payload = _docMap(_docData(snapshot.data ?? const {}));
          final stats = _docMap(payload['stats']);
          final filters = _docMap(payload['filters']);
          final subjects = _docList(filters['subjects']);
          final assignments = _filteredAssignments(
            _docList(payload['assignments']),
          );

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              children: [
                _DocHero(
                  title: 'إدارة التكاليف',
                  subtitle: 'إنشاء التكاليف ومراجعة تسليمات الطلاب وتصديرها.',
                  icon: Icons.assignment_rounded,
                  trailing: IconButton.filledTonal(
                    onPressed: () => _showAssignmentForm(subjects: subjects),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _DocMetric(
                      label: 'كل التكاليف',
                      value: _docText(stats['total'], '0'),
                      color: AppColors.royalBlue,
                      icon: Icons.assignment_rounded,
                    ),
                    _DocMetric(
                      label: 'النشطة',
                      value: _docText(stats['upcoming'], '0'),
                      color: AppColors.success,
                      icon: Icons.upcoming_rounded,
                    ),
                    _DocMetric(
                      label: 'المتأخرة',
                      value: _docText(stats['overdue'], '0'),
                      color: AppColors.danger,
                      icon: Icons.warning_rounded,
                    ),
                    _DocMetric(
                      label: 'التسليمات',
                      value: _docText(stats['submissions'], '0'),
                      color: AppColors.warning,
                      icon: Icons.upload_file_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _AssignmentsFilters(
                  subjects: subjects,
                  subjectId: _subjectId,
                  status: _status,
                  onSubjectChanged: (value) {
                    setState(() {
                      _subjectId = value;
                    });
                  },
                  onStatusChanged: (value) {
                    setState(() {
                      _status = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (assignments.isEmpty)
                  const _DocEmpty('لا توجد تكاليف مطابقة للفلاتر الحالية.')
                else
                  ...assignments.map(
                    (assignment) => _AssignmentCard(
                      assignment: assignment,
                      onDetails: () => context.push(
                        DoctorAssignmentDetailsScreen.path(
                          _docInt(assignment['id']),
                        ),
                      ),
                      onEdit: () => _showAssignmentForm(
                        subjects: subjects,
                        assignment: assignment,
                      ),
                      onDelete: () => _deleteAssignment(assignment),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAssignmentForm({
    required List<_Json> subjects,
    _Json? assignment,
  }) async {
    final formKey = GlobalKey<FormState>();
    final title = TextEditingController(text: _docText(assignment?['title']));
    final description = TextEditingController(
      text: _docText(assignment?['description']),
    );
    final dueDate = TextEditingController(
      text: _docDate(assignment?['due_date']),
    );
    int? subjectId = _docInt(assignment?['subject_id']) > 0
        ? _docInt(assignment?['subject_id'])
        : (subjects.isNotEmpty ? _docInt(subjects.first['id']) : null);
    var requiresSubmission = _docBool(assignment?['requires_submission']);

    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: assignment == null
          ? 'إضافة تكليف جديد'
          : 'تعديل التكليف الأكاديمي',
      icon: assignment == null ? Icons.assignment_add : Icons.edit_note_rounded,
      color: AppColors.royalBlue,
      child: StatefulBuilder(
        builder: (sheetContext, setLocal) => Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<int>(
                initialValue: subjectId,
                isExpanded: true,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                  color: AppColors.midnight,
                ),
                decoration: InputDecoration(
                  labelText: 'المادة الدراسية',
                  labelStyle: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                  ),
                  filled: true,
                  fillColor: AppColors.slate50,
                  prefixIcon: const Icon(
                    Icons.book_rounded,
                    color: AppColors.royalBlue,
                  ),
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
                    borderSide: const BorderSide(
                      color: AppColors.royalBlue,
                      width: 2,
                    ),
                  ),
                ),
                items: subjects
                    .map(
                      (subject) => DropdownMenuItem(
                        value: _docInt(subject['id']),
                        child: Text(
                          _docText(subject['name']),
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setLocal(() => subjectId = value),
                validator: (value) =>
                    value == null ? 'اختر المادة الدراسية.' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: title,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  labelText: 'عنوان التكليف',
                  labelStyle: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                  ),
                  filled: true,
                  fillColor: AppColors.slate50,
                  prefixIcon: const Icon(
                    Icons.title_rounded,
                    color: AppColors.royalBlue,
                  ),
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
                    borderSide: const BorderSide(
                      color: AppColors.royalBlue,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) =>
                    _docText(value).isEmpty ? 'اكتب عنوان التكليف.' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: description,
                maxLines: 4,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  labelText: 'وصف ومتطلبات التكليف',
                  labelStyle: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                  ),
                  filled: true,
                  fillColor: AppColors.slate50,
                  alignLabelWithHint: true,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 60),
                    child: Icon(
                      Icons.description_rounded,
                      color: AppColors.royalBlue,
                    ),
                  ),
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
                    borderSide: const BorderSide(
                      color: AppColors.royalBlue,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) =>
                    _docText(value).isEmpty ? 'اكتب وصف التكليف.' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: dueDate,
                readOnly: true,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: sheetContext,
                    initialDate:
                        DateTime.tryParse(dueDate.text) ??
                        DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                  );
                  if (picked != null) {
                    setLocal(() {
                      dueDate.text = picked.toIso8601String().substring(0, 10);
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: 'تاريخ التسليم الأقصى',
                  labelStyle: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                  ),
                  filled: true,
                  fillColor: AppColors.slate50,
                  prefixIcon: const Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.royalBlue,
                  ),
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
                    borderSide: const BorderSide(
                      color: AppColors.royalBlue,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) =>
                    _docText(value).isEmpty ? 'اختر تاريخ التسليم.' : null,
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.royalBlue,
                  title: const Text(
                    'يتطلب تسليم ملف من الطالب',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.midnight,
                    ),
                  ),
                  value: requiresSubmission,
                  onChanged: (value) =>
                      setLocal(() => requiresSubmission = value),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.slate600,
                        side: const BorderSide(color: AppColors.slate300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'إلغاء',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        if (formKey.currentState?.validate() != true) return;
                        Navigator.pop(sheetContext, true);
                      },
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: const Text(
                        'حفظ التكليف',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w900,
                        ),
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
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (ok != true || subjectId == null) return;
    try {
      final payload = {
        if (assignment == null) 'subject_id': subjectId,
        'title': title.text.trim(),
        'description': description.text.trim(),
        'due_date': dueDate.text.trim(),
        'requires_submission': requiresSubmission,
      };
      if (assignment == null) {
        await ref
            .read(staffRepositoryProvider)
            .post('/doctor/assignments', payload);
      } else {
        await ref
            .read(staffRepositoryProvider)
            .put('/doctor/assignments/${assignment['id']}', payload);
      }
      if (!mounted) return;
      _reload();
      _docSnack(context, 'تم حفظ التكليف بنجاح.', color: AppColors.success);
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  Future<void> _deleteAssignment(_Json assignment) async {
    final ok = await showMoeenConfirmDialog(
      context: context,
      title: 'حذف التكليف',
      message: 'هل تريد حذف هذا التكليف؟',
      confirmLabel: 'حذف',
      icon: Icons.delete_rounded,
      color: AppColors.danger,
    );
    if (!ok) return;
    try {
      await ref
          .read(staffRepositoryProvider)
          .delete('/doctor/assignments/${assignment['id']}');
      if (!mounted) return;
      _reload();
      _docSnack(context, 'تم حذف التكليف.', color: AppColors.success);
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }
}

class DoctorAssignmentDetailsScreen extends ConsumerStatefulWidget {
  const DoctorAssignmentDetailsScreen({super.key, required this.assignmentId});

  static const route = '/doctor/assignments/:assignmentId';

  final int assignmentId;

  static String path(int assignmentId) => '/doctor/assignments/$assignmentId';

  @override
  ConsumerState<DoctorAssignmentDetailsScreen> createState() =>
      _DoctorAssignmentDetailsScreenState();
}

class _DoctorAssignmentDetailsScreenState
    extends ConsumerState<DoctorAssignmentDetailsScreen> {
  late Future<_Json> _future = _fetch();

  Future<_Json> _fetch() async {
    final response = await ref
        .read(staffRepositoryProvider)
        .get('/doctor/assignments/${widget.assignmentId}');
    return _docMap(_docMap(_docData(response))['assignment']);
  }

  void _reload() => setState(() {
    _future = _fetch();
  });

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'تفاصيل التكليف',
      currentRoute: DoctorAssignmentsScreen.route,
      child: FutureBuilder<_Json>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
          final assignment = snapshot.data ?? const <String, dynamic>{};

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                _AssignmentDetailsHeader(assignment: assignment),
                const SizedBox(height: 16),
                _AssignmentSubmissionsPanel(
                  assignment: assignment,
                  showHeader: false,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AssignmentDetailsHeader extends StatelessWidget {
  const _AssignmentDetailsHeader({required this.assignment});

  final _Json assignment;

  @override
  Widget build(BuildContext context) {
    final subject = _docMap(assignment['subject']);
    final due = DateTime.tryParse(_docText(assignment['due_date']));
    final isOverdue = due != null && due.isBefore(DateTime.now());
    final requiresSubmission = _docBool(assignment['requires_submission']);

    return _DocHero(
      title: _docText(assignment['title'], 'تكليف'),
      subtitle: _docText(
        assignment['description'],
        'لا يوجد وصف لهذا التكليف.',
      ),
      icon: Icons.assignment_turned_in_rounded,
      trailing: _DocHeroPill(
        isOverdue ? 'متأخر' : 'قادم',
        icon: isOverdue ? Icons.warning_rounded : Icons.event_available_rounded,
      ),
      bottom: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _DocHeroPill(
              _docText(subject['name'], '-'),
              icon: Icons.menu_book_rounded,
            ),
            _DocHeroPill(
              'موعد التسليم: ${_docDate(assignment['due_date'])}',
              icon: Icons.calendar_month_rounded,
            ),
            _DocHeroPill(
              '${_docInt(assignment['submissions_count'])} تسليم',
              icon: Icons.upload_file_rounded,
            ),
            _DocHeroPill(
              requiresSubmission ? 'يتطلب تسليم ملف' : 'بدون ملف مطلوب',
              icon: requiresSubmission
                  ? Icons.task_alt_rounded
                  : Icons.visibility_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignmentsFilters extends StatelessWidget {
  const _AssignmentsFilters({
    required this.subjects,
    required this.subjectId,
    required this.status,
    required this.onSubjectChanged,
    required this.onStatusChanged,
  });

  final List<Map<String, dynamic>> subjects;
  final int? subjectId;
  final String status;
  final ValueChanged<int?> onSubjectChanged;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return _DocFilterPanel(
      title: 'تصفية التكاليف',
      icon: Icons.tune_rounded,
      children: [
        _DocSubjectPicker(
          subjects: subjects,
          subjectId: subjectId,
          onChanged: onSubjectChanged,
        ),
        const SizedBox(height: 12),
        _DocSegmentFilter(
          value: status,
          onChanged: onStatusChanged,
          choices: const [
            _DocFilterChoice(
              value: 'all',
              label: 'الكل',
              icon: Icons.apps_rounded,
              color: AppColors.royalBlue,
            ),
            _DocFilterChoice(
              value: 'upcoming',
              label: 'نشطة',
              icon: Icons.upcoming_rounded,
              color: AppColors.success,
            ),
            _DocFilterChoice(
              value: 'overdue',
              label: 'متأخرة',
              icon: Icons.warning_rounded,
              color: AppColors.danger,
            ),
          ],
        ),
      ],
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({
    required this.assignment,
    required this.onDetails,
    required this.onEdit,
    required this.onDelete,
  });

  final _Json assignment;
  final VoidCallback onDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final subject = _docMap(assignment['subject']);
    final due = DateTime.tryParse(_docText(assignment['due_date']));
    final isOverdue = due != null && due.isBefore(DateTime.now());
    final statusColor = isOverdue ? AppColors.danger : AppColors.success;
    final requiresSubmission = _docBool(assignment['requires_submission']);

    return InkWell(
      onTap: onDetails,
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
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 18,
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
                    gradient: LinearGradient(
                      colors: [
                        AppColors.royalBlue,
                        AppColors.royalBlueDark.withValues(alpha: 0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.royalBlue.withValues(alpha: 0.16),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.assignment_turned_in_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _docText(assignment['title'], 'تكليف'),
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
                        _docText(subject['name'], '-'),
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
                _DocPill(
                  isOverdue ? 'متأخر' : 'قادم',
                  statusColor,
                  icon: isOverdue
                      ? Icons.warning_rounded
                      : Icons.event_available_rounded,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor.withValues(alpha: 0.12)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    color: statusColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'موعد التسليم: ${_docDate(assignment['due_date'])}',
                      style: TextStyle(
                        color: statusColor,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DocPill(
                  '${_docInt(assignment['submissions_count'])} تسليم',
                  AppColors.royalBlue,
                  icon: Icons.upload_file_rounded,
                ),
                _DocPill(
                  requiresSubmission ? 'يتطلب تسليم' : 'بدون تسليم',
                  requiresSubmission ? AppColors.warning : AppColors.slate500,
                  icon: requiresSubmission
                      ? Icons.task_alt_rounded
                      : Icons.visibility_rounded,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onDetails,
                    icon: const Icon(Icons.visibility_rounded, size: 18),
                    label: const Text(
                      'التسليمات',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.royalBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.royalBlue.withValues(
                      alpha: 0.08,
                    ),
                    foregroundColor: AppColors.royalBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.filledTonal(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_rounded, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.danger.withValues(alpha: 0.08),
                    foregroundColor: AppColors.danger,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.all(12),
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

class _AssignmentSubmissionsPanel extends ConsumerStatefulWidget {
  const _AssignmentSubmissionsPanel({
    required this.assignment,
    this.showHeader = true,
  });

  final _Json assignment;
  final bool showHeader;

  @override
  ConsumerState<_AssignmentSubmissionsPanel> createState() =>
      _AssignmentSubmissionsPanelState();
}

class _AssignmentSubmissionsPanelState
    extends ConsumerState<_AssignmentSubmissionsPanel> {
  late Future<Map<String, dynamic>> _future = _fetch();
  bool _exporting = false;

  Future<Map<String, dynamic>> _fetch() {
    return ref
        .read(staffRepositoryProvider)
        .get('/doctor/assignments/${widget.assignment['id']}/submissions');
  }

  void _reload() => setState(() {
    _future = _fetch();
  });

  Future<void> _export() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final bytes = await ref
          .read(staffRepositoryProvider)
          .download(
            '/doctor/assignments/${widget.assignment['id']}/submissions/export',
          );
      final result = await DownloadService.saveBytes(
        bytes: bytes,
        fileName: 'assignment_submissions_${widget.assignment['id']}.csv',
        section: 'AssignmentReports',
      );
      if (!mounted) return;
      await showMoeenInfoDialog(
        context: context,
        title: 'تم التصدير',
        message: 'تم حفظ ملف التسليمات في:\n${result.path}',
        icon: Icons.file_download_done_rounded,
        color: AppColors.success,
      );
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _downloadSubmissionFile(_Json submission) async {
    final url = _docText(submission['file_url']);
    final fileName = _docText(submission['file_name'], 'assignment_submission');
    if (url.isEmpty) {
      await showMoeenInfoDialog(
        context: context,
        title: 'لا يوجد مرفق',
        message: 'هذا التسليم لا يحتوي على ملف قابل للتحميل.',
        icon: Icons.info_rounded,
        color: AppColors.warning,
      );
      return;
    }

    try {
      final localPath = await DownloadService.openMoeenFile(
        fileName: fileName,
        section: 'AssignmentSubmissions',
      );
      if (localPath != null) {
        if (!mounted) return;
        await showMoeenInfoDialog(
          context: context,
          title: 'تم فتح المرفق',
          message: 'تم فتح ملف التسليم من التخزين الداخلي:\n$localPath',
          icon: Icons.folder_open_rounded,
          color: AppColors.success,
        );
        return;
      }

      final result = await DownloadService.downloadUrlToMoeenFolder(
        url: url,
        fileName: fileName,
        section: 'AssignmentSubmissions',
      );
      if (!mounted) return;
      await showMoeenInfoDialog(
        context: context,
        title: result.opened ? 'تم فتح المرفق' : 'تم تحميل المرفق',
        message: result.opened
            ? 'تم تحميل وفتح ملف التسليم بنجاح.\n${result.path}'
            : 'تم حفظ ملف التسليم في:\n${result.path}',
        icon: result.opened
            ? Icons.check_circle_rounded
            : Icons.file_download_done_rounded,
        color: AppColors.success,
      );
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
        final submissions = _docList(_docData(snapshot.data ?? const {}));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showHeader) ...[
              Text(
                _docText(widget.assignment['title'], 'تكليف'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _docText(widget.assignment['description'], '-'),
                style: const TextStyle(color: AppColors.slate500),
              ),
              const SizedBox(height: 14),
            ],
            FilledButton.icon(
              onPressed: _exporting ? null : _export,
              icon: _exporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.table_chart_rounded),
              label: const Text('تصدير التسليمات'),
            ),
            const SizedBox(height: 16),
            if (submissions.isEmpty)
              const _DocEmpty('لا توجد تسليمات لهذا التكليف.')
            else
              ...submissions.map(
                (submission) => _SubmissionCard(
                  submission: submission,
                  onReview: () => _showReview(submission),
                  onDownload: () => _downloadSubmissionFile(submission),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _showReview(_Json submission) async {
    final grade = TextEditingController(text: _docText(submission['grade']));
    final feedback = TextEditingController(
      text: _docText(submission['feedback']),
    );
    var status = _docText(submission['status'], 'accepted');

    try {
      final ok = await showMoeenBottomSheet<bool>(
        context: context,
        title: 'مراجعة التسليم وتقييمه',
        icon: Icons.rate_review_rounded,
        color: AppColors.royalBlue,
        child: StatefulBuilder(
          builder: (sheetContext, setLocal) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SubmissionReviewSummary(
                submission: submission,
                onDownload: () => _downloadSubmissionFile(submission),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setLocal(() => status = 'accepted'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: status == 'accepted'
                              ? AppColors.success.withValues(alpha: 0.08)
                              : AppColors.slate50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: status == 'accepted'
                                ? AppColors.success
                                : AppColors.slate200,
                            width: status == 'accepted' ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: status == 'accepted'
                                  ? AppColors.success
                                  : AppColors.slate400,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'قبول',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                color: status == 'accepted'
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
                    child: GestureDetector(
                      onTap: () => setLocal(() => status = 'rejected'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: status == 'rejected'
                              ? AppColors.danger.withValues(alpha: 0.08)
                              : AppColors.slate50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: status == 'rejected'
                                ? AppColors.danger
                                : AppColors.slate200,
                            width: status == 'rejected' ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cancel_rounded,
                              color: status == 'rejected'
                                  ? AppColors.danger
                                  : AppColors.slate400,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'رفض',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                color: status == 'rejected'
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
              const SizedBox(height: 16),
              TextField(
                controller: grade,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  labelText: 'الدرجة المستحقة',
                  labelStyle: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                  ),
                  filled: true,
                  fillColor: AppColors.slate50,
                  prefixIcon: const Icon(
                    Icons.grade_rounded,
                    color: AppColors.royalBlue,
                  ),
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
                    borderSide: const BorderSide(
                      color: AppColors.royalBlue,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: feedback,
                minLines: 3,
                maxLines: 5,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  labelText: 'ملاحظات وتوجيهات الدكتور',
                  labelStyle: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                  ),
                  filled: true,
                  fillColor: AppColors.slate50,
                  alignLabelWithHint: true,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 60),
                    child: Icon(
                      Icons.comment_rounded,
                      color: AppColors.royalBlue,
                    ),
                  ),
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
                    borderSide: const BorderSide(
                      color: AppColors.royalBlue,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.slate600,
                        side: const BorderSide(color: AppColors.slate300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'إلغاء',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(sheetContext, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.royalBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'حفظ المراجعة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w900,
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

      if (ok != true) return;

      await ref
          .read(staffRepositoryProvider)
          .post('/doctor/submissions/${submission['id']}/review', {
            'status': status,
            'feedback': feedback.text.trim(),
            'grade': int.tryParse(grade.text.trim()),
          });
      if (!mounted) return;
      _reload();
      _docSnack(context, 'تم تقييم التسليم.', color: AppColors.success);
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    } finally {
      grade.dispose();
      feedback.dispose();
    }
  }
}

class _SubmissionCard extends StatelessWidget {
  const _SubmissionCard({
    required this.submission,
    required this.onReview,
    required this.onDownload,
  });

  final _Json submission;
  final VoidCallback onReview;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final student = _docMap(submission['student']);
    final status = _docText(submission['status'], 'pending');
    final fileName = _shortDocText(_docText(submission['file_name']), 34);
    final studentName = _docText(student['name'], 'طالب');
    final avatarLetter = studentName.isNotEmpty
        ? studentName.characters.first
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
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
                radius: 22,
                backgroundColor: AppColors.royalBlue.withValues(alpha: 0.08),
                child: Text(
                  avatarLetter,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.royalBlue,
                    fontSize: 16,
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
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                        color: AppColors.midnight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _docText(student['student_number'], '-'),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: AppColors.slate500,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _DocPill(_docStatusLabel(status), _docStatusColor(status)),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DocPill(
                'الدرجة: ${_docText(submission['grade'], '-')}',
                AppColors.royalBlue,
                icon: Icons.grade_rounded,
              ),
              _DocPill(
                'تاريخ: ${_docDate(submission['submitted_at'])}',
                AppColors.warning,
                icon: Icons.calendar_month_rounded,
              ),
              if (_docText(submission['file_name']).isNotEmpty)
                _DocPill(
                  fileName,
                  AppColors.teal,
                  icon: Icons.attach_file_rounded,
                ),
            ],
          ),
          if (_docText(submission['notes']).isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.rate_review_outlined,
                    size: 18,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _docText(submission['notes']),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate700,
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_docText(submission['feedback']).isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.royalBlue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.royalBlue.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.comment_bank_outlined,
                    size: 18,
                    color: AppColors.royalBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _docText(submission['feedback']),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate700,
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              if (_docText(submission['file_url']).isNotEmpty) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDownload,
                    icon: const Icon(Icons.file_download_rounded, size: 18),
                    label: const Text(
                      'فتح المرفق',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.teal,
                      side: const BorderSide(color: AppColors.teal),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: FilledButton.icon(
                  onPressed: onReview,
                  icon: const Icon(Icons.rate_review_rounded, size: 18),
                  label: const Text(
                    'مراجعة وتقييم',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.royalBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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

class _SubmissionReviewSummary extends StatelessWidget {
  const _SubmissionReviewSummary({
    required this.submission,
    required this.onDownload,
  });

  final _Json submission;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final student = _docMap(submission['student']);
    final hasFile = _docText(submission['file_url']).isNotEmpty;
    final studentName = _docText(student['name'], 'طالب');
    final avatarLetter = studentName.isNotEmpty
        ? studentName.characters.first
        : '?';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.royalBlue.withValues(alpha: 0.1),
                child: Text(
                  avatarLetter,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.royalBlue,
                    fontSize: 14,
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
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: AppColors.midnight,
                      ),
                    ),
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
              _DocPill(
                _docStatusLabel(_docText(submission['status'], 'pending')),
                _docStatusColor(_docText(submission['status'], 'pending')),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DocPill(
                'تاريخ التسليم: ${_docDate(submission['submitted_at'])}',
                AppColors.warning,
                icon: Icons.calendar_month_rounded,
              ),
              _DocPill(
                _docBool(submission['is_late']) ? 'متأخر' : 'ضمن الموعد',
                _docBool(submission['is_late'])
                    ? AppColors.danger
                    : AppColors.success,
                icon: _docBool(submission['is_late'])
                    ? Icons.warning_rounded
                    : Icons.check_circle_rounded,
              ),
              _DocPill(
                'الدرجة: ${_docText(submission['grade'], '-')}',
                AppColors.royalBlue,
                icon: Icons.grade_rounded,
              ),
              if (_docText(submission['formatted_file_size']).isNotEmpty)
                _DocPill(
                  _docText(submission['formatted_file_size']),
                  AppColors.teal,
                  icon: Icons.data_object_rounded,
                ),
            ],
          ),
          if (_docText(submission['notes']).isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'ملاحظات الطالب:',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: AppColors.slate500,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _docText(submission['notes']),
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.slate700,
              ),
            ),
          ],
          if (_docText(submission['feedback']).isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'ملاحظات الدكتور الحالية:',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: AppColors.slate500,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _docText(submission['feedback']),
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.slate700,
              ),
            ),
          ],
          if (hasFile) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onDownload,
                icon: const Icon(Icons.file_download_rounded, size: 18),
                label: Text(
                  _docText(submission['file_name'], 'تحميل المرفق'),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.royalBlue,
                  side: const BorderSide(color: AppColors.royalBlue),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
