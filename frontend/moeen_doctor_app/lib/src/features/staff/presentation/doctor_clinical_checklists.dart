part of 'staff_screens.dart';

class _ClinicalChecklistCard extends StatelessWidget {
  const _ClinicalChecklistCard({
    required this.item,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onRestore,
    this.isHidden = false,
  });

  final _Json item;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final bool isHidden;

  @override
  Widget build(BuildContext context) {
    final title = _docText(item['title'], 'قائمة تقييم');
    final desc = _docText(item['description']);
    final skillType = _docText(item['skill_type']);
    final totalMarks = _docInt(item['total_marks']);
    final timeLimit = _docInt(item['time_limit_minutes']);
    final isPractice = _docBool(item['is_practice_allowed']);
    final isStandard = _docBool(item['is_standard']);

    String skillLabel = 'مهارات أخرى';
    IconData skillIcon = Icons.fact_check_rounded;
    Color skillColor = AppColors.slate600;

    if (skillType == 'history_taking') {
      skillLabel = 'أخذ التاريخ المرضي';
      skillIcon = Icons.history_edu_rounded;
      skillColor = AppColors.royalBlue;
    } else if (skillType == 'clinical_examination') {
      skillLabel = 'الفحص السريري';
      skillIcon = Icons.person_search_rounded;
      skillColor = AppColors.gold;
    } else if (skillType == 'procedure') {
      skillLabel = 'إجراء طبي سريري';
      skillIcon = Icons.healing_rounded;
      skillColor = AppColors.teal;
    } else if (skillType == 'communication') {
      skillLabel = 'مهارات التواصل';
      skillIcon = Icons.forum_rounded;
      skillColor = Colors.purple;
    }

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
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: skillColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(skillIcon, color: skillColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                                color: AppColors.midnight,
                                fontFamily: 'Cairo',
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  skillLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: skillColor,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: AppColors.slate300,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isStandard
                                        ? AppColors.royalBlue.withValues(
                                            alpha: 0.08,
                                          )
                                        : Colors.purple.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isStandard ? 'أساسية' : 'مخصصة',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: isStandard
                                          ? AppColors.royalBlue
                                          : Colors.purple,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.slate500,
                        height: 1.4,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
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
                          child: _buildInfoItem(
                            Icons.star_rounded,
                            '$totalMarks درجة',
                            AppColors.gold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildInfoItem(
                            Icons.timer_rounded,
                            timeLimit > 0 ? '$timeLimit دقائق' : 'مفتوح',
                            AppColors.royalBlue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildInfoItem(
                            Icons.psychology_rounded,
                            isPractice ? 'يسمح بالتدريب' : 'تقييم رسمي',
                            AppColors.teal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isHidden && onRestore != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildActionButton(
                          icon: Icons.visibility_rounded,
                          label: 'عرض البنود',
                          color: AppColors.royalBlue,
                          onTap: onTap,
                        ),
                        const SizedBox(width: 12),
                        _buildActionButton(
                          icon: Icons.restore_rounded,
                          label: 'استرجاع',
                          color: AppColors.success,
                          onTap: onRestore!,
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildActionButton(
                          icon: Icons.visibility_rounded,
                          label: 'عرض البنود',
                          color: AppColors.royalBlue,
                          onTap: onTap,
                        ),
                        const SizedBox(width: 12),
                        _buildActionButton(
                          icon: onRestore != null
                              ? Icons.restore_rounded
                              : Icons.edit_rounded,
                          label: isStandard ? 'نسخ وتعديل' : 'تعديل',
                          color: onRestore != null
                              ? AppColors.success
                              : AppColors.success,
                          onTap: onEdit ?? onRestore ?? onTap,
                        ),
                        if (onDelete != null) ...[
                          const SizedBox(width: 12),
                          _buildActionButton(
                            icon: Icons.delete_rounded,
                            label: isStandard ? 'إخفاء القائمة' : 'حذف',
                            color: AppColors.danger,
                            onTap: onDelete ?? onRestore ?? onTap,
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

  Widget _buildInfoItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.slate600,
              fontWeight: FontWeight.w700,
              fontFamily: 'Cairo',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        ),
      ),
    );
  }
}

class _ChecklistDetailsView extends StatefulWidget {
  const _ChecklistDetailsView({required this.item});

  final _Json item;

  @override
  State<_ChecklistDetailsView> createState() => _ChecklistDetailsViewState();
}

class _ChecklistDetailsViewState extends State<_ChecklistDetailsView> {
  double _fontSizeScale = 1.0;

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
        t.contains('ضغط') ||
        t.contains('حرارة') ||
        t.contains('تنفس') ||
        t.contains('pulse') ||
        t.contains('blood pressure') ||
        t.contains('temperature')) {
      return Icons.monitor_heart_rounded;
    }
    return Icons.subdirectory_arrow_left_rounded; // Default fallback icon
  }

  String? _getSkillTypeTag(String text) {
    final t = text.toLowerCase();
    if (t.contains('تواصل') ||
        t.contains('شرح') ||
        t.contains('سؤال') ||
        t.contains('تحدث') ||
        t.contains('مريض') ||
        t.contains('explain') ||
        t.contains('ask')) {
      return 'مهارة تواصل';
    }
    if (t.contains('فحص') ||
        t.contains('سماع') ||
        t.contains('جس') ||
        t.contains('قرع') ||
        t.contains('examine') ||
        t.contains('listen') ||
        t.contains('palpate')) {
      return 'فحص سريري';
    }
    if (t.contains('حقن') ||
        t.contains('سحب') ||
        t.contains('تركيب') ||
        t.contains('خياطة') ||
        t.contains('علاج') ||
        t.contains('procedure')) {
      return 'إجراء عملي';
    }
    return null; // No special tag
  }

  @override
  Widget build(BuildContext context) {
    final title = _docText(widget.item['title'], 'قائمة التقييم');
    final desc = _docText(widget.item['description']);
    final totalMarks = _docInt(widget.item['total_marks']);
    final timeLimit = _docInt(widget.item['time_limit_minutes']);
    final isStandard = _docBool(widget.item['is_standard']);
    final rawItems = _docList(widget.item['items']);

    // Separate parents and sub items
    final parents = rawItems.where((i) {
      final pid = _docText(i['parent_id']);
      return pid.isEmpty || pid == '0';
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header title, zoom controls and tag
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isStandard
                                ? AppColors.royalBlue.withValues(alpha: 0.08)
                                : Colors.purple.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isStandard
                                  ? AppColors.royalBlue.withValues(alpha: 0.2)
                                  : Colors.purple.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            isStandard ? 'أساسية' : 'مخصصة',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: isStandard
                                  ? AppColors.royalBlue
                                  : Colors.purple,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Zoom accessibility controls
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
                                    setState(() {
                                      _fontSizeScale -= 0.15;
                                    });
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
                                    setState(() {
                                      _fontSizeScale += 0.15;
                                    });
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
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15 * _fontSizeScale,
                        fontWeight: FontWeight.bold,
                        color: AppColors.midnight,
                        fontFamily: 'Cairo',
                        height: 1.3,
                      ),
                    ),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        desc,
                        style: TextStyle(
                          fontSize: 12 * _fontSizeScale,
                          color: AppColors.slate500,
                          fontFamily: 'Cairo',
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.assignment_turned_in_rounded,
                  color: AppColors.royalBlue,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Bento Grid for Metadata
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          color: AppColors.gold,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'الدرجة الكلية',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.slate500,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            Text(
                              '$totalMarks درجة',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.midnight,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.royalBlue.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.royalBlue.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.royalBlue.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.timer_rounded,
                          color: AppColors.royalBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'زمن الاختبار',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.slate500,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            Text(
                              timeLimit > 0 ? '$timeLimit دقائق' : 'مفتوح',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.midnight,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'بنود ومعايير التقييم',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: AppColors.midnight,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 12),
          if (parents.isEmpty)
            const _DocEmpty('لا توجد بنود تقييم مضافة لهذه القائمة.')
          else
            ...parents.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final parent = entry.value;
              final pid = _docInt(parent['id']);
              final subItems = rawItems
                  .where((i) => _docInt(i['parent_id']) == pid)
                  .toList();
              final indexStr = index.toString().padLeft(2, '0');
              final parentMarks = _docText(parent['marks'], '0');
              final parentDesc = _docText(parent['description']);

              // Calculate parent weight
              final parentMarksDbl = double.tryParse(parentMarks) ?? 0.0;
              final weight = totalMarks > 0
                  ? (parentMarksDbl / totalMarks)
                  : 0.0;
              final skillTag = _getSkillTypeTag(parentDesc);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.slate100),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.midnight.withValues(alpha: 0.01),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Parent Item row
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sequential index circle
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.royalBlue.withValues(
                                alpha: 0.08,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              indexStr,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.royalBlue,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Content & Weight
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        parentDesc,
                                        style: TextStyle(
                                          fontSize: 12.5 * _fontSizeScale,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.midnight,
                                          fontFamily: 'Cairo',
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                    if (skillTag != null) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.royalBlue.withValues(
                                            alpha: 0.06,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          skillTag,
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.royalBlue,
                                            fontFamily: 'Cairo',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (weight > 0) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                          child: LinearProgressIndicator(
                                            value: weight,
                                            backgroundColor: AppColors.slate100,
                                            color: AppColors.gold.withValues(
                                              alpha: 0.6,
                                            ),
                                            minHeight: 3,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${(weight * 100).toInt()}% من الإجمالي',
                                        style: const TextStyle(
                                          fontSize: 9,
                                          color: AppColors.slate400,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Mark badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Text(
                              '$parentMarks د',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.gold,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (subItems.isNotEmpty) ...[
                      // Line separator
                      Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 14),
                        color: AppColors.slate100,
                      ),
                      // Nested sub items block
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        decoration: BoxDecoration(
                          color: AppColors.slate50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: subItems.map((sub) {
                            final subMarks = _docText(sub['marks'], '0');
                            final subDesc = _docText(sub['description']);
                            final adaptiveIcon = _getAdaptiveIcon(subDesc);

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Icon(
                                      adaptiveIcon,
                                      size: 13,
                                      color: AppColors.royalBlue,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      subDesc,
                                      style: TextStyle(
                                        fontSize: 11.5 * _fontSizeScale,
                                        color: AppColors.slate700,
                                        fontFamily: 'Cairo',
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppColors.slate200,
                                      ),
                                    ),
                                    child: Text(
                                      '$subMarks د',
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.slate600,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

extension _DoctorClinicalChecklistActions on _DoctorClinicalSectionScreenState {
  Future<void> _openChecklistForm({_Json? item}) async {
    final router = GoRouter.of(context);
    final updated = item == null
        ? await router.push<bool>(DoctorChecklistFormScreen.createRoute)
        : await router.push<bool>(
            DoctorChecklistFormScreen.editRoute.replaceFirst(
              ':checklistId',
              '${item['id']}',
            ),
            extra: item,
          );
    if (updated == true && mounted) {
      _reload();
    }
  }
}
