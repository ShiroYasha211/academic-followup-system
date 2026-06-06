part of 'staff_screens.dart';

class _ClinicalFilterChipMenu extends StatelessWidget {
  const _ClinicalFilterChipMenu({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final int? value;
  final List<_Json> options;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    String selected = '';
    if (value != null) {
      for (final item in options) {
        if (_docInt(item['id']) == value) {
          selected = _docText(item['name']);
          break;
        }
      }
    }
    return PopupMenuButton<int?>(
      initialValue: value,
      onSelected: onChanged,
      itemBuilder: (context) => [
        PopupMenuItem<int?>(value: null, child: Text('كل $label')),
        ...options.map(
          (item) => PopupMenuItem<int?>(
            value: _docInt(item['id']),
            child: Text(_docText(item['name'], '-')),
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: value == null
              ? AppColors.slate50
              : AppColors.royalBlue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: value == null
                ? AppColors.slate200
                : AppColors.royalBlue.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selected.isEmpty ? label : selected,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                color: value == null ? AppColors.slate600 : AppColors.royalBlue,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}

class _AssignmentCasePreview extends StatelessWidget {
  const _AssignmentCasePreview({required this.caseItem});

  final _Json caseItem;

  @override
  Widget build(BuildContext context) {
    final center = _docText(_docMap(caseItem['training_center'])['name']);
    final department = _docText(
      _docMap(caseItem['clinical_department'])['name'],
    );
    final system = _docText(_docMap(caseItem['body_system'])['name']);
    final diagnosis = _docText(caseItem['diagnosis_or_description']);
    final assignmentSummary = _docMap(caseItem['assignment_summary']);
    final similarSummary = _docMap(caseItem['similar_cases_summary']);
    final studentsCount = _docInt(assignmentSummary['students_count']);
    final activeCount = _docInt(assignmentSummary['active_assignments_count']);
    final similarCount = _docInt(similarSummary['cases_count']);
    final patient = _docText(
      caseItem['patient_name'],
      _docText(caseItem['name'], 'حالة سريرية'),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.medical_information_rounded,
                color: AppColors.teal,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  patient,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    color: AppColors.slate900,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (center.isNotEmpty)
                _DocPill(
                  center,
                  AppColors.royalBlue,
                  icon: Icons.location_city_rounded,
                ),
              if (department.isNotEmpty)
                _DocPill(
                  department,
                  AppColors.info,
                  icon: Icons.account_tree_rounded,
                ),
              if (system.isNotEmpty)
                _DocPill(
                  system,
                  AppColors.warning,
                  icon: Icons.bubble_chart_rounded,
                ),
            ],
          ),
          if (diagnosis.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              diagnosis,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
                height: 1.5,
                fontSize: 12,
                color: AppColors.slate700,
              ),
            ),
          ],
          if (studentsCount > 0 || similarCount > 0) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (similarCount > 0 ? AppColors.warning : AppColors.info)
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: (similarCount > 0 ? AppColors.warning : AppColors.info)
                      .withValues(alpha: 0.18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        similarCount > 0
                            ? Icons.warning_amber_rounded
                            : Icons.groups_rounded,
                        color: similarCount > 0
                            ? AppColors.warning
                            : AppColors.info,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'مراجعة استخدام الحالة قبل التكليف',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w900,
                            color: AppColors.slate900,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _DocPill(
                        '$studentsCount طالب مكلف',
                        activeCount > 0 ? AppColors.warning : AppColors.info,
                        icon: Icons.school_rounded,
                      ),
                      if (activeCount > 0)
                        _DocPill(
                          '$activeCount نشط/قيد المراجعة',
                          AppColors.warning,
                          icon: Icons.pending_actions_rounded,
                        ),
                      if (similarCount > 0)
                        _DocPill(
                          '$similarCount حالة مشابهة',
                          AppColors.danger,
                          icon: Icons.warning_amber_rounded,
                        ),
                    ],
                  ),
                  if (similarCount > 0) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'توجد حالات مشابهة داخل الكلية. تأكد أن استخدام هذه الحالة مقصود قبل إرسال التكليف.',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate700,
                        fontSize: 11.5,
                        height: 1.45,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/*
class ClinicalAssignmentCard extends StatelessWidget {
  const ClinicalAssignmentCard({
    required this.item,
    required this.onTap,
    this.onEdit,
    this.editLabel,
  });

  final _Json item;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final String? editLabel;

  @override
  Widget build(BuildContext context) {
    final status = _docText(item['status']);
    final effectiveStatus = _docBool(item['is_overdue']) ? 'overdue' : status;
    final statusColor = switch (effectiveStatus) {
      'approved' => AppColors.success,
      'submitted_for_review' => AppColors.warning,
      'assigned' => AppColors.royalBlue,
      'overdue' => AppColors.danger,
      'rejected' => AppColors.danger,
      _ => AppColors.slate500,
    };
    final statusLabel = switch (effectiveStatus) {
      'approved' => 'تم الاعتماد',
      'submitted_for_review' => 'بانتظار المراجعة',
      'assigned' => 'قيد العمل',
      'overdue' => 'متأخر',
      'rejected' => 'مرفوض',
      _ => _docText(item['status_label'], 'مكلف'),
    };

    final student = _docMap(item['student']);
    final studentName = _docText(student['name'], 'طالب');
    final studentNumber = _docText(student['student_number'], '-');

    final clinicalCase = _docMap(item['clinical_case']);
    final patientName = _docText(clinicalCase['patient_name'], 'مريض');
    final diagnosis = _docText(clinicalCase['diagnosis_or_description'], '-');
    final dept = _docText(_docMap(clinicalCase['clinical_department'])['name']);

    final taskType = _taskTypeLabel(_docText(item['task_type']));
    final dueAt = _docText(item['due_at_label'], _docDate(item['due_at']));
    final hasAttachment = _docText(item['attachment_url']).isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.slate100, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                width: 5,
                child: Container(color: statusColor),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 21, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                statusColor.withValues(alpha: 0.12),
                                statusColor.withValues(alpha: 0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              studentName.isNotEmpty ? studentName[0] : 'ط',
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Cairo',
                              ),
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
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.slate900,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.badge_rounded,
                                    size: 12,
                                    color: AppColors.slate400,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'رقم القيد: $studentNumber',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.slate500,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _DocPill(
                          statusLabel,
                          statusColor,
                          icon: status == 'approved'
                              ? Icons.check_circle_rounded
                              : status == 'submitted_for_review'
                              ? Icons.pending_rounded
                              : status == 'rejected'
                              ? Icons.cancel_rounded
                              : Icons.assignment_ind_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _DocPill(
                          'نوع المهمة: $taskType',
                          AppColors.royalBlue,
                          icon: Icons.assignment_rounded,
                        ),
                        if (dueAt.isNotEmpty && dueAt != '-')
                          _DocPill(
                            'الاستحقاق: $dueAt',
                            _docBool(item['is_overdue'])
                                ? AppColors.danger
                                : AppColors.warning,
                            icon: Icons.event_available_rounded,
                          ),
                        if (hasAttachment)
                          _DocPill(
                            'مرفق',
                            AppColors.teal,
                            icon: Icons.attach_file_rounded,
                          ),
                        _DocPill(
                          'المريض: $patientName',
                          AppColors.teal,
                          icon: Icons.person_rounded,
                        ),
                        if (dept.isNotEmpty)
                          _DocPill(
                            dept,
                            AppColors.info,
                            icon: Icons.account_tree_rounded,
                          ),
                        if (status == 'approved' &&
                            _docText(item['review_rating_label']).isNotEmpty)
                          _DocPill(
                            'التقييم: ${_docText(item['review_rating_label'])}',
                            AppColors.goldDeep,
                            icon: Icons.star_rounded,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.slate50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.slate100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.medical_services_rounded,
                                size: 12,
                                color: AppColors.slate400,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'التشخيص والوصف السريري للحالة:',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.slate500,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            diagnosis.isNotEmpty
                                ? diagnosis
                                : 'لا يوجد تشخيص محدد.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.slate700,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onEdit != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: onEdit,
                            icon: const Icon(
                              Icons.rate_review_rounded,
                              size: 16,
                            ),
                            label: Text(
                              editLabel ?? 'مراجعة التكليف',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Cairo',
                                fontSize: 12,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.warning,
                              backgroundColor: AppColors.warning.withValues(
                                alpha: 0.1,
                              ),
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
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClinicalAssignmentDetails extends StatelessWidget {
  const ClinicalAssignmentDetails({required this.item, this.onReview});

  final _Json item;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    final status = _docText(item['status']);
    final effectiveStatus = _docBool(item['is_overdue']) ? 'overdue' : status;
    final statusColor = switch (effectiveStatus) {
      'approved' => AppColors.success,
      'submitted_for_review' => AppColors.warning,
      'assigned' => AppColors.royalBlue,
      'overdue' => AppColors.danger,
      'rejected' => AppColors.danger,
      _ => AppColors.slate500,
    };
    final statusLabel = switch (effectiveStatus) {
      'approved' => 'تم اعتماد التكليف',
      'submitted_for_review' => 'التكليف بانتظار المراجعة والاعتماد',
      'assigned' => 'التكليف قيد العمل من قبل الطالب',
      'overdue' => 'التكليف متأخر عن موعد الاستحقاق',
      'rejected' => 'تم رفض التكليف',
      _ => _docText(item['status_label'], 'مكلف'),
    };

    final student = _docMap(item['student']);
    final studentName = _docText(student['name'], 'طالب');
    final studentNumber = _docText(student['student_number'], '-');

    final clinicalCase = _docMap(item['clinical_case']);
    final patientName = _docText(clinicalCase['patient_name'], 'مريض');
    final diagnosis = _docText(clinicalCase['diagnosis_or_description'], '-');
    final center = _docText(_docMap(clinicalCase['training_center'])['name']);
    final dept = _docText(_docMap(clinicalCase['clinical_department'])['name']);

    final taskType = _taskTypeLabel(_docText(item['task_type']));
    final reviewNotes = _docText(item['review_notes']);
    final dueAt = _docText(item['due_at_label'], _docDate(item['due_at']));
    final attachmentUrl = _docText(item['attachment_url']);
    final attachmentName = _docText(item['attachment_name'], 'مرفق التكليف');
    final reviewRating = _docText(item['review_rating_label']);
    final studentMessage = _docText(item['student_completion_message']);
    final attempts = _docList(item['attempts']);

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
              Icon(
                status == 'approved'
                    ? Icons.check_circle_rounded
                    : status == 'submitted_for_review'
                    ? Icons.pending_rounded
                    : status == 'rejected'
                    ? Icons.cancel_rounded
                    : Icons.assignment_ind_rounded,
                color: statusColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                    fontFamily: 'Cairo',
                  ),
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
                    Icons.school_rounded,
                    color: AppColors.royalBlue,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'بيانات الطالب والتكليف',
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
              _DetailRow('اسم الطالب', studentName),
              _DetailRow('رقم القيد', studentNumber),
              _DetailRow('نوع المهمة', taskType),
              if (dueAt.isNotEmpty && dueAt != '-')
                _DetailRow(
                  'موعد الاستحقاق',
                  dueAt,
                  trailing: _docBool(item['is_overdue'])
                      ? const Icon(
                          Icons.warning_rounded,
                          color: AppColors.danger,
                          size: 18,
                        )
                      : null,
                ),
              if (attachmentUrl.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(
                  height: 20,
                  thickness: 1,
                  color: AppColors.slate100,
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.attach_file_rounded,
                      color: AppColors.royalBlue,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'مرفق التكليف',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                        fontSize: 12.5,
                        color: AppColors.slate700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _AssignmentAttachmentPreview(
                  url: attachmentUrl,
                  name: attachmentName,
                  mimeType: _docText(item['attachment_type']),
                ),
              ],
              _DetailRow('تاريخ التكليف', _docDate(item['created_at'])),
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
                    Icons.medical_information_rounded,
                    color: AppColors.teal,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'تفاصيل الحالة السريرية المرتبطة',
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
              _DetailRow('اسم المريض', patientName),
              _DetailRow('المركز السريري', center.isNotEmpty ? center : '-'),
              _DetailRow('القسم المختص', dept.isNotEmpty ? dept : '-'),
              const SizedBox(height: 10),
              const Text(
                'التشخيص / الوصف السريري:',
                style: TextStyle(
                  color: AppColors.slate500,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                diagnosis.isNotEmpty ? diagnosis : 'لا يوجد تشخيص مضاف.',
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
        if (attempts.isNotEmpty) ...[
          const SizedBox(height: 12),
          _ClinicalAssignmentAttemptsPanel(attempts: attempts),
        ],
        if (studentMessage.isNotEmpty) ...[
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
                Row(
                  children: [
                    const Icon(
                      Icons.note_alt_rounded,
                      color: AppColors.royalBlue,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'ملاحظات إتمام الطالب',
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
                Text(
                  studentMessage,
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
        ],
        if (reviewNotes.isNotEmpty || reviewRating.isNotEmpty) ...[
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
                Row(
                  children: [
                    Icon(
                      Icons.rate_review_rounded,
                      color: statusColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'ملاحظات المراجعة والاعتماد',
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
                if (reviewRating.isNotEmpty)
                  _DetailRow('التقييم المختصر', reviewRating),
                if (reviewNotes.isNotEmpty)
                  Text(
                    reviewNotes,
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
        ],
        if (status == 'submitted_for_review' && onReview != null) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onReview,
            icon: const Icon(Icons.rate_review_rounded, size: 20),
            label: const Text(
              'مراجعة واعتماد التكليف',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w800,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ],
    );
  }
}

class _ClinicalAssignmentAttemptsPanel extends StatelessWidget {
  const _ClinicalAssignmentAttemptsPanel({required this.attempts});

  final List<_Json> attempts;

  @override
  Widget build(BuildContext context) {
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
          const Row(
            children: [
              Icon(Icons.fact_check_rounded, color: AppColors.teal, size: 18),
              SizedBox(width: 8),
              Text(
                'محاولات الطالب والسجل العملي',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.slate800,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1, color: AppColors.slate100),
          ...attempts.map(
            (attempt) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ClinicalAssignmentAttemptCard(attempt: attempt),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClinicalAssignmentAttemptCard extends StatelessWidget {
  const _ClinicalAssignmentAttemptCard({required this.attempt});

  final _Json attempt;

  @override
  Widget build(BuildContext context) {
    final status = _docText(attempt['status']);
    final statusColor = _assignmentAttemptStatusColor(status);
    final groups = _docList(attempt['groups']);
    final notes = _docText(attempt['doctor_notes']);
    final center = _docText(_docMap(attempt['training_center'])['name']);
    final department = _docText(_docMap(attempt['department'])['name']);
    final date = _docDate(attempt['log_date']);
    final time = _docText(attempt['log_time']);
    final done = groups.where((group) => _docBool(group['confirmed'])).length;
    final remaining = groups.length - done;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Icon(
                  status == 'rejected'
                      ? Icons.cancel_rounded
                      : status == 'confirmed'
                      ? Icons.verified_rounded
                      : Icons.pending_actions_rounded,
                  size: 18,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _docText(
                        attempt['status_label'],
                        _assignmentAttemptStatusLabel(status),
                      ),
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: statusColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        date,
                        time,
                      ].where((value) => value.isNotEmpty).join(' - '),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: AppColors.slate500,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _DocPill(
                'تم $done / متبقي $remaining',
                statusColor,
                icon: Icons.checklist_rtl_rounded,
              ),
            ],
          ),
          if (center.isNotEmpty || department.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (center.isNotEmpty)
                  _DocPill(
                    center,
                    AppColors.royalBlue,
                    icon: Icons.location_city_rounded,
                  ),
                if (department.isNotEmpty)
                  _DocPill(
                    department,
                    AppColors.info,
                    icon: Icons.account_tree_rounded,
                  ),
              ],
            ),
          ],
          if (groups.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...groups.map((group) {
              final confirmed = _docBool(group['confirmed']);
              final items = _docList(group['items']);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.slate100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          confirmed
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 17,
                          color: confirmed
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            _docText(group['label'], '-'),
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w900,
                              color: AppColors.slate800,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                        Text(
                          confirmed ? 'تم الاعتماد' : 'بانتظار الاعتماد',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w800,
                            color: confirmed
                                ? AppColors.success
                                : AppColors.warning,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    if (items.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      ...items.take(3).map((item) {
                        final diagnosis = _docText(
                          item['diagnosis'],
                          _docText(item['case_name']),
                        );
                        if (diagnosis.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '- $diagnosis',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              color: AppColors.slate600,
                              fontWeight: FontWeight.w700,
                              fontSize: 11.5,
                              height: 1.45,
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              );
            }),
          ],
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'ملاحظة الدكتور: $notes',
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: AppColors.danger,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Color _assignmentAttemptStatusColor(String status) {
  return switch (status) {
    'confirmed' => AppColors.success,
    'partially_confirmed' => AppColors.warning,
    'rejected' => AppColors.danger,
    _ => AppColors.royalBlue,
  };
}

String _assignmentAttemptStatusLabel(String status) {
  return switch (status) {
    'confirmed' => 'معتمد بالكامل',
    'partially_confirmed' => 'اعتماد جزئي',
    'rejected' => 'مرفوض',
    _ => 'بانتظار المراجعة',
  };
}
*/

// ---------------------------------------------------------------------------
// Assignment Attachment Preview – image preview with zoom, or file tile
// ---------------------------------------------------------------------------
class _AssignmentAttachmentPreview extends StatelessWidget {
  const _AssignmentAttachmentPreview({
    required this.url,
    required this.name,
    required this.mimeType,
  });

  final String url;
  final String name;
  final String mimeType;

  bool get _isImage =>
      mimeType.startsWith('image/') ||
      url.endsWith('.jpg') ||
      url.endsWith('.jpeg') ||
      url.endsWith('.png') ||
      url.endsWith('.gif') ||
      url.endsWith('.webp');

  @override
  Widget build(BuildContext context) {
    if (_isImage) {
      return Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
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
          onTap: () => _showFullImage(context),
          child: Stack(
            children: [
              Image.network(
                url,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    color: AppColors.slate50,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 100,
                    color: AppColors.slate50,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_rounded,
                          color: AppColors.slate400,
                          size: 32,
                        ),
                        SizedBox(height: 6),
                        Text(
                          'تعذر تحميل الصورة المرفقة',
                          style: TextStyle(
                            color: AppColors.slate500,
                            fontFamily: 'Cairo',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              // Zoom button
              Positioned(
                top: 10,
                left: 10,
                child: _ImageOverlayButton(
                  icon: Icons.open_in_full_rounded,
                  onPressed: () => _showFullImage(context),
                ),
              ),
              // Download button
              Positioned(
                bottom: 10,
                right: 10,
                child: _ImageOverlayButton(
                  icon: Icons.download_rounded,
                  onPressed: () => _openExternal(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Non-image file tile
    return InkWell(
      onTap: () => _openExternal(),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.royalBlue.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.royalBlue.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.royalBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(_fileIcon, color: AppColors.royalBlue, size: 22),
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
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                      color: AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _fileTypeLabel,
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.royalBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.download_rounded,
                color: AppColors.royalBlue,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData get _fileIcon {
    if (mimeType.contains('pdf')) return Icons.picture_as_pdf_rounded;
    if (mimeType.contains('word') || mimeType.contains('document')) {
      return Icons.description_rounded;
    }
    if (mimeType.contains('excel') || mimeType.contains('spreadsheet')) {
      return Icons.table_chart_rounded;
    }
    if (mimeType.contains('video')) return Icons.videocam_rounded;
    if (mimeType.contains('audio')) return Icons.audiotrack_rounded;
    return Icons.file_present_rounded;
  }

  String get _fileTypeLabel {
    if (mimeType.contains('pdf')) return 'ملف PDF';
    if (mimeType.contains('word') || mimeType.contains('document')) {
      return 'مستند Word';
    }
    if (mimeType.contains('excel') || mimeType.contains('spreadsheet')) {
      return 'جدول بيانات';
    }
    if (mimeType.contains('video')) return 'ملف فيديو';
    if (mimeType.contains('audio')) return 'ملف صوتي';
    return 'ملف مرفق';
  }

  Future<void> _openExternal() async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _showFullImage(BuildContext context) async {
    if (url.isEmpty) return;
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 5,
                child: Image.network(
                  url,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 280,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(24),
                    child: const Text(
                      'تعذر عرض الصورة',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton.filled(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.92),
                  foregroundColor: AppColors.slate900,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filled(
                onPressed: () => _openExternal(),
                icon: const Icon(Icons.download_rounded),
                tooltip: 'تحميل',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.92),
                  foregroundColor: AppColors.royalBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Student Search Picker – used inside _openAssignmentForm
// ---------------------------------------------------------------------------
class _StudentSearchPicker extends StatefulWidget {
  const _StudentSearchPicker({required this.students});

  final List<_Json> students;

  @override
  State<_StudentSearchPicker> createState() => _StudentSearchPickerState();
}

class _StudentSearchPickerState extends State<_StudentSearchPicker> {
  final _controller = TextEditingController();
  late List<_Json> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = List.of(widget.students);
    _controller.addListener(_onSearch);
  }

  void _onSearch() {
    final q = _controller.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = List.of(widget.students);
      } else {
        _filtered = widget.students.where((s) {
          final name = _docText(s['name']).toLowerCase();
          final number = _docText(s['student_number']).toLowerCase();
          final email = _docText(s['email']).toLowerCase();
          return name.contains(q) || number.contains(q) || email.contains(q);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listHeight = MediaQuery.sizeOf(context).height * 0.58;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search field
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.slate50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.slate200),
          ),
          child: TextField(
            controller: _controller,
            autofocus: true,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.midnight,
            ),
            decoration: InputDecoration(
              hintText: 'ابحث بالاسم أو رقم القيد...',
              hintStyle: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
                color: AppColors.slate400,
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.royalBlue,
              ),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      onPressed: () => _controller.clear(),
                      icon: const Icon(Icons.close_rounded, size: 18),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),

        // Results count
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              const Icon(
                Icons.people_alt_rounded,
                size: 14,
                color: AppColors.slate400,
              ),
              const SizedBox(width: 6),
              Text(
                '${_filtered.length} طالب',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate500,
                ),
              ),
            ],
          ),
        ),

        // Student list
        SizedBox(
          height: listHeight.clamp(320.0, 520.0),
          child: _filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_search_rounded,
                        size: 48,
                        color: AppColors.slate300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'لا توجد نتائج مطابقة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.slate400,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final student = _filtered[index];
                    final name = _docText(student['name']);
                    final number = _docText(student['student_number']);
                    final email = _docText(student['email']);

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context, student),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.slate100),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.royalBlue.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  name.isNotEmpty ? name[0] : '?',
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
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
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                        color: AppColors.slate900,
                                      ),
                                    ),
                                    if (number.isNotEmpty || email.isNotEmpty)
                                      Text(
                                        number.isNotEmpty
                                            ? 'رقم القيد: $number'
                                            : email,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
                              const Icon(
                                Icons.arrow_back_ios_rounded,
                                size: 14,
                                color: AppColors.slate300,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Case Search Picker – used inside _openAssignmentForm
// ---------------------------------------------------------------------------
class _CaseSearchPicker extends StatefulWidget {
  const _CaseSearchPicker({
    required this.cases,
    required this.centers,
    required this.departments,
    required this.systems,
  });

  final List<_Json> cases;
  final List<_Json> centers;
  final List<_Json> departments;
  final List<_Json> systems;

  @override
  State<_CaseSearchPicker> createState() => _CaseSearchPickerState();
}

class _CaseSearchPickerState extends State<_CaseSearchPicker> {
  final _controller = TextEditingController();
  late List<_Json> _filtered;
  int? _centerId;
  int? _departmentId;
  int? _systemId;

  @override
  void initState() {
    super.initState();
    _filtered = List.of(widget.cases);
    _controller.addListener(_applyFilters);
  }

  void _applyFilters() {
    final q = _controller.text.trim().toLowerCase();
    setState(() {
      _filtered = widget.cases.where((c) {
        // Text search
        if (q.isNotEmpty) {
          final patient = _docText(c['patient_name']).toLowerCase();
          final name = _docText(c['name']).toLowerCase();
          final diagnosis = _docText(
            c['diagnosis_or_description'],
          ).toLowerCase();
          if (!patient.contains(q) &&
              !name.contains(q) &&
              !diagnosis.contains(q)) {
            return false;
          }
        }
        // Filter by center
        if (_centerId != null) {
          final centerId = _docInt(_docMap(c['training_center'])['id']);
          if (centerId != _centerId) return false;
        }
        // Filter by department
        if (_departmentId != null) {
          final deptId = _docInt(_docMap(c['clinical_department'])['id']);
          if (deptId != _departmentId) return false;
        }
        // Filter by body system
        if (_systemId != null) {
          final sysId = _docInt(_docMap(c['body_system'])['id']);
          if (sysId != _systemId) return false;
        }
        return true;
      }).toList();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters =
        _centerId != null || _departmentId != null || _systemId != null;
    final listHeight = MediaQuery.sizeOf(context).height * 0.56;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search field
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.slate50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.slate200),
          ),
          child: TextField(
            controller: _controller,
            autofocus: true,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.midnight,
            ),
            decoration: InputDecoration(
              hintText: 'ابحث بالاسم أو التشخيص...',
              hintStyle: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
                color: AppColors.slate400,
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.teal,
              ),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      onPressed: () => _controller.clear(),
                      icon: const Icon(Icons.close_rounded, size: 18),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),

        // Filter chips row
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              if (hasActiveFilters)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: ActionChip(
                    avatar: const Icon(
                      Icons.clear_all_rounded,
                      size: 16,
                      color: AppColors.danger,
                    ),
                    label: const Text(
                      'مسح',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppColors.danger,
                      ),
                    ),
                    backgroundColor: AppColors.danger.withValues(alpha: 0.06),
                    side: BorderSide(
                      color: AppColors.danger.withValues(alpha: 0.2),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    onPressed: () {
                      _centerId = null;
                      _departmentId = null;
                      _systemId = null;
                      _applyFilters();
                    },
                  ),
                ),
              if (widget.centers.length > 1)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: _ClinicalFilterChipMenu(
                    label: 'المركز',
                    value: _centerId,
                    options: widget.centers,
                    onChanged: (v) {
                      _centerId = v;
                      _applyFilters();
                    },
                  ),
                ),
              if (widget.departments.length > 1)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: _ClinicalFilterChipMenu(
                    label: 'القسم',
                    value: _departmentId,
                    options: widget.departments,
                    onChanged: (v) {
                      _departmentId = v;
                      _applyFilters();
                    },
                  ),
                ),
              if (widget.systems.length > 1)
                _ClinicalFilterChipMenu(
                  label: 'الجهاز',
                  value: _systemId,
                  options: widget.systems,
                  onChanged: (v) {
                    _systemId = v;
                    _applyFilters();
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Results count
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              const Icon(
                Icons.medical_information_rounded,
                size: 14,
                color: AppColors.slate400,
              ),
              const SizedBox(width: 6),
              Text(
                '${_filtered.length} حالة سريرية',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate500,
                ),
              ),
            ],
          ),
        ),

        // Cases list
        SizedBox(
          height: listHeight.clamp(300.0, 500.0),
          child: _filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: AppColors.slate300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'لا توجد حالات مطابقة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.slate400,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final caseItem = _filtered[index];
                    final patient = _docText(
                      caseItem['patient_name'],
                      _docText(caseItem['name'], 'حالة سريرية'),
                    );
                    final diagnosis = _docText(
                      caseItem['diagnosis_or_description'],
                    );
                    final center = _docText(
                      _docMap(caseItem['training_center'])['name'],
                    );
                    final department = _docText(
                      _docMap(caseItem['clinical_department'])['name'],
                    );
                    final bodySystem = _docText(
                      _docMap(caseItem['body_system'])['name'],
                    );

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context, caseItem),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.slate100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: AppColors.teal.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.medical_information_rounded,
                                      color: AppColors.teal,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          patient,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontFamily: 'Cairo',
                                            fontWeight: FontWeight.w900,
                                            fontSize: 13,
                                            color: AppColors.slate900,
                                          ),
                                        ),
                                        if (diagnosis.isNotEmpty)
                                          Text(
                                            diagnosis,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
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
                                  const Icon(
                                    Icons.arrow_back_ios_rounded,
                                    size: 14,
                                    color: AppColors.slate300,
                                  ),
                                ],
                              ),
                              if (center.isNotEmpty ||
                                  department.isNotEmpty ||
                                  bodySystem.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    if (center.isNotEmpty)
                                      _DocPill(
                                        center,
                                        AppColors.royalBlue,
                                        icon: Icons.location_city_rounded,
                                      ),
                                    if (department.isNotEmpty)
                                      _DocPill(
                                        department,
                                        AppColors.info,
                                        icon: Icons.account_tree_rounded,
                                      ),
                                    if (bodySystem.isNotEmpty)
                                      _DocPill(
                                        bodySystem,
                                        AppColors.warning,
                                        icon: Icons.bubble_chart_rounded,
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

extension _DoctorClinicalAssignmentActions
    on _DoctorClinicalSectionScreenState {
  Future<void> _openAssignmentForm() async {
    _Json? findItem(List<_Json> items, int? id) {
      if (id == null) return null;
      for (final item in items) {
        if (_docInt(item['id']) == id) return item;
      }
      return null;
    }

    List<_Json> uniqueRelationOptions(List<_Json> items, String key) {
      final seen = <int>{};
      final result = <_Json>[];
      for (final item in items) {
        final relation = _docMap(item[key]);
        final id = _docInt(relation['id']);
        final name = _docText(relation['name']);
        if (id > 0 && name.isNotEmpty && seen.add(id)) {
          result.add({'id': id, 'name': name});
        }
      }
      result.sort((a, b) => _docText(a['name']).compareTo(_docText(b['name'])));
      return result;
    }

    final results = await Future.wait([
      ref
          .read(staffRepositoryProvider)
          .get(
            '/doctor/clinical/cases',
            query: const {'per_page': 200, 'include_assignment_summary': 1},
          ),
      ref
          .read(staffRepositoryProvider)
          .get('/doctor/clinical/evaluations/start-data'),
    ]);
    if (!mounted) return;
    final cases = _clinicalPagedItems(results[0]);
    final startData = _docMap(_docData(results[1]));
    final students = _docList(startData['students']);
    final formKey = GlobalKey<FormState>();
    int? studentId;
    int? caseId;
    String task = 'history_taking';
    DateTime? dueAt;
    PlatformFile? attachment;
    final instructions = TextEditingController();

    final centers = uniqueRelationOptions(cases, 'training_center');
    final departments = uniqueRelationOptions(cases, 'clinical_department');
    final systems = uniqueRelationOptions(cases, 'body_system');

    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: 'تكليف حالة لطالب',
      icon: Icons.assignment_ind_rounded,
      color: AppColors.royalBlue,
      fullScreen: true,
      child: StatefulBuilder(
        builder: (context, setLocal) {
          final selectedCase = findItem(cases, caseId);

          return Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Bento Container 1: Parties Data
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.slate200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.royalBlue.withValues(
                                alpha: 0.08,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.people_alt_rounded,
                              color: AppColors.royalBlue,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'أطراف التكليف',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w900,
                              fontSize: 13.5,
                              color: AppColors.slate900,
                            ),
                          ),
                        ],
                      ),
                      const Divider(
                        height: 24,
                        thickness: 1,
                        color: AppColors.slate100,
                      ),
                      // Student Selector Tile
                      FormField<int>(
                        initialValue: studentId,
                        validator: (value) =>
                            value == null ? 'اختر الطالب المكلف.' : null,
                        builder: (fieldState) {
                          final selectedStudent = findItem(students, studentId);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: () async {
                                  final selected =
                                      await showMoeenBottomSheet<_Json>(
                                        context: context,
                                        title: 'اختر الطالب المكلف',
                                        icon: Icons.school_rounded,
                                        color: AppColors.royalBlue,
                                        fullScreen: true,
                                        child: _StudentSearchPicker(
                                          students: students,
                                        ),
                                      );
                                  if (selected != null) {
                                    setLocal(() {
                                      studentId = _docInt(selected['id']);
                                      fieldState.didChange(studentId);
                                    });
                                  }
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.slate50,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: fieldState.hasError
                                          ? AppColors.danger
                                          : (studentId == null
                                                ? AppColors.slate200
                                                : AppColors.royalBlue),
                                      width: studentId == null ? 1 : 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.school_rounded,
                                        color: AppColors.royalBlue,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              studentId == null
                                                  ? 'الطالب المكلف'
                                                  : 'الطالب المحدد',
                                              style: const TextStyle(
                                                fontFamily: 'Cairo',
                                                fontWeight: FontWeight.w700,
                                                fontSize: 11,
                                                color: AppColors.slate500,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              studentId == null
                                                  ? 'اضغط للبحث واختيار طالب...'
                                                  : _docText(
                                                      selectedStudent?['name'],
                                                      'طالب',
                                                    ),
                                              style: TextStyle(
                                                fontFamily: 'Cairo',
                                                fontWeight: FontWeight.w800,
                                                fontSize: 13,
                                                color: studentId == null
                                                    ? AppColors.slate400
                                                    : AppColors.slate900,
                                              ),
                                            ),
                                            if (selectedStudent != null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                'رقم القيد: ${_docText(selectedStudent['student_number'], '-')}',
                                                style: const TextStyle(
                                                  fontFamily: 'Cairo',
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 11,
                                                  color: AppColors.slate500,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 14,
                                        color: AppColors.slate400,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (fieldState.hasError) ...[
                                const SizedBox(height: 6),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    fieldState.errorText ?? '',
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 11,
                                      color: AppColors.danger,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      // Case Selector Tile
                      FormField<int>(
                        initialValue: caseId,
                        validator: (value) =>
                            value == null ? 'اختر الحالة السريرية.' : null,
                        builder: (fieldState) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: () async {
                                  final selected =
                                      await showMoeenBottomSheet<_Json>(
                                        context: context,
                                        title: 'اختر الحالة السريرية',
                                        icon: Icons.medical_information_rounded,
                                        color: AppColors.teal,
                                        fullScreen: true,
                                        child: _CaseSearchPicker(
                                          cases: cases,
                                          centers: centers,
                                          departments: departments,
                                          systems: systems,
                                        ),
                                      );
                                  if (selected != null) {
                                    setLocal(() {
                                      caseId = _docInt(selected['id']);
                                      fieldState.didChange(caseId);
                                    });
                                  }
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.slate50,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: fieldState.hasError
                                          ? AppColors.danger
                                          : (caseId == null
                                                ? AppColors.slate200
                                                : AppColors.teal),
                                      width: caseId == null ? 1 : 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.medical_information_rounded,
                                        color: AppColors.teal,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              caseId == null
                                                  ? 'الحالة السريرية'
                                                  : 'الحالة المحددة',
                                              style: const TextStyle(
                                                fontFamily: 'Cairo',
                                                fontWeight: FontWeight.w700,
                                                fontSize: 11,
                                                color: AppColors.slate500,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              caseId == null
                                                  ? 'اضغط للبحث واختيار حالة سريرية...'
                                                  : _docText(
                                                      selectedCase?['patient_name'],
                                                      _docText(
                                                        selectedCase?['name'],
                                                        'حالة سريرية',
                                                      ),
                                                    ),
                                              style: TextStyle(
                                                fontFamily: 'Cairo',
                                                fontWeight: FontWeight.w800,
                                                fontSize: 13,
                                                color: caseId == null
                                                    ? AppColors.slate400
                                                    : AppColors.slate900,
                                              ),
                                            ),
                                            if (selectedCase != null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                'التشخيص: ${_docText(selectedCase['diagnosis_or_description'], '-')}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontFamily: 'Cairo',
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 11,
                                                  color: AppColors.slate500,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 14,
                                        color: AppColors.slate400,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (fieldState.hasError) ...[
                                const SizedBox(height: 6),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    fieldState.errorText ?? '',
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 11,
                                      color: AppColors.danger,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      if (selectedCase != null) ...[
                        const SizedBox(height: 12),
                        _AssignmentCasePreview(caseItem: selectedCase),
                      ],
                    ],
                  ),
                ),

                // Bento Container 2: Task details
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.slate200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.task_alt_rounded,
                              color: AppColors.warning,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'تفاصيل وتوجيهات المهمة',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w900,
                              fontSize: 13.5,
                              color: AppColors.slate900,
                            ),
                          ),
                        ],
                      ),
                      const Divider(
                        height: 24,
                        thickness: 1,
                        color: AppColors.slate100,
                      ),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: task,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w700,
                          color: AppColors.midnight,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          labelText: 'نوع المهمة المطلوبة',
                          labelStyle: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w700,
                          ),
                          prefixIcon: const Icon(
                            Icons.assignment_rounded,
                            color: AppColors.royalBlue,
                          ),
                          filled: true,
                          fillColor: AppColors.slate50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.slate200,
                            ),
                          ),
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
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'history_taking',
                            child: Text(
                              'أخذ قصة مرضية',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'clinical_examination',
                            child: Text(
                              'الفحص السريري',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'follow_up',
                            child: Text(
                              'متابعة',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (v) => setLocal(() => task = v ?? task),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final now = DateTime.now();
                          final date = await showDatePicker(
                            context: context,
                            initialDate: dueAt ?? now,
                            firstDate: DateTime(now.year - 1),
                            lastDate: DateTime(now.year + 3),
                          );
                          if (date == null || !context.mounted) return;
                          final time = await showTimePicker(
                            context: context,
                            initialTime: dueAt == null
                                ? TimeOfDay.now()
                                : TimeOfDay.fromDateTime(dueAt!),
                          );
                          if (time == null) return;
                          setLocal(() {
                            dueAt = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'موعد الاستحقاق',
                            prefixIcon: const Icon(
                              Icons.event_available_rounded,
                            ),
                            suffixIcon: dueAt == null
                                ? null
                                : IconButton(
                                    tooltip: 'مَسح الموعد',
                                    onPressed: () =>
                                        setLocal(() => dueAt = null),
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                          ),
                          child: Text(
                            dueAt == null
                                ? 'اختياري - بدون موعد محدد'
                                : _docDateTimeForInput(
                                    _docDateTimeForApi(dueAt!),
                                  ),
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w800,
                              color: AppColors.midnight,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: instructions,
                        minLines: 3,
                        maxLines: 5,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.midnight,
                        ),
                        decoration: InputDecoration(
                          labelText: 'تعليمات وإرشادات للطالب',
                          labelStyle: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w700,
                          ),
                          alignLabelWithHint: true,
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 50),
                            child: Icon(
                              Icons.description_rounded,
                              color: AppColors.slate500,
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.slate50,
                          contentPadding: const EdgeInsets.all(16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.slate200,
                            ),
                          ),
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
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final result = await FilePicker.platform.pickFiles(
                            allowMultiple: false,
                            withData: false,
                          );
                          if (result == null || result.files.isEmpty) return;
                          setLocal(() => attachment = result.files.single);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: attachment == null
                                ? AppColors.slate50
                                : AppColors.royalBlue.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: attachment == null
                                  ? AppColors.slate200
                                  : AppColors.royalBlue.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                attachment == null
                                    ? Icons.attach_file_rounded
                                    : Icons.file_present_rounded,
                                color: attachment == null
                                    ? AppColors.slate500
                                    : AppColors.royalBlue,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      attachment?.name ??
                                          'إرفاق ملف أو صورة للتكليف',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'Cairo',
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12.5,
                                        color: AppColors.slate900,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      attachment == null
                                          ? 'اختياري، يستخدم لتوجيه الطالب بصورة أو ملف للحالة.'
                                          : 'سيتم إرسال هذا المرفق مع التكليف.',
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
                              if (attachment != null)
                                IconButton(
                                  tooltip: 'إزالة المرفق',
                                  onPressed: () =>
                                      setLocal(() => attachment = null),
                                  icon: const Icon(Icons.close_rounded),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
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
                        onPressed: () async {
                          if (formKey.currentState?.validate() != true) return;
                          final summary = _docMap(
                            selectedCase?['assignment_summary'],
                          );
                          final similarSummary = _docMap(
                            selectedCase?['similar_cases_summary'],
                          );
                          final studentsCount = _docInt(
                            summary['students_count'],
                          );
                          final similarCount = _docInt(
                            similarSummary['cases_count'],
                          );
                          if (studentsCount > 0 || similarCount > 0) {
                            final approved = await showMoeenConfirmDialog(
                              context: context,
                              title: 'تأكيد تكليف الحالة',
                              message:
                                  'هذه الحالة عليها $studentsCount طالب مكلف، ويوجد $similarCount حالة مشابهة داخل الكلية. هل تريد إرسال التكليف رغم ذلك؟',
                              confirmLabel: 'نعم، إرسال التكليف',
                              cancelLabel: 'مراجعة الحالة',
                              icon: Icons.warning_amber_rounded,
                              color: AppColors.warning,
                            );
                            if (!approved || !context.mounted) return;
                          }
                          Navigator.pop(context, true);
                        },
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: const Text(
                          'إرسال التكليف',
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
                          elevation: 2,
                          shadowColor: AppColors.royalBlue.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
    final payload = {
      'student_id': studentId,
      'clinical_case_id': caseId,
      'task_type': task,
      'instructions': instructions.text.trim(),
      if (dueAt != null) 'due_at': _docDateTimeForApi(dueAt!),
    };
    Future.delayed(const Duration(milliseconds: 500), () {
      instructions.dispose();
    });
    if (ok != true) return;
    try {
      if (attachment?.path != null) {
        await ref.read(staffRepositoryProvider).upload(_endpoint, {
          ...payload,
          'attachment': await MultipartFile.fromFile(
            attachment!.path!,
            filename: attachment!.name,
          ),
        });
      } else {
        await ref.read(staffRepositoryProvider).post(_endpoint, payload);
      }
      if (!mounted) return;
      _reload();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }
}
