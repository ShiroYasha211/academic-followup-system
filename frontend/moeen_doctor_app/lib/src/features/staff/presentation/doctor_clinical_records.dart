part of 'staff_screens.dart';

class _ClinicalRecordCard extends StatelessWidget {
  const _ClinicalRecordCard({required this.item, required this.onTap});

  final _Json item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = _docText(item['status']);
    final statusLabel = _docText(item['status_label'], status);
    final student = _docMap(item['student']);
    final studentName = _docText(
      student['name'],
      _docText(item['student_name'], 'طالب'),
    );
    final studentNumber = _docText(
      student['student_number'],
      _docText(item['student_number'], '-'),
    );

    final center = _docText(
      _docMap(item['training_center'])['name'],
      _docText(item['training_center'], '-'),
    );
    final dept = _docText(
      _docMap(item['department'])['name'],
      _docText(item['department'], '-'),
    );
    final logDate = _docDate(item['log_date']);

    final groups = _docList(item['groups']);
    int historyCount = 0;
    int examCount = 0;
    bool didRound = false;

    for (final g in groups) {
      final map = _docMap(g);
      final key = _docText(map['key']);
      final count = _docInt(map['count']);
      if (key == 'history') {
        historyCount = count;
      } else if (key == 'exam') {
        examCount = count;
      } else if (key == 'round') {
        didRound = count > 0;
      }
    }

    final initial = studentName.isNotEmpty ? studentName.substring(0, 1) : 'ط';
    final statusColor = _docStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.04),
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.royalBlue.withValues(
                          alpha: 0.08,
                        ),
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.royalBlue,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Student info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              studentName,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                                color: AppColors.midnight,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'رقم القيد: $studentNumber',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.slate500,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status Badge
                      _buildStatusBadge(status, statusLabel, statusColor),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Training center & department & date
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.slate50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildMetaText(
                            Icons.local_hospital_rounded,
                            center,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetaText(
                            Icons.account_tree_rounded,
                            dept,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildMetaText(
                          Icons.calendar_month_rounded,
                          logDate,
                          isExpanded: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Activities stats row
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildStatChip(
                              Icons.history_edu_rounded,
                              'قصص: $historyCount',
                              AppColors.royalBlue,
                              historyCount > 0,
                            ),
                            _buildStatChip(
                              Icons.person_search_rounded,
                              'فحوصات: $examCount',
                              AppColors.gold,
                              examCount > 0,
                            ),
                            _buildStatChip(
                              Icons.groups_rounded,
                              'مرور سريري',
                              AppColors.teal,
                              didRound,
                            ),
                          ],
                        ),
                      ),
                      if (status == 'pending' ||
                          status == 'partially_confirmed') ...[
                        const SizedBox(width: 8),
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'مراجعة السجل',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.royalBlue,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 10,
                              color: AppColors.royalBlue,
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildStatusBadge(String status, String label, Color color) {
    IconData icon = Icons.info_outline_rounded;
    if (status == 'confirmed') {
      icon = Icons.verified_rounded;
    } else if (status == 'partially_confirmed') {
      icon = Icons.pending_actions_rounded;
    } else if (status == 'pending') {
      icon = Icons.hourglass_empty_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: color,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaText(IconData icon, String text, {bool isExpanded = true}) {
    final textWidget = Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 11,
        color: AppColors.slate600,
        fontWeight: FontWeight.w700,
        fontFamily: 'Cairo',
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.slate400),
        const SizedBox(width: 4),
        if (isExpanded) Expanded(child: textWidget) else textWidget,
      ],
    );
  }

  Widget _buildStatChip(
    IconData icon,
    String label,
    Color color,
    bool isActive,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.08) : AppColors.slate50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? color.withValues(alpha: 0.15) : AppColors.slate200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: isActive ? color : AppColors.slate400),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
              color: isActive ? color : AppColors.slate500,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}
