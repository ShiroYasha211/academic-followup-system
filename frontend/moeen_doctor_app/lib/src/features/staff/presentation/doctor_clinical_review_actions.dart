part of 'staff_screens.dart';

extension _DoctorClinicalReviewActions on _DoctorClinicalSectionScreenState {
  Future<void> _showGenericDetails(_Json item) async {
    if (widget.section == 'departments') {
      await _showDepartmentDetails(item);
      return;
    }
    if (widget.section == 'body-systems') {
      await _showBodySystemDetails(item);
      return;
    }
    if (widget.section == 'checklists') {
      await showMoeenBottomSheet<void>(
        context: context,
        title: _genericTitle(item),
        icon: _icon,
        color: AppColors.royalBlue,
        child: _ChecklistDetailsView(item: item),
      );
      return;
    }
    await showMoeenBottomSheet<void>(
      context: context,
      title: _genericTitle(item),
      icon: _icon,
      color: AppColors.royalBlue,
      child: _JsonDetailsView(item: item),
    );
  }

  Future<void> _showEvaluationResult(_Json item) async {
    await GoRouter.of(context).push(
      DoctorEvaluationResultDetailsScreen.route.replaceFirst(
        ':resultId',
        '${item['id']}',
      ),
      extra: item,
    );
  }

