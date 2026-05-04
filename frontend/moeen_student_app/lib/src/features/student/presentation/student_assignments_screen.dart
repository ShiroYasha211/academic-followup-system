part of 'student_content_screens.dart';

class StudentAssignmentsScreen extends ConsumerStatefulWidget {
  const StudentAssignmentsScreen({super.key});

  static const route = '/student/assignments';
  static String detailsPath(int id) => '/student/assignments/$id';

  @override
  ConsumerState<StudentAssignmentsScreen> createState() =>
      _StudentAssignmentsScreenState();
}

class _StudentAssignmentsScreenState
    extends ConsumerState<StudentAssignmentsScreen>
    with SingleTickerProviderStateMixin {
  String _sortBy = 'due_date';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_assignmentsProvider(_sortBy));
    return StudentShell(
      currentIndex: 14,
      title: 'مركز الإنجاز',
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_assignmentsProvider(_sortBy)),
        builder: (data) {
          final active = asList(data['active']).map(asMap).toList();
          final past = asList(data['past']).map(asMap).toList();

          final pending = active
              .where((item) => text(item, 'status') != 'submitted')
              .toList();
          final submitted = active
              .where((item) => text(item, 'status') == 'submitted')
              .toList();
          final missing = past;

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                  child: Column(
                    children: [
                      _AchievementHeader(
                        total:
                            pending.length + submitted.length + missing.length,
                        done: submitted.length,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.slate100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          labelColor: AppColors.midnight,
                          unselectedLabelColor: AppColors.slate500,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                          tabs: const [
                            Tab(text: 'قيد الانتظار'),
                            Tab(text: 'تم التسليم'),
                            Tab(text: 'متأخرة'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _AssignmentList(items: pending, onPriority: _setPriority),
                _AssignmentList(items: submitted, onPriority: _setPriority),
                _AssignmentList(items: missing, onPriority: _setPriority),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _setPriority(Map<String, dynamic> item, int priority) async {
    await _runSnack(
      context,
      () => ref
          .read(studentContentRepositoryProvider)
          .updateAssignmentPriority(
            assignmentId: number(item, 'id').toInt(),
            priority: priority,
          ),
      onDone: () => ref.invalidate(_assignmentsProvider(_sortBy)),
    );
  }
}

class StudentAssignmentDetailsScreen extends ConsumerStatefulWidget {
  const StudentAssignmentDetailsScreen({super.key, required this.assignmentId});

  final int assignmentId;

  @override
  ConsumerState<StudentAssignmentDetailsScreen> createState() =>
      _StudentAssignmentDetailsScreenState();
}

class _StudentAssignmentDetailsScreenState
    extends ConsumerState<StudentAssignmentDetailsScreen> {
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_assignmentDetailsProvider(widget.assignmentId));
    return StudentShell(
      currentIndex: 14,
      title: 'تفاصيل التكليف',
      child: _AsyncBody(
        state: state,
        onRetry: () =>
            ref.invalidate(_assignmentDetailsProvider(widget.assignmentId)),
        builder: (data) {
          final assignment = asMap(data['assignment']);
          final submission = asMap(data['submission']);
          final status = text(submission, 'status', fallback: 'pending');
          final isGraded = text(submission, 'grade').isNotEmpty;

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
            children: [
              _StatusBanner(status: status, isGraded: isGraded),
              const SizedBox(height: 16),
              _AssignmentHeaderInfo(
                assignment: assignment,
                submission: submission,
              ),
              const SizedBox(height: 20),
              _AssignmentDescription(
                description: text(assignment, 'description'),
              ),
              const SizedBox(height: 20),
              if (submission.isNotEmpty) ...[
                _SubmissionDetails(submission: submission),
                const SizedBox(height: 20),
              ],
              if (text(submission, 'feedback').isNotEmpty) ...[
                _ProfessorFeedback(
                  feedback: text(submission, 'feedback'),
                  grade: text(submission, 'grade'),
                ),
                const SizedBox(height: 24),
              ],
              FilledButton.icon(
                onPressed: _submitting ? null : () => _submit(assignment),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.upload_file_rounded),
                label: Text(
                  submission.isEmpty
                      ? 'تسليم التكليف الآن'
                      : 'تحديث التسليم السابق',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submit(Map<String, dynamic> assignment) async {
    final formKey = GlobalKey<FormState>();
    final notes = TextEditingController();
    PlatformFile? file;
    String? fileError;
    final requiresFile =
        boolValue(assignment, 'requires_file') ||
        boolValue(assignment, 'requires_submission');
    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: 'تسليم التكليف',
      icon: Icons.upload_file_rounded,
      color: AppColors.royalBlue,
      child: StatefulBuilder(
        builder: (sheetContext, setLocal) => Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (requiresFile) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.28),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.attach_file_rounded, color: AppColors.warning),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'هذا التكليف يتطلب إرفاق ملف قبل الإرسال.',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: notes,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات اختيارية',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles(
                    withData: false,
                  );
                  if (result != null && result.files.isNotEmpty) {
                    setLocal(() {
                      file = result.files.first;
                      fileError = null;
                    });
                  }
                },
                icon: const Icon(Icons.attach_file_rounded),
                label: Text(file?.name ?? 'اختيار ملف'),
              ),
              if (fileError != null) ...[
                const SizedBox(height: 6),
                Text(
                  fileError!,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  final valid = formKey.currentState?.validate() ?? true;
                  if (!valid) return;
                  if (requiresFile && file?.path == null) {
                    setLocal(() => fileError = 'اختر ملف التكليف أولاً.');
                    return;
                  }
                  Navigator.pop(sheetContext, true);
                },
                child: const Text('إرسال'),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true) return;
    if (requiresFile && file?.path == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('هذا التكليف يتطلب إرفاق ملف.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final message = await ref
          .read(studentContentRepositoryProvider)
          .submitAssignment(
            assignmentId: widget.assignmentId,
            notes: notes.text,
            filePath: file?.path,
            fileName: file?.name,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.success),
      );
      ref.invalidate(_assignmentDetailsProvider(widget.assignmentId));
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

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({required this.item, required this.onPriority});

  final Map<String, dynamic> item;
  final ValueChanged<int> onPriority;

  @override
  Widget build(BuildContext context) {
    final status = text(item, 'status', fallback: 'available');
    final requiresFile =
        boolValue(item, 'requires_file') ||
        boolValue(item, 'requires_submission');
    final dueDateStr = text(item, 'due_date');
    final dueDate = DateTime.tryParse(dueDateStr);
    final isUrgent =
        dueDate != null &&
        dueDate.isAfter(DateTime.now()) &&
        dueDate.difference(DateTime.now()).inHours < 48;

    final color = status == 'submitted'
        ? AppColors.success
        : (status == 'missing'
              ? AppColors.rose
              : (isUrgent ? AppColors.orange : AppColors.royalBlue));

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: isUrgent
            ? [
                BoxShadow(
                  color: AppColors.orange.withValues(alpha: 0.15),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => context.push(
            StudentAssignmentsScreen.detailsPath(number(item, 'id').toInt()),
          ),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isUrgent
                    ? AppColors.orange.withValues(alpha: 0.4)
                    : color.withValues(alpha: 0.12),
                width: isUrgent ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        status == 'submitted'
                            ? Icons.check_circle_rounded
                            : Icons.assignment_rounded,
                        color: color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            text(item, 'title', fallback: 'تكليف'),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.midnight,
                                ),
                          ),
                          Text(
                            text(item, 'subject_name', fallback: 'مادة'),
                            style: const TextStyle(
                              color: AppColors.slate500,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _PriorityFlag(
                      priority: number(item, 'my_priority').toInt(),
                      onChanged: onPriority,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (isUrgent && status != 'submitted')
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timer_rounded,
                          color: AppColors.orange,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'بقي ${_getTimeLeft(dueDate)}',
                          style: const TextStyle(
                            color: AppColors.orange,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (requiresFile) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.royalBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.royalBlue.withValues(alpha: 0.16),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.upload_file_rounded,
                          color: AppColors.royalBlue,
                          size: 15,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'يتطلب رفع ملف',
                          style: TextStyle(
                            color: AppColors.royalBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: AppColors.slate400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateOnly(dueDateStr),
                          style: const TextStyle(
                            color: AppColors.slate600,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _assignmentStatus(status),
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTimeLeft(DateTime? date) {
    if (date == null) return '';
    final diff = date.difference(DateTime.now());
    if (diff.inDays > 0) return '${diff.inDays} يوم';
    if (diff.inHours > 0) return '${diff.inHours} ساعة';
    return '${diff.inMinutes} دقيقة';
  }
}

class _AchievementHeader extends StatelessWidget {
  const _AchievementHeader({required this.total, required this.done});
  final int total;
  final int done;

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0.0 : (done / total);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.midnight, AppColors.royalBlueDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'معدل الإنجاز 📈',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'أنجزت $done من أصل $total تكاليف',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.gold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${(percent * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignmentList extends StatelessWidget {
  const _AssignmentList({required this.items, required this.onPriority});
  final List<Map<String, dynamic>> items;
  final Function(Map<String, dynamic>, int) onPriority;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(message: 'لا توجد تكليفات في هذا القسم.');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 90),
      itemCount: items.length,
      itemBuilder: (ctx, i) => _AssignmentCard(
        item: items[i],
        onPriority: (p) => onPriority(items[i], p),
      ),
    );
  }
}

class _PriorityFlag extends StatelessWidget {
  const _PriorityFlag({required this.priority, required this.onChanged});
  final int priority;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final color = priority == 2
        ? AppColors.rose
        : (priority == 1 ? AppColors.orange : AppColors.slate400);
    return PopupMenuButton<int>(
      onSelected: onChanged,
      itemBuilder: (_) => const [
        PopupMenuItem(value: 0, child: Text('عادية')),
        PopupMenuItem(value: 1, child: Text('مهمة')),
        PopupMenuItem(value: 2, child: Text('عاجلة')),
      ],
      child: Icon(Icons.flag_rounded, color: color),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status, required this.isGraded});
  final String status;
  final bool isGraded;

  @override
  Widget build(BuildContext context) {
    final normalized = isGraded && status == 'pending' ? 'accepted' : status;
    final color = _submissionReviewColor(normalized);
    final icon = switch (normalized) {
      'accepted' || 'approved' || 'graded' => Icons.verified_rounded,
      'rejected' => Icons.cancel_rounded,
      'missing' => Icons.error_rounded,
      'pending' || 'submitted' => Icons.pending_actions_rounded,
      _ => Icons.assignment_rounded,
    };
    final label = _submissionReviewLabel(normalized);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

String _submissionReviewLabel(String status) {
  return switch (status) {
    'accepted' || 'approved' || 'graded' => 'مقبول',
    'rejected' => 'مرفوض',
    'pending' || 'submitted' => 'قيد المراجعة',
    'missing' => 'متأخر',
    _ => _assignmentStatus(status),
  };
}

Color _submissionReviewColor(String status) {
  return switch (status) {
    'accepted' || 'approved' || 'graded' => AppColors.success,
    'rejected' => AppColors.danger,
    'pending' || 'submitted' => AppColors.warning,
    'missing' => AppColors.rose,
    _ => AppColors.royalBlue,
  };
}

class _AssignmentHeaderInfo extends StatelessWidget {
  const _AssignmentHeaderInfo({
    required this.assignment,
    required this.submission,
  });
  final Map<String, dynamic> assignment;
  final Map<String, dynamic> submission;

  @override
  Widget build(BuildContext context) {
    final requiresFile =
        boolValue(assignment, 'requires_file') ||
        boolValue(assignment, 'requires_submission');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text(assignment, 'title'),
            style: const TextStyle(
              color: AppColors.midnight,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text(
              asMap(assignment['subject']),
              'name',
              fallback: text(assignment, 'subject_name'),
            ),
            style: const TextStyle(
              color: AppColors.slate500,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: (requiresFile ? AppColors.warning : AppColors.success)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (requiresFile ? AppColors.warning : AppColors.success)
                    .withValues(alpha: 0.24),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  requiresFile
                      ? Icons.upload_file_rounded
                      : Icons.check_circle_rounded,
                  color: requiresFile ? AppColors.warning : AppColors.success,
                  size: 16,
                ),
                const SizedBox(width: 7),
                Text(
                  requiresFile
                      ? 'يتطلب إرفاق ملف عند التسليم'
                      : 'لا يتطلب إرفاق ملف',
                  style: TextStyle(
                    color: requiresFile ? AppColors.warning : AppColors.success,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            children: [
              _DetailInfo(
                icon: Icons.calendar_today_rounded,
                label: 'الموعد النهائي',
                value: dateOnly(text(assignment, 'due_date')),
                color: AppColors.rose,
              ),
              _DetailInfo(
                icon: Icons.grade_rounded,
                label: 'الدرجة الكلية',
                value: text(assignment, 'marks').isNotEmpty
                    ? text(assignment, 'marks')
                    : text(submission, 'grade', fallback: 'غير محدد'),
                color: AppColors.goldDeep,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailInfo extends StatelessWidget {
  const _DetailInfo({
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
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
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
                    color: AppColors.slate500,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.midnight,
                    fontSize: 13,
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

class _AssignmentDescription extends StatelessWidget {
  const _AssignmentDescription({required this.description});
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'وصف التكليف',
          style: TextStyle(
            color: AppColors.midnight,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.slate50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.slate100),
          ),
          child: Text(
            description.isEmpty ? 'لا يوجد وصف متاح.' : description,
            style: const TextStyle(
              color: AppColors.slate700,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

class _SubmissionDetails extends StatelessWidget {
  const _SubmissionDetails({required this.submission});
  final Map<String, dynamic> submission;

  @override
  Widget build(BuildContext context) {
    final status = text(submission, 'status', fallback: 'pending');
    final grade = text(submission, 'grade');
    final normalized = grade.isNotEmpty && status == 'pending'
        ? 'accepted'
        : status;
    final color = _submissionReviewColor(normalized);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.cloud_done_rounded,
                color: AppColors.success,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'تفاصيل تسليمك',
                style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SubmissionRow(
            label: 'حالة التسليم',
            value: _submissionReviewLabel(normalized),
            icon: Icons.fact_check_rounded,
          ),
          const SizedBox(height: 12),
          _SubmissionRow(
            label: 'درجة التكليف',
            value: grade.isEmpty ? 'لم تحدد بعد' : grade,
            icon: Icons.grade_rounded,
          ),
          const SizedBox(height: 12),
          _SubmissionRow(
            label: 'الملف المرفق',
            value: text(submission, 'file_name'),
            icon: Icons.insert_drive_file_rounded,
          ),
          const SizedBox(height: 12),
          _SubmissionRow(
            label: 'تاريخ التسليم',
            value: dateOnly(text(submission, 'submitted_at')),
            icon: Icons.access_time_filled_rounded,
          ),
        ],
      ),
    );
  }
}

class _SubmissionRow extends StatelessWidget {
  const _SubmissionRow({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.slate400),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(color: AppColors.slate500, fontSize: 12),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.midnight,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ProfessorFeedback extends StatelessWidget {
  const _ProfessorFeedback({required this.feedback, required this.grade});
  final String feedback;
  final String grade;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.royalBlue.withValues(alpha: 0.05), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.forum_rounded,
                    color: AppColors.royalBlue,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'ملاحظات المحاضر',
                    style: TextStyle(
                      color: AppColors.royalBlue,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              if (grade.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.goldDeep,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'الدرجة: $grade',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            feedback,
            style: const TextStyle(
              color: AppColors.slate700,
              fontSize: 14,
              height: 1.6,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
