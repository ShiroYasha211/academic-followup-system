part of 'student_content_screens.dart';

class StudentAuthorizedGradesScreen extends ConsumerStatefulWidget {
  const StudentAuthorizedGradesScreen({super.key});

  static const route = '/student/authorized-grades';
  static String detailsPath(int categoryId) => '$route/$categoryId';

  @override
  ConsumerState<StudentAuthorizedGradesScreen> createState() =>
      _StudentAuthorizedGradesScreenState();
}

class _StudentAuthorizedGradesScreenState
    extends ConsumerState<StudentAuthorizedGradesScreen> {
  int _refreshTick = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_authorizedGradesProvider(_refreshTick));

    return StudentShell(
      currentIndex: 36,
      title: 'الدرجات المفوضة',
      child: _AsyncBody(
        state: state,
        onRetry: () {
          setState(() => _refreshTick++);
          ref.invalidate(_authorizedGradesProvider(_refreshTick));
        },
        builder: (data) {
          final direct = asList(data['direct_delegations']).map(asMap).toList();
          final helpers = asList(data['helper_tasks']).map(asMap).toList();
          final total = direct.length + helpers.length;

          return RefreshIndicator(
            onRefresh: () async => setState(() => _refreshTick++),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
              children: [
                _HeroPanel(
                  title: '$total تفويض نشط',
                  subtitle:
                      'أدخل الدرجات التي فوضك الدكتور أو المندوب برصدها، وستبقى قيد المراجعة حتى يعتمدها الدكتور.',
                  icon: Icons.assignment_ind_rounded,
                  colors: const [Color(0xFF2563EB), Color(0xFF14B8A6)],
                ),
                const SizedBox(height: 22),
                if (total == 0)
                  const EmptyState(
                    message: 'لا توجد تفويضات درجات لحسابك حاليًا.',
                  )
                else ...[
                  if (direct.isNotEmpty) ...[
                    const SectionTitle(
                      title: 'تفويضات الدكتور',
                      icon: Icons.school_rounded,
                    ),
                    const SizedBox(height: 12),
                    ...direct.map(
                      (item) => _AuthorizedGradeCard(
                        item: item,
                        sourceLabel: 'تفويض مباشر',
                        sourceIcon: Icons.verified_user_rounded,
                        onTap: () => context.push(
                          StudentAuthorizedGradesScreen.detailsPath(
                            number(item, 'id').toInt(),
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (helpers.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const SectionTitle(
                      title: 'مهام مساعدة',
                      icon: Icons.group_rounded,
                    ),
                    const SizedBox(height: 12),
                    ...helpers.map((task) {
                      final category = asMap(task['category']);
                      return _AuthorizedGradeCard(
                        item: category,
                        helperTask: task,
                        sourceLabel: 'مهمة من مندوب',
                        sourceIcon: Icons.manage_accounts_rounded,
                        onTap: () => context.push(
                          StudentAuthorizedGradesScreen.detailsPath(
                            number(category, 'id').toInt(),
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class StudentAuthorizedGradeDetailsScreen extends ConsumerStatefulWidget {
  const StudentAuthorizedGradeDetailsScreen({
    super.key,
    required this.categoryId,
  });

  final int categoryId;

  @override
  ConsumerState<StudentAuthorizedGradeDetailsScreen> createState() =>
      _StudentAuthorizedGradeDetailsScreenState();
}

class _StudentAuthorizedGradeDetailsScreenState
    extends ConsumerState<StudentAuthorizedGradeDetailsScreen> {
  final _controllers = <int, TextEditingController>{};
  String _query = '';
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_authorizedGradeDetailsProvider(widget.categoryId));

    return StudentShell(
      currentIndex: 36,
      title: 'رصد الدرجات',
      parentRoute: StudentAuthorizedGradesScreen.route,
      child: _AsyncBody(
        state: state,
        onRetry: () =>
            ref.invalidate(_authorizedGradeDetailsProvider(widget.categoryId)),
        builder: (data) {
          final category = asMap(data['category']);
          final contextData = asMap(data['delegation_context']);
          final students = asList(data['students']).map(asMap).toList();
          final maxScore = number(category, 'max_score').toDouble();
          _syncControllers(students);

          final filtered = students.where((student) {
            final q = _query.trim();
            if (q.isEmpty) return true;
            return text(student, 'name').contains(q) ||
                text(student, 'student_number').contains(q);
          }).toList();

          return ListView(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              36 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            children: [
              _HeroPanel(
                title: text(category, 'name', fallback: 'تصنيف درجات'),
                subtitle:
                    '${text(asMap(category['subject']), 'name', fallback: 'مادة')} • الدرجة القصوى ${_formatScore(maxScore)}',
                icon: Icons.edit_note_rounded,
                colors: const [Color(0xFF0F766E), Color(0xFF2563EB)],
              ),
              const SizedBox(height: 16),
              _DelegationScopeCard(
                data: contextData,
                studentsCount: students.length,
              ),
              const SizedBox(height: 14),
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  labelText: 'بحث باسم الطالب أو رقم القيد',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                const EmptyState(message: 'لا توجد نتائج مطابقة للبحث.')
              else
                ...filtered.map(
                  (student) => _AuthorizedGradeStudentCard(
                    student: student,
                    controller: _controllers[number(student, 'id').toInt()]!,
                    maxScore: maxScore,
                  ),
                ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _saving ? null : () => _save(students, maxScore),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(_saving ? 'جار الإرسال...' : 'إرسال للمراجعة'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _syncControllers(List<Map<String, dynamic>> students) {
    final ids = students
        .map((student) => number(student, 'id').toInt())
        .toSet();
    for (final id
        in _controllers.keys.where((id) => !ids.contains(id)).toList()) {
      _controllers.remove(id)?.dispose();
    }

    for (final student in students) {
      final id = number(student, 'id').toInt();
      _controllers.putIfAbsent(id, () {
        final grade = asMap(student['current_grade']);
        return TextEditingController(text: text(grade, 'score'));
      });
    }
  }

  Future<void> _save(
    List<Map<String, dynamic>> students,
    double maxScore,
  ) async {
    final grades = <Map<String, dynamic>>[];

    for (final student in students) {
      final id = number(student, 'id').toInt();
      final raw = _controllers[id]?.text.trim() ?? '';
      if (raw.isEmpty) continue;
      final score = double.tryParse(raw);
      if (score == null || score < 0 || score > maxScore) {
        await showMoeenInfoDialog(
          context: context,
          title: 'درجة غير صحيحة',
          message:
              'تأكد أن كل درجة رقمية ولا تتجاوز ${_formatScore(maxScore)}.',
          icon: Icons.error_outline_rounded,
          color: AppColors.danger,
        );
        return;
      }
      grades.add({'student_id': id, 'score': score});
    }

    if (grades.isEmpty) {
      await showMoeenInfoDialog(
        context: context,
        title: 'لا توجد درجات',
        message: 'أدخل درجة طالب واحد على الأقل قبل الإرسال.',
        icon: Icons.info_outline_rounded,
        color: AppColors.goldDeep,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final message = await ref
          .read(studentContentRepositoryProvider)
          .saveAuthorizedGrades(categoryId: widget.categoryId, grades: grades);
      if (!mounted) return;
      ref.invalidate(_authorizedGradeDetailsProvider(widget.categoryId));
      ref.invalidate(_authorizedGradesProvider);
      await showMoeenInfoDialog(
        context: context,
        title: 'تم إرسال الدرجات',
        message: message,
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      await showMoeenInfoDialog(
        context: context,
        title: 'تعذر الحفظ',
        message: error.message,
        icon: Icons.error_outline_rounded,
        color: AppColors.danger,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _AuthorizedGradeCard extends StatelessWidget {
  const _AuthorizedGradeCard({
    required this.item,
    required this.sourceLabel,
    required this.sourceIcon,
    required this.onTap,
    this.helperTask,
  });

  final Map<String, dynamic> item;
  final Map<String, dynamic>? helperTask;
  final String sourceLabel;
  final IconData sourceIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subject = asMap(item['subject']);
    final doctor = asMap(item['doctor']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.royalBlue.withValues(alpha: 0.1),
                    child: Icon(sourceIcon, color: AppColors.royalBlue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          text(item, 'name', fallback: 'تصنيف درجات'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          text(subject, 'name', fallback: 'مادة غير محددة'),
                          style: const TextStyle(
                            color: AppColors.slate500,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_left_rounded),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MiniBadge(label: sourceLabel, color: AppColors.royalBlue),
                  _MiniBadge(
                    label: 'د. ${text(doctor, 'name', fallback: 'غير محدد')}',
                    color: AppColors.success,
                  ),
                  _MiniBadge(
                    label:
                        '${_formatScore(number(item, 'max_score').toDouble())} درجة',
                    color: AppColors.goldDeep,
                  ),
                  if (helperTask != null)
                    _MiniBadge(
                      label: text(
                        helperTask!,
                        'title',
                        fallback: 'مهمة مساعدة',
                      ),
                      color: AppColors.violet,
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

class _DelegationScopeCard extends StatelessWidget {
  const _DelegationScopeCard({required this.data, required this.studentsCount});

  final Map<String, dynamic> data;
  final int studentsCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.royalBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'النطاق المتاح: $studentsCount طالب • المسؤول: ${text(data, 'doctor_name', fallback: 'الدكتور')}',
              style: const TextStyle(
                color: AppColors.slate700,
                fontWeight: FontWeight.w800,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthorizedGradeStudentCard extends StatelessWidget {
  const _AuthorizedGradeStudentCard({
    required this.student,
    required this.controller,
    required this.maxScore,
  });

  final Map<String, dynamic> student;
  final TextEditingController controller;
  final double maxScore;

  @override
  Widget build(BuildContext context) {
    final current = asMap(student['current_grade']);
    final status = text(current, 'status');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.slate100,
            child: Text(
              text(
                student,
                'name',
                fallback: 'ط',
              ).characters.take(1).toString(),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text(student, 'name', fallback: 'طالب'),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  '${text(student, 'student_number', fallback: '-')} • ${_authorizedRoleLabel(text(student, 'role'))}',
                  style: const TextStyle(
                    color: AppColors.slate500,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (status.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    'الحالة الحالية: ${_gradeStatusLabel(status)}',
                    style: TextStyle(
                      color: _authorizedGradeStatusColor(status),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            width: 88,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: 'من ${_formatScore(maxScore)}',
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatScore(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(2);
}

String _authorizedRoleLabel(String role) {
  return switch (role) {
    'delegate' => 'مندوب',
    'practical_delegate' => 'مندوب عملي',
    _ => 'طالب',
  };
}

Color _authorizedGradeStatusColor(String status) {
  return switch (status) {
    'approved' => AppColors.success,
    'rejected' => AppColors.danger,
    'pending' => AppColors.goldDeep,
    _ => AppColors.slate500,
  };
}