  Future<void> _showLogDetails(_Json rawLog) async {
    final log = rawLog.containsKey('log') ? _docMap(rawLog['log']) : rawLog;
    final groups = _docList(log['groups']);
    final confirmations = <String, String>{
      for (final group in groups)
        _docText(group['key']): _docBool(group['confirmed'])
            ? 'approved'
            : _docBool(group['has_rejected'])
            ? 'rejected'
            : 'pending',
    };
    final notes = TextEditingController(text: _docText(log['doctor_notes']));
    final action = await showMoeenBottomSheet<String>(
      context: context,
      title: 'مراجعة السجل العملي',
      icon: Icons.library_books_rounded,
      color: _docStatusColor(_docText(log['status'])),
      fullScreen: true,
      child: StatefulBuilder(
        builder: (context, setLocal) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StudentLogInfoCard(log: log),
            const SizedBox(height: 16),
            if (groups.isNotEmpty) ...[
              OutlinedButton.icon(
                onPressed: () async {
                  final hasRejected = confirmations.values.any(
                    (value) => value == 'rejected',
                  );
                  if (hasRejected) {
                    final confirmed = await showMoeenConfirmDialog(
                      context: context,
                      title: 'تأكيد كل أجزاء السجل؟',
                      message:
                          'سيتم تحويل كل أجزاء السجل، بما فيها الأجزاء المرفوضة حاليًا، إلى اعتماد. هل تريد المتابعة؟',
                      confirmLabel: 'نعم، تأكيد الكل',
                      cancelLabel: 'إلغاء',
                      icon: Icons.done_all_rounded,
                      color: AppColors.success,
                    );
                    if (!confirmed) return;
                  }
                  setLocal(() {
                    for (final group in groups) {
                      confirmations[_docText(group['key'])] = 'approved';
                    }
                  });
                },
                icon: const Icon(Icons.done_all_rounded),
                label: const Text(
                  'تأكيد الكل',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.success,
                  side: BorderSide(
                    color: AppColors.success.withValues(alpha: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (groups.isNotEmpty)
              ...groups.map((group) {
                final key = _docText(group['key']);
                return _LogActivityGroupCard(
                  group: group,
                  status: confirmations[key] ?? 'pending',
                  onStatusChanged: (value) =>
                      setLocal(() => confirmations[key] = value),
                );
              }),
            _DoctorNotesBento(notesController: notes),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context, 'reject'),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.danger,
                    ),
                    label: const Text(
                      'رفض كامل',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                        color: AppColors.danger,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.danger),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      final hasAnyConfirm = confirmations.values.any(
                        (val) => val != 'pending',
                      );
                      if (!hasAnyConfirm) {
                        _docSnack(
                          context,
                          'يرجى اختيار قرار واحد على الأقل للمجموعات السريرية.',
                          color: AppColors.warning,
                        );
                        return;
                      }
                      Navigator.pop(context, 'confirm');
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: const Text(
                      'حفظ المراجعة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
    if (action == null) return;
    try {
      await ref.read(staffRepositoryProvider).post(
        '/doctor/clinical/logbook/confirm',
        {
          'log_id': log['log_id'] ?? log['id'],
          'action': action,
          'doctor_notes': notes.text.trim(),
          'confirmations': {
            for (final entry in confirmations.entries)
              entry.key: {'status': entry.value},
          },
        },
      );
      if (!mounted) return;
      _reload();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    } finally {
      notes.dispose();
    }
  }

  Future<void> _reviewAssignment(_Json assignment) async {
    final notes = TextEditingController();
    String reviewRating = 'good';

    final student = _docMap(assignment['student']);
    final studentName = _docText(student['name'], 'طالب');
    final studentNumber = _docText(student['student_number'], '-');

    final clinicalCase = _docMap(assignment['clinical_case']);
    final patientName = _docText(clinicalCase['patient_name'], 'مريض');
    final diagnosis = _docText(clinicalCase['diagnosis_or_description'], '-');
    final center = _docText(_docMap(clinicalCase['training_center'])['name']);
    final dept = _docText(_docMap(clinicalCase['clinical_department'])['name']);

    final taskType = _taskTypeLabel(_docText(assignment['task_type']));
    final studentMessage = _docText(assignment['student_completion_message']);
    final attachmentUrl = _docText(assignment['attachment_url']);
    final attachmentName = _docText(
      assignment['attachment_name'],
      'مرفق التكليف',
    );

    final action = await showMoeenBottomSheet<String>(
      context: context,
      title: 'مراجعة التكليف',
      icon: Icons.assignment_turned_in_rounded,
      color: AppColors.warning,
      child: StatefulBuilder(
        builder: (context, setLocal) {
          Widget buildDetailRow(String label, String value) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.slate500,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: AppColors.midnight,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Student & Task info header card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.royalBlue.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.royalBlue.withValues(
                        alpha: 0.15,
                      ),
                      child: Text(
                        studentName.isNotEmpty
                            ? studentName.substring(0, 1)
                            : 'ط',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.royalBlue,
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
                            studentName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppColors.midnight,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'رقم القيد: $studentNumber',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.slate500,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        taskType,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.gold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 2. Clinical Case details card
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
                          color: AppColors.royalBlue,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'تفاصيل الحالة الطبية',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppColors.midnight,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                    const Divider(
                      height: 20,
                      thickness: 0.8,
                      color: AppColors.slate100,
                    ),
                    buildDetailRow('المريض', patientName),
                    buildDetailRow('التشخيص', diagnosis),
                    buildDetailRow(
                      'المركز السريري',
                      center.isNotEmpty ? center : '-',
                    ),
                    buildDetailRow(
                      'القسم المختص',
                      dept.isNotEmpty ? dept : '-',
                    ),
                  ],
                ),
              ),

              // 3. Student message & attachments if present
              if (studentMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.slate50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: AppColors.royalBlue,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'رسالة إنجاز الطالب',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: AppColors.midnight,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                      const Divider(
                        height: 20,
                        thickness: 0.8,
                        color: AppColors.slate200,
                      ),
                      Text(
                        studentMessage,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate700,
                          height: 1.45,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (attachmentUrl.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'الملف المرفق',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.midnight,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 6),
                _AssignmentAttachmentPreview(
                  url: attachmentUrl,
                  name: attachmentName,
                  mimeType: _docText(assignment['attachment_type']),
                ),
              ],

              const SizedBox(height: 16),
              const Divider(
                height: 24,
                thickness: 1,
                color: AppColors.slate100,
              ),

              // Dropdown Rating
              DropdownButtonFormField<String>(
                initialValue: reviewRating,
                decoration: InputDecoration(
                  labelText: 'التقييم المختصر عند الاعتماد',
                  labelStyle: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                  ),
                  prefixIcon: const Icon(
                    Icons.stars_rounded,
                    color: AppColors.gold,
                  ),
                  filled: true,
                  fillColor: AppColors.slate50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.slate200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.slate200),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'excellent',
                    child: Text(
                      'ممتاز',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'good',
                    child: Text(
                      'جيد',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'needs_improvement',
                    child: Text(
                      'يحتاج تحسين',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) =>
                    setLocal(() => reviewRating = value ?? reviewRating),
              ),
              const SizedBox(height: 12),

              // Notes TextField
              TextField(
                controller: notes,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'ملاحظات المراجعة',
                  labelStyle: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                  ),
                  prefixIcon: const Icon(
                    Icons.rate_review_rounded,
                    color: AppColors.royalBlue,
                  ),
                  filled: true,
                  fillColor: AppColors.slate50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.slate200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.slate200),
                  ),
                ),
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context, 'reject'),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.danger,
                      ),
                      label: const Text(
                        'رفض التكليف',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w800,
                          color: AppColors.danger,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.danger),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context, 'approve'),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text(
                        'اعتماد وإغلاق',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
    if (action == null) return;
    try {
      await ref
          .read(staffRepositoryProvider)
          .post('/doctor/clinical/assignments/${assignment['id']}/review', {
            'action': action,
            'review_notes': notes.text.trim(),
            if (action == 'approve') 'review_rating': reviewRating,
          });
      if (!mounted) return;
      _reload();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    } finally {
      notes.dispose();
    }
  }

  Future<void> _deleteItem(_Json item) async {
    final ok = await showMoeenConfirmDialog(
      context: context,
      title: 'تأكيد الحذف',
      message: 'هل تريد حذف هذا العنصر؟',
      confirmLabel: 'حذف',
      icon: Icons.delete_rounded,
      color: AppColors.danger,
    );
    if (!ok) return;
    try {
      await ref
          .read(staffRepositoryProvider)
          .delete('$_endpoint/${item['id']}');
      if (!mounted) return;
      _reload();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  Future<void> _restoreChecklist(_Json item) async {
    final title = _docText(item['title'], 'قائمة التقييم');
    final ok = await showMoeenConfirmDialog(
      context: context,
      title: 'استرجاع قائمة التقييم',
      message: 'هل تريد استرجاع "$title" وإظهارها ضمن قوائم التقييم المتاحة؟',
      confirmLabel: 'استرجاع',
      icon: Icons.restore_rounded,
      color: AppColors.success,
    );
    if (!ok) return;

    try {
      await ref
          .read(staffRepositoryProvider)
          .post(
            '/doctor/clinical/evaluations/checklists/${item['id']}/restore',
            {},
          );
      if (!mounted) return;
      _docSnack(context, 'تم استرجاع قائمة التقييم.', color: AppColors.success);
      _reload();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }
}
