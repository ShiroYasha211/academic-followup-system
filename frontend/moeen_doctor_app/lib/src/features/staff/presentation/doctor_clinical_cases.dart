part of 'staff_screens.dart';

class _CaseCard extends StatelessWidget {
  const _CaseCard({
    required this.caseItem,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final _Json caseItem;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final status = _docText(caseItem['status'], 'active');
    final active = status == 'active';
    final statusColor = switch (status) {
      'active' => AppColors.success,
      'discharged' => AppColors.slate500,
      'transferred' => AppColors.warning,
      _ => AppColors.success,
    };
    final statusLabel = switch (status) {
      'active' => 'حالة نشطة',
      'discharged' => 'تم الخروج',
      'transferred' => 'تم التحويل',
      _ => 'نشطة',
    };

    final gender = _docText(caseItem['gender']) == 'female' ? 'أنثى' : 'ذكر';
    final age = _docText(caseItem['age'], '-');

    final center = _docText(_docMap(caseItem['training_center'])['name']);
    final dept = _docText(_docMap(caseItem['clinical_department'])['name']);
    final system = _docText(_docMap(caseItem['body_system'])['name']);
    final assignmentSummary = _docMap(caseItem['assignment_summary']);
    final similarSummary = _docMap(caseItem['similar_cases_summary']);
    final assignedStudents = _docInt(assignmentSummary['students_count']);
    final activeAssignments = _docInt(
      assignmentSummary['active_assignments_count'],
    );
    final similarCases = _docInt(similarSummary['cases_count']);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? AppColors.success.withValues(alpha: 0.15)
                : AppColors.slate200,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: active
                  ? AppColors.success.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 16,
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
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.medical_information_rounded,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _docText(caseItem['patient_name'], 'حالة سريرية'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.slate900,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _DocPill(
                            gender,
                            AppColors.royalBlue,
                            icon: Icons.person_rounded,
                          ),
                          const SizedBox(width: 6),
                          _DocPill(
                            '$age سنة',
                            AppColors.info,
                            icon: Icons.cake_rounded,
                          ),
                          const SizedBox(width: 6),
                          _DocPill(
                            statusLabel,
                            statusColor,
                            icon: Icons.circle_rounded,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (center.isNotEmpty)
                  _DocPill(
                    center,
                    AppColors.royalBlue,
                    icon: Icons.local_hospital_rounded,
                  ),
                if (dept.isNotEmpty)
                  _DocPill(
                    dept,
                    AppColors.info,
                    icon: Icons.account_tree_rounded,
                  ),
                if (system.isNotEmpty)
                  _DocPill(system, AppColors.teal, icon: Icons.biotech_rounded),
                if (assignedStudents > 0)
                  _DocPill(
                    'مكلف عليها $assignedStudents طالب',
                    activeAssignments > 0
                        ? AppColors.warning
                        : AppColors.success,
                    icon: Icons.groups_rounded,
                  ),
                if (similarCases > 0)
                  _DocPill(
                    '$similarCases حالة مشابهة',
                    AppColors.danger,
                    icon: Icons.warning_amber_rounded,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.slate100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'التشخيص والوصف السريري:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate500,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _docText(
                      caseItem['diagnosis_or_description'],
                      'لا يوجد تشخيص مضاف.',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.slate700,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text(
                      'تعديل الحالة',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Cairo',
                        fontSize: 12,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.royalBlue,
                      backgroundColor: AppColors.royalBlue.withValues(
                        alpha: 0.1,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onDelete,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    backgroundColor: AppColors.danger.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, size: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CaseDetails extends StatelessWidget {
  const _CaseDetails({required this.caseItem});

  final _Json caseItem;

  @override
  Widget build(BuildContext context) {
    final status = _docText(caseItem['status'], 'active');
    final statusColor = switch (status) {
      'active' => AppColors.success,
      'discharged' => AppColors.slate500,
      'transferred' => AppColors.warning,
      _ => AppColors.success,
    };
    final statusLabel = switch (status) {
      'active' => 'حالة نشطة ومتاحة للتدريب',
      'discharged' => 'تم خروج المريض',
      'transferred' => 'تم تحويل المريض لقسم/موقع آخر',
      _ => 'نشطة',
    };

    final gender = _docText(caseItem['gender']) == 'female' ? 'أنثى' : 'ذكر';
    final age = _docText(caseItem['age'], '-');
    final center = _docText(_docMap(caseItem['training_center'])['name'], '-');
    final dept = _docText(
      _docMap(caseItem['clinical_department'])['name'],
      '-',
    );
    final system = _docText(_docMap(caseItem['body_system'])['name'], '-');
    final assignmentSummary = _docMap(caseItem['assignment_summary']);
    final assignments = _docList(caseItem['assignments_preview']);
    final similarSummary = _docMap(caseItem['similar_cases_summary']);
    final similarCases = _docList(caseItem['similar_cases']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_rounded, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.badge_rounded,
                    color: AppColors.royalBlue,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'بيانات المريض الأساسية',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.slate800,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
              const Divider(
                height: 24,
                thickness: 1,
                color: AppColors.slate100,
              ),
              _DetailRow('اسم المريض', _docText(caseItem['patient_name'], '-')),
              _DetailRow('العمر', '$age سنة'),
              _DetailRow('الجنس', gender),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.local_hospital_rounded,
                    color: AppColors.info,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'المنطقة والفرز الطبي',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.slate800,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
              const Divider(
                height: 24,
                thickness: 1,
                color: AppColors.slate100,
              ),
              _DetailRow('المستشفى / المركز', center),
              _DetailRow('القسم السريري', dept),
              _DetailRow('جهاز / نظام الجسم', system),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.medical_services_rounded,
                    color: AppColors.success,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'التفاصيل الطبية والتشخيص',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.slate800,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
              const Divider(
                height: 24,
                thickness: 1,
                color: AppColors.slate100,
              ),
              const Text(
                'الوصف والتشخيص السريري:',
                style: TextStyle(
                  color: AppColors.slate500,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _docText(
                  caseItem['diagnosis_or_description'],
                  'لا يوجد تشخيص مضاف.',
                ),
                style: const TextStyle(
                  height: 1.6,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.slate700,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _CaseAssignmentOverview(
          summary: assignmentSummary,
          assignments: assignments,
        ),
        if (_docInt(similarSummary['cases_count']) > 0 ||
            similarCases.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SimilarCasesWarning(summary: similarSummary, cases: similarCases),
        ],
      ],
    );
  }
}

class _CaseAssignmentOverview extends StatelessWidget {
  const _CaseAssignmentOverview({
    required this.summary,
    required this.assignments,
  });

  final _Json summary;
  final List<_Json> assignments;

  @override
  Widget build(BuildContext context) {
    final studentsCount = _docInt(summary['students_count']);
    final doctorsCount = _docInt(summary['doctors_count']);
    final activeCount = _docInt(summary['active_assignments_count']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  Icons.groups_rounded,
                  color: AppColors.royalBlue,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'الطلاب المسجلون على هذه الحالة',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.slate800,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DocPill(
                '$studentsCount طالب',
                AppColors.royalBlue,
                icon: Icons.school_rounded,
              ),
              _DocPill(
                '$doctorsCount دكتور',
                AppColors.info,
                icon: Icons.medical_services_rounded,
              ),
              _DocPill(
                '$activeCount نشط/قيد المراجعة',
                activeCount > 0 ? AppColors.warning : AppColors.success,
                icon: Icons.pending_actions_rounded,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (assignments.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.slate100),
              ),
              child: const Text(
                'لا توجد تكليفات مسجلة على هذه الحالة حتى الآن.',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate600,
                ),
              ),
            )
          else
            ...assignments.map((assignment) {
              final student = _docMap(assignment['student']);
              final assigner = _docMap(assignment['assigner']);
              final status = _docText(assignment['status']);
              final statusColor = _caseAssignmentStatusColor(status);
              final major = _docText(_docMap(student['major'])['name']);
              final level = _docText(_docMap(student['level'])['name']);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.slate100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _docText(student['name'], 'طالب'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: AppColors.slate900,
                            ),
                          ),
                        ),
                        _DocPill(
                          _docText(assignment['status_label'], status),
                          statusColor,
                          icon: Icons.circle_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [
                        'رقم القيد: ${_docText(student['student_number'], '-')}',
                        if (major.isNotEmpty) major,
                        if (level.isNotEmpty) level,
                      ].join(' • '),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _DocPill(
                          _docText(assignment['task_type_label'], 'مهمة'),
                          AppColors.teal,
                          icon: Icons.assignment_turned_in_rounded,
                        ),
                        _DocPill(
                          _docText(assigner['name'], 'دكتور'),
                          AppColors.info,
                          icon: Icons.person_rounded,
                        ),
                        if (_docText(assignment['due_at_label']).isNotEmpty)
                          _DocPill(
                            _docText(assignment['due_at_label']),
                            AppColors.slate500,
                            icon: Icons.event_rounded,
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _SimilarCasesWarning extends StatelessWidget {
  const _SimilarCasesWarning({required this.summary, required this.cases});

  final _Json summary;
  final List<_Json> cases;

  @override
  Widget build(BuildContext context) {
    final casesCount = _docInt(summary['cases_count']);
    final assignmentsCount = _docInt(summary['assignments_count']);
    final doctorsCount = _docInt(summary['doctors_count']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'تنبيه: توجد حالات مشابهة داخل الكلية',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.slate900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'تم العثور على $casesCount حالة مشابهة، عليها $assignmentsCount تكليف من $doctorsCount دكتور. راجعها قبل إنشاء تكليف جديد حتى لا يتكدس الطلاب على نفس الحالة.',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.slate700,
              height: 1.5,
            ),
          ),
          if (cases.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...cases.map((caseItem) {
              final doctor = _docMap(caseItem['doctor']);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.medical_information_rounded,
                      color: AppColors.warning,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _docText(caseItem['patient_name'], 'حالة سريرية'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: AppColors.slate900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'الدكتور: ${_docText(doctor['name'], '-')} • التكليفات: ${_docInt(caseItem['assignments_count'])}',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.slate600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

Color _caseAssignmentStatusColor(String status) {
  return switch (status) {
    'approved' => AppColors.success,
    'submitted_for_review' => AppColors.warning,
    'rejected' => AppColors.danger,
    'assigned' => AppColors.royalBlue,
    _ => AppColors.slate500,
  };
}

String _taskTypeLabel(String type) {
  final normalized = type.trim();
  switch (normalized) {
    case 'history_taking':
    case 'أخذ التاريخ المرضي':
    case 'أخذ قصة مرضية':
      return 'أخذ قصة مرضية';
    case 'clinical_examination':
    case 'الفحص السريري':
      return 'الفحص السريري';
    case 'follow_up':
    case 'متابعة':
      return 'متابعة';
    default:
      return type.isEmpty ? 'مهمة سريرية' : type;
  }
}

extension _DoctorClinicalCaseActions on _DoctorClinicalSectionScreenState {
  Future<void> _openCaseForm({_Json? item}) async {
    final options = await Future.wait([
      ref
          .read(staffRepositoryProvider)
          .get('/doctor/clinical/training-centers'),
      ref.read(staffRepositoryProvider).get('/doctor/clinical/departments'),
      ref.read(staffRepositoryProvider).get('/doctor/clinical/body-systems'),
    ]);
    if (!mounted) return;
    final centers = _clinicalPagedItems(options[0]);
    final departments = _clinicalPagedItems(options[1]);
    final systems = _clinicalPagedItems(options[2]);
    final formKey = GlobalKey<FormState>();
    final patient = TextEditingController(
      text: _docText(item?['patient_name']),
    );
    final age = TextEditingController(text: _docText(item?['age']));
    final diagnosis = TextEditingController(
      text: _docText(item?['diagnosis_or_description']),
    );
    int? centerId = _docInt(item?['training_center_id'], 0) == 0
        ? null
        : _docInt(item?['training_center_id']);
    int? departmentId = _docInt(item?['clinical_department_id'], 0) == 0
        ? null
        : _docInt(item?['clinical_department_id']);
    int? systemId = _docInt(item?['body_system_id'], 0) == 0
        ? null
        : _docInt(item?['body_system_id']);
    String gender = _docText(item?['gender'], 'male');
    String status = _docText(item?['status'], 'active');
    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: item == null ? 'إضافة حالة سريرية' : 'تعديل حالة سريرية',
      icon: Icons.medical_information_rounded,
      color: AppColors.success,
      fullScreen: true,
      child: StatefulBuilder(
        builder: (context, setLocal) => Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.badge_rounded,
                          color: AppColors.royalBlue,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'بيانات المريض الأساسية',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.slate800,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                    const Divider(
                      height: 24,
                      thickness: 1,
                      color: AppColors.slate100,
                    ),
                    TextFormField(
                      controller: patient,
                      decoration: InputDecoration(
                        labelText: 'اسم المريض كامل',
                        prefixIcon: const Icon(
                          Icons.person_rounded,
                          color: AppColors.royalBlue,
                        ),
                        filled: true,
                        fillColor: AppColors.slate50,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.slate200,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.slate200,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.royalBlue,
                            width: 1.5,
                          ),
                        ),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'اسم المريض مطلوب.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: age,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'العمر',
                              prefixIcon: const Icon(
                                Icons.cake_rounded,
                                color: AppColors.royalBlue,
                              ),
                              filled: true,
                              fillColor: AppColors.slate50,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.slate200,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.slate200,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.royalBlue,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            validator: (value) =>
                                int.tryParse(value?.trim() ?? '') == null
                                ? 'العمر مطلوب كرقم.'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: gender,
                            decoration: InputDecoration(
                              labelText: 'الجنس',
                              prefixIcon: const Icon(
                                Icons.wc_rounded,
                                color: AppColors.slate500,
                              ),
                              filled: true,
                              fillColor: AppColors.slate50,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.slate200,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.slate200,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.slate500,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'male',
                                child: Text('ذكر'),
                              ),
                              DropdownMenuItem(
                                value: 'female',
                                child: Text('أنثى'),
                              ),
                            ],
                            onChanged: (v) =>
                                setLocal(() => gender = v ?? gender),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.local_hospital_rounded,
                          color: AppColors.info,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'الموقع والفرز الطبي',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.slate800,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                    const Divider(
                      height: 24,
                      thickness: 1,
                      color: AppColors.slate100,
                    ),
                    _clinicalDropdown(
                      'المستشفى / المركز السريري',
                      centers,
                      centerId,
                      (v) => setLocal(() => centerId = v),
                      prefixIcon: Icons.local_hospital_rounded,
                      activeColor: AppColors.info,
                      validator: (value) =>
                          value == null ? 'اختر المركز.' : null,
                    ),
                    const SizedBox(height: 12),
                    _clinicalDropdown(
                      'القسم الطبي المختص',
                      departments,
                      departmentId,
                      (v) => setLocal(() => departmentId = v),
                      prefixIcon: Icons.account_tree_rounded,
                      activeColor: AppColors.info,
                      validator: (value) =>
                          value == null ? 'اختر القسم.' : null,
                    ),
                    const SizedBox(height: 12),
                    _clinicalDropdown(
                      'جهاز أو نظام الجسم',
                      systems,
                      systemId,
                      (v) => setLocal(() => systemId = v),
                      prefixIcon: Icons.biotech_rounded,
                      activeColor: AppColors.info,
                      validator: (value) =>
                          value == null ? 'اختر نظام الجسم.' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: InputDecoration(
                        labelText: 'حالة الاستعداد',
                        prefixIcon: const Icon(
                          Icons.shield_rounded,
                          color: AppColors.info,
                        ),
                        filled: true,
                        fillColor: AppColors.slate50,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.slate200,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.slate200,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.info,
                            width: 1.5,
                          ),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('نشط')),
                        DropdownMenuItem(
                          value: 'discharged',
                          child: Text('خروج'),
                        ),
                        DropdownMenuItem(
                          value: 'transferred',
                          child: Text('تحويل'),
                        ),
                      ],
                      onChanged: (v) => setLocal(() => status = v ?? status),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.medical_services_rounded,
                          color: AppColors.success,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'التفاصيل والتشخيص السريري',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.slate800,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                    const Divider(
                      height: 24,
                      thickness: 1,
                      color: AppColors.slate100,
                    ),
                    TextFormField(
                      controller: diagnosis,
                      minLines: 3,
                      maxLines: 6,
                      decoration: InputDecoration(
                        labelText: 'التشخيص أو الوصف التفصيلي',
                        prefixIcon: const Icon(
                          Icons.description_rounded,
                          color: AppColors.success,
                        ),
                        filled: true,
                        fillColor: AppColors.slate50,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.slate200,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.slate200,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.success,
                            width: 1.5,
                          ),
                        ),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'التشخيص أو الوصف مطلوب.'
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  if (formKey.currentState?.validate() != true) return;
                  Navigator.pop(context, true);
                },
                icon: const Icon(Icons.save_rounded),
                label: const Text(
                  'حفظ الحالة السريرية',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Cairo',
                    fontSize: 14,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final payload = ok == true
        ? {
            'patient_name': patient.text.trim(),
            'age': int.tryParse(age.text.trim()),
            'gender': gender,
            'training_center_id': centerId,
            'clinical_department_id': departmentId,
            'body_system_id': systemId,
            'diagnosis_or_description': diagnosis.text.trim(),
            'status': status,
          }
        : null;

    Future.delayed(const Duration(milliseconds: 500), () {
      patient.dispose();
      age.dispose();
      diagnosis.dispose();
    });

    if (ok != true || payload == null) return;
    try {
      if (item == null) {
        await ref.read(staffRepositoryProvider).post(_endpoint, payload);
      } else {
        await ref
            .read(staffRepositoryProvider)
            .put('$_endpoint/${item['id']}', payload);
      }
      if (!mounted) return;
      _reload();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }
}
