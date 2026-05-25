import re

path = "frontend/moeen_doctor_app/lib/src/features/staff/presentation/doctor_quizzes.dart"
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

pattern = r'(@override\s+Widget build\(BuildContext context\) \{\s+return FutureBuilder<Map<String, dynamic>>\(\s+future: _future,.*?)(\n\s*\}\s*class _QuizInfoCard)'

new_build = """  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
        final data = _docMap(_docData(snapshot.data ?? const {}));
        final quiz = _docMap(data['quiz']);
        final stats = _docMap(data['stats']);
        final models = _docList(quiz['models']);
        final canEditContent = _docBool(data['can_edit_content']);
        final status = _docText(quiz['status'], 'draft');
        final statusColor = _docStatusColor(status);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.royalBlue,
                    AppColors.royalBlue.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.45),
                  width: 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.22),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                        width: 1.2,
                      ),
                    ),
                    child: Icon(_quizStatusIcon(status), color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _docText(quiz['title'], 'كويز'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Cairo',
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.timer_rounded,
                              color: Colors.white.withValues(alpha: 0.72),
                              size: 14,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _quizTimerLabel(quiz),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DocPill(
                  _docStatusLabel(status),
                  statusColor,
                  icon: _quizStatusIcon(status),
                ),
                _DocPill(
                  _quizTimerLabel(quiz),
                  AppColors.warning,
                  icon: Icons.timer_rounded,
                ),
                _DocPill(
                  _docText(quiz['results_visibility']) == 'public'
                      ? 'نتائج عامة للكل'
                      : _docText(quiz['results_visibility']) == 'individual'
                          ? 'نتائج فردية للطلاب'
                          : 'النتائج مخفية حالياً',
                  _docText(quiz['results_visibility']) == 'hidden' || _docText(quiz['results_visibility']).isEmpty
                      ? AppColors.danger
                      : AppColors.success,
                  icon: _docText(quiz['results_visibility']) == 'hidden' || _docText(quiz['results_visibility']).isEmpty
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildBentoMetricCard(
                        label: 'عدد المحاولات',
                        value: _docText(stats['total_attempts'], '0'),
                        color: AppColors.info,
                        icon: Icons.people_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildBentoMetricCard(
                        label: 'متوسط الدرجات',
                        value: _docText(stats['avg_score'], '0'),
                        color: AppColors.royalBlue,
                        icon: Icons.analytics_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildBentoMetricCard(
                        label: 'أعلى درجة مرصودة',
                        value: _docText(stats['highest_score'], '0'),
                        color: AppColors.success,
                        icon: Icons.trending_up_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildBentoMetricCard(
                        label: 'أدنى درجة مرصودة',
                        value: _docText(stats['lowest_score'], '0'),
                        color: AppColors.danger,
                        icon: Icons.trending_down_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.slate100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.notes_rounded, color: AppColors.royalBlue, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'وصف الكويز',
                        style: TextStyle(
                          color: AppColors.midnight,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _docText(quiz['description']).trim().isEmpty
                        ? 'لا يوجد وصف مضاف لهذا الكويز.'
                        : _docText(quiz['description']),
                    style: const TextStyle(
                      color: AppColors.slate700,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      fontFamily: 'Cairo',
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuizInfoCard(
                    label: 'الجدولة والبدء',
                    value: _docText(quiz['scheduled_at']).isNotEmpty
                        ? _docDate(quiz['scheduled_at'])
                        : 'النشر فوراً',
                    icon: Icons.event_available_rounded,
                    color: _docText(quiz['scheduled_at']).isNotEmpty
                        ? AppColors.info
                        : AppColors.success,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuizInfoCard(
                    label: 'تاريخ الإغلاق',
                    value: _docText(quiz['closes_at']).isNotEmpty
                        ? _docDate(quiz['closes_at'])
                        : 'غير محدد (مفتوح)',
                    icon: Icons.event_busy_rounded,
                    color: _docText(quiz['closes_at']).isNotEmpty
                        ? AppColors.danger
                        : AppColors.slate500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _DocFilterPanel(
              title: 'نماذج الكويز والأسئلة',
              icon: Icons.view_module_rounded,
              children: [
                if (models.isEmpty)
                  const _DocEmpty('لا توجد نماذج مرتبطة بهذا الكويز.')
                else
                  ...models.asMap().entries.map((entry) {
                    final index = entry.key;
                    final model = entry.value;
                    final questions = _docList(model['questions']);
                    final isExpanded = _expandedModels.contains(index);
                    final hasAccessCode = _docText(model['access_code']).isNotEmpty;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isExpanded ? AppColors.royalBlue.withValues(alpha: 0.3) : AppColors.slate100,
                          width: isExpanded ? 1.4 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header (Tap to toggle)
                          InkWell(
                            onTap: () => setState(() {
                              if (isExpanded) {
                                _expandedModels.remove(index);
                              } else {
                                _expandedModels.add(index);
                              }
                            }),
                            borderRadius: BorderRadius.circular(22),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: (isExpanded ? AppColors.royalBlue : AppColors.slate200).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      Icons.ballot_rounded,
                                      color: isExpanded ? AppColors.royalBlue : AppColors.slate600,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _docText(model['name'], 'نموذج'),
                                          style: const TextStyle(
                                            color: AppColors.midnight,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14.5,
                                            fontFamily: 'Cairo',
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Text(
                                              '${questions.length} سؤال',
                                              style: const TextStyle(
                                                color: AppColors.slate500,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                fontFamily: 'Cairo',
                                              ),
                                            ),
                                            if (hasAccessCode) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.royalBlue.withValues(alpha: 0.08),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  'كود: ${_docText(model['access_code'])}',
                                                  style: const TextStyle(
                                                    color: AppColors.royalBlue,
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                    color: AppColors.slate400,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Expanded questions panel
                          if (isExpanded) ...[
                            const Divider(height: 1, color: AppColors.slate100),
                            Container(
                              color: AppColors.slate50.withValues(alpha: 0.5),
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  if (questions.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      child: _DocEmpty('لا توجد أسئلة مضافة في هذا النموذج.'),
                                    )
                                  else
                                    ...questions.asMap().entries.map((qEntry) {
                                      final qIndex = qEntry.key;
                                      final q = qEntry.value;
                                      final qText = _docText(q['question_text']);
                                      final qScore = _docText(q['score'], '1');
                                      final qTime = _docText(q['time_limit_seconds']);
                                      final qOptions = _docList(q['options']);
                                      final correctionNote = _docText(q['correction_note']);
                                      final infoSource = _docText(q['info_source']);

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: AppColors.slate100),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Question header
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.royalBlue.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    'س ${qIndex + 1}',
                                                    style: const TextStyle(
                                                      color: AppColors.royalBlue,
                                                      fontWeight: FontWeight.w900,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    qText,
                                                    style: const TextStyle(
                                                      color: AppColors.midnight,
                                                      fontWeight: FontWeight.w900,
                                                      fontSize: 13.5,
                                                      fontFamily: 'Cairo',
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                _DocPill(
                                                  '$qScore درجة',
                                                  AppColors.royalBlue,
                                                  icon: Icons.grade_rounded,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            // Options list
                                            ...qOptions.asMap().entries.map((optEntry) {
                                              final opt = optEntry.value;
                                              final optText = _docText(opt['option_text']);
                                              final isCorrect = _docBool(opt['is_correct']);

                                              return Container(
                                                margin: const EdgeInsets.only(bottom: 6),
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: isCorrect
                                                      ? AppColors.success.withValues(alpha: 0.07)
                                                      : AppColors.slate50,
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: isCorrect
                                                        ? AppColors.success.withValues(alpha: 0.25)
                                                        : AppColors.slate100,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      isCorrect ? Icons.check_circle_rounded : Icons.circle_outlined,
                                                      color: isCorrect ? AppColors.success : AppColors.slate400,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        optText,
                                                        style: TextStyle(
                                                          color: isCorrect ? AppColors.success : AppColors.slate700,
                                                          fontWeight: isCorrect ? FontWeight.w900 : FontWeight.w700,
                                                          fontSize: 12.5,
                                                          fontFamily: 'Cairo',
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }),
                                            // Question metadata (Correction notes, source, time)
                                            if (correctionNote.isNotEmpty || infoSource.isNotEmpty || (quiz['timer_mode'] == 'per_question' && qTime.isNotEmpty)) ...[
                                              const SizedBox(height: 8),
                                              const Divider(height: 1, color: AppColors.slate100),
                                              const SizedBox(height: 8),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 6,
                                                children: [
                                                  if (quiz['timer_mode'] == 'per_question' && qTime.isNotEmpty)
                                                    _DocPill(
                                                      'الوقت: $qTime ثانية',
                                                      AppColors.warning,
                                                      icon: Icons.timer_rounded,
                                                    ),
                                                  if (correctionNote.isNotEmpty)
                                                    _DocPill(
                                                      'ملاحظة: $correctionNote',
                                                      AppColors.info,
                                                      icon: Icons.fact_check_rounded,
                                                    ),
                                                  if (infoSource.isNotEmpty)
                                                    _DocPill(
                                                      'المصدر: $infoSource',
                                                      AppColors.teal,
                                                      icon: Icons.source_rounded,
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      );
                                    }),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
              ],
            ),
            const SizedBox(height: 14),
            _DocFilterPanel(
              title: 'إجراءات الكويز والتحكم',
              icon: Icons.tune_rounded,
              children: [
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            onPressed: _busy || status == 'published'
                                ? null
                                : () => _action(
                                    '/doctor/quizzes/${widget.quizId}/publish',
                                    'تم نشر الكويز.',
                                  ),
                            label: 'نشر الكويز',
                            icon: Icons.public_rounded,
                            color: AppColors.success,
                            filled: status != 'published',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildActionButton(
                            onPressed: _busy || status == 'closed'
                                ? null
                                : () => _action(
                                    '/doctor/quizzes/${widget.quizId}/close',
                                    'تم إغلاق الكويز.',
                                  ),
                            label: 'إغلاق الكويز',
                            icon: Icons.lock_rounded,
                            color: AppColors.danger,
                            filled: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            onPressed: _results,
                            label: 'نتائج الطلاب',
                            icon: Icons.analytics_rounded,
                            color: AppColors.royalBlue,
                            filled: false,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildActionButton(
                            onPressed: () => widget.onEdit(data),
                            label: canEditContent ? 'تعديل كامل' : 'تعديل الإعدادات',
                            icon: Icons.edit_rounded,
                            color: AppColors.royalBlue,
                            filled: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Row(
                  children: [
                    Icon(Icons.visibility_rounded, color: AppColors.royalBlue, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'مستوى ظهور النتائج للطلاب',
                      style: TextStyle(
                        color: AppColors.midnight,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildResultsVisibilityChips(
                  current: _docText(quiz['results_visibility'], 'hidden'),
                  onChanged: (value) {
                    if (value != null) _shareResults(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _delete,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: BorderSide(color: AppColors.danger.withValues(alpha: 0.35), width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.delete_rounded, size: 18),
              label: const Text(
                'حذف هذا الكويز نهائياً',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ],
        );
      },
    );
  }"""

match = re.search(pattern, content, re.DOTALL)
if match:
    content = content.replace(match.group(1), new_build)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("REPLACE_SUCCESS")
else:
    print("REPLACE_PATTERN_NOT_FOUND")
