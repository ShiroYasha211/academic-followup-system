part of 'staff_screens.dart';

class DoctorEvaluationResultDetailsScreen extends ConsumerStatefulWidget {
  const DoctorEvaluationResultDetailsScreen({
    super.key,
    required this.resultId,
    this.initialResult,
  });

  static const route = '/doctor/clinical/evaluations/results/:resultId';

  final int resultId;
  final Map<String, dynamic>? initialResult;

  @override
  ConsumerState<DoctorEvaluationResultDetailsScreen> createState() =>
      _DoctorEvaluationResultDetailsScreenState();
}

class _DoctorEvaluationResultDetailsScreenState
    extends ConsumerState<DoctorEvaluationResultDetailsScreen> {
  late Future<_Json> _future = _fetch();

  Future<_Json> _fetch() async {
    final response = await ref
        .read(staffRepositoryProvider)
        .get('/doctor/clinical/evaluations/results/${widget.resultId}');
    return _docMap(_docData(response));
  }

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'تفاصيل نتيجة التقييم',
      currentRoute: DoctorClinicalSectionScreen.path('results'),
      child: FutureBuilder<_Json>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
          final result = snapshot.data ?? const <String, dynamic>{};
          return RefreshIndicator(
            onRefresh: () async => setState(() => _future = _fetch()),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              children: [
                _EvaluationResultHero(result: result),
                const SizedBox(height: 14),
                _EvaluationResultStats(result: result),
                const SizedBox(height: 14),
                _EvaluationChecklistTree(result: result),
                const SizedBox(height: 14),
                _EvaluationWeaknesses(result: result),
                const SizedBox(height: 14),
                _EvaluationFeedback(result: result),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EvaluationResultHero extends StatelessWidget {
  const _EvaluationResultHero({required this.result});

  final _Json result;

  @override
  Widget build(BuildContext context) {
    final student = _docMap(result['student']);
    final checklist = _docMap(result['checklist']);
    final gradeColor = _evaluationGradeColor(_docText(result['grade']));
    final gradeLabel = _docText(
      result['grade_label'],
      _evaluationGradeLabel(_docText(result['grade'])),
    );
    final percentage = _docDouble(result['percentage']);
    final studentName = _docText(student['name'], 'طالب');
    final studentNo = _docText(student['student_number'], '-');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradeColor.withValues(alpha: 0.85),
            AppColors.midnight,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: gradeColor.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: AppColors.midnight.withValues(alpha: 0.1),
            blurRadius: 8,
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
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  studentName.isNotEmpty ? studentName.trim()[0] : '؟',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.school_rounded,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            studentName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Text(
                        'رقم القيد: $studentNo',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      gradeLabel,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.assignment_rounded,
                  color: Colors.white70,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _docText(checklist['title'], 'قائمة تقييم'),
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.45,
                    ),
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

class _EvaluationResultStats extends StatelessWidget {
  const _EvaluationResultStats({required this.result});

  final _Json result;

  @override
  Widget build(BuildContext context) {
    final counts = _docMap(result['status_counts']);
    final percentage = _docDouble(result['percentage']);
    final gradeColor = _evaluationGradeColor(_docText(result['grade']));
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(14),
                height: 104,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.slate100),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.midnight.withValues(alpha: 0.02),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 58,
                      height: 58,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: CircularProgressIndicator(
                              value: percentage / 100.0,
                              strokeWidth: 5.5,
                              color: gradeColor,
                              backgroundColor: AppColors.slate100,
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Text(
                            '${percentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: gradeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'الدرجة الكلية',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.slate500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_docText(result['total_score'], '0')} / ${_docText(result['max_score'], '0')}',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.midnight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                height: 104,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.slate100),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.midnight.withValues(alpha: 0.02),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.royalBlue.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.timer_rounded,
                        color: AppColors.royalBlue,
                        size: 18,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _docText(result['formatted_time'], '-'),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.midnight,
                        height: 1.1,
                      ),
                    ),
                    const Text(
                      'وقت الجلسة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.slate500,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ResultMetricTile(
                label: 'تم بالكامل',
                value: _docText(counts['done'], '0'),
                icon: Icons.check_circle_rounded,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ResultMetricTile(
                label: 'جزئي',
                value: _docText(counts['partial'], '0'),
                icon: Icons.pending_rounded,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ResultMetricTile(
                label: 'لم يتم',
                value: _docText(counts['not_done'], '0'),
                icon: Icons.cancel_rounded,
                color: AppColors.danger,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EvaluationChecklistTree extends StatelessWidget {
  const _EvaluationChecklistTree({required this.result});

  final _Json result;

  @override
  Widget build(BuildContext context) {
    final checklist = _docMap(result['checklist']);
    final items = _docList(checklist['items']);
    final scores = _docMap(result['scores_by_item']);
    if (items.isEmpty) {
      return const _DocEmpty('لا توجد بنود تفصيلية لهذه النتيجة.');
    }

    return _ResultSection(
      title: 'تفاصيل البنود',
      subtitle: 'البنود الرئيسية والفرعية كما ظهرت أثناء التقييم.',
      icon: Icons.account_tree_rounded,
      child: Column(
        children: items.asMap().entries.map((entry) {
          final item = entry.value;
          final subItems = _docList(item['sub_items']);
          final itemScore = _docMap(scores['${item['id']}']);
          return _ResultMainItem(
            index: entry.key,
            item: item,
            score: itemScore,
            subItems: subItems,
            scores: scores,
          );
        }).toList(),
      ),
    );
  }
}

class _EvaluationWeaknesses extends StatelessWidget {
  const _EvaluationWeaknesses({required this.result});

  final _Json result;

  @override
  Widget build(BuildContext context) {
    final items = _docList(
      result['weaknesses'],
    ).where((item) => _docText(item['description']).isNotEmpty).toList();
    if (items.isEmpty) {
      return _ResultSection(
        title: 'نقاط المتابعة والتوصيات',
        subtitle: 'لم تظهر بنود غير مكتملة في هذه النتيجة.',
        icon: Icons.verified_rounded,
        child: const _DocEmpty('الأداء ممتاز ومكتمل في كافة البنود.'),
      );
    }

    return _ResultSection(
      title: 'نقاط تحتاج متابعة وتطوير',
      subtitle: 'البنود التي تم تقييمها كجزئية أو لم تنفذ من قبل الطالب.',
      icon: Icons.error_outline_rounded,
      child: Column(
        children: items.map((item) {
          final scoreVal = _docText(item['score']);
          final color = _scoreColor(scoreVal);
          final isDanger = scoreVal == 'not_done';
          
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: 0.12),
                width: 1.2,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isDanger ? Icons.gpp_bad_rounded : Icons.warning_amber_rounded,
                  color: color,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _docText(item['description']),
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.midnight,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _ScoreBadge(score: scoreVal),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EvaluationFeedback extends StatelessWidget {
  const _EvaluationFeedback({required this.result});

  final _Json result;

  @override
  Widget build(BuildContext context) {
    final feedback = _docText(result['doctor_feedback']).trim();
    if (feedback.isEmpty) return const SizedBox.shrink();
    return _ResultSection(
      title: 'ملاحظات وتوجيهات المشرف',
      subtitle: 'التوصيات الأكاديمية والسريرية الموثقة للطالب.',
      icon: Icons.rate_review_rounded,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.royalBlue.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.royalBlue.withValues(alpha: 0.12),
            width: 1.2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.format_quote_rounded,
              color: AppColors.royalBlue.withValues(alpha: 0.25),
              size: 28,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                feedback,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.midnight,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultMainItem extends StatelessWidget {
  const _ResultMainItem({
    required this.index,
    required this.item,
    required this.score,
    required this.subItems,
    required this.scores,
  });

  final int index;
  final _Json item;
  final _Json score;
  final List<_Json> subItems;
  final _Json scores;

  IconData _itemIcon(String desc) {
    final text = desc.toLowerCase();
    if (text.contains('غسل') || text.contains('تعقيم') || text.contains('يد') || text.contains('wash') || text.contains('hand')) {
      return Icons.clean_hands_rounded;
    }
    if (text.contains('تواصل') || text.contains('تحدث') || text.contains('سؤال') || text.contains('شرح') || text.contains('explain') || text.contains('ask') || text.contains('commun')) {
      return Icons.forum_rounded;
    }
    if (text.contains('فحص') || text.contains('سماع') || text.contains('صدر') || text.contains('بطن') || text.contains('أذن') || text.contains('عين') || text.contains('stethoscope') || text.contains('examin')) {
      return Icons.healing_rounded;
    }
    if (text.contains('نبض') || text.contains('ضغط') || text.contains('حرارة') || text.contains('مؤشرات') || text.contains('pulse') || text.contains('temp')) {
      return Icons.monitor_heart_rounded;
    }
    if (text.contains('إبرة') || text.contains('حقن') || text.contains('سحب') || text.contains('دم') || text.contains('blood') || text.contains('inject')) {
      return Icons.vaccines_rounded;
    }
    return Icons.assignment_turned_in_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final hasSubItems = subItems.isNotEmpty;
    final itemDesc = _docText(item['description'], 'بند تقييم');
    final color = hasSubItems
        ? AppColors.royalBlue
        : _scoreColor(_docText(score['score']));
        
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: color.withValues(alpha: 0.16),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: color.withValues(alpha: 0.18),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    _itemIcon(itemDesc),
                    color: color,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        itemDesc,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColors.midnight,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.slate50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.slate100.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          hasSubItems
                              ? 'درجة البند: ${_docText(item['marks'], '0')}'
                              : 'الدرجة: ${_docText(score['marks_obtained'], '0')} من ${_docText(item['marks'], '0')}',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.slate600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (!hasSubItems) _ScoreBadge(score: _docText(score['score'])),
              ],
            ),
          ),
          if (hasSubItems)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: subItems.map((subItem) {
                  final subScore = _docMap(scores['${subItem['id']}']);
                  final subScoreVal = _docText(subScore['score']);
                  final subColor = _scoreColor(subScoreVal);
                  return Container(
                    margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.slate50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border(
                        right: BorderSide(
                          color: subColor,
                          width: 4,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _docText(subItem['description'], 'معيار فرعي'),
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.midnight,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'الدرجة: ${_docText(subScore['marks_obtained'], '0')} من ${_docText(subItem['marks'], '0')}',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.slate500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _ScoreBadge(score: subScoreVal),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _ResultSection extends StatelessWidget {
  const _ResultSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: AppColors.royalBlue, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.midnight,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate500,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ResultMetricTile extends StatelessWidget {
  const _ResultMetricTile({
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: AppColors.midnight.withValues(alpha: 0.01),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: color,
                    height: 1.1,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate500,
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


class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});

  final String score;

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _scoreLabel(score),
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

Color _scoreColor(String score) {
  return switch (score) {
    'done' => AppColors.success,
    'partial' => AppColors.warning,
    'not_done' => AppColors.danger,
    _ => AppColors.slate500,
  };
}

String _scoreLabel(String score) {
  return switch (score) {
    'done' => 'تم',
    'partial' => 'جزئي',
    'not_done' => 'لم يتم',
    _ => '-',
  };
}

String _evaluationGradeLabel(String grade) {
  return switch (grade) {
    'excellent' => 'ممتاز',
    'good' || 'very_good' => 'جيد جدا',
    'acceptable' || 'pass' => 'مقبول',
    'weak' => 'ضعيف',
    'fail' => 'راسب',
    _ => '-',
  };
}

Color _evaluationGradeColor(String grade) {
  return switch (grade) {
    'excellent' => AppColors.success,
    'good' || 'very_good' => AppColors.royalBlue,
    'acceptable' || 'pass' => AppColors.goldDeep,
    'weak' || 'fail' => AppColors.danger,
    _ => AppColors.slate600,
  };
}

double _docDouble(Object? value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  return double.tryParse(_docText(value)) ?? fallback;
}

