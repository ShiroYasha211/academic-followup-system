part of 'staff_screens.dart';

class _ClinicalEvaluationResultCard extends StatelessWidget {
  const _ClinicalEvaluationResultCard({
    required this.item,
    required this.onTap,
  });

  final _Json item;
  final VoidCallback onTap;

  IconData _gradeIcon(String grade) {
    return switch (grade) {
      'excellent' => Icons.workspace_premium_rounded,
      'good' || 'very_good' => Icons.thumb_up_rounded,
      'acceptable' || 'pass' => Icons.check_circle_rounded,
      'weak' => Icons.info_rounded,
      'fail' => Icons.cancel_rounded,
      _ => Icons.star_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final student = _docMap(item['student']);
    final studentName = _docText(student['name'], 'طالب');
    final studentNo = _docText(student['student_number'], '-');
    final checklist = _docMap(item['checklist']);
    final checklistTitle = _docText(checklist['title'], 'تقييم');
    final percentage = _docDouble(item['percentage']);
    final grade = _docText(item['grade']);
    final hasFeedback = _docText(item['doctor_feedback']).trim().isNotEmpty;
    final date = _docText(item['created_at']);

    final gradeColor = _evaluationGradeColor(grade);
    final gradeLabel = _docText(
      item['grade_label'],
      _evaluationGradeLabel(grade),
    );

    String formattedDate = '';
    try {
      if (date.isNotEmpty) {
        final parsed = DateTime.parse(date).toLocal();
        formattedDate =
            '${parsed.year}/${parsed.month.toString().padLeft(2, '0')}/${parsed.day.toString().padLeft(2, '0')} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
      }
    } catch (_) {
      formattedDate = date;
    }

    final String initial = studentName.isNotEmpty
        ? studentName.trim().substring(0, 1)
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: AppColors.midnight.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: gradeColor.withValues(alpha: 0.08),
            highlightColor: gradeColor.withValues(alpha: 0.04),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: gradeColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: gradeColor.withValues(alpha: 0.18),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          initial,
                          style: TextStyle(
                            color: gradeColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                                color: AppColors.midnight,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.slate50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.slate100.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              child: Text(
                                'رقم القيد: $studentNo',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.slate600,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: gradeColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: gradeColor.withValues(alpha: 0.18),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _gradeIcon(grade),
                              color: gradeColor,
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$gradeLabel - ${percentage.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: gradeColor,
                                fontFamily: 'Cairo',
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 1,
                    color: AppColors.slate100.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.assignment_outlined,
                        size: 15,
                        color: AppColors.slate400,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          checklistTitle,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.midnight,
                            fontFamily: 'Cairo',
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.slate50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.slate100.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_rounded,
                              size: 13,
                              color: AppColors.slate400,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              formattedDate,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: AppColors.slate600,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (hasFeedback)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.royalBlue.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.royalBlue.withValues(
                                alpha: 0.12,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 13,
                                color: AppColors.royalBlue,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'ملاحظات مضافة',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: AppColors.royalBlue,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
